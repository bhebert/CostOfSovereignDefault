set more off
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/ADR_Collection_0409.xlsx", sheet("ADRs") clear
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/BB_ADR_return_temp.dta", replace


forvalues i=1(2)53 {
use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/BB_ADR_return_temp.dta", clear
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/BB_ADR_`x'.dta", replace
}


use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/BB_ADR_1.dta", clear
forvalues i=2/27 {
append using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/BB_ADR_`i'.dta"
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/BB_ADR_Full.dta", replace


********************
*Exchange rate data*
********************
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Datastream/Exchange Rates 0409.xlsx", sheet("Stata_import") clear
drop if _n==1
foreach x of varlist _all {
if `x'[1]==""{
drop `x' 
}
}
foreach x of varlist _all {
	replace `x'=subinstr(`x',"(","_",.)
	replace `x'=subinstr(`x',")","",.)
	replace `x'=subinstr(`x',"#","",.)
	}

	
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
	}
	rename Code date
	drop if _n==1
		rename date datestr
	gen date=date(datestr,"MDY")
	format date %td
	order date
	drop if date==.
	drop datestr
	foreach x of varlist _all { 
		destring `x', force replace
		}
		
		
	reshape long ARSUSDS ARUSDSR TDARSSP PDARS1M PDARS2M PDARS3M PDARS6M PDARS1Y, i(date) j(tempvar) str
	replace tempvar=subinstr(temp,"_","",.)
	rename tempvar obs_type

	foreach x in ARSUSDS ARUSDSR TDARSSP PDARS1M PDARS2M PDARS3M PDARS6M PDARS1Y {
	destring `x', force replace
	}
	label var ARSUSDS "Onshore Blue Rate"
	label var ARUSDSR "Official (RASL)"
	label var TDARSSP "Official Thomson Reuters"
	label var PDARS1M "1M NDF"
	label var PDARS2M "2M NDF" 
	label var PDARS3M "3M NDF" 
	label var PDARS6M "6M NDF" 
	label var PDARS1Y "1Y NDF"


sort obs_type date 
browse if obs_type=="ER"

twoway (line ARSUSDS date) (line TDARSSP date) (line PDARS1M date) (line PDARS6M date) (line PDARS1Y date) if obs_type=="ER" & yofd(date)>=2011
gen obs_num=.
replace obs_num=1 if obs_type=="EB"
replace obs_num=2 if obs_type=="EH"
replace obs_num=3 if obs_type=="EL"
replace obs_num=4 if obs_type=="EO"
replace obs_num=5 if obs_type=="ER"
replace obs_num=6 if obs_type=="ERS"
order date obs*

label define obs_type_vals 1 "Bid" 2 "Intraday high" 3 "Intraday low" 4 "Ask" 5 "Mid" 6 "Mid (unpadded?)"
label values obs_num obs_type_vals
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Datastream/Exchange_Rates_April2015.dta", replace


****************************
*LOCALs, ADRs, some Indices*
****************************
set more off
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Argentina_Bloomberg_0415.xlsx", sheet("Local_ADR_data") clear
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Local_ADR_temp.dta", replace


forvalues i=1(3)406 {
use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Local_ADR_temp.dta", clear
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Local_ADR_`x'.dta", replace
}


use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Local_ADR_1.dta", clear
forvalues i=2/136 {
append using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Local_ADR_`i'.dta"
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Local_ADR_Full.dta", replace


****************************
*Indices*
****************************
*MERVALs*

import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Misc Data/GFD Merval/Jesse_Schreger_Merval_excel2007.xlsx", sheet("Price Data") firstrow clear
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Misc Data/GFD Merval/GFD_Merval.dta", replace

*BLOOMBERG
set more off
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/BB_Indices_04152015.xlsx", sheet("Index_values") clear
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Indices_temp.dta", replace


forvalues i=1(4)61 {
use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Indices_temp.dta", clear
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
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Index_`x'.dta", replace
}


use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Index_1.dta", clear
forvalues i=2/16 {
append using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Index_`i'.dta"
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
append using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Misc Data/GFD Merval/GFD_Merval.dta"
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Indices_Full.dta", replace




use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Local_ADR_Full.dta", clear
append using  "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Indices_Full.dta"
mmerge date ticker_full using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/BB_ADR_Full.dta", update
mmerge date ticker_full using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/BB_Local_Full.dta", update
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/BB_Local_ADR_Indices_April2014.dta", replace


use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Analysis/Datasets/FirmTable.dta"
use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Local_ADR_Full.dta", clear
keep if market=="AR"
rename px_open px_open_local
rename px_last px_last_local
mmerge bb_ticker using  "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Analysis/Datasets/FirmTable.dta", ukeep (ADRticker name ticker isin_code)
keep if ADRticker~=""
replace ADRticker="IRCP US Equity" if bb_ticker=="APSA AR Equity"
rename bb_ticker bb_ticker_temp
rename ADRticker bb_ticker
mmerge bb_ticker date using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Local_ADR_Full.dta"
keep if _merge==3
rename bb_ticker ADRticker
rename bb_ticker_temp bb_ticker
drop _merge
rename px_open px_open_adr
rename px_last px_last_adr
gen adr_ratio=.
replace adr_ratio=1 if Ticker=="YPFD" 
replace adr_ratio=5 if Ticker=="TECO2" 
replace adr_ratio=10 if Ticker=="BMA" 
replace adr_ratio=10 if Ticker=="GGAL" 
replace adr_ratio=3 if Ticker=="FRAN" 
replace adr_ratio=10 if Ticker=="PESA" 
order px_open* px_last*
gen blue_open=adr_ratio*px_open_local/px_open_adr
gen blue_close=adr_ratio*px_last_local/px_last_adr
order blue*, after(date)
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Local_ADR_ForBlue_April.dta", replace




******************
*Dividend Cleaning
*******************
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Dividend Download.xlsx", sheet("Sheet2") clear
foreach x of varlist _all {
tostring `x', replace
	if `x'[3]=="." | `x'[3]=="#N/A Field Not Applicable"{
		drop `x'
		}
		}
		
local i=1
foreach x of varlist _all {		
	rename `x' v`i'
	local i=`i'+1
	}
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Dividend_temp.dta", replace


forvalues i=1(7)323 {
use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Dividend_temp.dta", clear
local j=`i'+1
local k=`i'+2
local l=`i'+3
local m=`i'+4
local n=`i'+5
local o=`i'+6

keep v`i' v`j' v`k' v`l' v`m' v`n' v`o'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' declared_date
rename v`j' ex_date
rename v`k' record_date
rename v`l' pay_date
rename v`m' dividend
rename v`n' frequency
rename v`o' type
drop if _n==1 | _n==2
local x=`o'/7
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Dividend_`x'.dta", replace
}


use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Dividend_1.dta", clear
forvalues i=2/47 {
append using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Dividend_`i'.dta"
}

foreach x in declared_date ex_date record_date pay_date {
gen `x'_temp=date(`x',"MDY")
order `x'_temp
destring `x', force replace
replace `x'=`x'_temp if `x'==.
drop `x'_temp
format `x' %td
}
replace dividend="" if dividend=="#N/A N/A"
destring dividend, replace 
drop if dividend==.
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Dividend_merged.dta", replace

use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate/Dividend_merged.dta", clear
drop if type=="Cancelled"
gen record_quarter=qofd(record_date)
drop if record_date==.
format record_quarter %tq
order record_quarter
collapse (sum) dividend, by(bb_ticker ticker record_quarter)
rename rec quarter
encode ticker, gen(fid)
tsset fid quarter
tsfill, full

save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Dividend_quarterly.dta", replace
