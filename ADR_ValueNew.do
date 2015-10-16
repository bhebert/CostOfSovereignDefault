**********************
*GENERATE ADR Weights*
**********************
set more off

/*use "$apath/Datastream_Quarterly.dta", clear

mmerge Ticker using "$apath/FirmTable.dta"
keep if _merge==3
split ADRticker, p(" ")
drop ADRticker2 ADRticker3
drop Ticker
rename ADRticker1 Ticker
keep Ticker quarter MV EPS ADRratio WC05101 leverage WC03255 WC03501 WC02999
rename WC05101 DivPerShare
rename WC03255 TotalDebt
rename WC03501 BookCommon
rename WC02999 TotalAssets

drop if Ticker==""

sort  Ticker quarter
encode Ticker, gen(tid)
tsset tid quarter

gen MVye = MV

gen year = year(dofq(quarter))

* The total assets stuff is the same each quarter
replace MVye = . if year == F.year

gen negqtr = -quarter

bysort tid year (negqtr): carryforward MVye, replace

sort tid quarter

gen MV2 = (L3.TotalAssets - L3.BookCommon + L3.MVye * 1000) / 1000

replace leverage = MV2 / L3.MVye*/

use "$apath/ADR_CRSP.dta", clear

gen MV = marketeq
gen MV2 = marketeq * crsp_lev
gen leverage = crsp_lev
gen EPS = epsfxq

gen DivPerShare = dvpsxq
gen DPS2 = dvpsxq + repurchases
replace DPS2 = DivPerShare if repurchases == .
gen ADRratio = adrrq


keep quarter Ticker MV MV2 leverage EPS DivPerShare DPS2 ADRratio

encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
replace EPS = F.EPS
replace DivPerShare = F.DivPerShare
replace DPS2 = F.DPS2
gen EPSgrowth = log(F.EPS / EPS)
drop tid

bysort quarter: egen total_market=sum(MV)
bysort quarter: egen total_market2=sum(MV2)
gen weight=MV/total_market
gen weight2=MV2/total_market2
replace weight=0 if weight==.
replace weight2=0 if weight2==.
drop total_market total_market2 //tid

bysort quarter: egen total_market=sum(MV) if Ticker~="YPF"
bysort quarter: egen total_market2=sum(MV2) if Ticker~="YPF"
gen weight_exypf=MV/total_market if Ticker~="YPF"
gen weight_exypf2=MV2/total_market2 if Ticker~="YPF"
replace weight_exypf=0 if weight_exypf==.
replace weight_exypf2=0 if weight_exypf2==.
drop total_market total_market2
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
keep Ticker quarter MV EPS ADRratio WC05101 leverage WC02999
rename WC05101 DivPerShare
rename WC02999 TotalAssets
drop if Ticker==""
replace ADRratio = 1

sort  Ticker quarter
encode Ticker, gen(tid)
tsset tid quarter
gen MV2 = L3.TotalAssets / 1000

replace leverage = MV2 / MV

bysort quarter: egen total_market=sum(MV)
bysort quarter: egen total_market2=sum(MV2)
gen weight=MV/total_market
gen weight2=MV2/total_market2
replace weight=0 if weight==.
replace weight2=0 if weight2==.
drop total_market tid total_market2

bysort quarter: egen total_market=sum(MV) if Ticker~="YPFD"
bysort quarter: egen total_market2=sum(MV2) if Ticker~="YPFD"
gen weight_exypf=MV/total_market if Ticker~="YPFD"
gen weight_exypf2=MV2/total_market2 if Ticker~="YPFD"
replace weight_exypf=0 if weight_exypf==.
replace weight_exypf2=0 if weight_exypf2==.
drop total_market total_market2
replace quarter=quarter+1


/*bysort quarter: egen total_market=sum(MV)
gen weight=MV/total_market
replace weight=0 if weight==.
bysort quarter: egen test=sum(weight)
drop test total_market

bysort quarter: egen total_market=sum(MV) if Ticker~="YPFD"
gen weight_exypf=MV/total_market if Ticker~="YPFD"
replace weight_exypf=0 if weight_exypf==.
bysort quarter: egen test=sum(weight_exypf)
drop test total_market
replace quarter=quarter+1*/

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
foreach mark in AR US {

	local tweight = 0.1
	local types Value Delev Acct
	local avars EPS EPSgrowth DivPerShare DPS2 ADRratio leverage
	local avars2 EPS EPSgrowth DivPerShare DPS2
	
	if "`mark'" == "AR" {
		local tweight = 0
		local types Value
		local avars
		local avars2
	}

	foreach indtype in Value ValueNonFin ValueBank  {

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
		
	/*	encode Ticker, gen(tid)
		sort tid quarter
		tsset tid quarter
		gen divtest = total_return / L.total_return * L.px_close - px_close*/
		
		rename quarter prev_quarter
		rename px_close qe_price
		rename total_return qe_total_return
		
		mmerge prev_quarter Ticker market using "`temp'", unmatched(using)
		
		order date Ticker market
		sort date Ticker market
		
		
		
		mmerge quarter Ticker using "$apath/`weightfile'.dta", ukeep(weight_exypf weight_exypf2 `avars') unmatched(master)
		rename weight_exypf* weight*
		keep if _merge==3 | Ticker == "Tbill"
		
		if "`mark'" == "US" {
			replace DivPerShare = tbill / 400 if Ticker == "Tbill"
			replace DPS2 = tbill / 400 if Ticker == "Tbill"
			replace EPS = tbill / 400 if Ticker == "Tbill"
			replace EPSgrowth = 0 if Ticker == "Tbill"
			replace ADRratio = 1 if Ticker == "Tbill"
			replace leverage = 1 if Ticker == "Tbill"
		}
		
		* Compute the returns for various event windows
		gen bdate = bofd("basic",date)
		format bdate %tbbasic
		tsset tid bdate
		sort tid bdate
		
		drop if bdate==.
		
		sort tid bdate
		
		gen weight_acct = weight
		
		replace weight = 0 if px_close == . | qe_price == .
		replace weight = 0 if Ticker=="Tbill"
		bysort date: egen total_weight=sum(weight)
		replace weight=. if total_weight == 0
		replace weight=(1-`tweight')*weight/total_weight  if Ticker~="Tbill" & total_weight > 0
		replace weight=`tweight' if Ticker=="Tbill" & total_weight > 0
		* this covers days with no tbill returns
		bysort date: egen total_weight_test=sum(weight)
		replace weight=. if total_weight_test < 0.999
		drop total_weight_test
		
		
		if "`mark'" == "US" {
			replace weight2 = 0 if px_close == . | qe_price == .
			replace weight2 = 0 if Ticker=="Tbill"
			bysort date: egen total_weight2=sum(weight2)
		
			replace weight2=. if total_weight2 == 0
			replace weight2=0.9*weight2/total_weight2  if Ticker~="Tbill" & total_weight2 > 0
			replace weight2=0.1 if Ticker=="Tbill" & total_weight2 > 0

		
			gen tweight = weight2 * (leverage - 1) / leverage
			replace tweight = weight2 if Ticker=="Tbill" 
			replace weight2 = weight2 / leverage
			bysort date: egen total_tweight = sum(tweight)
			replace weight2 = total_tweight if Ticker=="Tbill" 
		
			bysort date: egen total_weight_test=sum(weight2)
		
			replace weight2=. if total_weight_test < 0.999
			drop total_weight_test
		
			replace weight_acct = 0 if px_close == . | qe_price == . | EPSgrowth == .
			replace weight_acct = 0 if Ticker=="Tbill"
			bysort date: egen total_weight_acct=sum(weight_acct)
			replace weight_acct=. if total_weight_acct == 0
			replace weight_acct=weight_acct/total_weight_acct  if Ticker~="Tbill" & total_weight_acct > 0
			* this covers days with no tbill returns
			bysort date: egen total_weight_test=sum(weight_acct)
			replace weight_acct=. if total_weight_test < 0.999
			drop total_weight_test
			
			rename weight2 weightDelev
			rename weight_acct weightAcct
		
		}
		rename weight weightValue

		
		foreach ind in `types' {
		
			gen shares_px_open`ind' = weight`ind' / qe_price
			gen shares_px_close`ind' = shares_px_open`ind'
			gen shares_total_return`ind' = weight`ind' / qe_total_return
		
			if "`mark'" == "US" {
				gen shares_EPS`ind' = weight`ind' / qe_price * ADRratio
				gen shares_EPSgrowth`ind' = weight`ind' / qe_price * ADRratio
				gen shares_DivPerShare`ind' = weight`ind' / qe_price * ADRratio
				gen shares_DPS2`ind' = weight`ind' / qe_price * ADRratio
			}
		}
	
		local startypes
		foreach ind in `types' {
			local startypes `startypes' *`ind'
			foreach rtype  in px_close px_open total_return `avars2' {
				by date: egen `rtype'`ind' = sum(shares_`rtype'`ind'*`rtype')
				by date: egen `rtype'`ind'_cnt = sum(weight`ind'*(`rtype'!=.))
				replace `rtype'`ind' = . if `rtype'`ind'_cnt < 0.999
				drop `rtype'`ind'_cnt
			}
		}

		collapse (firstnm) `startypes' quarter prev_quarter, by(date)
		
		reshape long px_close px_open total_return `avars2', i(date) j(Ticker) string
		
		sort Ticker prev_quarter date
		
		save "`temp'", replace
		
		drop prev_quarter
		
		drop if px_close == .
		sort Ticker quarter date
		by Ticker quarter: egen end_day = max(date)
		drop if end_day != date
		
		** at this point, these things are actually more like price and total returns
		** than levels. So we turn them into price levels.
		
		drop px_open
		replace px_close = log(px_close)
		replace total_return = log(total_return)
		
		by Ticker: gen px_close_sum = sum(px_close)
		by Ticker: gen total_return_sum = sum(total_return)
		
		
		
		replace px_close_sum = . if px_close == .
		replace total_return_sum = . if total_return == .
		
		drop px_close total_return
		gen px_close_qe = exp(px_close_sum)
		gen total_return_qe = exp(total_return_sum)
		
		encode Ticker, gen(tid)
		tsset tid quarter
		
		capture graph drop `indtype'_`mark'
		tsline px_close_qe if Ticker == "Value", name(`indtype'_`mark')
		
		if "`mark'" == "US" {
			capture graph drop `indtype'_`mark'Acct
			tsline px_close_qe if Ticker == "Acct", name(`indtype'_`mark'Acct)
		
			capture graph drop `indtype'_`mark'Delev
			tsline px_close_qe if Ticker == "Delev", name(`indtype'_`mark'Delev)
		}
		
		rename quarter prev_quarter
		keep px_close_qe prev_quarter total_return_qe Ticker
		
		mmerge Ticker prev_quarter using "`temp'"
		
		sort Ticker date
		
		replace px_close = px_close * px_close_qe
		replace px_open = px_open * px_close_qe
		replace total_return = total_return * total_return_qe
		
		keep date quarter Ticker px_close px_open total_return `avars2'
		
		//reshape long px_close px_open total_return EPS DivPerShare, i(date) j(Ticker) string
		gen market = "`mark'"
		replace Ticker = "`indtype'IndexNew" if Ticker == "Value"
		gen industry_sector = "`indtype'IndexNew"
		
		replace industry_sector = "`indtype'IndexDelev" if regexm(Ticker,"Delev")
		replace industry_sector = "`indtype'IndexAcct" if regexm(Ticker,"Acct")
		replace Ticker = "`indtype'AcctNew" if Ticker == "Acct"
		replace Ticker = "`indtype'IndexDelev" if Ticker == "Delev"
		
		sort quarter date
		
		save "$apath/`filename'.dta", replace
	
	}
	
}






