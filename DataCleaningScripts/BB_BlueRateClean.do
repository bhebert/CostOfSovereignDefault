*Bloomberg ADR/Underlying clean for BlueRateMaker_v2
*Note, this still generates output to dropbox, need to correct.
set more off
import excel "$mainpath/Bloomberg/Additional_Data_081215.xlsx", sheet("Data All") clear
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
	
	local ii=`i'-3
save "$mainpath/Bloomberg/intermediate/Data_081215.dta", replace
	
	forvalues i=1(4)`ii' {
use "$mainpath/Bloomberg/intermediate/Data_081215.dta", clear
local y=`i'+1
local z=`i'+2
local w=`i'+3
keep v`i' v`y' v`z' v`w'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' px_open
rename v`z' px_last
rename v`w' total_return
drop if _n==1 | _n==2
local x=`w'/4
save "$mainpath/Bloomberg/intermediate/eqnew_`x'.dta", replace
}

use "$mainpath/Bloomberg/intermediate/eqnew_1.dta", clear
forvalues i=2/16 {
append using "$mainpath/Bloomberg/intermediate/eqnew_`i'.dta"
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
destring px_open, replace force
destring px_last, replace force
destring total_return, replace force
drop if date==.
save "$mainpath/Bloomberg/Datasets/EqNewBlueRate.dta", replace
