*CONSTRUCT ADR BLUE RATE USING DATA DIRECTLY FROM EXCHANGES
*BCBA BOLSAR FOR LOCAL
*CRSP FOR ADRS

*Clean data
set more off
use "$crsp_path/Argentina_ADRdta.dta", clear
drop if ticker=="PZL" | ticker=="POEA" | ticker=="POBR" | ticker=="PC" | ticker=="BRO"
bysort ticker: tab comnam
drop if comnam=="PENNZENERGY CO" | comnam=="POE & BROWN INC" | comnam=="PAMIDA HOLDINGS CORP" | comnam=="PACIFIC C M A INC"
order date ticker open prc 
keep date ticker open prc
rename open px_open1
rename prc px_close1
rename ticker ADR_Ticker
gen Under_Ticker=""
replace Under_Ticker="GGAL" if ADR_Ticker=="GGAL" 
replace Under_Ticker="TS" if ADR_Ticker=="TS" 
replace Under_Ticker="FRAN"  if  ADR_Ticker=="BFR"
replace Under_Ticker="BMA" if ADR_Ticker=="BMA"
replace Under_Ticker="PAMP" if ADR_Ticker=="PAM"
replace Under_Ticker="PESA" if ADR_Ticker=="PZE"
replace Under_Ticker="APBR" if ADR_Ticker=="PBR"
replace Under_Ticker="TECO2" if ADR_Ticker=="TEO"
replace Under_Ticker="YPFD" if ADR_Ticker=="YPF"
gen ratio=2
replace ratio=10 if ADR_T=="BMA" | ADR_T=="GGAL" | ADR_T=="PZE"
replace ratio=3 if ADR_T=="BFR" 
replace ratio=5 if ADR_T=="TEO"
replace ratio=25 if ADR_T=="PAM"
replace ratio=1 if ADR_T=="YPF"

save "$apath/CRSP_ADR.dta", replace


use "$local_path/Bolsar/Bolsar_merged.dta", clear
rename ticker Ticker
 keep if Ticker=="GGAL" | Ticker=="TS" | Ticker=="FRAN" | Ticker=="BMA" | Ticker=="PAMP" | Ticker=="PESA" | Ticker=="APBR" | Ticker=="TECO2" | Ticker=="YPFD"
rename Ticker Under_Ticker
gen ADR_Ticker=""
replace ADR_Ticker="GGAL" if Under_Ticker=="GGAL"
replace ADR_Ticker="TS" if Under_Ticker=="TS"
replace ADR_Ticker="BFR" if Under_Ticker=="FRAN"
replace ADR_Ticker="BMA" if Under_Ticker=="BMA"
replace ADR_Ticker="PAM" if Under_Ticker=="PAMP"
replace ADR_Ticker="PZE" if Under_Ticker=="PESA"
replace ADR_Ticker="PBR" if Under_Ticker=="APBR"
replace ADR_Ticker="TEO" if Under_Ticker=="TECO2"
replace ADR_Ticker="YPF" if Under_Ticker=="YPFD"

keep date Under ADR Last Open
rename Open px_open0 
rename Last px_close0
mmerge date ADR_Ticker using "$apath/CRSP_ADR.dta"

replace px_open1=px_open1/ratio
replace px_close1=px_close1/ratio

gen blue_open=px_open0/px_open1
gen blue_close=px_close0/px_close1

*bysort date: egen blue_open_ds=mean(blue_open) if ADR~="YPF"
*bysort date: egen blue_close_ds=mean(blue_close) if ADR~="YPF"
save "$apath/CRSP_Bolsar_merge.dta", replace

use "$apath/CRSP_Bolsar_merge.dta", clear
keep if _merge==3
drop if ADR=="YPF" 
order date Under blue*
gen exclude=0
bysort date: egen min_blue_close=min(blue_close)
bysort date: egen max_blue_close=max(blue_close)
bysort date: replace exclude=1 if blue_close==min_blue_close | blue_close==max_blue_close
drop if exclude==1
collapse (mean) blue_open blue_close, by(date)
rename blue_open px_open
rename blue_close px_close
gen total_return=px_close
gen Ticker="ADRBaltdata"
save "$apath/adrdb_altdata.dta", replace


*bysort date: egen adrdb_temp =mean(blue_close)
*gen blue_close_norm=blue_close/adrdb_temp
*bysort date: egen sd_blue_close= sd(blue_close_norm)
*summ sd_blue_close , detail
*replace blue_close=. if sd_blue_close>r(p99)  & sd_blue_close~=.


*twoway (line blue_close_ds date) if Under=="TECO2" & yofd(date)>=2011
*twoway (line blue_close_ds date) if Under=="TECO2" & date>=td(01jun2014) & date<=td(30jun2014)
