set more off

use "$dpath/ARS_Blue.dta", clear
keep ARSUSDS TDARSSP date
drop if date >= td(30jul2014)
*drop if date < td(1jan2011)
rename ARSUSDS total_returnDSBlue
rename TDARSSP total_returnOfficialRate
reshape long total_return, i(date) j(Ticker) string
gen px_close = total_return
gen px_open=.
tempfile temp
save "`temp'", replace


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

gen ADRticker = ADR_Ticker + " US Equity"
mmerge ADRticker using "$apath/FirmTable.dta", ukeep(ADRratio) unmatched(master)

rename ADRratio ratio

drop ADRticker
replace ratio = 2 if ADR_T == "TS" | ADR_T == "PBR"
drop if ratio == .

sort ADR_T date



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
gen exclude=0
bysort date: egen min_px_close=min(px_close)
bysort date: egen max_px_close=max(px_close)
bysort date: egen count=count(px_close)
bysort date: replace exclude=1 if (px_close==min_px_close | px_close==max_px_close) & count>=3


drop if exclude==1
collapse (mean) px_open px_close total_return, by(date)
gen Ticker="ADRBlue"
append using "$apath/ADRBlue_All.dta"
save "$apath/ADRBlue_All.dta", replace

use "$apath/ADRBlue_All.dta", clear
keep date px_open px_close total_return Ticker
keep if Ticker=="ADRBlue"
append using "`temp'"
save "$apath/blue_rate.dta", replace


** code to generate quarterly data series
use "$apath/blue_rate.dta", clear
browse
gen quarter=qofd(date)
format quarter %tq
collapse (lastnm) px_close, by(quarter Ticker)
reshape wide px_close, i(quarter) j(Ticker) string
renpfix px_close

keep quarter ADRBlue OfficialRate
replace OfficialRate = 1 if quarter < yq(2001,4)
replace OfficialRate = ADRBlue if quarter >= yq(2001,4) & quarter <= yq(2007,3)

save "$apath/ADRBlue_quarter.dta", replace


*CALCULATE DISPERSION NUMBER FOR PAPER
use "$apath/ADRBlue_All.dta", clear
gen ADRBluetemp=px_close if Ticker=="ADRBlue"
bysort date: egen ADRBlue=max(ADRBluetemp)
keep date px_close ADR_Tick ADRBlue
keep if ADR_T~=""
keep if date>=td(01jan2011) & date<=td(30jul2014)
summ px_close
bysort date: egen mean=mean(px_close)
gen px_close2=px_close
collapse (max) px_close (min) px_close2 (firstnm) mean ADRBlue, by(date)
rename px_close max
rename px_close2 min
gen gap=max-min
gen share_mean=100*(gap/mean)
gen share_ADRBlue=100*(gap/ADRBlue)
summ share_ADRBlue
