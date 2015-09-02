
*BCS: IMPORT ALL DATA
tempfile tempbond
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

*Drop bad data series 
use  "$mainpath/Bloomberg/Datasets/BCS.dta", clear
keep if yofd(date)>=2011 & yofd(date)<=td(01aug2014)
encode bb_ticker, gen(tid)
sort tid date
bysort tid: gen n=_n
tsset tid n
gen change=log(px_last)-log(l.px_last)
gen stale=1 if px_last==l.px_last
bysort tid: egen tidcount=count(px_last)
bysort tid: egen stalecount=sum(stale)
gen stale_ratio=stalecount/tidcount
*Drop stale data
drop if stale_ratio>.05

*See what data we have
browse if Ticker=="EF106106" & ARS==1 & date==td(16jun2014)
browse if Ticker=="EF106106" & ARS==0 & date==td(16jun2014)
browse if Ticker~="EF106106" & ARS==1 & date==td(16jun2014)
browse if Ticker~="EF106106" & ARS==0 & date==td(16jun2014)

*Make sure that there are no 
replace px_last=. if px_last>150 & ARS==0
replace px_last=. if px_last<200 & ARS==1
*drop if less than 300 days of data
drop if tidcount<300

*plot individual series
/*discard
levelsof source, local(sid)
foreach x of local sid {
twoway (line px_last date  if Ticker=="EF106106", sort) if source=="`x'" & yofd(date)>=2011, title("`x'") name("`x'")
} */

*Select median price by currency, bond, date
collapse (median) px_last, by(date Ticker ARS)
save "`tempbond'", replace

reshape wide px_last, i(date Ticker) j(ARS)
gen blue=px_last1/px_last0
*Call Blue Chip Swap Rate the mean across the two bonds.
*This is the step where we could add more bonds.
collapse (mean) blue, by(date)
twoway (line blue date), title("Blue Chip Swap Rate") ytitle("Blue Chip Swap Rate")
graph export "$rpath/BCS_Clean.png", replace
gen bdate = bofd("basic",date)
format bdate %tbbasic
sort bdate
rename blue px_close
tsset bdate
gen px_open =.
gen Ticker="BCS"
gen total_return=px_close
drop bdate 
*ready to merge into ThirdAnalysis.dta
save "$apath/bcs.dta", replace


*SET UP FOR BOND LEVEL TO ADD TO THIRD ANALYSIS
use "`tempbond'", clear
replace Ticker="boden7_ars" if Ticker=="EG3581295" & ARS==1
replace Ticker="boden7_usd" if Ticker=="EG3581295" & ARS==0
replace Ticker="bonarx_ars" if Ticker=="EF106106" & ARS==1
replace Ticker="bonarx_usd" if Ticker=="EF106106" & ARS==0
drop ARS
rename px_last px_close
gen px_open=.
gen total_return=px_close
gen market="Index"
gen industry_sector=Ticker
save "$apath/domestic_bonds.dta", replace

