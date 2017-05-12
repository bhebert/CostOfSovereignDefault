*
import excel "$fpath/GFD_SP.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
format date %td
drop Date
order date
replace Ticker="SPX_Price"
rename Ticker ticker
rename Open open
rename Close close
drop High Low
save "$apath/SPX.dta", replace

import excel "$fpath/GFDMexicoIndex.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
format date %td
drop Date
order date
replace Ticker="DJ_Mexico"
rename Ticker ticker
rename Open open
rename Close close
drop High Low Volume
save "$apath/Mexico.dta", replace

import excel "$bbpath/Indices.xlsx", sheet("EEMAUS") firstrow clear
sort date
rename index ticker
replace ticker="EEMA"
save "$apath/EEMA.dta", replace

import excel "$bbpath/Indices.xlsx", sheet("MXASJ") firstrow clear
sort date
rename index ticker
replace ticker="MXASJ"
save "$apath/MXASJ.dta", replace

import excel "$fpath/vix_CBOE.xlsx", sheet("vix") firstrow clear
gen ticker="VIX"
drop high low
save "$apath/VIX.dta", replace

use "$apath/VIX.dta", clear
append using "$apath/SPX.dta"
append using "$apath/Mexico.dta"
append using "$apath/EEMA.dta"
append using "$apath/MXASJ.dta"
keep date open close ticker
order date ticker
sort ticker date 
save "$apath/Addition_Vars.dta", replace

