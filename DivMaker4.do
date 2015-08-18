
set more off


*use "`bbpath'/Total_Returns.dta", clear
use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear
drop if date == .
drop if Ticker == ""
drop if market != "US"
keep date px_open px_last Ticker total_return market

//rename Ticker ticker
//replace ticker = ticker + " US Equity" if market == "US"

drop if date < mdy(1,1,1995)
drop if date>mdy(4,1,2015)
gen quarter=qofd(date)
format quarter %tq
mmerge quarter Ticker using "$dpath/ADR_weighting.dta", ukeep(weight_exypf)
rename weight_exypf weight
keep if _merge==3

sort date Ticker
collapse (lastnm) total_return px_last weight, by(quarter Ticker)

encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
gen ret = total_return / L.total_return - 1
sort quarter Ticker
local rtypes ret px_ret 
replace weight=0 if ret==.
bysort quarter: egen total_w=sum(weight)
replace weight=0.9*weight/total_w 
drop total_w
drop ret tid

append using "$gdppath/Tbill.dta"
keep if quarter>=tq(1995q2)
keep if quarter<=tq(2014q4)


encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
gen ret = total_return / L.total_return - 1
gen div = (1+ret) * L.px_last - px_last
gen px_ret = px_last / L.px_last - 1

sort quarter tid
foreach rtype  in ret px_ret {
	by quarter: egen `rtype'mxar = sum(weight*`rtype')
	by quarter: egen `rtype'mxar_cnt = sum(weight*(`rtype'!=.))
	replace `rtype'mxar = . if `rtype'mxar_cnt == 0
	replace `rtype'mxar = `rtype'mxar / `rtype'mxar_cnt 
	drop `rtype'mxar_cnt 
	}

gen divmxar=.

gen px_lastmxar = 5000


drop weight total_return tid
reshape wide ret px_ret  px_last div, i(quarter) j(Ticker) string
reshape long ret px_ret  px_last div, i(quarter) j(Ticker) string
replace Ticker="ValueIndex" if Ticker=="mxar"

gen log_px_ret = log(1+px_ret)
bysort Ticker (quarter): gen cum_px_ret = sum(log_px_ret)

replace px_last = px_last * exp(cum_px_ret) if Ticker == "ValueIndex"

encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
replace div = (1+ret) * L.px_last - px_last if Ticker == "ValueIndex"
drop log_px_ret cum_px_ret

drop if Ticker != "ValueIndex"
levelsof Ticker, local(inds_adr) clean


*ADDIGN SOME ADDITIONAL VARIABLES
mmerge quarter using "$apath/rer_gdp_dataset.dta", unmatched(master) ukeep(Real_GDP* Nominal_GDP_GFD ADRBlue cpi us_cpi)
gen log_rer = log((ADRBlue / cpi) * us_cpi)
gen log_rel_cpi = log(cpi / us_cpi)
gen Nominal_GDPusd = Nominal_GDP_GFD / ADRBlue
gen year = yofd(dofq(quarter))
sort quarter
tsset quarter


save "$apath/dataset_temp.dta", replace

