set more off
import excel "$bbpath/Argentina_Bloomberg_0304.xlsx", sheet("Returns") clear
foreach x of varlist _all {
tostring `x', replace
	if `x'[3]=="." {
		drop `x'
		}
		}
		
local i=1
foreach x of varlist _all {		
	rename `x' v`i'
	local i=`i'+1
	}
save "$apath/BB_return_temp.dta", replace


forvalues i=1(2)217 {
use "$apath/BB_return_temp.dta", clear
local y=`i'+1
keep v`i' v`y'
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' total_return

drop if _n==1 | _n==2
local x=`y'/2
save "$apath/BB_`x'.dta", replace
}

use "$apath/BB_1.dta", clear
forvalues i=2/109 {
append using "$apath/BB_`i'.dta"
}
split ticker, p("_")
rename ticker ticker_full
rename ticker1 Ticker
rename ticker2 market
rename date datestr
gen date=date(datestr,"MDY")
format date %td
order date
drop datestr
destring total_return, replace force
sort date ticker_full
save "$apath/BB_Local_Full.dta", replace


