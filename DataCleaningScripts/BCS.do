*THIS IS A WORK IN PROGRESS

*BCS
 set more off
import excel "$mainpath/Bloomberg/BlueChipSwap08132015.xlsx", sheet("BULK_DL") clear
*Note, this still generates output to dropbox, need to correct.
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
	
	local ii=`i'-1
save "$mainpath/Bloomberg/intermediate/BCS.dta", replace
	
	forvalues i=1(2)`ii' {
use "$mainpath/Bloomberg/intermediate/BCS.dta", clear
local y=`i'+1
keep v`i' v`y'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Corp","",.)
replace v`i'=subinstr(v`i',"@","_",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' px_last
drop if _n==1 | _n==2
local x=`y'/2
save "$mainpath/Bloomberg/intermediate/BCS_`x'.dta", replace
}

use "$mainpath/Bloomberg/intermediate/BCS_1.dta", clear
forvalues i=2/54 {
append using "$mainpath/Bloomberg/intermediate/BCS_`i'.dta"
}
split ticker, p("_")
rename ticker ticker_full
rename ticker1 Ticker
rename ticker2 source
rename date datestr
gen date=date(datestr,"MDY")
format date %td
order date
drop datestr
destring px_last, replace force
drop if date==.
browse if date==td(16jun2014)
gen ARS_temp=0
replace ARS_temp=1 if px_last>200 & date==td(16jun2014)
bysort ticker_full: egen ARS=max(ARS_temp)
drop ARS_temp
save "$mainpath/Bloomberg/Datasets/BCS.dta", replace

use  "$mainpath/Bloomberg/Datasets/BCS.dta", clear
collapse (median) px_last, by(date Ticker ARS)
reshape wide px_last, i(date Ticker) j(ARS)
gen blue=px_last1/px_last0
twoway (line blue date if Ticker=="EF106106") (line blue date if Ticker=="EG3581295") if yofd(date)>=2011
graph export (
twoway (line blue date if Ticker=="EF106106") (line blue date if Ticker=="EG3581295") if yofd(date)==2014
twoway (line blue date if Ticker=="EF106106") (line blue date if Ticker=="EG3581295") if date>=td(10jun2014) & date<=td(20jun2014)


use  "$mainpath/Bloomberg/Datasets/BCS.dta", clear
collapse (median) px_last, by(date ARS)
reshape wide px_last, i(date) j(ARS)
gen blue=px_last1/px_last0
*twoway (line blue date)

gen Ticker="BCS"
drop px_last*
rename blue px_close
append using "$apath/blue_rate.dta"
append using "$apath/NDF_Datastream.dta"
append using "$apath/dolarblue.dta"
append using "$apath/ADRBaltdata.dta"

twoway (line px_close date if Ticker=="BCS", sort) (line px_close date if Ticker=="dolarblue", sort) (line px_close date if Ticker=="ADRBlue", sort) (line px_close date if Ticker=="ADRBaltdata", sort) if yofd(date)>=2011, legend(order(1 "Blue Chip Swap" 2 "Dolar Blue" 3 "ADR Blue (CRSP/BCBA)" 4 "ADRBlue"))
graph export "$rpath/BlueRateNew.png", replace

twoway (line px_close date if Ticker=="BCS", sort) (line px_close date if Ticker=="dolarblue", sort) (line px_close date if Ticker=="ADRBlue", sort) (line px_close date if Ticker=="ADRBaltdata", sort) if date>=td(01jun2014) & date<=td(30jun2014), legend(order(1 "Blue Chip Swap" 2 "Dolar Blue" 3 "ADR Blue (CRSP/BCBA)" 4 "ADRBlue"))
graph export "$rpath/BlueRateNew_June2014.png", replace
