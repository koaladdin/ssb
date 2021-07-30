* **********************************************************************
* Project: SSB tax in the Philippines
* Created: June 2021
* Last modified 2020/07/30 by AK
* Stata v.15.1
* **********************************************************************
* Run  diff-in-diff
* Run propensity score match

* Try changing logs to inverse hyperbolic sine functions

* Turn sample weight on and off here
  global weight = "[aw=rfact]"
//global weight = ""

* Declare variables for regressions
  global treatment "tr513 tr7 tr10 tr1316"
  global ssbvar    "tssb tssb_exp tssb_inc"
  global lnssbvar  "lntssb lntssb_exp lntssb_inc"
  global subsvar   "tsubst tsubst_inc tsubst_exp tdnossb tdnossb_inc tdnossb_exp tfruits tfruits_inc tfruits_exp tconf tconf_inc tconf_exp tsweet tsweet_inc tsweet_exp"
  global lnsubsvar "lntsubst lntsubst_inc lntsubst_exp lntdnossb lntdnossb_inc lntdnossb_exp lntfruits lntfruits_inc lntfruits_exp lntconf lntconf_inc lntconf_exp lntsweet lntsweet_inc lntsweet_exp"
  global placebo   "tcloth tcloth_inc tcloth_exp tfurn tfurn_inc tfurn_exp"
  global lnplacebo "lntcloth lntcloth_inc lntcloth_exp lntfurn lntfurn_inc lntfurn_exp"
  global covar1    "fsize   ageless5   age5_17 i.urb   toinc   thealth   age i.agind i.sex   num_bed " 
  global lncovar1  "fsize   ageless5   age5_17 i.urb lntoinc   thealth   age i.agind i.sex   num_bed " 
  global covar2    "fsize   ageless5   age5_17 i.urb   toinc   thealth   age i.agind i.sex   " 
  global lncovar2  "fsize   ageless5   age5_17 i.urb lntoinc   thealth   age i.agind i.sex   "
  global covar3    "fsize   ageless5   age5_17 i.urb   toinc   thealth   age i.agind i.sex   num_bed i.(cw p4s bldg_type hhtype)" 
  global lncovar3  "fsize   ageless5   age5_17 i.urb lntoinc   thealth   age i.agind i.sex   num_bed i.(cw p4s bldg_type hhtype)" 

* Check if need to remove covars (eg. adding agless5 will drop 2,500hh in 2015 and 5,400hh in 2018) //95% of data kept
  //misstable patterns tssb fsize   ageless5     age5_17 urb   toinc   thealth   age agind sex   num_bed //95% of data kept
  //misstable patterns tssb fsize   ageless5     age5_17 urb   toinc   thealth   age agind sex   num_bed cw p4s bldg_type hhtype // 76% of data kept
  //number of beds does not exist in fies 2012 num_bed lnnum_bed
  //dont ln nummber. 17,883 across both 2015 and 2018 dont have a bedroom so ln takes them away.
  
* **********************************************************************
* 1a - Pooled OLS on levels - 2015 and 2018 ssb and subst
* **********************************************************************
* eststo has a limit of 300, so all the variables cannot be run in the same loop. 300/4treatmentgroups/4regressionmods = 18 vars at a time only

* DID will deal with selection on unobservables as long as the bias from it is time-invariant, conditional on covariates
  use "$analysis/FIES_20152018append_SSB.dta", clear

* Run DiD regression with no controls using regress //same estimates as reghdfe but diff se because of clustering
  /*foreach i in $ssbvar $lnssbvar {
	foreach j in $treatment { 
		eststo did`i'`j': regress `i' i.time##i.`j' $weight , robust
		margins time#`j' // expected SSB consumption for each group in each time period
		margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
	}
  }  
  esttab using "$output/did.csv", replace starlevels(* .1 ** .05 *** .01) se ar2 b(a2)     ///
	nonumber nobaselevels noomitted nonote interaction(" x ") label
   */
   
* Run DiD regression in a loop for all variables  
  global sets "ssbvar subsvar placebo lnssbvar lnsubsvar lnplacebo"
  foreach k in $sets {
	eststo clear
	foreach i in $`k' {
		foreach j in $treatment { 
			quietly eststo provc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight             , absorb(w_prov)   vce(cluster w_prov)
				quietly estadd local fixedp "Yes", replace
				quietly estadd ysumm, replace		
					cap drop sample
					generate sample = e(sample)
			quietly eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight if sample==1, noabsorb         vce(cluster w_prov) 
				quietly estadd local fixedp "No", replace
				quietly estadd ysumm, replace		
			quietly eststo prov`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, absorb(w_prov)   vce(cluster w_prov)
				quietly estadd local fixedp "Yes", replace
				quietly estadd ysumm, replace	
			quietly eststo nofe`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, noabsorb         vce(cluster w_prov)
				quietly estadd local fixedp "No", replace
				quietly estadd ysumm, replace		
			//eststo urb`i'`j':  reghdfe `i' i.time##i.`j' $weight , absorb(urb)         vce(cluster w_prov) 
			//quietly eststo urpr`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(urb w_prov) vce(cluster w_prov) 	
			//quietly eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
			//margins time#`j' // expected SSB consumption for each group in each time period
			//margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
		}
	  } 
	* Delete the tables if they already exist	(levels)	
	  foreach i in $`k' {
		 cap erase "$output/tables/did_`i'.tex"
	  }
	* Generate a complete table for each variable of interest for the appendix
	  foreach i in $`k' {
		foreach j in $treatment { 
		  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
			using "$output/tables/did_`i'.tex", append ///
			starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
			nobaselevels noomitted nonote interaction(" x ")  label ///
			s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
			mtitles("base" "w/covars" "prov fe" "w/covars") 
		}
	  }
	* Generate a table for each variable of interest for the main table       
	  foreach i in $`k' {
		 cap erase "$output/tables/main_`i'.tex"
		 esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
			using "$output/tables/main_`i'.tex", append ///
			drop(*) ///
			mtitles("base" "w/covars" "prov fe" "w/covars") ///
			noobs nobaselevels nonote ///
			prehead( `"\begin{table}[htbp]"' ///
			`"\centering"' ///
			`"\hspace*{-1.2cm}"' ///
			`"\begin{threeparttable}"' ///
			`"\caption{Impact of SSB tax on `: var label `i''}"' ///
			`"\label{tab:`i'}"' ///
			`"\begin{tabular}{l cccc}"' ///
			`"\hline"' `"\hline"') ///
			postfoot(`""') 
	  }
	 foreach i in $`k' {
		foreach j in $treatment { 
		  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
			using "$output/tables/main_`i'.tex", append ///
			keep( *.time#*`j' ) ///
			starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
			nobaselevels noomitted nonote noobs interaction(" x ") nolines  ///
			eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}"))  label ///
			prehead( `""' ) mlabels(none) collabels(none) refcat(*.time#*.`j' "`: var label `j''") ///
			postfoot("& & & & \\" `"\hline"') ///
	// 		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
	// 		mtitles("base" "w/covars" "prov fe" "w/covars") ///
		} 
	  }
	foreach i in $`k' {
		esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
			using "$output/tables/main_`i'.tex", append ///
			drop(*) ///
			nobaselevels noomitted nonote noobs nomtitles interaction(" x ")   ///
			eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}")) label ///
			prehead(`""') mlabels(none) collabels(none) ///
			s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
			postfoot(`"\hline"' `"\hline"' ///
			`"\end{tabular}"' `"\end{threeparttable}"' `"\end{table}"') 
	  }
	  
  }
 
 
  eststo clear	
* Run DiD regression for ssb and substitutes	(levels)     
  foreach i in $ssbvar $subsvar {
	foreach j in $treatment { 
		quietly eststo provc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight             , absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace		
				cap drop sample
				generate sample = e(sample)
		quietly eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight if sample==1, noabsorb         vce(cluster w_prov) 
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		quietly eststo prov`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace	
		quietly eststo nofe`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, noabsorb         vce(cluster w_prov)
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		//eststo urb`i'`j':  reghdfe `i' i.time##i.`j' $weight , absorb(urb)         vce(cluster w_prov) 
		//quietly eststo urpr`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//quietly eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//margins time#`j' // expected SSB consumption for each group in each time period
		//margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
	}
  } 
* Delete the tables if they already exist	(levels)	
  foreach i in $ssbvar $subsvar {
	 cap erase "$output/tables/did_`i'.tex"
  }
* Generate a complete table for each variable of interest for the appendix
  foreach i in $ssbvar $subsvar {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/did_`i'.tex", append ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote interaction(" x ")  label ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		mtitles("base" "w/covars" "prov fe" "w/covars") 
	}
  }
* Generate a table for each variable of interest for the main table       
  foreach i in $ssbvar $subsvar {
	 cap erase "$output/tables/main_`i'.tex"
	 esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		mtitles("base" "w/covars" "prov fe" "w/covars") ///
		noobs nobaselevels nonote ///
		prehead( `"\begin{table}[htbp]"' ///
		`"\centering"' ///
		`"\hspace*{-1.2cm}"' ///
		`"\begin{threeparttable}"' ///
		`"\caption{Impact of SSB tax on `: var label `i''}"' ///
		`"\label{tab:`i'}"' ///
		`"\begin{tabular}{l cccc}"' ///
		`"\hline"' `"\hline"') ///
		postfoot(`""') 
  }
  foreach i in $ssbvar $subsvar {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/main_`i'.tex", append ///
		keep( *.time#*`j' ) ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote noobs interaction(" x ") nolines  ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}"))  label ///
		prehead( `""' ) mlabels(none) collabels(none) refcat(*.time#*.`j' "`: var label `j''") ///
		postfoot("& & & & \\" `"\hline"') ///
// 		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
// 		mtitles("base" "w/covars" "prov fe" "w/covars") ///
	} 
  }
foreach i in $ssbvar $subsvar {
	esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		nobaselevels noomitted nonote noobs nomtitles interaction(" x ")   ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}")) label ///
		prehead(`""') mlabels(none) collabels(none) ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		postfoot(`"\hline"' `"\hline"' ///
		`"\end{tabular}"' `"\end{threeparttable}"' `"\end{table}"') 
  }

* **********************************************************************
* 1a - Pooled OLS on levels - 2015 and 2018 placebo
* **********************************************************************
  eststo clear
* Run DiD regression for placebo (levels)
  foreach i in $placebo  {
	foreach j in $treatment { 
		quietly eststo provc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight             , absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace		
				cap drop sample
				generate sample = e(sample)
		quietly eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight if sample==1, noabsorb         vce(cluster w_prov) 
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		quietly eststo prov`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace	
		quietly eststo nofe`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, noabsorb         vce(cluster w_prov)
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		//eststo urb`i'`j':  reghdfe `i' i.time##i.`j' $weight , absorb(urb)         vce(cluster w_prov) 
		//quietly eststo urpr`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//quietly eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//margins time#`j' // expected SSB consumption for each group in each time period
		//margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
	}
  }   
* Delete the tables if they already exist	(levels)	
  foreach i in $placebo {
	 cap erase "$output/tables/did_`i'.tex"
  }  
* Generate a complete table for each variable of interest for the appendix
  foreach i in  $placebo {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/did_`i'.tex", append ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote interaction(" x ") label ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		mtitles("base" "w/covars" "prov fe" "w/covars" ) ///
		//booktabs postfoot("& & & & \\" `"\hline"') ///
	}
  }
* Generate a table for each variable of interest for the main table       
  foreach i in $placebo {
	 cap erase "$output/tables/main_`i'.tex"
	 esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		mtitles("base" "w/covars" "prov fe" "w/covars") ///
		noobs nobaselevels nonote ///
		prehead( `"\begin{table}[htbp]"' ///
		`"\centering"' ///
		`"\hspace*{-1.2cm}"' ///
		`"\begin{threeparttable}"' ///
		`"\caption{Impact of SSB tax on `: var label `i''}"' ///
		`"\label{tab:`i'}"' ///
		`"\begin{tabular}{l cccc}"' ///
		`"\hline"' `"\hline"') ///
		postfoot(`""') 
  }
  foreach i in $placebo {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/main_`i'.tex", append ///
		keep( *.time#*`j' ) ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote noobs interaction(" x ") nolines  ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}"))  label ///
		prehead( `""' ) mlabels(none) collabels(none) refcat(*.time#*.`j' "`: var label `j''") ///
		postfoot("& & & & \\" `"\hline"') ///
// 		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
// 		mtitles("base" "w/covars" "prov fe" "w/covars") ///
	} 
  }
foreach i in $placebo {
	esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		nobaselevels noomitted nonote noobs nomtitles interaction(" x ")   ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}")) label ///
		prehead(`""') mlabels(none) collabels(none) ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		postfoot(`"\hline"' `"\hline"' ///
		`"\end{tabular}"' `"\end{threeparttable}"' `"\end{table}"') 
  }
  
* **********************************************************************
* 1b - Pooled OLS on logs - 2015 and 2018 - lnssb lnsubs
* **********************************************************************
  eststo clear 
* Run DiD regression for ssb and subst with using reghdfe	(log)
   foreach i in $lnssbvar $lnsubsvar {
	foreach j in $treatment { 
		quietly eststo provc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight             , absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace		
				cap drop sample
				generate sample = e(sample)
		quietly eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight if sample==1, noabsorb         vce(cluster w_prov) 
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		quietly eststo prov`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace	
		quietly eststo nofe`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, noabsorb         vce(cluster w_prov)
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		//eststo urb`i'`j':  reghdfe `i' i.time##i.`j' $weight , absorb(urb)         vce(cluster w_prov) 
		//quietly eststo urpr`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//quietly eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//margins time#`j' // expected SSB consumption for each group in each time period
		//margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
	}
  } 
* Delete the tables if they already exist		
  foreach i in $lnssbvar $lnsubsvar {
	 cap erase "$output/tables/did_`i'.tex"
  }
* Generate a complete table for each variable of interest for the appendix
  foreach i in $lnssbvar $lnsubsvar {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/did_`i'.tex", append ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		nobaselevels noomitted nonote interaction(" x ") label ///
		mtitles("base" "w/covars" "prov fe" "w/covars") ///
	}
  }
 * Generate a table for each variable of interest for the main table       
  foreach i in $lnssbvar $lnsubsvar {
	 cap erase "$output/tables/main_`i'.tex"
	 esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		mtitles("base" "w/covars" "prov fe" "w/covars") ///
		noobs nobaselevels nonote ///
		prehead( `"\begin{table}[htbp]"' ///
		`"\centering"' ///
		`"\hspace*{-1.2cm}"' ///
		`"\begin{threeparttable}"' ///
		`"\caption{Impact of SSB tax on `: var label `i''}"' ///
		`"\label{tab:`i'}"' ///
		`"\begin{tabular}{l cccc}"' ///
		`"\hline"' `"\hline"') ///
		postfoot(`""') 
  }
  foreach i in $lnssbvar $lnsubsvar {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/main_`i'.tex", append ///
		keep( *.time#*`j' ) ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote noobs interaction(" x ") nolines  ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}"))  label ///
		prehead( `""' ) mlabels(none) collabels(none) refcat(*.time#*.`j' "`: var label `j''") ///
		postfoot("& & & & \\" `"\hline"') ///
// 		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
// 		mtitles("base" "w/covars" "prov fe" "w/covars") ///
	} 
  }
foreach i in $lnssbvar $lnsubsvar {
	esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		nobaselevels noomitted nonote noobs nomtitles interaction(" x ")   ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}")) label ///
		prehead(`""') mlabels(none) collabels(none) ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		postfoot(`"\hline"' `"\hline"' ///
		`"\end{tabular}"' `"\end{threeparttable}"' `"\end{table}"') 
  } 
 
* **********************************************************************
* 1b - Pooled OLS on logs - 2015 and 2018 - ln placebo
* **********************************************************************
  eststo clear
* Run DiD regression for placebo with using reghdfe	(log)
  foreach i in $lnplacebo  {
	foreach j in $treatment {  
		quietly eststo provc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight             , absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace		
				cap drop sample
				generate sample = e(sample)
		quietly eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight if sample==1, noabsorb         vce(cluster w_prov) 
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		quietly eststo prov`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace	
		quietly eststo nofe`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, noabsorb         vce(cluster w_prov)
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		//eststo urb`i'`j':  reghdfe `i' i.time##i.`j' $weight , absorb(urb)         vce(cluster w_prov) 
		//quietly eststo urpr`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//quietly eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//margins time#`j' // expected SSB consumption for each group in each time period
		//margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
	}
}
* Delete the tables if they already exist		
  foreach i in $lnplacebo  {
	 cap erase "$output/tables/did_`i'.tex"
  }
* Generate a complete table for each variable of interest for the appendix
  foreach i in $lnplacebo  {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/did_`i'.tex", append ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		nobaselevels noomitted nonote interaction(" x ") label ///
		mtitles("base" "w/covars" "prov fe" "w/covars" ) ///
	}
  }
   foreach i in $lnplacebo{
	 cap erase "$output/tables/main_`i'.tex"
	 esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		mtitles("base" "w/covars" "prov fe" "w/covars") ///
		noobs nobaselevels nonote ///
		prehead( `"\begin{table}[htbp]"' ///
		`"\centering"' ///
		`"\hspace*{-1.2cm}"' ///
		`"\begin{threeparttable}"' ///
		`"\caption{Impact of SSB tax on `: var label `i''}"' ///
		`"\label{tab:`i'}"' ///
		`"\begin{tabular}{l cccc}"' ///
		`"\hline"' `"\hline"') ///
		postfoot(`""') 
  }
  foreach i in $lnplacebo {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/main_`i'.tex", append ///
		keep( *.time#*`j' ) ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote noobs interaction(" x ") nolines  ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}"))  label ///
		prehead( `""' ) mlabels(none) collabels(none) refcat(*.time#*.`j' "`: var label `j''") ///
		postfoot("& & & & \\" `"\hline"') ///
// 		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
// 		mtitles("base" "w/covars" "prov fe" "w/covars") ///
	} 
  }
foreach i in $lnplacebo {
	esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		nobaselevels noomitted nonote noobs nomtitles interaction(" x ")   ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}")) label ///
		prehead(`""') mlabels(none) collabels(none) ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		postfoot(`"\hline"' `"\hline"' ///
		`"\end{tabular}"' `"\end{threeparttable}"' `"\end{table}"') 
  } 
  
* **********************************************************************
* 2 - Pooled OLS - 2012 and 2015 -> placebo regression
* **********************************************************************
*note: covars do not include num_bed because num_bed is not available in 2012

* Use the proper file and rename treatments so they dont exceed var name limit
  use "$analysis/FIES_20122015append_SSB.dta", clear
  rename  treat_513  tr513
  rename  treat_7    tr7
  rename  treat_10   tr10
  rename  treat_1316 tr1316

  eststo clear
  * Run DiD regression for ssb and substitutes	(levels)
  foreach i in $ssbvar $lnssbvar {
	foreach j in $treatment { 
		quietly eststo provc`i'`j': reghdfe `i' i.time##i.`j' $covar2 $weight             , absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace		
				cap drop sample
				generate sample = e(sample)
		quietly eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $covar2 $weight if sample==1, noabsorb         vce(cluster w_prov) 
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		quietly eststo prov`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, absorb(w_prov)   vce(cluster w_prov)
			quietly estadd local fixedp "Yes", replace
			quietly estadd ysumm, replace	
		quietly eststo nofe`i'`j':  reghdfe `i' i.time##i.`j'         $weight if sample==1, noabsorb         vce(cluster w_prov)
			quietly estadd local fixedp "No", replace
			quietly estadd ysumm, replace		
		//eststo urb`i'`j':  reghdfe `i' i.time##i.`j' $weight , absorb(urb)         vce(cluster w_prov) 
		//quietly eststo urpr`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//quietly eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
		//margins time#`j' // expected SSB consumption for each group in each time period
		//margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
	}
  } 
* Delete the tables if they already exist	
  foreach i in $ssbvar $lnssbvar {
	 cap erase "$output/tables/p_did_`i'.tex"
  }
* Generate a complete table for each variable of interest for the appendix
  foreach i in $ssbvar $lnssbvar {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/p_did_`i'.tex", append ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote interaction(" x ") label ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		mtitles("base" "w/covars" "prov fe" "w/covars") ///
	}
  }
* Generate a table for each variable of interest for the main table       
  foreach i in $ssbvar $subsvar {
	 cap erase "$output/tables/main_`i'.tex"
	 esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		mtitles("base" "w/covars" "prov fe" "w/covars") ///
		noobs nobaselevels nonote ///
		prehead( `"\begin{table}[htbp]"' ///
		`"\centering"' ///
		`"\hspace*{-1.2cm}"' ///
		`"\begin{threeparttable}"' ///
		`"\caption{Impact of SSB tax on `: var label `i''}"' ///
		`"\label{tab:`i'}"' ///
		`"\begin{tabular}{l cccc}"' ///
		`"\hline"' `"\hline"') ///
		postfoot(`""') 
  }
  foreach i in $ssbvar $subsvar {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' ///
		using "$output/tables/main_`i'.tex", append ///
		keep( *.time#*`j' ) ///
		starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote noobs interaction(" x ") nolines  ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}"))  label ///
		prehead( `""' ) mlabels(none) collabels(none) refcat(*.time#*.`j' "`: var label `j''") ///
		postfoot("& & & & \\" `"\hline"') ///
// 		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
// 		mtitles("base" "w/covars" "prov fe" "w/covars") ///
	} 
  }
foreach i in $ssbvar $subsvar {
	esttab nofe`i'tr7 nofec`i'tr7 prov`i'tr7 provc`i'tr7 ///
		using "$output/tables/main_`i'.tex", append ///
		drop(*) ///
		nobaselevels noomitted nonote noobs nomtitles interaction(" x ")   ///
		eqlabels(, prefix("\multicolumn{1}{c}{") suffix ("}")) label ///
		prehead(`""') mlabels(none) collabels(none) ///
		s(fixedp N ymean,label("Province FE" "Observations" "Mean of Dep. Variable")) ///
		postfoot(`"\hline"' `"\hline"' ///
		`"\end{tabular}"' `"\end{threeparttable}"' `"\end{table}"') 
  }  
* **********************************************************************
* 3 - Propensity score matching  --> FINISH THE DIFF AND DIFF FIRST. including the paper
* **********************************************************************
// Daw and Hatfield (2018) -> pSM will not take care of parallel trends if it doesnt exist.
// matching and weighting will take care of the selection into treatment based on observables, 
// use (ssc install) -psmatch2- command to obtain matched treatment and control groups, and then use the matched sample to do DID analysis.

//psmatch2 (variable that defines treatment group) (variables that define the characteristics of the households 1,2,...), out(outcome var) -> probit
//psmatch2 trade, mahalanobis(carac1 carac2) out(outvar)    -> logit
 
* Psmatch and lpscore following Emilia's pset 
 /* use "$analysis/FIES_20152018append_SSB.dta", clear
 
  foreach i in tssb lntssb tssb_share_exp lntssb_share_exp tssb_share_inc lntssb_share_inc {
	foreach j in treat_513 treat_7 treat_10 treat_1316 { 
		logit `i' `j'  urb agind fsize toinc hgc occup //tssb_2015
		predict double pscore if e(sample), pr
		gen double lpscore = ln(pscore/(1-pscore)) if e(sample)
		sum lpscore
	  forvalues k = 1/20 {
			quietly psmatch2 `j', outcome(`i') pscore(lpscore) n(`k') ties
			pstest lpscore urb agind fsize toinc hgc occup, treated (`j') both
* Create density plots		
			twoway (kdensity lpscore if `j' == 1, lcolor(gs10)) (kdensity lpscore if `j' == 0, lpattern(dash) ylabel(, nogrid) ytitle("Density") xtitle("Linearized propensity score") lcolor(black)), graphregion(color(white)) legend(lab(1 "Treated") lab(2 "Raw controls"))
			graph export "$output/densraw_`k'.png", replace
			twoway (kdensity lpscore if `j' == 1 [aw = _weight], lcolor(gs10)) (kdensity lpscore if `j' == 0 [aw = _weight], lpattern(dash) ylabel(, nogrid) ytitle("Density") xtitle("Linearized propensity score") lcolor(black)), graphregion(color(white)) legend(lab(1 "Treated") lab(2 "Matched controls"))
			graph export "$output/densmatched_`k'.png", replace

	   }
	}
  }
 
*estimate propensity score and match
psmatch2 treat_513 toinc tfood, out(ssb) common //common - see estimates based on common support - overlap in propensity scores
//psmatch2 treat_513 aginc nagin othin toinc tfood, out(ssb) common

//only 29 observations off support
//estimates 291peso decrease in ssb consumption

*evaluate match grapically
psgraph //plot the pscore before and after

*evaluate match with tests
pstest toinc tfood //check extent bias is reduced, threshold usually 5%

psmatch2 treat_513 toinc tfood, out(ssb) neighbor(1) noreplace caliper(0.01) ate
psmatch 

// psmatch2, then control for propensity score in the DID regression as covariate
// estimate DID as normal, weight the regression using frequency weights generated from the psmatch2 process
// explore diff command


/*
* **********************************************************************
* 0 - Open data
* **********************************************************************
  use "$dataWork/data/inter/hourlyPM", clear

* Run DiD regression
eststo clear
eststo nofe: reghdfe logpm i.treat##i.lockdown, noabsorb vce(cluster month)
eststo week: reghdfe logpm i.treat##i.lockdown, absorb(week) vce(cluster month)
eststo month: reghdfe logpm i.treat##i.lockdown, absorb(month) vce(cluster month)

esttab using "$dataWork/output/tables/did.tex", replace starlevels(* .1 ** .05 *** .01) se ar2 b(a2)     ///
  nonumber nobaselevels noomitted nonote interaction(" x ") label

*** from STATALIST 
 
/* (1) -diff- to get ATT */
diff fte, treated(treated) period(t) id(id) cov(bk kfc roys) kernel ktype(gaussian) support bw(0.05) cluster(id) robust //
assert _support==1


/* (2a) Regression Using Kernel Weights for ATE */
reg fte i.treated##i.t [aw=_weights], cluster(id) robust

xtset id t

xtreg fte i.treated##i.t [aw=_weights], fe cluster(id) robust

/* Create ATT and ATE Weights for regressions*/
/* You can install -xfill- by typing net from https://www.sealedenvelope.com/ and clicking on the name */
xfill _ps, i(id)

gen double w_att = cond(treated==1,1,_ps/(1-_ps))
gen double w_ate = cond(treated==1,1/_ps,1/(1-_ps))

/* (2b) Regression Using ATT and ATE IPW Weights */
reg fte i.treated##i.t [pw=w_att] /*if _support==1*/, cluster(id) robust
xtreg fte i.treated##i.t [pw=w_att], fe cluster(id) robust
xtreg fte i.treated##i.t [pw=w_ate], fe cluster(id) robust

//With IPW, things can go south if the estimated propensity scores are near zero or 1 since you would be dividing by small number
//Asymptotically, both PSM and IPW should give you the same answer (though I cannot recall where I saw this result)

/* (3) psmatch2 for ATE and ATT */
keep id fte treated t bk kfc roys
qui reshape wide fte, i(id treated bk kfc roys) j(t)
gen did_fte = fte1 - fte0
psmatch2 treated bk kfc roys, outcome(fte0 fte1 did_fte) kernel kerneltype(normal) bw(0.05) common ate

/* (4) IPW Matching ATT=ATET and ATE */
teffects ipw (did_fte) (treated bk kfc roys, probit), atet vce(robust) // osample(ipw1)  
teffects ipw (did_fte) (treated bk kfc roys, probit), ate vce(robust) // osample(ipw2)  

// get same resukts for 1 and 2a, 3 (did_fte att), 4-2
// get same results for 2b and 4-1 (atet)

	esttab using "$dataWork/analysis/output/tables/farmchar.tex", cells("mean(fmt(a2)) sd(fmt(a2)) min(fmt(a2)) max(fmt(a2))") unstack ///
		collabels("Mean""Std Deviation""Min""Max", begin("Panel A: Farmer and plot characteristics"))  ///
		eqlabels(none) label noobs nonum legend style (tex) mlabels (none) ///
		postfoot("& & & & \\" `"\hline"') ///
		prehead( `"\begin{table}[htbp]"' ///
		`"\centering"' ///
		`"\hspace*{-1.2cm}"' ///
		`"\begin{threeparttable}"' ///
		`"\caption{Baseline characteristics and game interactions }"' ///
		`"\label{tab:farmchar}"' ///
		`"\begin{tabular}{l cccc}"' ///
		`"\hline"' `"\hline"') replace

		esttab using "$dataWork/analysis/output/tables/farmchar.tex", cells("mean(fmt(a2)) sd(fmt(a2)) min(fmt(a2)) max(fmt(a2))") unstack ///
			collabels("Mean""Std Deviation""Min""Max", begin("Panel B: Game play")) ///
			eqlabels(none) label nonum legend style (tex) mlabels (none) ///
			prehead (%) ///
			postfoot(`"\hline"' `"\hline"' ///
			`"\end{tabular}"' `"\end{threeparttable}"' `"\end{table}"') append
