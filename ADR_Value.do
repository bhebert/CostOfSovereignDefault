	**********************
*GENERATE ADR Weights*
**********************
use "$apath/Datastream_Quarterly.dta", clear
mmerge Ticker using "$apath/FirmTable.dta"
keep if _merge==3
split ADR, p(" ")
drop ADRticker2 ADRticker3
drop Ticker
rename ADRticker1 Ticker
keep Ticker quarter MV
drop if Ticker==""

bysort quarter: egen total_market=sum(MV)
gen weight=MV/total_market
replace weight=0 if weight==.
bysort quarter: egen test=sum(weight)
drop test total_market

bysort quarter: egen total_market=sum(MV) if Ticker~="YPF"
gen weight_exypf=MV/total_market if Ticker~="YPF"
replace weight_exypf=0 if weight_exypf==.
bysort quarter: egen test=sum(weight_exypf)
drop test total_market
replace quarter=quarter+1
save "$apath/ADR_weighting.dta", replace

*******************
*FOR LOCAL Value**
*******************
use "$apath/Datastream_Quarterly.dta", clear
mmerge Ticker using "$apath/FirmTable.dta"
keep if _merge==3
split bb_ticker, p(" ")
order bb_ticker*
replace Ticker=bb_ticker1
drop bb_tic*
keep Ticker quarter MV
drop if Ticker==""

bysort quarter: egen total_market=sum(MV)
gen weight=MV/total_market
replace weight=0 if weight==.
bysort quarter: egen test=sum(weight)
drop test total_market

bysort quarter: egen total_market=sum(MV) if Ticker~="YPFD"
gen weight_exypf=MV/total_market if Ticker~="YPFD"
replace weight_exypf=0 if weight_exypf==.
bysort quarter: egen test=sum(weight_exypf)
drop test total_market
replace quarter=quarter+1
save "$apath/Local_weighting.dta", replace





******************************************
*CONSTRUCT RETURNS ON THE  VALUE INDICES**
******************************************

*COMMENTING OUT FACTOR STUFF
/*set more off
*SET UP FACTORS FOR MERGE
use "$apath/MarketFactorsNew.dta", clear
* Save the names of each factor variable, which will
* be needed to avoid dropping them later
levelsof ticker, local(factors)
* Now there is a factor_intraSPX, factor_intraVIX, etc...
reshape wide factor_intra factor_nightbefore factor_onedayN factor_onedayL factor_1_5 factor_twoday, i(date) j(ticker) string
local fnames
local fprefs
foreach nm in `factors' {
	local fprefs `fprefs' `nm'_
	foreach et in intra nightbefore onedayN onedayL 1_5 twoday {
		rename factor_`et'`nm' `nm'_`et'
		local fnames `fnames' `nm'_`et'
		
	}
}
disp "`fnames'"
disp "`fprefs'"
tempfile factor_temp
save "`factor_temp'", replace
*/



*****************
****VALUE INDEX*
*****************
forvalues i=1/2 {
if `i'==1 {
local mark="US"
local filename="ValueIndex_ADR"
local weightfile="ADR_weighting"
}
else if `i'==2 {
local mark="AR"
local filename="LocalValueIndex"
local weightfile="Local_weighting"
}

use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear
drop if date == .
drop if Ticker == ""
drop if market != "`mark'"
keep date px_open px_last Ticker total_return market

//rename Ticker ticker
//replace ticker = ticker + " US Equity" if market == "US"
drop if date < mdy(1,1,1995)
drop if date>mdy(4,1,2015)
gen quarter=qofd(date)
format quarter %tq
mmerge quarter Ticker using "$apath/`weightfile'.dta", ukeep(weight_exypf)
rename weight_exypf weight
keep if _merge==3
rename px_last px_close


*MERGE IN BILLS
append using "$dir_gdpw/Tbill_daily.dta"
gen dow=dow(date)
drop if dow==0 | dow==6

*JUST HERE TO FIX WEIGHT
encode Ticker, gen(tid)

* Compute the returns for various event windows
gen bdate = bofd("basic",date)
format bdate %tbbasic
tsset tid bdate
sort tid bdate

gen ret1 = total_return / L.total_return - 1
gen ret2=total_return / L2.total_return - 1

local rtypes ret px_ret 
gen weight1=weight
gen weight2=weight
replace weight1=0 if ret1==.
replace weight2=0 if ret2==.

bysort date: egen total_w1=sum(weight1)
bysort date: egen total_w2=sum(weight2)

replace weight1=0.9*weight1/total_w1 
replace weight2=0.9*weight2/total_w2 

drop total_w*
sort date Ticker
by date: egen valid = count(total_return)
ta Ticker valid

drop if valid <= 6
drop valid


sort date tid
foreach rtype  in ret1 ret2  {
	by date: egen `rtype'mxar = sum(weight*`rtype')
	by date: egen `rtype'mxar_cnt = sum(weight*(`rtype'!=.))
	replace `rtype'mxar = . if `rtype'mxar_cnt == 0
	replace `rtype'mxar = `rtype'mxar / `rtype'mxar_cnt 
	drop `rtype'mxar_cnt 
	}
collapse (firstnm) ret1mxar ret2mxar bdate, by(date)
keep if bdate~=.
gen Ticker="ValueIndex"
gen industry_sector="ValueIndex"
gen market="`mark'"
rename ret1mxar return_onedayN
rename ret2mxar return_twoday
*COMMENTING OUT FACTOR STUFF
*mmerge  date using "`factor_temp'", unmatched(master)
*drop _merge
*replace return_o=return_o*100
*replace return_t=return_t*100
save "$apath/`filename'.dta", replace
}




