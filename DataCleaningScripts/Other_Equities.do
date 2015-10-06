*EQUITIES
tempfile temp
import excel "$miscdata/GFD Stock Markets/USD.xlsx", sheet("Data Information") clear firstrow
keep Ticker Country
save "`temp'", replace


import excel "$miscdata/GFD Stock Markets/USD.xlsx", sheet("Price Data") clear firstrow
gen date=date(Date,"MDY")
format date %td
order date
keep if yofd(date)>=2011 & date<=td(30jul2014)
keep date Ticker Close
drop if Ticker=="_BR2" | Ticker=="_CL2" | Ticker=="_MX2"
mmerge Ticker using "`temp'"
keep if _merge==3
drop Ticker
rename Country Ticker
replace Ticker="Equity"+Ticker
rename Close total_return
gen market="Index"
drop _merge
sort Ticker date
save "$apath/GFD_Equity.dta", replace
