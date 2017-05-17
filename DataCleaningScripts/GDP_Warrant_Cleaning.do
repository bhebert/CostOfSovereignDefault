

*GDP WARRANTS
set more off
import excel "$bbpath/GDP Warrants Full.xlsx", sheet("Prices") clear
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
save "$apath/Warrant_inter.dta", replace


forvalues i=1(3)16 {
use "$apath/Warrant_inter.dta", clear
local y=`i'+1
local z=`i'+2
keep v`i' v`y' v`z'
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' px_last
rename v`z' px_open
drop if _n==1 | _n==2
local x=`z'/3
save "$apath/Warrant_`x'.dta", replace
}


use "$apath/Warrant_1.dta", clear
forvalues i=2/6 {
append using "$apath/Warrant_`i'.dta"
}
split ticker, p("_")
drop ticker
rename ticker1 Ticker
rename ticker2 market
rename date datestr
gen date=date(datestr,"MDY")
format date %td
order date
drop datestr
destring px_last, replace force
destring px_open, replace force

drop if date==.
rename Ticker ticker
save  "$apath/Warrant_Master.dta", replace

*WARRANT CHARACTERISTICS
import excel "$bbpath/GDP Warrants Full.xlsx", sheet("All") firstrow clear
keep if GDP==1
order Identifier
drop Ticker
rename Identifier ticker
order ticker Curr Country
gen Market=""
replace Market="Global" if ticker=="EF0131575"
replace Market="Euro Non-Dollar" if ticker=="EF0151748"
replace Market="Domestic" if ticker=="EF0162331"
replace Market="Domestic" if ticker=="EF0162372"
replace Market="Samurai" if ticker=="EF1989112"
replace Market="Euro-Dollar" if ticker=="EI2415061"
save  "$apath/Warrant_detail.dta", replace

use "$apath/Warrant_Master.dta", clear
mmerge ticker using "$apath/Warrant_detail.dta", ukeep(Curr Market ISIN)
drop _merge
save "$apath/Warrant_Master.dta", replace


*BORSE FRANKFURT
tempfile bfusd bfeur
import excel "$warrant_path/Borse_Frankfurt.xlsx", sheet("Data_XS0209139244") firstrow clear
gen date=date(Date,"DMY")
order date
format date %td
drop Date
rename Open open
rename DailyH high
rename DailyL low
rename Last last
rename DailyTurnoverN turnover_nominal
rename Dail turnover
foreach x in open high low last turnover_nominal turnover {
	destring `x', force replace
	}
*SAME BOND AS EF0151748
gen ISIN="XS0209139244"

rename last px_open
gen px_close = .
*rename last px_close
*rename open px_open

gen Ticker="gdpw_bfeur"
gen market="Index"
gen industry_sector=Ticker
save "`bfeur'", replace
	
import excel "$warrant_path/Borse_Frankfurt.xlsx", sheet("Data_US040114GM64") firstrow clear
gen date=date(Date,"DMY")
order date
format date %td
drop Date
rename Open open
rename DailyH high
rename DailyL low
rename Last last
rename DailyTurnoverN turnover_nominal
rename Dail turnover
foreach x in open high low last turnover_nominal turnover {
	destring `x', force replace
	}
gen Ticker="gdpw_bfusd"
drop high low turn*
gen market="Index"
gen industry_sector=Ticker
*THIS IS THE SAME BOND AS "EF0131575"
gen ISIN="US040114GM64"

rename last px_open
gen px_close = .
*rename last px_close
*rename open px_open

save "`bfusd'", replace

use "`bfusd'", clear
append using "`bfeur'"
drop high low turn*
gen total_return=px_close
duplicates drop
save "$apath/gdpw_merge.dta", replace
