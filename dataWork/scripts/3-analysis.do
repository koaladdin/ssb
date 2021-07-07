* **********************************************************************
* Project: SSB tax in the Philippines
* Created: June 2021
* Last modified 2020/06/06 by AK
* Stata v.15.1
* **********************************************************************
* Run propensity score match
* Run basic diff-in-diff


* **********************************************************************
* 1 - Pooled OLS
* **********************************************************************

//DID will deal with selection on unobservables as long as the bias from it is time-invariant, conditional on covariates

  use "$analysis/FIES_20152018append_SSB.dta", clear

* Run DiD regression with no controls
regress ssb i.time##i.treat_513, robust
margins time#treat_513 // EXPECTED INCOME EACH GROUP IN EACH TIME PERIOD
margins treat_513, dydx(time) // CHANGE IN SSB CONSUMPTION AT  2015 & 2018 IN EACH GROUP

* Substitutes regression

* Placebo regression (run on unrelated consumed items)

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


* **********************************************************************
* 2 - Propensity score matching
* **********************************************************************
//Daw and Hatfield (2018) -> pSM will not take care of parallel trends if it doesnt exist.
// matching and weighting will take care of the selection into treatment based on observables, 
 // use (ssc install) -psmatch2- command to obtain matched treatment and control groups, and then use the matched sample to do DID analysis.

 //psmatch2 (variable that defines treatment group) (variables that define the characteristics of the households 1,2,...), out(outcome var) -> probit
 //psmatch2 trade, mahalanobis(carac1 carac2) out(outvar)    -> logit
 
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





//


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

* Copy outputs to Overleaf
  * Grab filenames in output/tables
  local tables : dir "$dataWork/output/tables" files *

* Loop over all files in outputs/tables
  foreach filename of local tables {
    copy        "$dataWork/output/tables/`filename'"             ///
                "$dropbox/Apps/Overleaf/CovidAirQuality/tables/`filename'"  ///
                , replace
  }

 
