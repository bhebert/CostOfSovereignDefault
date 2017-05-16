set more off
import excel "$bbpath/ADR_Collection_0409.xlsx", sheet("ADRs") clear
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
save "$apath/BB_ADR_return_temp.dta", replace


forvalues i=1(2)53 {
use "$apath/BB_ADR_return_temp.dta", clear
local y=`i'+1
keep v`i' v`y'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' total_return

drop if _n==1 | _n==2
local x=`y'/2
save "$apath/BB_ADR_`x'.dta", replace
}


use "$apath/BB_ADR_1.dta", clear
forvalues i=2/27 {
append using "$apath/BB_ADR_`i'.dta"
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
drop if date==.
save "$apath/BB_ADR_Full.dta", replace


****************************
*LOCALs, ADRs, some Indices*
****************************
set more off
import excel "$bbpath/Argentina_Bloomberg_0415.xlsx", sheet("Local_ADR_data") clear
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
save "$apath/Local_ADR_temp.dta", replace


forvalues i=1(3)406 {
use "$apath/Local_ADR_temp.dta", clear
local y=`i'+1
local z=`i'+2
keep v`i' v`y' v`z'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' px_open
rename v`z' px_last

drop if _n==1 | _n==2
local x=`z'/3
save "$apath/Local_ADR_`x'.dta", replace
}


use "$apath/Local_ADR_1.dta", clear
forvalues i=2/136 {
append using "$apath/Local_ADR_`i'.dta"
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

drop if date==.
drop if market=="CN"
save "$apath/Local_ADR_Full.dta", replace


****************************
*Indices*
****************************
*MERVALs*

import excel "$csd_data/GFD/Jesse_Schreger_Merval_excel2007.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
format date %td 
order date
drop Date
replace Ticker=subinstr(Ticker,"_","",.)
rename Open px_open
rename Close px_last
gen total_return=px_last
drop Low High Volume
gen market="Index"
*drop if Ticker=="MERVD"
replace Ticker=trim(Ticker)
replace Ticker="Merval" if Ticker=="MARD"
replace Ticker="Merval25" if Ticker=="MER25D"
replace Ticker="MervalD" if Ticker=="MERVD"
gen ticker_full=Ticker+"_"+"Index"
replace px_open=. if date==td(30dec2014) & Ticker=="Merval"
replace px_last=. if date==td(30dec2014) & Ticker=="Merval"
replace total_return=. if date==td(30dec2014) & Ticker=="Merval"
save "$apath/GFD_Merval.dta", replace

*BLOOMBERG
set more off
import excel "$bbpath/BB_Indices_04152015.xlsx", sheet("Index_values") clear
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
save "$apath/Indices_temp.dta", replace


forvalues i=1(4)61 {
use "$apath/Indices_temp.dta", clear
local y=`i'+1
local z=`i'+2
local k=`i'+3

keep v`i' v`y' v`z' v`k'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' px_open
rename v`z' px_last
rename v`k' total_return

drop if _n==1 | _n==2
local x=`k'/4
save "$apath/Index_`x'.dta", replace
}


use "$apath/Index_1.dta", clear
forvalues i=2/16 {
append using "$apath/Index_`i'.dta"
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
drop if market=="CN"
append using "$apath/GFD_Merval.dta"
save "$apath/Indices_Full.dta", replace


use "$apath/Local_ADR_Full.dta", clear
append using  "$apath/Indices_Full.dta"
mmerge date ticker_full using "$apath/BB_ADR_Full.dta", update
mmerge date ticker_full using "$apath/BB_Local_Full.dta", update
save "$apath/BB_Local_ADR_Indices_April2014.dta", replace




