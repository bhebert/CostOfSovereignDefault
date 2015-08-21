*NOT INTEGRATED INTO THIRD ANALYSIS YET

use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/CRSP/CRSP_Additional_ADR.dta", clear
drop if ticker=="BRO"
order ticker date ret prc openprc
keep ticker date ret prc openprc
encode ticker, gen(tid)
gen bdate = bofd("basic",date)
format bdate %tbbasic
tsset tid bdate
sort tid bdate
bysort ticker: egen mindate=min(date)
sort tid bdate
bysort ticker: gen n=_n
gen total_return=1 if date==mindate
tsset tid n
sort tid n
replace total_return=l.total_return*(1+ret) if mindate~=date
keep date ticker prc openprc total_return 
keep if yofd(date)>=2011
gen market="US"
rename ticker Ticker
rename openprc px_open 
rename prc px_close
save "$apath/Additional_CRSP.dta", replace
use "$mainpath/Bloomberg/Datasets/EqNewBlueRate.dta", clear
keep Ticker date px_last px_open total market
rename px_last px_close
drop if market=="US"
keep if Ticker=="APBR" | Ticker=="TS"
append using "$apath/Additional_CRSP.dta"
gen name="Petrobras" if Ticker=="APBR" | Ticker=="PBR"
replace name="Arcos Dorados" if Ticker=="ARCO"
replace name="Tenaris" if Ticker=="TS"
save "$apath/Additonal_Securities.dta", replace

/*
*CHECK IT IS FINE TO USE CRSP
use "$apath/Additional_CRSP.dta", clear
replace Ticker=Ticker+"_CRSP"
append using  "$mainpath/Bloomberg/Datasets/EqNewBlueRate.dta"
drop if market=="AR"

gen tr_temp=total_return if date==td(13apr2012)
bysort Ticker: egen tr2=max(tr_temp)
replace total_return=total_return/tr2
twoway (line total_return date if Ticker=="TS", sort) (line  total_return date if Ticker=="TS_CRSP", yaxis(2) sort) if yofd(date)>=2011
twoway (line total_return date if Ticker=="PBR", sort) (line  total_return date if Ticker=="PBR_CRSP", yaxis(2) sort) if yofd(date)>=2011
*/
