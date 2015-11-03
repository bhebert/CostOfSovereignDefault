*Clean TGNO4
import excel "$mainpath/Bloomberg/Data/TGNO4.xlsx", sheet("Sheet1") clear
keep A B C D
gen date=date(A,"MDY")
format date %td
rename B px_open
rename C px_last 
rename D total_return
drop if _n<3
destring px_open, replace
destring px_last , replace
destring total_return, replace
drop A
gen Ticker="TGNO4"
gen ticker_full=Ticker+"_AR"
gen bb_ticker=Ticker+" AR Equity"
gen market="AR"
save "$apath/TGNO4.dta", replace
