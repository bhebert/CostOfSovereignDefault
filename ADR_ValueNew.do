**********************
*GENERATE ADR Weights*
**********************
set more off
use "$apath/Datastream_Quarterly.dta", clear

mmerge Ticker using "$apath/FirmTable.dta"
keep if _merge==3
split ADRticker, p(" ")
drop ADRticker2 ADRticker3
drop Ticker
rename ADRticker1 Ticker
keep Ticker quarter MV EPS ADRratio WC05101 leverage
rename WC05101 DivPerShare
drop if Ticker==""

sort Ticker quarter


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
save "$apath/US_weighting.dta", replace

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
save "$apath/AR_weighting.dta", replace





******************************************
*CONSTRUCT RETURNS ON THE  VALUE INDICES**
******************************************

*FACTOR STUFF
*SET UP FACTORS FOR MERGE
//use "$apath/MarketFactorsNew.dta", clear
* Save the names of each factor variable, which will
* be needed to avoid dropping them later
//levelsof ticker, local(factors)
* Now there is a factor_intraSPX, factor_intraVIX, etc...
/*reshape wide factor_intra factor_nightbefore factor_onedayN factor_onedayL factor_1_5 factor_twoday, i(date) j(ticker) string
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
save "`factor_temp'", replace*/

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
keep date total_return_d tbill
rename total_return total_return

*Assuming the interest is earned overnight and there is no price movement
gen px_open=1

*Assuming the interest is earned between open and close
*gen px_open=l.total_return
*gen px_close=total_return
gen px_close = 1

gen Ticker="Tbill"
gen weight=.1
save "$apath/Tbill_daily.dta", replace


*****************
****VALUE INDEX*
*****************
foreach mark in US /*AR*/ {

	foreach indtype in /*ValueBank ValueNonFin*/ Value {

		local filename= "`indtype'Index_`mark'_New"
		
		local weightfile="`mark'_weighting"
		
		use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear
		
		drop if date == .
		drop if Ticker == ""
		drop if market != "`mark'"
		
		
		gen ADRticker = bb_ticker if market == "US"
		replace ADRticker = "none" if market == "AR" | market == "Index"
		mmerge bb_ticker using "$apath/FirmTable.dta", unmatched(master) ukeep(finvar isin_code) update

		* The firm table uses the old IRSA ADR ticker
		replace ADRticker = "APSA US Equity" if ADRticker == "IRCP US Equity"
		mmerge ADRticker using "$apath/FirmTable.dta", unmatched(master) ukeep(finvar isin_code) update
		
		* Drop anything that isn't in the FirmTable.
		drop if isin_code == ""
		drop isin_code
		
		local minstocks 4
		
		if "`indtype'" == "ValueBank" {
			drop if finvar != 1
			local minstocks 2
		}
		if "`indtype'" == "ValueNonFin" {
			drop if finvar != 0
		}
		
		keep date px_open px_last Ticker total_return market
	
		rename px_last px_close
		
		*MERGE IN BILLS
		append using "$apath/Tbill_daily.dta"
		gen dow=dow(date)
		drop if dow==0 | dow==6
		drop weight
		
		drop if date < mdy(1,1,1995)
		drop if date>mdy(4,1,2015)
		
		gen quarter=qofd(date)
		format quarter %tq
		
		gen prev_quarter = quarter - 1
		
		*JUST HERE TO FIX WEIGHT
		encode Ticker, gen(tid)
		
		foreach x in px_close px_open total_return {
			bysort date: egen count_`x'=count(`x')
		}	
		foreach x in px_close px_open total_return {
			replace px_close=. if count_`x'<(`minstocks'+1)
			replace px_open=. if count_`x'<(`minstocks'+1)
			replace total_return=. if count_`x'<(`minstocks'+1)
		}
		
		sort prev_quarter Ticker market date
		
		tempfile temp
		save "`temp'", replace
		
		drop if px_close == .
		sort quarter Ticker date
		by quarter Ticker: egen end_day = max(date)
		drop if end_day != date
		
		keep Ticker market px_close total_return quarter 
		rename quarter prev_quarter
		rename px_close qe_price
		rename total_return qe_total_return
		
		mmerge prev_quarter Ticker market using "`temp'", unmatched(using)
		
		order date Ticker market
		sort date Ticker market
		
		
		
		mmerge quarter Ticker using "$apath/`weightfile'.dta", ukeep(weight_exypf EPS DivPerShare ADRratio leverage) unmatched(master)
		rename weight_exypf weight
		keep if _merge==3 | Ticker == "Tbill"
		
		replace DivPerShare = tbill / 400 if Ticker == "Tbill"
		replace EPS = tbill / 400 if Ticker == "Tbill"
		replace ADRratio = 1 if Ticker == "Tbill"
		replace leverage = 1 if Ticker == "Tbill"
		
		* Compute the returns for various event windows
		gen bdate = bofd("basic",date)
		format bdate %tbbasic
		tsset tid bdate
		sort tid bdate
		
		drop if bdate==.
		
		sort tid bdate
		
		replace weight = 0 if px_close == . | qe_price == .
		replace weight = 0 if Ticker=="Tbill"
		bysort date: egen total_weight=sum(weight)
		replace weight=. if total_weight == 0
		replace weight=0.9*weight/total_weight  if Ticker~="Tbill" & total_weight > 0
		replace weight=0.1 if Ticker=="Tbill" & total_weight > 0
		//drop total_weight
		
		* this covers days with no tbill returns
		bysort date: egen total_weight2=sum(weight)
		replace weight=. if total_weight2 < 0.999
		
		gen shares_px_open = weight / qe_price
		gen shares_px_close = shares_px_open
		gen shares_total_return = weight / qe_total_return
		
		gen shares_EPS = weight / qe_price * ADRratio
		gen shares_DivPerShare = weight / qe_price * ADRratio
		
		sort date tid
	
		foreach rtype  in px_close px_open total_return EPS DivPerShare {
			by date: egen `rtype'mxar = sum(shares_`rtype'*`rtype')
			by date: egen `rtype'mxar_cnt = sum(weight*(`rtype'!=.))
			replace `rtype'mxar = . if `rtype'mxar_cnt < 0.999
			drop `rtype'mxar_cnt
		}
		
		/*gen tot_ret = total_return / qe_total_return
		gen px_ret = px_close / qe_price
		
		gen divyield = tot_ret - px_ret
		
		return*/
		//px_closemxar px_openmxar total_returnmxar 
		collapse (firstnm) *mxar quarter prev_quarter, by(date)
		
		sort prev_quarter date
		
		
		save "`temp'", replace
		
		drop prev_quarter
		
		drop if px_closemxar == .
		sort quarter date
		by quarter: egen end_day = max(date)
		drop if end_day != date
		
		** at this point, these things are actually more like price and total returns
		** than levels. So we turn them into price levels.
		
		drop px_openmxar
		replace px_closemxar = log(px_closemxar)
		replace total_returnmxar = log(total_returnmxar)
		
		gen px_close = sum(px_closemxar)
		gen total_return = sum(total_returnmxar)
		
		drop px_closemxar total_returnmxar
		gen px_close_qe = exp(px_close)
		gen total_return_qe = exp(total_return)
		
		
		tsset quarter
		capture graph drop `indtype'_`mark'
		tsline px_close_qe, name(`indtype'_`mark')
		
		rename quarter prev_quarter
		keep px_close_qe prev_quarter total_return_qe
		
		mmerge prev_quarter using "`temp'"
		
		sort date
		
		replace px_closemxar = px_closemxar * px_close_qe
		replace px_openmxar = px_openmxar * px_close_qe
		replace total_returnmxar = total_returnmxar * total_return_qe
		
		keep date quarter *mxar
		
		reshape long px_close px_open total_return EPS DivPerShare, i(date) j(Ticker) string
		gen market = "`mark'"
		replace Ticker = "`indtype'IndexNew"
		gen industry_sector = "`indtype'IndexNew"
		
		sort quarter date
		
		save "$apath/`filename'.dta", replace
	
	}
	
}






