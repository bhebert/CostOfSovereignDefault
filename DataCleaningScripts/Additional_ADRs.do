*TERNIUM
use "$crsp_path/Ternium.dta", clear
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
save "$apath/Ternium_CRSP.dta", replace

use "$crsp_path/CRSP_Additional_ADR.dta", clear
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
tempfile temp
save "`temp'.dta", replace
drop name
append using "$apath/Ternium_CRSP.dta"
replace Ticker=Ticker+"_"+market
drop if market=="AR"
replace market="Index"
gen industry_sector=Ticker
save "$apath/Additonal_Securities.dta", replace




