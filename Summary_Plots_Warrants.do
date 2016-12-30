
local hname NMLbond2030

*****************
*SUMMARY FIGURES*
*****************
*RUNS WITH DATES
set more off
use "$apath/ThirdAnalysis.dta", clear
sort industry_sector market day_type event_day date
bysort industry_sector market day_type  event_day: gen n2=_n if event_day==1
sort industry_sector market day_type  eventcloses date
bysort industry_sector market day_type  eventcloses: gen n1=_n if eventcloses==1

replace cds=cds_*100

*WARRANT PLOTS
local warrantplot gdpw_bfeur gdpw_bfusd 
local y=1
discard
foreach x of local warrantplot {
twoway    (scatter return_ cds if event_day==0, mcolor(gs9) msize(tiny)) (scatter return_ cds_ if event_day==1, mlabel(n2)) if industry_sec=="`x'" & eventexcluded==0 & day_type=="twodayL", legend(order(1 "Non-Event" 2 "Event")) xtitle("Change in Default Probability") ytitle("Log Change") name("TwodayL_`x'") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/Scatter_`x'_twodayL.eps", replace
local y=`y'+1
} 


