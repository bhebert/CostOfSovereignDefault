set more off

use "$apath/daily_factors.dta", clear

rename Close total_return

append using "$apath/ValueIndex_US_New.dta"

append using "$apath/blue_rate.dta"

keep Ticker total_return date

gen bdate = bofd("basic",date)

drop if bdate == .

encode Ticker, gen(tid)

tsset tid bdate

gen ret_ = 100*log(total_return / L.total_return)

keep ret_ bdate Ticker date

reshape wide ret_, i(bdate) j(Ticker) string

local frets
foreach factor in $lf_factors {
	local frets `frets' ret_`factor'
}

tsset bdate

ivreg2 ret_ValueIndexNew `frets' if year(date) > 2003, robust bw(5)

matrix ValueIndexNew_b = e(b)

ivreg2 ret_ADRBlue `frets' if year(date) > 2003, robust bw(5)

matrix ADRBlue_b = e(b)
