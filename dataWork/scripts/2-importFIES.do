* **********************************************************************
* Project: SSB tax in the Philippines
* Created: June 2021
* Last modified 2021/07/29 by AK
* Stata v.15.1
* **********************************************************************
* Generates variables for SSB and others
* Creates FIES merged data sets for POLS

//TO DO:
** ask emilia if need to recode dummy variables to 0,1 from 1,2. Clyde says no changes in prediction. Just cant use it as dependent variable.

* Turn sampling weights on and off here -> but have to manually turn off 
global weightm = "* rfact"
//global weightm = ""
global weight = "[aw=rfact]"
//global weight = ""

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
  rename cloth             tcloth
  rename ndfur             tfurn 
  rename trcom             ttransport	
  rename b0072             thealth
  
* Generate variables for SSB and substitutes
  egen tssb    = rowtotal(tea cocoa carbd ncarb soda othdr) //for FIES2009
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
  keep   tssb tmilks tdnossb tfruits tconf tsweet tsubst w_regn-rfact sex-ttotex toinc tsugar tcoffee agind tcloth tfurn ttransport	pcinc_decile toinc_decile reg_pcdecile thealth //2009

* Generate SSB indicator (dummy indicator) //same as other years
  gen ssb_stat = (tssb>0) if !missing(tssb)
	
* Generate year variable //same as other years
  gen year = 2009
  destring year, replace
  label var year "Year"
  
* Generate population weight from household weight  //same as other years
  gen popw = rfact*fsize
  label var popw "Population weight"
  egen rfactsum = total(rfact)
  replace rfactsum = 1 if 1$weightm ==.
  
* Destring variables //same as other years
  destring w_prov, replace
  destring w_shsn, replace
  destring w_hcn,  replace
  //rename tclothfootwear tcloth
  //rename tfurnishing tfurn
  
* Generate per capita variables, per capita decile totals, and shares of income and expenditure //same as other years
  foreach var in tssb tsubst tdnossb tconf tsweet tfruits tcloth tfurn ttotex toinc {
	local lbl : variable label `var'
	gen `var'_pc = `var' / fsize
	label var `var'_pc         "`lbl' (per capita)"
	bysort pcinc_decile: egen `var'_pc_dc = total(`var'_pc $weightm )
	replace `var'_pc_dc = `var'_pc_dc / rfactsum
	label var `var'_pc_dc   "`lbl' (by per capita income decile)"
	gen `var'_exp = 100*`var' / ttotex
	label var `var'_exp  "`lbl' (share of total expenditure)"
	gen `var'_inc = 100*`var' / toinc
	label var `var'_inc  "`lbl' (share of total income)" 
	}
  foreach var in tssb tsubst tdnossb tconf tsweet tfruits tcloth tfurn ttotex toinc {
	gen `var'_exp_d   = 100* `var'_pc_dc/ttotex_pc_dc
	label var `var'_exp_d "`lbl' (share of total expenditure by income decile)"
	gen `var'_inc_d  = 100* `var'_pc_dc/toinc_pc_dc
	label var `var'_inc_d "`lbl'(share of total expenditure by income decile)"
	//tabstat `var'_pc [aw=rfact], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile)
	}		

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
	
* Generate variables for SSB and substitutes
  egen tssb    = rowtotal(ttea tcocoa tsoftdrink tfruitjuice tfconcentrates tfothernonalcohol) //milk and coffee exempted
  egen tmilks  = rowtotal(tmraw tcondevap tfdessert tmbeverage tmsoya)
  egen tdnossb = rowtotal(tmilks tcoffee tmineral)
  egen tfruits = rowtotal(tffresh tdfruit tcoconut tpresfruit tkaong tnata)
  egen tconf   = rowtotal(tjamsmar tchocolate tice tothersugar tfnecdessert)
  egen tsweet  = rowtotal(tsugar thoney)
  egen tsubst  = rowtotal(tdnossb tfruits tconf tsweet)

* Label new variables
  label	var	tssb	"Taxable beverage expenditure"
  label	var	tmilks	"Milk expenditure"
  label	var	tdnossb	"Non-taxable beverage expenditure"
  label	var tfruits "Fresh, dried fruits, preserved fruit expenditure"
  label	var	tconf	"Confectionary expenditure"
  label	var	tsweet	"Sugar and honey expenditure"
  label	var tsubst	"SSB substitutes expenditure"

* Keep only necessary variables and drop the rest
  cap keep   tssb tmilks tdnossb tfruits tconf tsweet tsubst w_regn-pcinc ttotex toinc tsugar thoney tcoffee tmineral agind sex-p4s tclothfootwear tfurnishing thealth //2015 and 2018
  cap keep   w_regn-fsize ttotex toinc pcinc tsugar thoney tcoffee tmineral agind-pov_thresh pov_ind tssb-tsubst tclothfootwear tfurnishing ttransport pcinc_decile toinc_decile reg_pcdecile thealth //2012
		
* Generate SSB indicator (dummy indicator)
  gen ssb_stat = (tssb>0) if !missing(tssb)
	
* Generate year variable
  gen year = `i'
  destring year, replace
  label var year "Year"
	
* Generate population weight from household weight 
  gen popw = rfact*fsize
  label var popw "Population weight"
  egen rfactsum = total(rfact)
  replace rfactsum = 1 if 1$weightm ==.

* Destring variables
  cap destring w_prov, replace
  cap destring w_mun,  replace
  cap destring w_bgy,  replace
  cap destring w_ea,   replace
  cap destring w_shsn, replace
  cap destring w_hcn,  replace
  rename tclothfootwear tcloth
  rename tfurnishing tfurn
  
* Generate per capita variables, per capita decile totals, and shares of income and expenditure
  foreach var in tssb tsubst tdnossb tconf tsweet tfruits tcloth tfurn ttotex toinc  {
	local lbl : variable label `var'
	gen `var'_pc = `var' / fsize
	label var `var'_pc         "`lbl' (per capita)"
	bysort pcinc_decile: egen `var'_pc_dc = total(`var'_pc $weightm)
	replace `var'_pc_dc = `var'_pc_dc / rfactsum //turn off if not weighted
	label var `var'_pc_dc   "`lbl' (by per capita income decile)"
	gen `var'_exp = 100*`var' / ttotex
	label var `var'_exp  "`lbl' (share of total expenditure)"
	gen `var'_inc = 100*`var' / toinc
	label var `var'_inc  "`lbl' (share of total income)" 
	}
  foreach var in tssb tsubst tdnossb tconf tsweet tfruits tcloth tfurn ttotex toinc {
	gen `var'_exp_d   = 100* `var'_pc_dc/ttotex_pc_dc
	label var `var'_exp_d "`lbl' (share of total expenditure by income decile)"
	gen `var'_inc_d  = 100* `var'_pc_dc/toinc_pc_dc
	label var `var'_inc_d "`lbl'(share of total income by income decile)"
	//tabstat `var'_pc [aw=rfact], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile)
	}				

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
	
* Merge in identifiers for treatment and control groups
  merge m:1 w_prov using "$pricedata", generate(mergebyprov)
	
* Save analysis data
  save "$analysis/FIES_`i'_SSB.dta", replace
  local i = `i' + 3
	
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

  foreach j in tr513 tr7 tr10 tr1316 {
	forvalues i = 2009(3)2018 {
       use "$analysis/FIES_`i'_SSB.dta", clear
       collapse (mean) tssb`i'=tssb tssb_exp`i'=tssb_exp tssb_inc`i'=tssb_inc $weight, by("`j'")
       tempfile pta`i'`j'
       save `pta`i'`j''
	}
	use `pta2009`j''
	forvalues k = 2012(3)2018 {
		merge 1:1 `j' using "`pta`k'`j''", nogenerate
		save "$analysis/SSBmean_`j'.dta", replace 
	}
	use  "$analysis/SSBmean_`j'.dta"
	reshape long tssb tssb_exp tssb_inc, i(`j') j(year)
    reshape wide tssb tssb_exp tssb_inc, i(year) j(`j')
	label	var	tssb0	"Control"
    label	var	tssb1	"Treatment"
    label   var year    "Year"
	label   var tssb_exp0 "Control"
	label   var tssb_exp1 "Treatment"
	label   var tssb_inc0 "Control"
	label   var tssb_inc1 "Treatment"
    save "$analysis/SSBmean_`j'.dta", replace
  }

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

* **********************************************************************
* 5 - Create appended FIES 2012 and FIES 2015 (for placebo regression)
* **********************************************************************
* Append FIES 2015 to 2012
  use "$analysis/FIES_2012_SSB.dta", clear
  replace urb =2 if urb==0 //some data cleaning on the FIES 2012
  append using "$analysis/FIES_2015_SSB.dta"
  gen   time = (year==2015) if !missing(year)
  label define post_ssb 0 "Pre-policy" 1 "Post-policy"
  label values time post_ssb
  save "$analysis/FIES_20122015append_SSB.dta", replace
  tabstat ssb, by(time) stat(n mean min max sd)
 
 
