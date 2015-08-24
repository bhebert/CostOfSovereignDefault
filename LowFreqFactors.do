set more off

global lf_factors SPX oil soybean VIX emasia igbonds //hybonds

* Load controls data
import excel "$miscdata/IP/Controls_GFD.xlsx", firstrow sheet("Price Data") clear
keep Date Ticker Close
gen date=date(Date,"MDY")
drop Date

gen month=mofd(date)

format date %td
format month %tm

drop if Ticker=="BRT_D" | Ticker=="__Sc1_ID" 
replace Ticker="oil" if Ticker=="__WTC_D"
replace Ticker="soybean" if Ticker=="__SYB_TD"
replace Ticker="hybonds" if Ticker=="__MRLHYD"
replace Ticker="VIX" if Ticker=="_VIXD"
replace Ticker="SPX" if Ticker=="_SPXTRD"
replace Ticker="igbonds" if Ticker=="TRUSACOM"
replace Ticker="emasia" if Ticker=="_IPDASD"

save "$apath/daily_factors.dta", replace

collapse (lastnm) Close, by(Ticker month)

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
