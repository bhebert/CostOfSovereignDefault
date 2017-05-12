*Stale and events
tempfile cds
use "$apath/CDS_Data.dta", clear
keep if event_twoday==1 | eventday==1
keep date eventday
save "`cds'", replace

use "$apath/BB_Local_ADR_Indices_April2014.dta", clear
append using "$apath/TGNO4.dta"
keep if market=="AR"
keep if date>=td(01jan2011) & date<=td(30jul2014)
encode Ticker, gen(firm_id)
sort Ticker date

bysort Ticker: gen n=_n
tsset firm_id n
gen stale=.
replace stale=0 if total_return~=l.total_return & total_return~=. & l.total_return~=.
replace stale=1 if total_return==l.total_return & total_return~=. & l.total_return~=.
bysort firm_id: egen stale_freq=mean(stale)
drop n firm_id 
bysort Ticker: egen start_temp=min(date) if total_return~=.
bysort Ticker: egen start=max(start_temp)
drop start_temp
bysort Ticker: egen end_temp=max(date) if total_return~=.
bysort Ticker: egen end=max(end_temp)
drop end_temp
format start %td
format end %td
bysort Ticker: egen obs=count(total_return)
mmerge date using "`cds'"
bysort Ticker: egen events=count(total_return) if event==1

*Merge in events
collapse (firstnm) obs events stale_freq bb_ticker ticker_full, by(Ticker)
egen maxobs=max(obs)
gen stale_freq_eff=stale_freq+(maxobs-obs)/maxobs
replace stale_freq_eff=1 if obs<100
replace stale_freq_eff=1 if stale_freq_eff>1
keep bb_ticker events stale_freq_eff
rename stale_freq_eff stale_freq
sort bb_ticker
drop if bb_tick==""
save "$apath/stale.dta", replace

