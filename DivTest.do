set more off

use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear

drop if market != "US"
drop if Ticker == ""

rename px_last px_close

gen quarter = qofd(date)

drop if px_close == .
sort Ticker quarter date
by Ticker quarter: egen end_day = max(date)
drop if end_day != date

encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
gen div = total_return / L.total_return * L.px_close - px_close

mmerge Ticker quarter using "$apath/ADR_CRSP.dta", unmatched(none)

mmerge quarter using "$apath/ADRBlue_quarter.dta", ukeep(ADRBlue OfficialRate) unmatched(master)

gen adr_div = div

replace div = div / adrrq

gen div_peso = div * OfficialRate

gen div_dollar = dvpsxq / OfficialRate

gen div_crsp_adr = dvpsxq * adrrq / OfficialRate

keep Ticker quarter adr_div div_crsp_adr div div_dollar div_peso dvpsxq repurchases adrrq

format %9.2f adr_div div_crsp_adr div div_dollar div_peso dvpsxq repurchases

format quarter %tq

drop if quarter < yq(2003,1)


order Ticker quarter adr_div div_crsp_adr div div_dollar div_peso dvpsxq repurchases
sort Ticker quarter
