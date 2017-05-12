*Commodities clean
*Raw data from Global Financial Data
import excel "$csd_data/GFD/Jesse_Schreger_Misc_Series_excel2007_GFDComm.xlsx", sheet("Price Data") firstrow clear
rename Date date
rename Ticker ticker
rename Open open
rename Close close
keep date ticker open close
keep if ticker=="__WTC_D" | ticker=="__SYB_TD"
replace ticker="oil" if ticker=="__WTC_D"
replace ticker="soybean" if ticker=="__SYB_TD"
rename date datestr
gen date=date(datestr,"MDY")
format date %td
drop datestr
order date
keep if yofd(date)>=2004
save "$apath/commodity_prices.dta", replace

