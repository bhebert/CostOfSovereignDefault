*Show US Inflation unaffected
import excel "$miscdata/US Breakeven Inflation/Breakeven_GFD.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
order date
format date %td
drop Date
replace Ticker="US10YBE" if Ticker=="IGT10YIE"
replace Ticker="US5YBE" if Ticker=="IGT5YIE"
encode Ticker,gen(tid)
tsset tid date
rename Close total_return

tsfill
carryforward Ticker, replace
carryforward total_return, replace
gen px_close=total_return
gen px_open=l.total_return
drop tid
save "$apath/US_Breakeven.dta", replace
