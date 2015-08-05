

local localratios YPFD 1 TECO2 5 BMA 10 GGAL 10 FRAN 3 PESA 10
local localnames YPFD 31.76 TECO2 22.99 BMA 18.39 GGAL 14.59 FRAN 6.79 PESA 5.48
local anames YPF TEO BMA GGAL BFR PZE

set more off

use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear
drop if date == .
drop if Ticker == ""
drop if market != "US" & market != "AR"
keep date px_open px_last Ticker total_return market
drop if ~regexm("`localnames'",Ticker) & ~regexm("`anames'",Ticker)

rename Ticker ticker
replace ticker = ticker + " US Equity" if market == "US"

gen ticker_short = ticker if market == "AR"

mmerge ticker using "$bbpath/ADR_Static.dta", unmatched(master) ukeep(underlying_ticker ticker_short) update
mmerge ticker_short using "$bbpath/ADR_Static.dta", unmatched(master) ukeep(underlying_ticker) update

sort ticker_short date market
rename px_last px_close

keep date px_open px_close total_return market ticker_short
rename ticker_short Ticker

reshape wide px_open px_close total_return, i(date Ticker) j(market) string


sort Ticker date


local rtypes px_open px_close total_return

gen weight = .
gen conversion = .
local nm
levelsof(Ticker), local(tickers) clean
disp "tx: `tickers'"
foreach nmw in `localnames' {
	if regexm("`tickers'","`nmw'") {
		local nm `nmw'
	}
	else{
		replace weight = `nmw' / 100 if regexm(Ticker,"`nm'")
	}
}

foreach nmw in `localratios' {
	if regexm("`tickers'","`nmw'") {
		local nm `nmw'
	}
	else{
		replace conversion = `nmw' if regexm(Ticker,"`nm'")
	}
}


foreach rtype in `rtypes' {
	gen `rtype' = (`rtype'AR / `rtype'US * conversion)
	drop `rtype'AR `rtype'US
}

*** The total_return is problematic because it includes the dividends
*** the value of which is affected by the official-blue gap

replace total_return = px_close
*replace px_close = total_return

*collapse (sum) `rtypes', by(date)

*gen Ticker = "ADRBlue"

replace Ticker = Ticker + "Blue"


sort date Ticker


foreach rtype in `rtypes' {
	by date: egen `rtype'ADRBlue = sum(weight*`rtype')
	by date: egen `rtype'ADRBlue_cnt = sum(weight*(`rtype'!=.))
	replace `rtype'ADRBlue = . if `rtype'ADRBlue_cnt == 0
	replace `rtype'ADRBlue = `rtype'ADRBlue / `rtype'ADRBlue_cnt 
	su `rtype'ADRBlue_cnt
	drop `rtype'ADRBlue_cnt
}
drop weight conversion

reshape wide `rtypes', i(date) j(Ticker) string
reshape long `rtypes', i(date) j(Ticker) string

tempfile temp
save "$bbpath/`temp'", replace

use "$dpath/ARS_Blue.dta", clear
keep ARSUSDS TDARSSP date

drop if date >= td(30jul2014)
*drop if date < td(1jan2011)

rename ARSUSDS total_returnDSBlue
rename TDARSSP total_returnOfficialRate

reshape long total_return, i(date) j(Ticker) string

gen px_close = total_return

append using "$bbpath/temp.dta"




sort date Ticker

save "$apath/blue_rate.dta", replace


use "$apath/blue_rate.dta", clear
keep date Ticker px_close

drop if ~regexm(Ticker,"ADRBlue") & ~regexm(Ticker,"OfficialRate") & ~regexm(Ticker,"DSBlue")

reshape wide px_close, i(date) j(Ticker) string


twoway (line px_closeADRBlue date) (line  px_closeDSBlue date, lpattern(dash)) (line  px_closeOfficialRate date, lpattern(dash dot) lwidth(thick)) if date<=td(31Aug2014), legend(order(1 "ADR" 2 "Onshore" 3 "Official")) xtitle("") graphregion(fcolor(white) lcolor(white))

graph export "$rpath/ADRChart.png", replace

twoway (line px_closeADRBlue date) (line  px_closeOfficialRate date, lpattern(dash dot) lwidth(thick)) if date<=td(31Aug2014), legend(order(1 "Blue Rate" 2 "Official")) xtitle("") graphregion(fcolor(white) lcolor(white))
graph export "$rpath/ADRonlyChart.eps", replace



