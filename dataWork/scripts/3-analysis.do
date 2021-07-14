* **********************************************************************
* Project: SSB tax in the Philippines
* Created: June 2021
* Last modified 2020/06/06 by AK
* Stata v.15.1
* **********************************************************************
* Run  diff-in-diff
* Run propensity score match

* Turn sample weight on and off here
global weight = "[aw=rfact]"
//global weight = ""

* Declare variables for regressions
global treatment "treat_513 treat_7 treat_10 treat_1316"
global ssbvar    "tssb tssb_exp tssb_inc"
global lnssbvar  "lntssb lntssb_exp lntssb_inc"
global subsvar   "tdnossb tfruits tconf tsweet tsubst"
global lnsubsvar "lntdnossb lntfruits lntconf lntsweet lntsubst"
global placebo   "tcloth tfurn"
global lnplacebo "lntcloth lntfurn"
global covar1    "fsize      ageless5  age5_17   toinc i.age i.agind i.sex i.hhtype   num_bed i.p4s i.cw i.bldg_type"  //vector of household level characteristics
global lncovar1  "lnfsize lnageless5 lnage5_17 lntoinc i.age i.agind i.sex i.hhtype lnnum_bed i.p4s i.cw i.bldg_type"

* **********************************************************************
* 1a - Pooled OLS no covariates - 2015 and 2018
* **********************************************************************

* DID will deal with selection on unobservables as long as the bias from it is time-invariant, conditional on covariates
  use "$analysis/FIES_20152018append_SSB.dta", clear
  rename tclothfootwear tcloth
  rename lntclothfootwear lntcloth
  rename tfurnishing tfurn
  rename lntfurnishing lntfurn
  eststo clear
  
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
	
* Run DiD regression with no controls using reghdfe	
  foreach i in $ssbvar $lnssbvar $subsvar $lnsubsvar $placebo $lnplacebo {
	foreach j in $treatment { 
		eststo nofe`i'`j': reghdfe `i' i.time##i.`j' $weight , noabsorb            vce(cluster w_prov)  //how to cluster? by time period? by prov?
		margins time#`j' // expected SSB consumption for each group in each time period
		margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
		eststo prov`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(w_prov)      vce(cluster w_prov)
		//eststo urb`i'`j':  reghdfe `i' i.time##i.`j' $weight , absorb(urb)         vce(cluster w_prov) 
		eststo urpr`i'`j': reghdfe `i' i.time##i.`j' $weight , absorb(urb w_prov) vce(cluster w_prov) 	
	}
  } 
//esttab provtssbtreat_7 provlntssbtreat_7, noomit nobase
//esttab nofetssb_share_exptreat_7, noomit nobase

* **********************************************************************
* 1b - Pooled OLS with covariates- 2015 and 2018
* **********************************************************************
  
* Run DiD regression with parsimonious covariates (levels)
  foreach i in $ssbvar $subsvar $placebo  {
	foreach j in $treatment { 
		eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , noabsorb            vce(cluster w_prov)  //how to cluster? by time period? by prov?
		margins time#`j' // expected SSB consumption for each group in each time period
		margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
		eststo provc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(w_prov)      vce(cluster w_prov)
		eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $covar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
	}
  }

* Run DiD regression with parsimonious covariates (log)
  foreach i in $lnssbvar $lnsubsvar $lnplacebo  {
	foreach j in $treatment { 
		eststo nofec`i'`j': reghdfe `i' i.time##i.`j' $lncovar1 $weight , noabsorb            vce(cluster w_prov)  //how to cluster? by time period? by prov?
		margins time#`j' // expected SSB consumption for each group in each time period
		margins `j', dydx(time) // change in SSB consumption in 2015 and 2018 for each group
		eststo provc`i'`j': reghdfe `i' i.time##i.`j' $lncovar1 $weight , absorb(w_prov)      vce(cluster w_prov)
		eststo urprc`i'`j': reghdfe `i' i.time##i.`j' $lncovar1 $weight , absorb(urb w_prov) vce(cluster w_prov) 	
	}
  }
 
* **********************************************************************
* 1c - Regression tables- 2015 and 2018
* **********************************************************************
 
  /*esttab using "$output/didpcovar.tex", replace starlevels(* .1 ** .05 *** .01) se ar2 b(a2)     ///
	nonumber nobaselevels noomitted nonote interaction(" x ") label ///
	rename (treat treat)... /// FIX THIS */
	
* Delete the tables if they already exist		
  foreach i in $ssbvar $lnssbvar $subsvar $lnsubsvar $placebo $lnplacebo {
	 cap erase "$output/tables/did_`i'.csv"
  }
  
* Generate a table for each variable of interest containing all models		
  foreach i in $ssbvar $lnssbvar $subsvar $lnsubsvar $placebo $lnplacebo {
	foreach j in $treatment { 
	  esttab nofe`i'`j' nofec`i'`j' prov`i'`j' provc`i'`j' urpr`i'`j' urprc`i'`j' ///
		using "$output/tables/did_`i'.csv", append starlevels(* .1 ** .05 *** .01) se ar2 b(a2)  ///
		nobaselevels noomitted nonote oblast interaction(" x ") label ///
		mtitles("base" "w/covars" "prov fe" "w/covars" "prov&urb fe" "w/covars") ///
		postfoot("& & & & \\" `"\hline"') ///
		prehead( `"\begin{table}[htbp]"' ///
		`"\centering"' ///
		`"\hspace*{-1.2cm}"' ///
		`"\begin{threeparttable}"' ///
		`"\caption{Baseline characteristics and game interactions }"' ///
		`"\label{tab:farmchar}"' ///
		`"\begin{tabular}{l cccc}"' ///
		`"\hline"' `"\hline"')
	}
  }
/*
* Copy outputs to Overleaf
  * Grab filenames in output/tables
  local tables : dir "$dataWork/output/tables" files *

* Loop over all files in outputs/tables
  foreach filename of local tables {
    copy        "$dataWork/output/tables/`filename'"             ///
                "$dropbox/Apps/Overleaf/SSB-thesis/tables/`filename'"  ///
                , replace
  }
  
/*
* **********************************************************************
* 2 - Pooled OLS - 2009 and 2018
* **********************************************************************

*a-  all the predata with year fixed effects
*leads - look at problem set on elads and lags - show treatment effect for each year 
*

* **********************************************************************
* 3 - Propensity score matching  --> FINISH THE DIFF AND DIFF FIRST. including the paper
* **********************************************************************
// Daw and Hatfield (2018) -> pSM will not take care of parallel trends if it doesnt exist.
// matching and weighting will take care of the selection into treatment based on observables, 
// use (ssc install) -psmatch2- command to obtain matched treatment and control groups, and then use the matched sample to do DID analysis.

//psmatch2 (variable that defines treatment group) (variables that define the characteristics of the households 1,2,...), out(outcome var) -> probit
//psmatch2 trade, mahalanobis(carac1 carac2) out(outvar)    -> logit
 
* Psmatch and lpscore following Emilia's pset 
  use "$analysis/FIES_20152018append_SSB.dta", clear
 
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
