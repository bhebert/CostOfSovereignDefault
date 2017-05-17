*Cleaning Bloomberg data



*INDEX Static
import excel "$bbpath/Data/Argentina Indices.xlsx", sheet("indices") firstrow allstring clear
rename Security ticker
save "$apath/Nov_Indices_chars.dta", replace


* Industries (moved from Cleaning.do)
import excel "$bbpath/Industry.xlsx", sheet("Industry") firstrow clear
foreach x of varlist _all {
rename `x', lower
}

split a, p(" ")
order a1
rename a1 Ticker
replace Ticker=trim(Ticker)
drop a a2 a3
save "$apath/Industries.dta", replace


*ADR Static
import excel "$bbpath/Data/Argentina Nov2.xlsx", sheet("Static Values") firstrow allstring clear
order Ticker ULT_PARENT_TICKER_EXCHANGE
rename Ticker adr_ticker
rename ADR_UNDL_Ticker underlying_ticker
split underlying_ticker, p(" ")
drop underlying_ticker2
rename underlying_ticker1 Ticker
order Ticker adr underlying_ticker
mmerge Ticker using "$apath/Industries.dta"
keep if _merge==3
rename Ticker ticker_short
rename adr_ticker ticker

encode ticker_short, gen(firm_number)
order firm_number
save "$apath/ADR_Static.dta", replace
