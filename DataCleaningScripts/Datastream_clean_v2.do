set more off

*FIX ISIN MISMATCH IN 
import excel "$csd_data/Bloomberg/Argentina_Bloomberg_0304.xlsx", sheet("Static_Values") firstrow clear
replace ID_ISIN ="ARTGNO010117" if ID_ISIN=="ARP930811186"
rename bb_ BB_ticker
save  "$apath/BB_Static_0304.dta", replace

************************
*Static Characteristics*
************************
import excel "$csd_data/Datastream/Datastream_Static_0302.xlsx",  sheet("Static") clear
replace F="Industry_group_num" if F=="INDUSTRY GROUP"
foreach x of varlist _all {
	replace `x'=subinstr(`x'," ","_",.) if _n==1
	replace `x'=subinstr(`x',".","",.) if _n==1
	replace `x'=lower(`x') if _n==1
	replace `x'=subinstr(`x'," - ","_",.) if _n==1
    replace `x'=subinstr(`x',"-","_",.) if _n==1
    replace `x'=subinstr(`x',"__","_",.) if _n==1
    replace `x'=subinstr(`x',"__","_",.) if _n==1
}	
	
foreach x of varlist _all {
cap {
		local temp=`x'[1]
		rename `x' `temp'
}		
}

drop if _n==1
split type, p(":")
rename type2 Ticker
order Ticker
drop type1		
save "$apath/Datastr_Static_Chars_v2.dta", replace


*MERGE BB STATIC with Datastream Static
use "$apath/Datastr_Static_Chars_v2.dta", clear
mmerge isin_code using "$apath/BB_Static_0304.dta", umatch(ID_ISIN)
keep if _merge==3

save "$apath/DS_BB_Static.dta", replace

** Ownership
import excel "$csd_data/Bloomberg/Argentina_Bloomberg_0304.xlsx", sheet("Ownership") clear
foreach x of varlist _all {
	tostring `x', replace force
	if `x'[3]=="." {
		drop `x'
		}
		}
	
	foreach x of varlist _all{
	if `x'[3]=="#N/A Field Not Applicable" {
	drop `x'
	}
	}
local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	
	
	
	save "$apath/Ownership_temp.dta", replace
	
forvalues i=1(2)143 {
use "$apath/Ownership_temp.dta", clear
    local j=`i'+1
	keep v`i' v`j'
	local temp=v`i'[1]
	gen bb_ticker="`temp'"
	destring v`j', force replace
	rename v`j' share
	rename v`i' type
	drop if _n==1 | _n==2
	drop if type==""
	local y=`j'/2
	save "$apath/Ownership_`y'.dta", replace
}	

use "$apath/Ownership_1.dta", clear
forvalues i=2(1)72 {
append using "$apath/Ownership_`i'.dta"
}


replace type=subinstr(type,"(","",.)
replace type=subinstr(type,")","",.)
replace type=subinstr(type," ","_",.)
replace type=subinstr(type,"__","_",.)
replace type=subinstr(type,"__","_",.)

reshape wide share, i(bb_ticker) j(type) string
renpfix share
order bb_ticker Government
foreach x in Government Bank Corporation Endowment Hedge_Fund_Manager Holding_Company Individual Insurance_Company Investment_Advisor Other Pension_Fund_ERISA Private_Equity Unclassified Venture_Capital {
replace `x'=0 if `x'==.
}
mmerge bb_ticker using "$apath/BB_Static_0304.dta", umatch(BB_ticker) ukeep(ID_ISIN)
keep if _merge==3
mmerge ID_ISIN using "$apath/Datastr_Static_Chars_v2.dta", umatch(isin_code) ukeep(Ticker name)
keep if _merge==3
keep if Ticker~=""
order Ticker bb_ticker name Gov
save "$apath/Ownership_Ticker.dta", replace

***********************
*Foreign Ownership***
***********************
import excel "$csd_data/Bloomberg/Argentina_Bloomberg_0304.xlsx", first sheet("Domicile") clear
replace ID_ISIN ="ARTGNO010117" if ID_ISIN=="ARP930811186"
rename PARENT_COM parent
rename ID_BB_ULTIMATE_PARENT_CO_NAME ultimate_parent
rename COUNTRY country
rename ULT_PAR parent_country
mmerge ID_ISIN using "$apath/Datastr_Static_Chars_v2.dta", umatch(isin_code) ukeep(Ticker)
drop if _merge==2
order bb_ticker Ticker parent_country
gen foreign_own=0
replace foreign=1 if parent_country~="AR"
order foreign, before (parent_c)
sort Ticker
save "$apath/Foreign_Ownership_Ticker.dta", replace


***********************
*Exports Sales ***
***********************
import excel "$csd_data/Bloomberg/Argentina_Bloomberg_0304.xlsx",  sheet("Exports_Sales") clear
foreach x of varlist _all {
	tostring `x', replace force
	if `x'[3]=="." {
		drop `x'
		}
		}
	

local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	
	
	forvalues x=1/325{
			local y=`x'+1
			local z=`x'+2
		cap  {
			if v`x'[3]=="#N/A N/A" & v`y'[3]=="" & v`z'[3]=="" {
				drop v`x' v`y' v`z'
			}
		}
	}
	
	local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	save "$apath/Ownership_temp.dta", replace

forvalues i=1(3)307 {
use "$apath/Ownership_temp.dta", clear
    local j=`i'+1
	local k=`i'+2
	keep v`i' v`j' v`k'
	local temp=v`i'[1]
	gen bb_ticker="`temp'"
	destring v`j', force replace
	destring v`k', force replace

	rename v`j' exports
	rename v`k' revenue
	rename v`i' datestr
	drop if _n==1 | _n==2
	drop if datestr==""
	local y=`k'/3
	save "$apath/export_sales_`y'.dta", replace
}		

use "$apath/export_sales_1.dta", clear
forvalues i=2(1)103 {
append using "$apath/export_sales_`i'.dta"
}
gen date=date(datestr,"MDY")
format date %td
drop datestr
order date
mmerge bb_ticker using "$apath/BB_Static_0304.dta", umatch(BB_ticker) ukeep(ID_ISIN)
keep if _merge==3
replace ID_ISIN ="ARTGNO010117" if ID_ISIN=="ARP930811186"
mmerge ID_ISIN using "$apath/Datastr_Static_Chars_v2.dta", umatch(isin_code) ukeep(Ticker name)
keep if _merge==3
keep if Ticker~=""
drop _merge
gen export_share=(exports/revenue)*100
order date Ticker bb_ticker export_share exports revenue
sort Ticker date
save "$apath/Export_TS_manual_Ticker.dta", replace

***********************
*Market Cap************
***********************
import excel "$csd_data/Bloomberg/Market_Cap.xlsx",  sheet("Market_Cap") clear
foreach x of varlist _all {
	tostring `x', replace force
	if `x'[3]=="." {
		drop `x'
		}
		}
	

local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	
	local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	save "$apath/Market_Cap_temp.dta", replace

forvalues i=1(2)167 {
use "$apath/Market_Cap_temp.dta", clear
    local j=`i'+1
	keep v`i' v`j'
	local temp=v`i'[1]
	gen bb_ticker="`temp'"
	destring v`j', force replace
	rename v`j' market_cap
	rename v`i' quarterstr
	drop if _n==1 | _n==2
	drop if quarterstr==""
	local y=`j'/2
	save "$apath/MC_`y'.dta", replace
}		

use "$apath/MC_1.dta", clear
forvalues i=2(1)84 {
append using "$apath/MC_`i'.dta"
}
gen date=date(quarterstr,"MDY")
format date %td
drop quarterstr
order date
mmerge bb_ticker using "$bbpath/BB_Static_0304.dta", umatch(BB_ticker) ukeep(ID_ISIN)
replace ID_ISIN ="ARTGNO010117" if ID_ISIN=="ARP930811186"

keep if _merge==3
mmerge ID_ISIN using "$apath/Datastr_Static_Chars_v2.dta", umatch(isin_code) ukeep(Ticker name)
keep if _merge==3
keep if Ticker~=""
drop _merge
order date Ticker bb_ticker market_cap
sort Ticker date
save "$apath/Market_Cap_Ticker.dta", replace

use "$apath/Market_Cap_Ticker.dta", clear
gen quarter=qofd(date)
format quarter %tq
keep if quarter==tq(2011q2)
gen year=yofd(date)
keep if year==2011
collapse (mean) market_cap, by(Ticker bb_ticker ID_ISIN name)
save "$apath/Market_Cap_Ticker_2011.dta", replace



	
	
	
