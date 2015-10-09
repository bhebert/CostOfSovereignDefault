
local hname NMLbond2030

*****************
*SUMMARY FIGURES*
*****************
*RUNS WITH DATES
set more off
use "$apath/ThirdAnalysis.dta", clear
* Non-events are days at least two days away from and event day.
*gen nonevent = mod(dayindex,2)==0 & event_day == 0 & (L.event_day == 0 | (L.event_day == . & L2.event_day == 0)) & (F.event_day == 0 | (F.event_day == . & F2.event_day == 0))
* Exclusions were defined earlier. This implements them.

	*gen excludedday = eventexcluded == 1 | L.eventexcluded == 1 | F.eventexcluded == 1
*keep if industry_sector=="INDEX"
sort industry_sector market day_type event_day date
bysort industry_sector market day_type  event_day: gen n2=_n if event_day==1
sort industry_sector market day_type  eventcloses date
bysort industry_sector market day_type  eventcloses: gen n1=_n if eventcloses==1

*
/*local indplot ADRB_PBRTS ADRBlue BCS Contado_Ambito DSBlue dolarblue ValueINDEXNew MexicoEquity
discard
foreach x of local indplot {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(date)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) title("Two day: `x'") xtitle("Argentina CDS Spread Change") ytitle("Change") name("Twoday`y'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`y'_twoday.eps", replace
twoway    (scatter return_ cds if eventcloses==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if eventcloses==1, mlabel(date)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="onedayN" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) title("One day: `x'") xtitle("Argentina CDS Spread Change") ytitle("Change") name("oneday`y'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`y'_onedayN.eps", replace
local y=`y'+1
}*/
replace cds=cds_*100

local indplot ADRB_PBRTS ADRBlue BCS   dolarblue 
local y=1
discard
foreach x of local indplot {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Change") name("Twoday_`x'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`x'_twoday.eps", replace
twoway    (scatter return_ cds if eventcloses==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if eventcloses==1, mlabel(n1)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="onedayN" & market~="AR", legend(order(1 "Non-Event" 2 "Event"))  xtitle("Change in Default Probability") ytitle("Log Change") name("oneday`x'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`x'_onedayN.eps", replace
local y=`y'+1
} 

*FOR PRESENATIONS
*Twoday_ValueINDEXNew
*Twoday_MexicoEquity

*Can add versions here to get old numbers back
use "$apath/data_for_summary.dta", clear
replace cds=cds_*100
sort industry_sector market day_type event_day date
bysort industry_sector market day_type  event_day: gen n2=_n if event_day==1 & return_~=.
sort industry_sector market day_type  eventcloses date
bysort industry_sector market day_type  eventcloses: gen n1=_n if eventcloses==1
gen event_desc="Stay, 11/29/12" if date==td(29nov2012) & day_type=="twoday"
replace event_desc="Supreme Court Denial, 6/16/14" if date==td(16jun2014) & day_type=="twoday"
discard

twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="ValueINDEXNew" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Twoday_ValueINDEXNew1") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueINDEXNew_1.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1 & n2~=2, mlabel(n2)) (scatter return_ cds_ if n2==2, mlabel(event_desc) mcolor(blue)  mlabcolor(blue)) if industry_sec=="ValueINDEXNew" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Twoday_ValueINDEXNew2") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueINDEXNew_2.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1 & n2~=13, mlabel(n2)) (scatter return_ cds_ if n2==13, mlabel(event_desc)  mlabposition(9) mlabcolor(blue) mcolor(blue)) if industry_sec=="ValueINDEXNew" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Twoday_ValueINDEXNew3") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueINDEXNew_3.eps", replace
*This way it won't crash if we exclude Mexico
cap {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="MexicoEquity" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Mexico") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/MexicoEquityScatter.eps", replace
}

cap {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="`hname'" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("holdout") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/HoldoutScatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="rsbond_usd_disc" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("restructured") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/RestructuredScatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="bonarx_usd" & eventexcluded==0 & day_type=="twoday" , legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("domestic_bonar") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/DomesticBonarScatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="boden15_usd" & eventexcluded==0 & day_type=="twoday" , legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("domestic_boden") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/DomesticBodenScatter.eps", replace
}

*APPENDIX FIGURES
discard
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="ADRBlue" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("ADR Blue Rate") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("ADRBlue") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ADRBlue_Scatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="BCS" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("Blue-Chip Swap Rate") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("BCS") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/BCS_Scatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="dolarblue" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("Dolar Blue Rate") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("dolarblue") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/DolarBlue_Scatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="OfficialRate" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("Official Exchange Rate") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Official") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Official_Scatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="ValueBankINDEXNew" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("Value-Weighted Index: Banks") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("VIBanks") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueBank_Scatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="ValueNonFinINDEXNew" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("Value-Weighted Index: Non-Financial") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("VINonFin") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueNonfin_Scatter.eps", replace


********************************
*BOND LEVEL PLOT

use "$apath/bondlevel.dta", clear
discard
drop if Ticker==""
keep date px_close Ticker
reshape wide px_close, i(date) j(Ticker) str
renpfix px_close
twoway  (line rsbond_usd_disc date) (line `hname' date), legend(order( 1 "Restructured Bond" 2 "Holdout Bond")) xtitle("") ytitle("Price") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xline(19934, lwidth(.5) lcolor(black)) name("holdoutres") ylabel(0(20)100) 
graph export "$rpath/BondTimeSeries.eps", replace
mmerge date using "$mpath/Default_Prob_all.dta"
label var rsbond_usd_disc "Price"
label var defbond "Price"

label var mC5_5y "Default Probability"
label var conh_ust_def5y "Default Probability"

replace mC5_5y=mC5_5y*100
replace conh_ust_def5y=conh_ust_def5y*100
twoway (line rsbond_usd_disc date, yaxis(2)) (line mC5_5y date),  legend(order(1 "Restructured Bond" 2 "Default Probability (Inverse)")) xtitle("")  graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xline(19934, lwidth(.5) lcolor(black)) yscale(rev) name("defprob")  
graph export "$rpath/Restructured_Defprob.eps", replace

twoway (line rsbond_usd_disc date, yaxis(2)) (line conh_ust_def5y date),  legend(order(1 "Restructured Bond" 2 "Default Probability (Inverse)")) xtitle("")  graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xline(19934, lwidth(.5) lcolor(black)) yscale(rev) name("defprobconh")  
graph export "$rpath/Restructured_DefprobconH.eps", replace

twoway (line `hname' date, yaxis(2)) (line mC5_5y date),  legend(order(1 "Holdout Bond" 2 "Default Probability")) xtitle("")  graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xline(19934, lwidth(.5) lcolor(black))  name("defprob_defbond")  
graph export "$rpath/Defaulted_Defprob.eps", replace

twoway (line `hname' date, yaxis(2)) (line mC5_5y date),  legend(order(1 "Holdout Bond" 2 "Default Probability (Inverse)")) xtitle("")  graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xline(19934, lwidth(.5) lcolor(black)) yscale(rev)  name("defprob_defbond_inv")  
graph export "$rpath/Defaulted_Defprob_inv.eps", replace


*********************
*EXCHANGE RATE Plots
*********************
use "$apath/ADRBlue_All.dta", clear
append using "$apath/blue_rate.dta"
append using "$apath/NDF_Datastream.dta"
append using "$apath/dolarblue.dta"
append using "$apath/bcs.dta"
append using "$apath/ADRB_PBRTS.dta"
append using "$apath/Contado.dta"

replace Ticker=ADR_Ticker if Ticker==""
twoway (connected px_close date if Ticker=="BFR") (connected px_close date if Ticker=="BMA") (connected px_close date if Ticker=="GGAL") (connected px_close date if Ticker=="PAM") (connected px_close date if Ticker=="PBR") (connected px_close date if Ticker=="PZE") (connected px_close date if Ticker=="TEO") (line px_close date if Ticker=="TS") (line px_close date if Ticker=="dolarblue")  (connected px_close date if Ticker=="ADRB_PBRTS") (line px_close date if Ticker=="BCS") (line px_close date if Ticker=="ADRBlue") (line px_close date if Ticker=="YPFDBlue") (line px_close date if Ticker=="DSBlue") if date>=td(13jun2014) & date<=td(19jun2014), legend(order(1 "BFR" 2 "BMA" 3 "GGAL" 4 "PAM" 5 "PBR" 6 "PZE" 7 "TEO" 8 "TS" 9 "Dolarblue" 10 "ADRB_PBRTS" 11 "BCS" 12 "ADRBlue" 13 "YPF" 14 "DSBlue"))
graph export "$rpath/SupremeCourtDispersion.eps", replace

twoway (line px_close date if Ticker=="dolarblue", sort)  (connected px_close date if Ticker=="ADRB_PBRTS", sort) (line px_close date if Ticker=="BCS", sort) (line px_close date if Ticker=="ADRBlue", sort)  (line px_close date if Ticker=="DSBlue") if date>=td(13jun2014) & date<=td(19jun2014), legend(order(1 "Dolarblue" 2 "ADRB_PBRTS" 3 "BCS" 4 "ADRBlue" 5 "DSBlue"))
graph export "$rpath/SupremeCourtDispersion_Main.eps", replace

twoway (line px_close date if Ticker=="OfficialRate", sort) (line px_close date if Ticker=="dolarblue", sort) (line px_close date if Ticker=="BCS", sort) (line px_close date if Ticker=="ADRBlue", sort)  (line px_close date if Ticker=="NDF12M", sort)  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ExchangeRates_Presentation.eps", replace

twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(medthick)) (line px_close date if Ticker=="dolarblue", sort  lwidth(thick)) (line px_close date if Ticker=="BCS", sort lpattern(dash_dot) lwidth(medthick)) (line px_close date if Ticker=="ADRBlue", sort lpattern(dash) lwidth(medthick))  (line px_close date if Ticker=="NDF12M", sort lpattern(shortdash) lwidth(thick))  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ExchangeRates_Presentation_bw.eps", replace


*CLICKABLE
discard
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(thick)) (line px_close date if Ticker=="dolarblue", sort lcolor(white)) (line px_close date if Ticker=="BCS", sort lcolor(white)) (line px_close date if Ticker=="ADRBlue", sort lcolor(white))  (line px_close date if Ticker=="NDF12M", sort lcolor(white))  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white)) name("fx1")
graph export "$rpath/fx1.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(thick))   if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx2")
graph export "$rpath/fx2.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(thick)) if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx3")
graph export "$rpath/fx3.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med)) (line px_close date if Ticker=="ADRBlue", sort lwidth(thick)) if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx4")
graph export "$rpath/fx4.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med)) (line px_close date if Ticker=="ADRBlue", sort lwidth(med)) (line px_close date if Ticker=="NDF12M", sort lwidth(thick))  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx5")
graph export "$rpath/fx5.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med)) (line px_close date if Ticker=="ADRBlue", sort lwidth(med)) (line px_close date if Ticker=="NDF12M", sort lwidth(med))  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx6")
graph export "$rpath/fx6.eps", replace


*SUMMARY TABLE
foreach var in ValueINDEXNew dolarblue{
cap { 
use "$apath/data_for_summary.dta", clear
keep if  industry_sec=="`var'"
replace cds_=cds_*100
summ cds_ if event_day==1
local event_mean_deltad=r(mean)
local event_sd_deltad=r(sd)
local event_n=r(N)
summ return_ if event_day==1
local event_mean_return=r(mean)
local event_sd_return=r(sd)
summ cds if event_day==0
local nonevent_mean_deltad=r(mean)
local nonevent_sd_deltad=r(sd)
local nonevent_n=r(N)
summ return_ if event_day==0
local nonevent_mean_return=r(mean)
local nonevent_sd_return=r(sd)
corr cds_ return_ if event_day==1, cov
local event_cov=r(cov_12)

corr cds_ return_ if event_day==0, cov
local nonevent_cov=r(cov_12)

gen Ticker="`var'"
gen event_mean_deltad = `event_mean_deltad'
gen event_sd_deltad =`event_sd_deltad'
gen event_n =`event_n'
gen nonevent_mean_deltad =`nonevent_mean_deltad'
gen nonevent_sd_deltad =`nonevent_sd_deltad'
gen nonevent_n =`nonevent_n'
gen event_cov =`event_cov'
gen nonevent_cov=`nonevent_cov'
gen event_mean_return = `event_mean_return'
gen event_sd_return = `event_sd_return'
gen nonevent_mean_return = `nonevent_mean_return'
gen nonevent_sd_return = `nonevent_sd_return'

keep Ticker event_mean_deltad event_sd_deltad event_n nonevent_mean_deltad nonevent_sd_deltad nonevent_n event_cov nonevent_cov event_mean_return event_sd_return nonevent_mean_return nonevent_sd_return
keep if _n==1
gen point_est=100*(event_cov-nonevent_cov)/(event_sd_deltad^2-nonevent_sd_deltad^2)
reshape long event_ nonevent_, i(Ticker) j(var) str
gen order=.
replace order=1 if var=="mean_deltad"
replace order=2 if var=="sd_deltad"
replace order=3 if var=="mean_return"
replace order=4 if var=="sd_return"
replace order=5 if var=="cov"
replace order=6 if var=="n"
sort order 
drop order
replace point_est=. if _n~=1
order Ticker point_est
rename event event
rename nonevent nonevent
replace event=round(event,.01) if var~="n"
replace nonevent=round(nonevent,.01) if var~="n"
export excel using "$rpath/Summary_`var'.xls", firstrow(variables) replace
}
}


**********************************
*Make CDS Figures for Presentation
**********************************

discard
use "$mpath/Composite_USD.dta", clear
twoway (line Spread6m date) (line Spread1y date) (line Spread2y date) (line Spread3y date) (line Spread4y date) (line Spread5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Par Spread") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("CDS")
graph export "$rpath/CDS_Plot.eps", replace

twoway (line Recovery date)if date>=td(01jan2011) & date<=td(30jul2014),  ytitle("Recovery Rate") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Recovery")
graph export "$rpath/Recovery_Plot.eps", replace



capture confirm file "$apath/cumdef_hazard.dta"

if _rc == 0 {
	use "$apath/cumdef_hazard.dta", clear
	twoway (line haz6m date) (line haz1y date) (line haz2y date) (line haz3y date) (line haz4y date) (line haz5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "0-6 Months" 2  "6 Months-1 Year" 3 "1-2 Years"  4 "2-3 Years" 5 "3-4 Years" 6 "4-5 Years")) ytitle("Hazard Rate") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Hazard")
	graph export "$rpath/Hazard_Plot.eps", replace

	twoway (line def6m date) (line def1y date) (line def2y date) (line def3y date) (line def4y date) (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Cumulative Default Probability") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default")
	graph export "$rpath/Default_Plot.eps", replace

	twoway (line def6m date, lcolor(white)) (line def1y date, lcolor(white)) (line def2y date, lcolor(white)) (line def3y date, lcolor(white)) (line def4y date, lcolor(white)) (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Cumulative Default Probability") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default2")
	graph export "$rpath/Default_Plot2.eps", replace
}


*JUST FOR THE VERSION WITH BONDS
/*
use "$apath/data_for_summary.dta", clear
replace cds=cds_*100
sort industry_sector market day_type event_day date
bysort industry_sector market day_type  event_day: gen n2=_n if event_day==1
sort industry_sector market day_type  eventcloses date
bysort industry_sector market day_type  eventcloses: gen n1=_n if eventcloses==1
gen event_desc="Stay, 11/29/12" if date==td(29nov2012) & day_type=="twoday"
replace event_desc="Supreme Court Denial, 6/16/14" if date==td(17jun2014) & day_type=="twoday"
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="defbond_eur" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Change") name("Twoday_defbond_eur") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/defbond_eur.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="rsbond_usd_disc" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Change") name("Twoday_rsbond_usd_disc") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/rsbond_usd_disc.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="rsbond_usd_par" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Change") name("Twoday_rsbond_usd_par") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/rsbond_usd_par.eps", replace

