
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

*EXCHANGE RATE PLOTS
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

twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if firmname=="ValueINDEXNew_US" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Twoday_ValueINDEXNew1") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueINDEXNew_1.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1 & n2~=2, mlabel(n2)) (scatter return_ cds_ if n2==2, mlabel(event_desc) mcolor(blue)  mlabcolor(blue)) if firmname=="ValueINDEXNew_US" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Twoday_ValueINDEXNew2") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueINDEXNew_2.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1 & n2~=13, mlabel(n2)) (scatter return_ cds_ if n2==13, mlabel(event_desc)  mlabposition(9) mlabcolor(blue) mcolor(blue)) if firmname=="ValueINDEXNew_US" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("Twoday_ValueINDEXNew3") graphregion(fcolor(white) lcolor(white))
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
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if firmname=="ValueBankINDEXNew_US" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("Value-Weighted Index: Banks") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("VIBanks") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueBank_Scatter.eps", replace
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if firmname=="ValueNonFinINDEXNew_US" & eventexcluded==0 & day_type=="twoday" & market~="AR",title("Value-Weighted Index: Non-Financial") legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Return") name("VINonFin") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ValueNonfin_Scatter.eps", replace

keep if event_day==1 & firmname=="ValueINDEXNew_US" & eventexcluded==0 & day_type=="twoday" & market~="AR"
sort n2
browse  date return_ cds_  n2 
export excel n2 date cds_ return_ using "$rpath/Figure1_Table.xls", firstrow(variables) replace datestring("%tdMonth_dd,_CCYY")


********************************
*ALTERNATE CDS FIGURES
use "$apath/ThirdAnalysis.dta", clear

replace cds=cds*100
discard
browse if  industry_sec=="mC5_5y_DTRI" & eventexcluded==0 & day_type=="twoday" & event_day==1
order date industry_sec cds return_

foreach x in mC5_5y_DTRI bb_tri_def5y_DTRI ds_tri_def5y_DTRI tri_def5y_DTRI tri_conH_def5y_DTRI {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(date)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Change in Default Probability") name("`x'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/`x'.eps", replace
}


keep if industry_sec=="mC5_5y_DTRI" | industry_sec=="bb_tri_def5y_DTRI" | industry_sec=="ds_tri_def5y_DTRI" | industry_sec=="tri_def5y_DTRI" | industry_sec=="tri_conH_def5y_DTRI" | industry_sec=="ValueINDEXNew"
keep if day_type=="twoday" & market~="AR"
keep date industry_sec cds_ return_ event_day eventexcluded
gen valuet=return_ if industry_sec=="ValueINDEXNew"
bysort date: egen value=max(valuet)
drop valuet
discard
foreach x in mC5_5y_DTRI bb_tri_def5y_DTRI ds_tri_def5y_DTRI tri_def5y_DTRI tri_conH_def5y_DTRI {
twoway    (scatter value return_  if event_day==0, mcolor(gs9) msize(tiny)) (scatter value return_ if event_day==1, mlabel(date)) if industry_sec=="`x'" & eventexcluded==0 , legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Value Index Log Return") name("`x'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/`x'_value.eps", replace
}


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

local defprobfile "$apath/Default_Prob_All.dta"
capture confirm file `defprobfile'
if _rc != 0 {
	local defprobfile "$mpath/Default_Prob_All.dta"
}

mmerge date using "`defprobfile'"


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
*append using "$apath/NDF_Datastream.dta"
append using "$apath/dolarblue.dta"
append using "$apath/bcs.dta"
append using "$apath/ADRB_PBRTS.dta"
*append using "$apath/Contado.dta"

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

twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med)) (line px_close date if Ticker=="ADRBlue", sort lwidth(med)) if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx_nondf")
graph export "$rpath/fx_nondf.eps", replace

twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(thick)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med) lpattern(dash)) (line px_close date if Ticker=="ADRBlue", sort lwidth(medthick) lpattern( longdash_dot)) if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx_nondf_bw")
graph export "$rpath/fx_nondf_bw.eps", replace


*SUMMARY TABLE
foreach var in ValueINDEXNew_US dolarblue{
cap { 
use "$apath/data_for_summary.dta", clear
keep if  firmname=="`var'"
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


*****************
*FIRM TABLE FOR PAPER
use "$apath/FirmTable.dta", clear
order name Ticker industry_sec es_ import_rev market_cap indicator_adr ADRt foreign
replace name=proper(name)
replace name=subinstr(name," 'B'","",.)
replace name=subinstr(name," 'A'","",.)
replace name=subinstr(name," 'C'","",.)
replace industry_sec="Chemicals" if industry_sec=="Chems"
replace industry_sec="Energy" if industry_sec=="Enrgy"
replace industry_sec="Manufacturing" if industry_sec=="Manuf"
replace industry_sec="Non-Durables" if industry_sec=="NoDur"
replace industry_sec="Real Estate" if industry_sec=="RlEst"
replace industry_sec="Telecoms" if industry_sec=="Telcm"
replace industry_sec="Utilities" if industry_sec=="Utils"
gen ind_ADR="Y" if indicator_adr==1 & ADRticker~=""
replace ind_ADR="Y*" if indicator_adr & ADRticker==""
gen foreign_ind="Y" if foreign_own==1
keep name ticker_short industry_sec es_ import_rev market_cap foreign_ind ind_ADR 
order name ticker_short industry_sec es_ import_rev market_cap foreign_ind ind_ADR  
 
replace name="Edenor" if name=="Edenor Emsa.Disb.Y Comlz.Norte"
replace name="IRSA Propiedades Commerciales" if name=="Irsa Propiedades Comit."
replace name="Petrobras Argentina" if name=="Petrobras Energia"
replace name="YPF" if name=="Ypf"
replace name="SA San Miguel" if name=="Sa San Miguel"
replace name="IRSA" if name=="Irsa"

label var name "Company"
label var  industry "Industry"
label var  es "Exports"
label var  imp "Imports"
label var  market "Market Cap (2011)"
label var ind_ADR "ADR"
label var foreign "Foreign"
label var ticker_short "Ticker"
replace es=es*100
replace imp=imp*100
replace es=. if industry=="Banks" | industry=="Real Estate"
replace imp=. if industry=="Banks" | industry=="Real Estate"
sort ticker_short
export excel using "$rpath/FirmTable_Paper.xls", firstrow(varlabels) replace 

********************
*JUNE 16 Figure*****
capture {
	use "$mainpath/Slides/Figures/June16/June16.dta", clear
	mmerge clocktime using  "$mainpath/Slides/Figures/June16/DefProbJune16.dta"
	replace def=def*100
	discard
	twoway (scatter def clocktime if type=="Markit_ARS_CDS", mlabel("snaptime")) (line MXAR_dpx clocktime, lpattern(dash) yaxis(2))  if clocktime>=9.5 & clocktime<=11.75, legend(order(1 "Probability of Default" 2 "MSCI Argentina Index"))  ytitle("Probability of Default (Percent)") ytitle("Equity Log Return Since Close (Percent)", axis(2))  name("defprob") xlabel( 9.5 "9:30 am" 10.5 "10:30 am" 11.5 "11:30 am") xtitle("") graphregion(fcolor(white) lcolor(white))
	graph export "$rpath/June16newfig.eps", as(eps) preview(off) replace
}



