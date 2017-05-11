*Tickers
import excel "$csd_data/Bolsar/Tickers.xlsx", sheet("All_Tickers") firstrow allstring clear
save "$apath/bolsar_ticker_name.dta", replace

import excel "$csd_data/Bolsar/Tickers.xlsx", sheet("Ticker_Industry") firstrow clear
rename Main industry
mmerge ticker using "$apath/bolsar_ticker_name.dta"
drop if ticker==""
save "$apath/bolsar_ticker_name_industry.dta", replace

*Paper
import excel "$csd_data/Bolsar/Bolsar1.xlsx", sheet("Sheet1") firstrow clear
rename SYMB ticker
rename LastClose Last
save "$apath/Bolsar1.dta", replace

import excel "$csd_data/Bolsar/Bolsar2.xlsx", sheet("Securities") firstrow clear
rename SYMB ticker
rename LastClose Last
save "$apath/Bolsar2.dta", replace

import excel "$csd_data/Bolsar/Bolsar2.xlsx", sheet("Indexes") firstrow clear
rename Indexes ticker
save "$apath/bolsar_Index.dta", replace

use "$apath/Bolsar1.dta", clear
append using "$apath/Bolsar2.dta"
append using "$apath/bolsar_Index.dta"
drop  Settle
destring Last, replace force
destring Change, replace force
destring Open, replace force
destring High, replace force
destring Low, replace force
destring Nominal, replace force
destring Trading, replace force
destring N_Oper, replace force
encode ticker, gen(firm_id)
gen date=date(Date,"DMY")
format date %td
drop Date
order date
replace Type="Index" if Type==""
replace Type="Equity" if Type~="Index"
rename Type type
rename NominalsValue volume
rename TradingValue volume_value
save "$apath/Bolsar_merged.dta", replace



