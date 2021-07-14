* **********************************************************************
* Project: SSB tax in the Philippines
* Created: June 2021
* Last modified 2021/06/29 by AK
* Stata v.15.1
* **********************************************************************
* Imports price data and creates treatment and control groups
* Find a way not to hard code Davao Occidental and NCR2,3,4
* **********************************************************************
* 1 - Import, label, and reshape data
* **********************************************************************
* Import and relabel price data
  import delimited "$raw/2M4ACPI1.csv", bindquote(strict) varnames(2) clear
  foreach v of varlist _all {  //renames variables
	   local x : variable label `v'
	   local q_`v'  =strlower(strtoname("`x'"))
	   rename `v' `q_`v''
  }

* **********************************************************************
* 2 - Merge PSGC indicator
* **********************************************************************
* Merge PSGC indicator and rename with FIES province indicator 
  merge 1:1 geolocation using "$raw/psgc_prov.dta"
  rename psgc w_prov

* Delete regional level price data
 // cap drop if _merge==2 
  
* **********************************************************************
* 3 - Generate variables
* **********************************************************************
  
* Generate inflation figures
  gen    inf_dec18 = _2018_dec / _2017_dec - 1
  format inf_dec18 %9.2f

* Manually create values for NCR districts 2,3,4 (no separate data collected for NCR1,2,3,4) and Davao Occidental (broke off from Davao del Sur in 2013)
  //local ncr   =  0.146976744186047 
  sum inf_dec18 if w_prov== 39
  scalar ncr = r(mean)
  //local davao =  0.112328767123288
  sum inf_dec18 if w_prov== 24
  scalar davao = r(mean)
  replace inf_dec18 = ncr   if w_prov == 74 |  w_prov == 75 | w_prov == 76  // NCR2,3,4 no separate price data, copy NCR
  replace inf_dec18 = davao if w_prov == 86 // Davao Occidental no separate price data, copy Davao del Sur
  
* Generate treatment variables
  gen treat_513  = inf_dec18>0.0513 if !missing(inf_dec18) // Philippines all items inflation
  gen treat_7    = inf_dec18>0.07   if !missing(inf_dec18) // between the two
  gen treat_10   = inf_dec18>0.10   if !missing(inf_dec18) // between the two 
  gen treat_1316 = inf_dec18>0.1316 if !missing(inf_dec18) // Philippines non alcohol bev inflation
 
* Label treatment variables
  label define treat_ssb 0 "control" 1 "treatment"
  foreach v in "treat_513 treat_7 treat_10 treat_1316" {
	label values `v' treat_ssb
	//label variable ``v''
  }

* Drop non-province PSGC level data
  drop if w_prov==.
  drop if w_prov==0
* **********************************************************************
* 4 - Save data
* **********************************************************************
* Save  
  save "$analysis/pricedata.dta", replace
  
  /*
* Add metadata and save
  customsave,  idvar(date) filename("hourlyPM") path("$dataWork/data/inter") ///
              dofile("0-import.do") description("Hourly data for DiD") noidok

  export delimited            "$dataWork/data/inter/4cityHourly.csv", replace
  */
  

