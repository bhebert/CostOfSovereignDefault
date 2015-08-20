
set more off

use "$apath/blue_rate.dta", clear
browse
gen month=mofd(date)
format month %tm
collapse (lastnm) px_close, by(month Ticker)
reshape wide px_close, i(month) j(Ticker) string
renpfix px_close
keep month ADRBlue
tempfile temp

mmerge month using "$miscdata/Inflation/us_inflation_month.dta", ukeep(us_cpi)
mmerge month using "$miscdata/Inflation/inflation_month.dta", ukeep(cpi)
mmerge month using "$apath/IP_data.dta", ukeep(ip_index)
save "$apath/rer_ip_dataset.dta", replace


use "$apath/Tbill_daily.dta", clear
gen month=mofd(date)
format month %tm
gen quarter=qofd(date)
format quarter %tq
collapse (lastnm) total_return weight, by(Ticker month)
tempfile temp
save "`temp'", replace

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
mmerge quarter Ticker using "$apath/ADR_weighting.dta", ukeep(weight_exypf)
rename weight_exypf weight
keep if _merge==3

sort date Ticker
gen month=mofd(date)
format month %tm
collapse (lastnm) total_return px_last weight quarter, by(month Ticker)


********************************************************
*THIS HAS THE PROBLEM OF RECONSTRUCTING THE VALUE INDEX*
********************************************************
encode Ticker, gen(tid)
sort tid month
tsset tid month
gen ret = total_return / L.total_return - 1
sort Ticker month 
local rtypes ret px_ret 
replace weight=0 if ret==.
bysort month: egen total_w=sum(weight)
replace weight=0.9*weight/total_w 
drop total_w
drop ret tid

append using  "`temp'"
replace px_last=1 if Ticker=="Tbill"
keep if quarter>=tq(1995q2)
keep if quarter<=tq(2014q4)


encode Ticker, gen(tid)
sort tid month
tsset tid month
gen ret = total_return / L.total_return - 1
gen div = (1+ret) * L.px_last - px_last
gen px_ret = px_last / L.px_last - 1

sort  month tid  
foreach rtype  in ret px_ret {
	by month: egen `rtype'mxar = sum(weight*`rtype')
	by month: egen `rtype'mxar_cnt = sum(weight*(`rtype'!=.))
	replace `rtype'mxar = . if `rtype'mxar_cnt == 0
	replace `rtype'mxar = `rtype'mxar / `rtype'mxar_cnt 
	drop `rtype'mxar_cnt 
	}

gen divmxar=.

gen px_lastmxar = 5000


drop weight total_return tid
reshape wide ret px_ret  px_last div, i(month quarter) j(Ticker) string
reshape long ret px_ret  px_last div, i(month quarter) j(Ticker) string
replace Ticker="ValueIndex" if Ticker=="mxar"

gen log_px_ret = log(1+px_ret)
bysort Ticker (quarter): gen cum_px_ret = sum(log_px_ret)

replace px_last = px_last * exp(cum_px_ret) if Ticker == "ValueIndex"

encode Ticker, gen(tid)
sort tid month
tsset tid month
replace div = (1+ret) * L.px_last - px_last if Ticker == "ValueIndex"
drop log_px_ret cum_px_ret

drop if Ticker != "ValueIndex"
levelsof Ticker, local(inds_adr) clean

*******************************************************
*NOW NEED TO MAKE MONTHLY VARS AND INDUSTRIAL PRODUCTION FOR THIS. 
*ADDIGN SOME ADDITIONAL VARIABLES
mmerge month using "$apath/rer_ip_dataset.dta", unmatched(master) 
gen log_rer = log((ADRBlue / cpi) * us_cpi)
gen log_rel_cpi = log(cpi / us_cpi)
gen year = yofd(dofm(month))
sort month
tsset month
save "$apath/dataset_temp_ip.dta", replace

