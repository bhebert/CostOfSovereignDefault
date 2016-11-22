set more off

*ADR Volume
tempfile ticks
use "$apath/FirmTable.dta", clear
keep Ticker ADRtick  bb_ticker
keep if ADRt~=""
replace ADRti=subinstr(ADRti," US Equity","",.)
replace bb_=subinstr(bb_," AR Equity","",.)
rename Ticker undertick
rename ADRt adrticker 
save "`ticks'", replace

*CRSP
use "$mainpath/CRSP/ADR_Update_April2016.dta", clear
keep if date>=td(01jan2011) & date<=td(01aug2014)
replace ticker="APSA" if ticker=="IRCP"
mmerge ticker using "`ticks'", umatch(adrticker)
keep if _merge==3
order date ticker vol prc
keep date ticker under bb vol prc

mmerge bb date using "$mainpath/Local Data/Bolsar/Bolsar_merged.dta", umatch(ticker date) ukeep(volume volume_value) uname(bolsar_)
keep if _merge==3
gen adr_turnover=vol*prc
*merge in ADR Blue rate
mmerge date using "$apath/blue_rate.dta", ukeep(px_close)
rename px_close adrblue
keep if _merge==3
gen bolsar_usd=bolsar_volume_value/adrblue

replace bolsar_usd=bolsar_usd/(10^6)
replace adr_turnover=adr_turnover/(10^6)
save "$apath/ADR_Bolsar_Volume.dta", replace


*TABLE 
use "$apath/ADR_Bolsar_Volume.dta", clear
drop if adr_turnover<0 | bolsar_usd<0
gen month=mofd(date)
format month %tm

collapse (sum) adr_turnover bolsar_usd, by(month ticker)
collapse (mean) adr_turnover bolsar_usd, by(ticker)
gen ratio=adr/bolsar
label var ticker "Ticker"
label var adr_turnover "Turnover - ADR, USD M."
label var bolsar_usd "Turnover - Local, USD M."
label var ratio "ADR/Local Turnover"
replace ticker="IRCP" if ticker=="APSA"
sort ticker
export excel using "$rpath/Turnover_ADRBolsar.xls", firstrow(varlabels) replace
