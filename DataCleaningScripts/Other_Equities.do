set more off

*EQUITIES
tempfile temp
import excel "$csd_data/GFD/USD.xlsx", sheet("Data Information") clear firstrow
keep Ticker Country
save "`temp'", replace


import excel "$csd_data/GFD/USD.xlsx", sheet("Price Data") clear firstrow
gen date=date(Date,"MDY")
format date %td
order date
keep if yofd(date)>=2011 & date<=td(30jul2014)
keep date Ticker Close
drop if Ticker=="_BR2" | Ticker=="_CL2" | Ticker=="_MX2" | Ticker=="_CYMAIND" | Ticker=="_FTWIGRC"
mmerge Ticker using "`temp'"
keep if _merge==3
drop Ticker
replace Country="BRL" if Country=="Brazil"
replace Country="MEX" if Country=="Mexico"

rename Country Ticker
replace Ticker="EquityInd"+Ticker
rename Close total_return
gen market="Index"
drop _merge
sort Ticker date
gen industry_sector=Ticker
save "$apath/GFD_Equity.dta", replace
