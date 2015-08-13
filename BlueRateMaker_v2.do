*Note, this still generates output to dropbox, need to correct.
set more off
import excel "$mainpath/Bloomberg/Additional_Data_081215.xlsx", sheet("Data All") clear
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
	
	local ii=`i'-3
save "$mainpath/Bloomberg/intermediate/Data_081215.dta", replace
	
	forvalues i=1(4)`ii' {
use "$mainpath/Bloomberg/intermediate/Data_081215.dta", clear
local y=`i'+1
local z=`i'+2
local w=`i'+3
keep v`i' v`y' v`z' v`w'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Equity","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' px_open
rename v`z' px_last
rename v`w' total_return
drop if _n==1 | _n==2
local x=`w'/4
save "$mainpath/Bloomberg/intermediate/eqnew_`x'.dta", replace
}

use "$mainpath/Bloomberg/intermediate/eqnew_1.dta", clear
forvalues i=2/16 {
append using "$mainpath/Bloomberg/intermediate/eqnew_`i'.dta"
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
save "$mainpath/Bloomberg/Datasets/EqNewBlueRate.dta", replace

tempfile eqtemp ADR_temp
use "$mainpath/Bloomberg/Datasets/EqNewBlueRate.dta", clear
gen ADR=.
replace ADR=1 if market=="US"
replace ADR=0 if market=="AR"
gen ADR_Ticker=Ticker if market=="US"
gen Under_Ticker=Ticker if market=="AR"

replace ADR_Ticker="GGAL" if Under_Ticker=="GGAL"
replace ADR_Ticker="TS" if Under_Ticker=="TS"
replace ADR_Ticker="BFR" if Under_Ticker=="FRAN"
replace ADR_Ticker="BMA" if Under_Ticker=="BMA"
replace ADR_Ticker="PAM" if Under_Ticker=="PAMP"
replace ADR_Ticker="PZE" if Under_Ticker=="PESA"
replace ADR_Ticker="PBR" if Under_Ticker=="APBR"
replace ADR_Ticker="TEO" if Under_Ticker=="TECO2"

replace Under_Ticker="GGAL" if ADR_Ticker=="GGAL" 
replace Under_Ticker="TS" if ADR_Ticker=="TS" 
replace Under_Ticker="FRAN"  if  ADR_Ticker=="BFR"
replace Under_Ticker="BMA" if ADR_Ticker=="BMA"
replace Under_Ticker="PAMP" if ADR_Ticker=="PAM"
replace Under_Ticker="PESA" if ADR_Ticker=="PZE"
replace Under_Ticker="APBR" if ADR_Ticker=="PBR"
replace Under_Ticker="TECO2" if ADR_Ticker=="TEO"

keep date px_open px_last  ADR_Ticker Under_Ticker ADR
reshape wide px_open px_last , i(date ADR_T Und) j(ADR) 
gen ratio=2
replace ratio=10 if ADR_T=="BMA" | ADR_T=="GGAL" | ADR_T=="PZE"
replace ratio=3 if ADR_T=="BFR" 
replace ratio=5 if ADR_T=="TEO"
replace ratio=25 if ADR_T=="PAM"

replace px_open1=px_open1/ratio
replace px_last1=px_last1/ratio

gen px_open=px_open0/px_open1
gen px_close=px_last0/px_last1
rename px_last1 px_close1
rename px_last0 px_close0
label var px_open0 "Open, Underlying"
label var px_open1 "Open, ADR (scaled)"
label var px_close0 "Close, Underlying"
label var px_close1 "Close, ADR(scaled)"
label var px_open "Open, Blue Rate"
label var px_close "Close, Blue Rate"
gen total_return=px_close
twoway (line px_close date if ADR_T=="BFR") (line px_close date if ADR_T=="BMA") (line px_close date if ADR_T=="GGAL") (line px_close date if ADR_T=="PAM") (line px_close date if ADR_T=="PBR") (line px_close date if ADR_T=="PZE") (line px_close date if ADR_T=="TEO") (line px_close date if ADR_T=="TS") , legend(order(1 "BFR" 2 "BMA" 3 "GGAL" 4 "PAM" 5 "PBR" 6 "PZE" 7 "TEO" 8 "TS"))
graph export "$rpath/ADR_Blue_db.png", replace
save "$apath/ADRBlue_All.dta", replace

use "$apath/ADRBlue_All.dta", clear
order date ADR_ Under_ px_open px_close total_return
collapse px_open px_close total_return, by(date)
gen Ticker="ADRBluedb"
append using "$apath/ADRBlue_All.dta"
replace Ticker=Under_T if Ticker==""
order date Ticker px_open px_close
save "$apath/ADRBluedb.dta", replace

use "$apath/ADRBluedb.dta", clear
append using "$apath/blue_rate.dta"
append using "$apath/dolarblue.dta"
twoway (line px_close date if Ticker=="ADRBlue") (line px_close date if Ticker=="ADRBluedb") (line px_close date if Ticker=="dolarblue", sort), legend(order( 1 "ADRBlue" 2 "ADRBluedb" 3 "dolarblue")) ytitle("Blue Rate")
graph export "$rpath/Blue_Rate_Comparison.png", replace
twoway (line px_close date if Ticker=="ADRBlue") (line px_close date if Ticker=="ADRBluedb") (line px_close date if Ticker=="dolarblue", sort) if date>=td(01jan2011) & date<=td(30jul2014), legend(order( 1 "ADRBlue" 2 "ADRBluedb" 3 "dolarblue")) ytitle("Blue Rate")
graph export "$rpath/Blue_Rate_Comparison_Sample.png", replace
twoway (line px_close date if Ticker=="ADRBlue") (line px_close date if Ticker=="ADRBluedb") (line px_close date if Ticker=="dolarblue", sort) if date>=td(01jun2014) & date<=td(30jun2014), legend(order( 1 "ADRBlue" 2 "ADRBluedb" 3 "dolarblue")) ytitle("Blue Rate")
graph export "$rpath/Blue_Rate_Comparison_June2014.png", replace

use "$apath/ADRBluedb.dta", clear
keep if Ticker=="ADRBluedb"
keep date Ticker px_open px_close total_return
save "$apath/ADRBluedb_merge.dta", replace


use "$apath/ADRBlue_All.dta", clear
gen exclude=0
bysort date: egen min_px_close=min(px_close)
bysort date: egen max_px_close=max(px_close)
bysort date: replace exclude=1 if px_close==min_px_close | px_close==max_px_close

*FOR A VARIANCE CUTOFF
*bysort date: egen adrdb_temp =mean(px_close)
*gen px_close_norm=px_close/adrdb_temp
*bysort date: egen sd_px_close= sd(px_close_norm)
*summ sd_px_close if yofd(date)>=2009, detail
*replace px_close=. if sd_px_close>r(p99)  & sd_px_close~=. & yofd(date)>=2009
*summ sd_px_close if yofd(date)<2009, detail
*replace px_close=. if sd_px_close>r(p99)  & sd_px_close~=. & yofd(date)<2009
drop if exclude==1
collapse px_open px_close total_return, by(date)
gen Ticker="adrdb_clean"
append using "$apath/ADRBlue_All.dta"
save "$apath/ADRBlue_All.dta", replace


/*
use "$apath/ThirdAnalysis.dta", clear
twoway (scatter return_ cds_ if industry_sec=="adrdb") (scatter return_ cds_ if industry_sec=="dolarblue") (scatter return_ cds_ if industry_sec=="ADRBlue") if day_type=="twoday" & event_day==1

keep if industry_sec=="ADRBlue" | industry_sec=="dolarblue"
collapse (mean) return_ cds_, by(date day_type event_day) 

twoway (scatter return_ cds_ if day_type=="twoday") if event_day==1 */

