* **********************************************************************
* Project: SSB tax in the Philippines
* Created: June 2021
* Last modified 2021/07/6 by AK
* Stata v.15.1
* **********************************************************************
* Generates variables for SSB and others
* Creates FIES 2015 and 2018 merged data set for POLS
* merge PSGC variable 
* figure out how to include FIES 2009 in the loop

//TO DO:
**ask emilia if need to recode dummy variables to 0,1 from 1,2. Clyde says no changes in prediction. Just cant use it as dependent variable.

* **********************************************************************
* 1 - Generate SSB variables and more compact version of FIES
* **********************************************************************
* Import FIES
  //global FIES2006  "$raw/fies2006.dta" //no province!!!
  //egen ssb = rowtotal(tea cocoa carbd ncarb othdr) //for FIES2006
  
  global FIES2009  "$raw/FIES 2009 long_format"
  global FIES2012  "$raw/FIES2012_v2"
  global FIES2015  "$raw/FIES2015full_raw_v3.dta"
  global FIES2018  "$raw/FIES2018_v2.dta" 
  global pricedata "$analysis/pricedata.dta"
  
* FIES 2009
  use "$FIES2009", clear
* Rename variables to have same variables  
  rename w_prv w_prov //for FIES 2009
  rename totex ttotex //for FIES 2009
  gen    pov_ind = pov_thresh > toinc
  rename natpc             pcinc_decile
  rename natdc             toinc_decile
  rename regpc             reg_pcdecile
  rename z2011_h_sex       sex
  rename z2021_h_age       age
  rename z2031_h_ms        ms
  rename z2041_h_educ      hgc
  rename z2051_h_has_job   job
  rename z2061_h_occup     occup
  rename z2071_h_kb        kb
  rename z2081_h_cw        cw
  rename z2091_hhld_type   hhtype
  rename z2101_tot_mem     members
  rename z2181_wife_emp    spouse_emp
  rename b4011_bldg_type   bldg_type
  rename b4021_roof        roof
  rename b4031_walls       walls
  rename b4041_tenure      tenure
  rename b4081_hse_altertn hse_altertn
  rename b5021_toilet      toilet
  rename b5031_electric    electric
  rename b5041_water       water
  rename b5052_n_radio     radio_qty
  rename b5062_n_tv        tv_qty
  rename b5072_n_vtr       cd_qty
  rename b5082_n_stereo    stereo_qty
  rename b5092_n_ref       ref_qty
  rename b5102_n_wash      wash_qty
  rename b5112_n_aircon    aircon_qty
  rename b5142_n_car       car_qty
  rename b5152_n_phone     landline_qty
  rename b5162_n_pc        pc_qty
  rename b5172_n_oven      oven_qty
  rename b5182_n_motor     motorcycle_qty
  rename cloth             tclothfootwear
  rename ndfur             tfurnishing 
  rename trcom             ttransport	
* Generate variables for SSB and substitutes
  egen   tssb    = rowtotal(tea cocoa carbd ncarb soda othdr) //for FIES2009
  rename tmilk tmilks 
  egen tdnossb = rowtotal(tmilks cofct botle)
  egen tfruits = rowtotal(frfrt frpre otpre)
  egen tconf   = rowtotal(sugpr icrem)
  egen tsweet  = rowtotal(sugar)
  egen tsubst  = rowtotal(tdnossb tfruits tconf tsweet)
* Label new variables //same as other years
  label	var	tssb	"Taxable beverage expenditure"
  label	var	tmilks	"Milk expenditure"
  label	var	tdnossb	"Non-taxable beverage expenditure"
  label	var tfruits "Fresh, dried fruits, preserved fruit expenditure"
  label	var	tconf	"Confectionary expenditure"
  label	var	tsweet	"Sugar and honey expenditure"
  label	var tsubst	"SSB substitutes expenditure"
* Keep only necessary variables and drop the rest 
  rename cofct tcoffee
  rename sugar tsugar
  keep   tssb tmilks tdnossb tfruits tconf tsweet tsubst w_regn-rfact sex-ttotex toinc tsugar tcoffee agind tclothfootwear tfurnishing ttransport	pcinc_decile toinc_decile reg_pcdecile //2009
* Generate per capita variables, per capita decile totals, and shares of income and expenditure //same as other years
  foreach var in tssb tsubst ttotex toinc {
	local lbl : variable label `var'
	gen `var'_pc = `var' / fsize
	label var `var'_pc         "`lbl' (per capita)"
	bysort pcinc_decile: egen `var'_total_pc = total(`var'_pc)
	label var `var'_total_pc   "`lbl' (by per capita income decile)"
	gen `var'_share_exp = 100*`var' / ttotex
	label var `var'_share_exp  "`lbl' (share of total expenditure)"
	gen `var'_share_inc = 100*`var' / toinc
	label var `var'_share_inc  "`lbl' (share of total income)"
	//tabstat `var'_pc[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile)
	}		
* Generate SSB indicator (dummy indicator) //same as other years
  gen ssb_stat = (tssb>0) if !missing(tssb)
	di "success6"
* Generate year variable //same as other years
  gen year = 2009
  destring year, replace
  label var year "Year"
* Generate population weight from household weight  //same as other years
  gen popw = rfact*fsize
  label var popw "Population weight"
* Destring variables //same as other years
  destring w_prov, replace
  destring w_shsn, replace
  destring w_hcn,  replace
* Create log of all variables //same as other years
  quietly ds, has(type numeric) 
  quietly ds `r(varlist)', not(vallabel)
  quietly foreach v of varlist `r(varlist)' {
	local     lbl    : variable label `v' 
	gen       ln`v'  = log(`v')  // how to check if im taking logs of zero, negatives or blanks, some do log(v+1)
	label var ln`v' "Log of `lbl'"
	replace   ln`v'  = .m if `v' < 1
	}
	cap drop lnyear_built lnyear
	cap drop lnsequence_no
	cap drop lnw_prov
* Merge in identifiers for treatment and control groups
  merge m:1 w_prov using "$pricedata", generate(mergebyprov)
* Save analysis data
  save "$analysis/FIES_2009_SSB.dta", replace

* FIES 2012
  /*use "$FIES2012", clear
  gen    pov_ind = pov_thresh > toinc
  rename natpc     pcinc_decile
  rename natdc     toinc_decile
  rename regpc     reg_pcdecile
  save, replace*/

* FIES 2012, 2015 and 2018 
  local i = 2012 //need this to be outside loop
  foreach a in "$FIES2012" "$FIES2015" "$FIES2018"  {
	use "`a'", clear
	di "success1"
* Generate variables for SSB and substitutes
  egen tssb    = rowtotal(ttea tcocoa tsoftdrink tfruitjuice tfconcentrates tfothernonalcohol) //milk and coffee exempted
  egen tmilks  = rowtotal(tmraw tcondevap tfdessert tmbeverage tmsoya)
  egen tdnossb = rowtotal(tmilks tcoffee tmineral)
  egen tfruits = rowtotal(tffresh tdfruit tcoconut tpresfruit tkaong tnata)
  egen tconf   = rowtotal(tjamsmar tchocolate tice tothersugar tfnecdessert)
  egen tsweet  = rowtotal(tsugar thoney)
  egen tsubst  = rowtotal(tdnossb tfruits tconf tsweet)
di "success2"
* Label new variables
  label	var	tssb	"Taxable beverage expenditure"
  label	var	tmilks	"Milk expenditure"
  label	var	tdnossb	"Non-taxable beverage expenditure"
  label	var tfruits "Fresh, dried fruits, preserved fruit expenditure"
  label	var	tconf	"Confectionary expenditure"
  label	var	tsweet	"Sugar and honey expenditure"
  label	var tsubst	"SSB substitutes expenditure"
di "success3"
* Keep only necessary variables and drop the rest
	cap keep   tssb tmilks tdnossb tfruits tconf tsweet tsubst w_regn-pcinc ttotex toinc tsugar thoney tcoffee tmineral agind sex-p4s tclothfootwear tfurnishing ttransport	//2015 and 2018
	cap keep   w_regn-fsize ttotex toinc pcinc tsugar thoney tcoffee tmineral agind-pov_thresh pov_ind tssb-tsubst tclothfootwear tfurnishing ttransport pcinc_decile toinc_decile reg_pcdecile //2012
	di "success4"	
* Generate per capita variables, per capita decile totals, and shares of income and expenditure
  foreach var in tssb tsubst ttotex toinc {
	local lbl : variable label `var'
	gen `var'_pc = `var' / fsize
	label var `var'_pc         "`lbl' (per capita)"
	bysort pcinc_decile: egen `var'_total_pc = total(`var'_pc)
	label var `var'_total_pc   "`lbl' (by per capita income decile)"
	gen `var'_share_exp = 100*`var' / ttotex
	label var `var'_share_exp  "`lbl' (share of total expenditure)"
	gen `var'_share_inc = 100*`var' / toinc
	label var `var'_share_inc  "`lbl' (share of total income)"
	//tabstat `var'_pc[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile)
	}		
di "success5	"	
* Generate SSB indicator (dummy indicator)
  gen ssb_stat = (tssb>0) if !missing(tssb)
	di "success6"
* Generate year variable
  gen year = `i'
  destring year, replace
  label var year "Year"
	di "success7"
* Generate population weight from household weight 
  gen popw = rfact*fsize
  label var popw "Population weight"
	di "success8"
* Destring variables
  cap destring w_prov, replace
  cap destring w_mun,  replace
  cap destring w_bgy,  replace
  cap destring w_ea,   replace
  cap destring w_shsn, replace
  cap destring w_hcn,  replace
di "success9"
* Create log of all variables
  quietly ds, has(type numeric) 
  quietly ds `r(varlist)', not(vallabel)
  quietly foreach v of varlist `r(varlist)' {
	local     lbl    : variable label `v' 
	gen       ln`v'  = log(`v')  // how to check if im taking logs of zero, negatives or blanks, some do log(v+1)
	label var ln`v' "Log of `lbl'"
	replace   ln`v'  = .m if `v' < 1
	}
	cap drop lnyear_built lnyear
	cap drop lnsequence_no
	cap drop lnw_prov
	di "success10"
* Merge in identifiers for treatment and control groups
  merge m:1 w_prov using "$pricedata", generate(mergebyprov)
di "success10"	
* Save analysis data
  save "$analysis/FIES_`i'_SSB.dta", replace
  local i = `i' + 3
di "success11"	
	}

* **********************************************************************
* 2 - Create appended FIES 2015 and FIES 2018 (for pooled cross section)
* **********************************************************************
* Append FIES 2015 to 2018
  use "$analysis/FIES_2015_SSB.dta", clear
  append using "$analysis/FIES_2018_SSB.dta"
  gen   time = (year==2018) if !missing(year)
  label define post_ssb 0 "Pre-policy" 1 "Post-policy"
  label values time post_ssb
  save "$analysis/FIES_20152018append_SSB.dta", replace
  tabstat ssb, by(time) stat(n mean min max sd)
 
* **********************************************************************
* 3 - Collapse FIES and find SSB consumption over time (for parallel trends assumption)
* **********************************************************************
* Load each FIES year, for each treatment variable find average SSB consumption
* emilia's previous comment: do the parallel trends for each province with diff colors
* emilia's comment on not doing solid lines
* should I be weighting by rfact? 

  foreach j in treat_513 treat_7 treat_10 treat_1316 {
	forvalues i = 2009(3)2018 {
       use "$analysis/FIES_`i'_SSB.dta", clear
       collapse (mean) tssb`i'=tssb tssb_share_exp`i'=tssb_share_exp tssb_share_inc`i'=tssb_share_inc, by("`j'")
       tempfile pta`i'`j'
       save `pta`i'`j''
	}
	use `pta2009`j''
	forvalues k = 2012(3)2018 {
		merge 1:1 `j' using "`pta`k'`j''", nogenerate
		save "$analysis/SSBmean_`j'.dta", replace 
	}
	use  "$analysis/SSBmean_`j'.dta"
	reshape long tssb tssb_share_exp tssb_share_inc, i(`j') j(year)
    reshape wide tssb tssb_share_exp tssb_share_inc, i(year) j(`j')
	label	var	tssb0	"Control"
    label	var	tssb1	"Treatment"
    label   var year    "Year"
	label   var tssb_share_exp0 "Control"
	label   var tssb_share_exp1 "Treatment"
	label   var tssb_share_inc0 "Control"
	label   var tssb_share_inc1 "Treatment"
    save "$analysis/SSBmean_`j'.dta", replace
  }

* Create graphs for parallel trends for each treatment group definition
  local jgrp "treat_513 treat_7 treat_10 treat_1316"
  local kgrp "5.13 7 10 13.16"
  local n: word count `jgrp'
  forvalues i = 1/`n' {
	local j: word `i' of `jgrp'
	local k: word `i' of `kgrp'
	use  "$analysis/SSBmean_`j'.dta"
	
 	twoway connected tssb0 tssb1 year, ytitle("Philippine Peso (PHP)") ///
     title(Average taxable beverage consumption) subtitle(Treatment: provinces with at least `k'% increase in SSB prices in 2018) ///
     ylabel(2300(100)2600) lpattern(longdash dot solid) ///
	 note("Source: FIES")
	graph save "$output/paralleltrends_ssb_`j'.gph", replace
	
	twoway connected tssb_share_exp0 tssb_share_exp1 year, ytitle(Percent) ///
     title(SSB consumption as a share of household expenditure ) subtitle(Treatment: provinces with at least `k'% increase in SSB prices in 2018) ///
     ylabel(0.9(0.1)1.6) lpattern(longdash dot solid) ///
	 note("Source: FIES")
	graph save "$output/paralleltrends_ssbexp_`j'.gph", replace
	
	twoway connected tssb_share_inc0 tssb_share_inc1 year, ytitle(Percent) ///
     title(SSB consumption as a share of household income ) subtitle(Treatment: provinces with at least `k'% increase in SSB prices in 2018) ///
     ylabel(0.9(0.1)1.6) lpattern(longdash dot solid) ///
	 note("Source: FIES")
	graph save "$output/paralleltrends_ssbinc_`j'.gph", replace 
	} 
	  
	graph combine "$output/paralleltrends_ssb_treat_513.gph" "$output/paralleltrends_ssb_treat_7.gph" "$output/paralleltrends_ssb_treat_10.gph" "$output/paralleltrends_ssb_treat_1316.gph", name("paralleltrends_ssb_comb", replace) ycommon iscale(0.75) title("SSB consumption of treatment and control groups") 
	graph export "$output/paralleltrends_ssb_comb.png", replace 
	graph combine "$output/paralleltrends_ssbexp_treat_513.gph" "$output/paralleltrends_ssbexp_treat_7.gph" "$output/paralleltrends_ssbexp_treat_10.gph" "$output/paralleltrends_ssbexp_treat_1316.gph", name("paralleltrends_ssbexp_comb", replace) ycommon iscale(0.75) title("SSB consumption as a share of expenditure of treatment and control groups") 
	graph export "$output/paralleltrends_ssbexp_comb.png", replace 
	graph combine "$output/paralleltrends_ssbinc_treat_513.gph" "$output/paralleltrends_ssbinc_treat_7.gph" "$output/paralleltrends_ssbinc_treat_10.gph" "$output/paralleltrends_ssbinc_treat_1316.gph", name("paralleltrends_ssbinc_comb", replace) ycommon iscale(0.75) title("SSB consumption as a share of income of treatment and control groups") 
	graph export "$output/paralleltrends_ssbinc_comb.png", replace 
	
     
//twoway (line tssb_share_exp0  tssb_share_exp1 year)

* **********************************************************************
* 4 - Create appended FIES 2009 to FIES 2018 (for pooled cross section)
* **********************************************************************
* Append FIES 2009 to 2018
  use "$analysis/FIES_2009_SSB.dta", clear
  append using "$analysis/FIES_2012_SSB.dta", force
  append using "$analysis/FIES_2015_SSB.dta", force
  append using "$analysis/FIES_2018_SSB.dta", force

* Drop variables not available in all 4 datasets (not exhaustive)
  drop w_id_recode-w_no_hh
  drop z2111_m_less_1-z2171_m_tot_emp
  drop b4042_tenure_ind-b4053_lot_rent
  drop b5012_oth_house lnb5012_oth_house
  drop w_mun-floor
  
* Generate variables and save data set 
  gen   time = (year==2018) if !missing(year)
  label define post_ssb 0 "Pre-policy" 1 "Post-policy"
  label values time post_ssb
  save "$analysis/FIES_20092018append_SSB.dta", replace

  
  
 
