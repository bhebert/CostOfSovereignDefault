set more off

***************************
*IMPORT AND CLEAN GDF STUFF
import excel "$miscdata/IP/Controls_GFD.xlsx", firstrow sheet("Price Data") clear
keep Date Ticker Close
gen date=date(Date,"MDY")
gen month=mofd(date)
format date %td
format month %tm
collapse (lastnm) Close date, by(Ticker month)
drop if Ticker=="BRT_D" | Ticker=="__Sc1_ID" 
replace Ticker="oil" if Ticker=="__WTC_D"
replace Ticker="soybean" if Ticker=="__SYB_TD"
replace Ticker="hybonds" if Ticker=="__MRLHYD"
replace Ticker="VIX" if Ticker=="_VIXD"
replace Ticker="SPX" if Ticker=="_SPXTRD"
replace Ticker="igbonds" if Ticker=="TRUSACOM"
replace Ticker="emasia" if Ticker=="_IPDASD"
drop date
reshape wide Close, i(month) j(Ticker) str
renpfix Close

tsset month
sort month
foreach var in SPX VIX emasia hybonds igbonds oil soybean {
gen `var'_n=100*(log(`var')-log(l.`var'))
replace `var'=`var'_n
drop `var'_n
}

save "$apath/monthly_controls.dta", replace

*Clean industrial production data
*Industrial Production
tempfile temp

import excel "$miscdata/IP/GDF_IP.xlsx", sheet("Price Data") firstrow clear
drop Ticker
rename Close ip_index
gen date=date(Date,"MDY")
format date %td
gen month=mofd(date)
format month %tm
order date month
drop Date
*IP is reported for leap date 1992, and Oct 30 and 31 1998
collapse (mean) ip_index, by(month)
label var ip_index "Industrial Production Index"
sort month
rename ip_index IndustrialProduction
save "`temp'", replace


*SET UP Exchange rates
use "$apath/blue_rate.dta", clear
keep if Ticker=="ADRBlue"
tsset date
tsfill
carryforward total_return, replace
keep date total_return
rename total_return ADRBlue
gen month = mofd(date)
collapse (lastnm) ADRBlue, by(month)

mmerge month using "`temp'"
drop _merge

mmerge month using "$miscdata/Inflation/us_inflation_month.dta", unmatched(master) ukeep(us_cpi)
mmerge month using "$miscdata/Inflation/inflation_month.dta", unmatched(master) ukeep(cpi)

drop _merge
format month %tm

save "$apath/rer_ip_dataset.dta", replace

