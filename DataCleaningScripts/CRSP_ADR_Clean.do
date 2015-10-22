*Clean CRSP ADR Data
use "$miscdata/CRSP Security/ADR_CRSP_daily.dta", clear
drop if ticker=="PC"
encode ticker, gen (tid)
bysort tid date: gen n=_n
bysort tid date: egen maxn=max(n)
drop if n==2
drop if ret==.
drop n maxn
tsset tid date
sort tid date
bysort tid: gen n=_n
tsset tid n
gen index=1 if n==1
replace index=l.index*(1+ret) if n>1
keep date permno ticker index prc openprc
rename index total_return
rename prc px_last
rename open px_open
replace ticker="IRCP" if ticker=="APSA"
gen market="US"
rename ticker Ticker
drop permno
save "$apath/CRSP_ADRs.dta", replace
