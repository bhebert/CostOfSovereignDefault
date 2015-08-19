**********************
*GENERATE ADR Weights*
**********************
set more off
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

*FACTOR STUFF
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

*******************************************************
*Construct T-bill returns for inclusion in Value Index*
*******************************************************
import excel "$gdppath/Tbill_rate.xls", sheet("fred_stata") firstrow clear
gen quarter=qofd(date)
format quarter %tq
collapse (firstnm) tbill, by(quarter)
gen Ticker="Tbill"
tsset quarter
drop if quarter<tq(1980q1)
gen total_return=1+(tbill/400) if quarter==tq(1980q1)
replace total_return=l.total_return*(1+tbill/400) if quarter>tq(1980q1)
gen px_last=1 
gen date=dofq(quarter)
gen newq=1
format date %td
tsset date
tsfill
carryforward tbill, replace
gen total_return_d=1+(tbill/36500) if date==td(01jan1980)
replace total_return_d=l.total_return_d*(1+tbill/36500) if  date>td(01jan1980)
carryforward total_return, replace
order quarter date total_return*
keep date total_return_d 
rename total_return total_return
*Assuming the interest is earned between open and close
gen px_open=l.total_return
gen px_close=total_return
gen Ticker="Tbill"
gen weight=.1
save "$apath/Tbill_daily.dta", replace


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
append using "$apath/Tbill_daily.dta"
gen dow=dow(date)
drop if dow==0 | dow==6

*JUST HERE TO FIX WEIGHT
encode Ticker, gen(tid)

* Compute the returns for various event windows
gen bdate = bofd("basic",date)
format bdate %tbbasic
tsset tid bdate
sort tid bdate


drop if bdate==.


local rtypes return_intra return_onedayN return_onedayL return_nightbefore return_1_5 return_twoday

gen return_intra = log(px_close/px_open)
gen return_onedayN = log(total_return / L.total_return)
gen return_onedayL = log(total_return / L.total_return) - return_intra + L.return_intra
gen return_nightbefore = return_onedayN - return_intra
gen return_twoday = log(total_return / L2.total_return) 
gen return_1_5 = return_twoday - return_intra

foreach x in `rtypes' {
	bysort date: egen count_`x'=count(`x')
}	
foreach x in `rtypes' {
	replace `x'=. if count_`x'<6
	}


//gen ret1 = total_return / L.total_return - 1
//gen ret2=total_return / L2.total_return - 1

//local rtypes ret px_ret 

*bysort date: egen temp2=count(total_return)
*drop if temp2==1

sort tid bdate

foreach rt in `rtypes' {
	gen weight_`rt' = weight
	replace weight_`rt' = 0 if `rt' == .
	bysort date: egen total_`rt'=sum(weight_`rt') if Ticker~="Tbill"
	replace weight_`rt'=0.9*weight_`rt'/total_`rt'  if Ticker~="Tbill"
	bysort date: egen total_test_`rt'=sum(weight_`rt') 
	drop total_`rt'
}



sort date Ticker
by date: egen valid = count(total_return)
ta Ticker valid



sort date tid
local mxarrets
foreach rtype  in `rtypes' {
	gen temp = exp(`rtype') - 1
	by date: egen `rtype'mxar = sum(weight*temp)
	by date: egen `rtype'mxar_cnt = sum(weight*(`rtype'!=.))
	replace `rtype'mxar = . if `rtype'mxar_cnt == 0
	replace `rtype'mxar = `rtype'mxar / `rtype'mxar_cnt 
	replace `rtype'mxar = 100*log(1+`rtype'mxar)
	drop `rtype'mxar_cnt temp
	local mxarrets `mxarrets' `rtype'mxar
}


/*sort tid bdate
gen ret1=(total_return/l.total_return)-1
replace weight=0 if ret1==.
bysort date: egen total_w=sum(weight)
replace weight=0.9*weight/total_w 
drop if total_w==0
replace weight=0.1 if Ticker=="Tbill"
replace weight=0 if Ticker=="ADRBlue"
by date: egen ValueIndexRet = sum(weight*ret1)
collapse (firstnm) `mxarrets' ValueIndexRet bdate count*, by(date)
*/

collapse (firstnm) `mxarrets'  bdate count*, by(date)
*replace ValueIndexRet=. if count_return_onedayN<6
gen n=_n
gen ValueIndex=1 if n==1

tsset bdate

*replace ValueIndexRet=log(1+ValueIndexRet)
*gen lag_V=0
*replace lag_V=1 if ValueIndexRet~=.

gen lag_V=0
replace lag_V=1 if return_onedayNmxar~=.
replace lag_V=1 if n==2

summ n
local maxtemp=r(max)
/*forvalues i=2/`maxtemp' {
	if lag_V[`i']==1 {
		replace ValueIndex=l.ValueIndex*(1+ValueIndexRet) if n>1 & n==`i'
		}
	else if lag_V[`i']==0 {
		local y=`i'-1
		local temp=ValueIndex[`y']
		replace ValueIndex=`temp' if n==`i'
	}
	}
*/	
	forvalues i=2/`maxtemp' {
	if lag_V[`i']==1 {
		replace ValueIndex=l.ValueIndex*(exp(return_onedayNmxar/100)) if n>1 & n==`i'
		}
	else if lag_V[`i']==0 {
		local y=`i'-1
		local temp=ValueIndex[`y']
		replace ValueIndex=`temp' if n==`i'
	}
	}
 	
keep if yofd(date)<=2014

*COMPARE
/*gen return_onedayN_test = 100*log(ValueIndex / L.ValueIndex)
gen return_twoday_test = 100*log(ValueIndex / L2.ValueIndex) 
replace return_twoday_test=. if count_return_twoday<6
replace return_twoday_test=. if ValueIndex==L2.ValueIndex

corr return_onedayN_test return_onedayNmxar
summ ValueIndexRet return_onedayNmxar	
scatter return_twoday_test return_twodaymxar
scatter return_onedayNmxar return_onedayN_test
*/

	
keep if bdate~=.
gen Ticker="ValueIndex"
gen industry_sector="ValueIndex"
gen market="`mark'"
drop lag_V n count* 


foreach rtype  in `rtypes' {
	rename `rtype'mxar `rtype'
}

tempfile temp
save "`temp'", replace
keep date bdate ValueIndex
save "$apath/ValueIndex_`mark'_Only.dta", replace

use "`temp'", clear
drop ValueIndex

//rename ret1mxar return_onedayN
//rename ret2mxar return_twoday

*COMMENTING OUT FACTOR STUFF
mmerge  date using "`factor_temp'", unmatched(master)
drop _merge
*replace return_o=return_o*100
*replace return_t=return_t*100
save "$apath/`filename'.dta", replace
}






