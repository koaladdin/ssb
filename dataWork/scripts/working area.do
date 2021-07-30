	global myDocs  "/Users/aladdin/OneDrive/University of Sydney/ECON7010+7020 research dissertation/data stata"
	global dropbox "/Users/aladdin/Dropbox (Sydney Uni Student)" 
    global projectFolder          "$myDocs/SSBtaxPH"
    global dataWork               "${projectFolder}/dataWork"
    global data                   "${dataWork}/data"
	global raw                    "${data}/raw"
	global analysis               "${data}/analysis"
    global scripts                "${dataWork}/scripts"
    global logs                   "${scripts}/logs"
	global output                 "${dataWork}/output"
	global tables                 "${output}/tables"
	global graphs                 "${output}/graphs"
	global maps                   "${data}/maps"
	
	//use "$analysis/FIES_2015_SSB.dta", clear
	//use "$analysis/FIES_20152018append_SSB.dta", clear
	use "$analysis/FIES_2018_SSB.dta", clear

	/*
** psmatch and lpscore following Emilia's pset	- 2015 only!
 global pricedata "$source/data/price data/nonalcobyprov.dta"
merge m:1 w_prov using "$pricedata"

 logit tssb treat_513 urb agind fsize toinc hgc occup //tssb_2015
 predict double pscore if e(sample), pr
 gen double lpscore = ln(pscore/(1-pscore)) if e(sample)
 sum lpscore
 
 
 forvalues i = 1/20 {
 
	quietly psmatch2 treat_513, outcome(tssb) pscore(lpscore) n(`i') ties
 di (1)
	pstest lpscore urb agind fsize toinc hgc occup, treated (treat_513) both
  di (2)

twoway (kdensity lpscore if treat_513 == 1, lcolor(gs10)) (kdensity lpscore if treat_513 == 0, lpattern(dash) ylabel(, nogrid) ytitle("Density") xtitle("Linearized propensity score") lcolor(black)), graphregion(color(white)) legend(lab(1 "Treated") lab(2 "Raw controls"))
graph export densraw_`i'.png, replace
  di (3)

twoway (kdensity lpscore if treat_513 == 1 [aw = _weight], lcolor(gs10)) (kdensity lpscore if treat_513 == 0 [aw = _weight], lpattern(dash) ylabel(, nogrid) ytitle("Density") xtitle("Linearized propensity score") lcolor(black)), graphregion(color(white)) legend(lab(1 "Treated") lab(2 "Matched controls"))
graph export densmatched_`i'.png, replace
  di (4)
}
*/

replace age = age + 3

**attempt to merge FIES 2015 and 2018 based on common characteristics

//merge 1:1 w_prov urb fsize agind sex age ms hgc job occup kb cw hhtype bldg_type roof walls  year_built toilet electric using "$analysis/FIES_2015_SSB.dta" //variables do not uniquely identify observations in the master data
//merge m:m w_prov urb fsize agind sex age ms hgc job occup kb cw hhtype bldg_type roof walls  year_built toilet electric using "$analysis/FIES_2015_SSB.dta" //matches nothing!


	
