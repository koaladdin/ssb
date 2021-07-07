* **********************************************************************
* Project: SSB tax in the Philippines
* Created: June 2021
* Last modified 2020/06/16 by AK
* Stata v.15.1
* **********************************************************************
* Make pretty figures & summary stats
* Make maps
* Copied everything from old do files except PIT stuff
* need to use new variable names

* **********************************************************************
* 0 - Open data
* **********************************************************************
  use "$dataWork/data/inter/hourlyPM", clear

* **********************************************************************
* 1 - Summarize the data
* **********************************************************************
* Let's summarize the data
  eststo sumStats: estpost tabstat pm logpm, by(city)          ///
         statistics(mean sd min max) columns(statistics)

  esttab sumStats using $dataWork/output/tables/summaryStats.tex,  ///
         cell("mean sd min max")                                   ///
         wide noobs label nonote nomtitle nonumber                 ///
         title(Summary statistics\label{tab:sumStats}) replace

//generate share of income and exp spent on ssb per capita by decile
gen ssb_share_d     = 100*ssb_total_pc/ttotex_total_pc
gen ssb_shareinc_d  = 100*ssb_total_pc/toinc_total_pc

//share of income/exp spent on ssb by decile
tabstat ssb_share_d[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile) 
tabstat ssb_shareinc_d[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile) 
		 
		 
  **** summary stats for treatment
  local treatment "treat_513 treat_7 treat_10 treat_1316"
local ssbvar "ssb ssb_share_exp ssb_share_inc"

foreach v in `treatment' {
		tabstat `ssbvar', stat(mean count) by(`v') }		
		
use "/Users/aladdin/Downloads/FIES data files/FIES2015full_raw_v3.dta", clear
xtile decile = toinc [w=rfact], nq(10)


//ssb as a share of total exp by income decile
egen ssb = rowtotal(ttea tcocoa tsoftdrink tfruitjuice tfconcentrates tfothernonalcohol) //milk and coffee exempted
bysort decile: egen ssb_total_d = total(ssb)
bysort decile: egen exp_total_d = total(ttotex)
bysort decile: egen inc_total_d = total(toinc)

//hh income by decile
tabstat toinc[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(decile) 

//hh expenditure by decile
tabstat ttotex[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(decile) 

//ssb expenditure by decile
tabstat ssb[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(decile) 

//ssb expenditure as a share of total expenditure by decile
gen ssb_share_d = 100*ssb_total_d/exp_total_d
tabstat ssb_share_d[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(decile) 

//ssb expenditure as a share of total income by decile
gen ssb_shareinc_d = 100*ssb_total_d/inc_total_d
tabstat ssb_shareinc_d[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(decile) 

//share of income/exp spent on ssb by decile
tabstat ssb_share_d[aw=popw], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile) 
tabstat ssb_shareinc_d[aw=popw], stat(mean) format(%20.2fc) col(stat) by(pcinc_decile) 

//attempt with log income and log expenditure
gen lnpcinc = ln(toinc/fsize)
table pcinc_decile, c(mean lnpcinc) //average ln percapita income per decile

/*
// are poorer households larger by family size?
table fsize [aw=rfact], c(mean pcinc) format(%20.2fc)
twoway scatter fsize pcinc [aw=rfact], msymbol(oh)  || qfitci fsize pcinc
graph export  "$graphsfolder/family size and pcinc.png" ,replace

table fsize [aw=rfact], c(mean lnpcinc) format(%20.2fc)
twoway scatter fsize lnpcinc [aw=rfact], msymbol(oh) || qfitci fsize lnpcinc
graph export  "$graphsfolder/family size and lnpcinc.png" ,replace
*/

// ssb consumption by family size
table fsize [aw=rfact],  c(mean ssb min ssb max ssb) f(%9.0fc)
table fsize [aw=rfact],  c(mean ssb_share_inc min ssb_share_inc max ssb_share_inc) 
table fsize ,  c(mean ssb_share_inc min ssb_share_inc max ssb_share_inc) 

//

tabstat ssb, by(treat) stat(n mean min max sd)



/*
//by geographic region
tabstat ssb[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(w_regn)
tabstat ssb_share_d[aw=rfact], stat(mean) format(%20.2fc) col(stat) by(w_regn)


//total percapita expenditure (divide the 2 manually) 
tabstat ssb, stat(sum) format(%20.0fc)
tabstat ttotex, stat(sum) format(%20.0fc)

sum ssb_total_d
di r(sum)
sum exp_total_d
di r(sum)
*/


// did means table
table treatment time, c(mean ssb)
		 
		 
		 
* **********************************************************************
* 2 - Make pretty graphs
* **********************************************************************


set graphics off

twoway scatter ssb_share     toinc_pc [aw=rfact] || qfitci ssb_share     toinc_pc
graph export "$graphsfolder/ssb_share pcinc scatter2018.png"
twoway scatter ssb_share_inc toinc_pc [aw=rfact] || qfitci ssb_share_inc toinc_pc
graph export "$graphsfolder/ssb_share_inc pcinc scatter2018.png"

/*twoway( scatter ssb_share toinc_pc if pcinc_decile == 1, legend(label(1 "Decile 1"))) ///
      ( scatter ssb_share toinc_pc if pcinc_decile == 2, legend(label(2 "Decile 2"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 3, legend(label(3 "Decile 3"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 4, legend(label(4 "Decile 4"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 5, legend(label(5 "Decile 5"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 6, legend(label(6 "Decile 6"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 7, legend(label(7 "Decile 7"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 8, legend(label(8 "Decile 8"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 9, legend(label(9 "Decile 9"))) ///
	  ( scatter ssb_share toinc_pc if pcinc_decile == 10, legend(label(10 "Decile 10"))), by(pcinc_decile)*/

//sscinstall sepscatter
sepscatter ssb_share toinc_pc [aw=rfact], separate(pcinc_decile)
graph export "$graphsfolder/ssb_share pcinc decscatter.png"

sepscatter ssb_share toinc_pc [aw=rfact], separate(pcinc_decile) mylabel(pcinc_decile)
graph export "$graphsfolder/ssb_share pcinc numdecscatter.png"

//attempt with log income and log expenditure
gen lnpcinc = ln(toinc/fsize)
table pcinc_decile, c(mean lnpcinc) //average ln percapita income per decile

twoway scatter ssb_share     lnpcinc [aw=rfact] || qfitci ssb_share     lnpcinc
graph export "$graphsfolder/ssb_share lnpcinc scatter2018.png"
twoway scatter ssb_share_inc lnpcinc [aw=rfact] || qfitci ssb_share_inc lnpcinc
graph export "$graphsfolder/ssb_share_inc lnpcinc scatter2018.png"
sepscatter ssb_share lnpcinc [aw=rfact], separate(pcinc_decile)
graph export "$graphsfolder/ssb_share lnpcinc decscatter2018.png"
sepscatter ssb_share lnpcinc [aw=rfact], separate(pcinc_decile) mylabel(pcinc_decile)
graph export "$graphsfolder/ssb_share lnpcinc numdecscatter2018.png"
sepscatter ssb_share lnpcinc , separate(pcinc_decile)
graph export "$graphsfolder/ssb_share lnpcinc decscatter noweight2018.png"


table pcinc_decile, c(mean ssb_share sd ssb_share min ssb_share max ssb_share) 

/*
forvalues number = 1/10{
	twoway (scatter ssb_share toinc_pc if pcinc_decile == `number'), saving(scatterssb`i', replace)
	local scatterssb `scatterssb' "scatterssb`number'"
}
local scatterssb : subinstr local scatterssb "scatterssb1" `""scatterssb1""'
graph combine 
graph export scatter_combined.png
*/


//SHOW parallel trends 
// descriptives of the two groups
table year treat, c(mean y)
ssc install lgraph, replace
lgraph y year, by(treat) stat(mean) xline(2015) ylab(, nogrid) scheme(s2mono)


/////SPECCURVE - stata16 only https://github.com/martin-andresen/speccurve
//




* Make a week-city id
  egen        city_year = group(city year), label

* Scatter all together
  // twoway      (scatter logpm week, by(city_year))   // not very informative

* Set some graph options
	local line1       = "lcolor(gs5%80) msymb(none) lpattern(solid) lwidth(medthick)"
	local scatter1    = "msymb(o) mcolor(gs10%05) jitter(2)"

	local line2       = "lcolor(ebblue%80) msymb(none) lpattern(solid) lwidth(medthick)"
	local scatter2    = "msymb(o) mcolor(gs10%05) jitter(2)"

	local line3       = "lcolor(dkorange%80) msymb(none) lpattern(solid) lwidth(medthick)"
	local scatter3    = "msymb(o) mcolor(gs10%05) jitter(2)"

	local line4       = "lcolor(cranberry%80) msymb(none) lpattern(solid) lwidth(medthick)"
	local scatter4    = "msymb(oh) mcolor(cranberry%10) jitter(2)"


* Scatter Kampala, week
  sort city year week
  twoway    (scatter logpm week if city_year == 1, `scatter1')       ///
            (scatter logpm week if city_year == 2, `scatter2')       ///
            (scatter logpm week if city_year == 3, `scatter3')       ///
            (scatter logpm week if city_year == 4, `scatter4')       ///
            (connected logpm_week week if city_year == 1, `line1')   ///
            (connected logpm_week week if city_year == 2, `line2')   ///
            (connected logpm_week week if city_year == 3, `line3')   ///
            (connected logpm_week week if city_year == 4, `line4')   ///
            , legend(cols(4)                                         ///
            order(5 "Kampala, 2017" 6 "Kampala, 2018" 7             ///
            "Kampala, 2019" 8 "Kampala, 2020") pos(6))               ///
            ytitle("Log(PM 2.5)")

graph export "$dataWork/output/figs/Kampala_week.pdf", replace

* Scatter Addis, week
  sort city year week
  twoway    (scatter logpm week if city_year == 5, `scatter1')       ///
            (scatter logpm week if city_year == 6, `scatter2')       ///
            (scatter logpm week if city_year == 7, `scatter3')       ///
            (scatter logpm week if city_year == 8, `scatter4')       ///
            (connected logpm_week week if city_year == 5, `line1')   ///
            (connected logpm_week week if city_year == 6, `line2')   ///
            (connected logpm_week week if city_year == 7, `line3')   ///
            (connected logpm_week week if city_year == 8, `line4')   ///
            , legend(cols(4)                                         ///
            order(5 "Addis, 2017" 6 "Addis, 2018" 7             ///
            "Addis, 2019" 8 "Addis, 2020") pos(6))               ///
            ytitle("Log(PM 2.5)")

graph export "$dataWork/output/figs/Addis_week.pdf", replace

* Scatter Kigali, week
  sort city year week
  twoway    (scatter logpm week if city_year == 11, `scatter3')       ///
            (scatter logpm week if city_year == 12, `scatter4')       ///
            (connected logpm_week week if city_year == 11, `line3')   ///
            (connected logpm_week week if city_year == 12, `line4')   ///
            , legend(cols(4)                                          ///
            order(3 "Kigali, 2019" 4 "Kigali, 2020") pos(6))         ///
            ytitle("Log(PM 2.5)")

graph export "$dataWork/output/figs/Kigali_week.pdf", replace


* Scatter Nairobi, week
  sort city year week
  twoway    (scatter logpm week if city_year == 16, `scatter4')       ///
            (connected logpm_week week if city_year == 16, `line4')   ///
            , legend(cols(4)                                          ///
            order(2 "Nairobi, 2020") pos(6))                          ///
            ytitle("Log(PM 2.5)")

graph export "$dataWork/output/figs/Nairobi_week.pdf", replace


// * Scatter Kampala, day
//   sort city year day
//   twoway    (scatter logpm day if city_year == 1, `scatter1')       ///
//             (scatter logpm day if city_year == 2, `scatter2')       ///
//             (scatter logpm day if city_year == 3, `scatter3')       ///
//             (scatter logpm day if city_year == 4, `scatter4')       ///
//             (connected logpm_day day if city_year == 1, `line1')   ///
//             (connected logpm_day day if city_year == 2, `line2')   ///
//             (connected logpm_day day if city_year == 3, `line3')    ///
//             (connected logpm_day day if city_year == 4, `line4')


  // twoway      (scatter logpm week if city_year == 1, `density1')    ///
  //             (scatter logpm week if city_year == 2, `density2')    ///
  //             (scatter logpm week if city_year == 3, `density3')    ///
  //             (scatter logpm week if city_year == 4, `density4')


* Copy outputs to Overleaf
  * Grab filenames in output/tables
  local tables : dir "$dataWork/output/tables" files *

* Loop over all files in outputs/tables
  foreach filename of local tables {
    copy        "$dataWork/output/tables/`filename'"             ///
                "$dropbox/Apps/Overleaf/CovidAirQuality/tables/`filename'"  ///
                , replace
  }
  }

* **********************************************************************
* 3 - Make pretty maps
* **********************************************************************
use "$datafolder/sugar price for graphing AK", clear
//use "/Users/aladdin/OneDrive/University of Sydney/ECON7010+7020 research dissertation/data stata/data/sugar price for graphing AK.dta"

//clean data
drop if psgc == 0
drop if missing(psgc)
destring inf_dec18, replace
destring inf_decjul18, replace

//Match PSGC with map ID
merge 1:1 psgc using "$mapfolder/PSGC ID map matching file LL.dta"


//clean variable name
rename _id _ID


/*
//graph 8 classes
spmap palaydiff_3year using "$mapfolder\New map coordinates\PHL_1_coordinates.dta", ///
	id(_ID) fcolor(red*1.9 red*1.5 red*1.1 red*.9 red*.5 red*.3 green*.3 green) osize(thin) ocolor(black black black black) ///
	title("Change in farm gate prices of palay" "from the 2015 to 2017 average") ///
	name(temp3) nodraw clmethod(custom) clbreaks(-7 -6 -5 -4 -3 -2 -1 0 5)
graph combine temp3, saving("$graphfolder\price drop graph June 8cl.gph", replace)
//
*/

// 5 classes

/* spmap inf_decjul18 using "$mapfolder/New map coordinates/PHL_1_coordinates.dta" , ///
	id(_ID) fcolor(red*1.9 red*1.1 red*.5  green*.3 green) osize(thin) ocolor( black black black black black) ///
	title("Change in price of non-alcoholic beverages" "by region from Dec 2017 to July 2018") ///
	name(temp4) nodraw clmethod(custom) clbreaks(-1 .05 .1 .16 .21 .3)
graph combine temp4, saving("$graphfolder/inf_decjul18.gph", replace) 
*/


 spmap inf_dec18 using "$mapfolder/New map coordinates/PHL_1_coordinates.dta" , ///
	id(_ID) fcolor(green*1.9 green*1.1 green*.5  green red) osize(thin) ocolor( black black black black black) ///
	title("Change in price of non-alcoholic beverages" "by province from Dec 2017 to Dec 2018") ///
	name(temp5) nodraw clmethod(custom) clbreaks(-.01 .05 .07 .10 .13 .32)
graph combine temp5, saving("$graphfolder/inf_dec18.gph", replace)
