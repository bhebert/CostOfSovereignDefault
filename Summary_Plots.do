
*****************
*SUMMARY FIGURES*
*****************
*RUNS WITH DATES
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

/*local indplot ADRB_PBRTS ADRBlue BCS Contado_Ambito DSBlue dolarblue ValueINDEXNew MexicoEquity
discard
foreach x of local indplot {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(date)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) title("Two day: `x'") xtitle("Argentina CDS Spread Change") ytitle("Change") name("Twoday`y'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`y'_twoday.png", replace
twoway    (scatter return_ cds if eventcloses==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if eventcloses==1, mlabel(date)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="onedayN" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) title("One day: `x'") xtitle("Argentina CDS Spread Change") ytitle("Change") name("oneday`y'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`y'_onedayN.png", replace
local y=`y'+1
}
*/

local indplot ADRB_PBRTS ADRBlue BCS Contado_Ambito DSBlue dolarblue ValueINDEXNew MexicoEquity
local y=1
discard
foreach x of local indplot {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="twoday" & market~="AR", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Change") name("Twoday_`x'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`x'_twoday.png", replace
twoway    (scatter return_ cds if eventcloses==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if eventcloses==1, mlabel(n1)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="onedayN" & market~="AR", legend(order(1 "Non-Event" 2 "Event"))  xtitle("Change in Default Probability") ytitle("Change") name("oneday`x'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`x'_onedayN.png", replace
local y=`y'+1
}


*Can add versions here to get old numbers back


*********************
*EXCHANGE RATE Plots

use "$apath/blue_rate_old.dta", clear
keep if Ticker=="YPFDBlue"
append using "$apath/ADRBlue_All.dta"
append using "$apath/blue_rate.dta"
append using "$apath/NDF_Datastream.dta"
append using "$apath/dolarblue.dta"
append using "$apath/bcs.dta"
append using "$apath/ADRB_PBRTS.dta"
append using "$apath/Contado.dta"

replace Ticker=ADR_Ticker if Ticker==""
twoway (connected px_close date if Ticker=="BFR") (connected px_close date if Ticker=="BMA") (connected px_close date if Ticker=="GGAL") (connected px_close date if Ticker=="PAM") (connected px_close date if Ticker=="PBR") (connected px_close date if Ticker=="PZE") (connected px_close date if Ticker=="TEO") (line px_close date if Ticker=="TS") (line px_close date if Ticker=="dolarblue")  (connected px_close date if Ticker=="ADRB_PBRTS") (line px_close date if Ticker=="BCS") (line px_close date if Ticker=="ADRBlue") (line px_close date if Ticker=="YPFDBlue") (line px_close date if Ticker=="DSBlue") if date>=td(13jun2014) & date<=td(19jun2014), legend(order(1 "BFR" 2 "BMA" 3 "GGAL" 4 "PAM" 5 "PBR" 6 "PZE" 7 "TEO" 8 "TS" 9 "Dolarblue" 10 "ADRB_PBRTS" 11 "BCS" 12 "ADRBlue" 13 "YPF" 14 "DSBlue"))
graph export "$rpath/SupremeCourtDispersion.png", replace

twoway (line px_close date if Ticker=="dolarblue", sort)  (connected px_close date if Ticker=="ADRB_PBRTS", sort) (line px_close date if Ticker=="BCS", sort) (line px_close date if Ticker=="ADRBlue", sort) (line px_close date if Ticker=="YPFDBlue")  (line px_close date if Ticker=="DSBlue") if date>=td(13jun2014) & date<=td(19jun2014), legend(order(1 "Dolarblue" 2 "ADRB_PBRTS" 3 "BCS" 4 "ADRBlue" 5 "YPF" 6 "DSBlue"))
graph export "$rpath/SupremeCourtDispersion_Main.png", replace

twoway (line px_close date if Ticker=="OfficialRate", sort) (line px_close date if Ticker=="dolarblue", sort) (line px_close date if Ticker=="BCS", sort) (line px_close date if Ticker=="ADRBlue", sort)  (line px_close date if Ticker=="NDF12M", sort)  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ExchangeRates_Presentation.png", replace


*CLICKABLE
discard
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(thick)) (line px_close date if Ticker=="dolarblue", sort lcolor(white)) (line px_close date if Ticker=="BCS", sort lcolor(white)) (line px_close date if Ticker=="ADRBlue", sort lcolor(white))  (line px_close date if Ticker=="NDF12M", sort lcolor(white))  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white)) name("fx1")
graph export "$mainpath/Figures and Tables/Exchange Rate/fx1.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(thick))   if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx2")
graph export "$mainpath/Figures and Tables/Exchange Rate/fx2.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(thick)) if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx3")
graph export "$mainpath/Figures and Tables/Exchange Rate/fx3.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med)) (line px_close date if Ticker=="ADRBlue", sort lwidth(thick)) if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx4")
graph export "$mainpath/Figures and Tables/Exchange Rate/fx4.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med)) (line px_close date if Ticker=="ADRBlue", sort lwidth(med)) (line px_close date if Ticker=="NDF12M", sort lwidth(thick))  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx5")
graph export "$mainpath/Figures and Tables/Exchange Rate/fx5.eps", replace
twoway (line px_close date if Ticker=="OfficialRate", sort lwidth(med)) (line px_close date if Ticker=="dolarblue", sort  lwidth(med))  (line px_close date if Ticker=="BCS", sort lwidth(med)) (line px_close date if Ticker=="ADRBlue", sort lwidth(med)) (line px_close date if Ticker=="NDF12M", sort lwidth(med))  if date>=td(01jan2011) & date<=td(30jun2014),  legend(order(1 "Official" 2 "Dolar Blue" 3 "ADR" 4 "Blue Chip Swap" 5 "NDF - 12 Months"))  xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("ARS/USD") graphregion(fcolor(white) lcolor(white))  name("fx6")
graph export "$mainpath/Figures and Tables/Exchange Rate/fx6.eps", replace

