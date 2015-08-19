*Clean industrial production data
*Industrial Production
local horizon 3 12 24
local hlength 3
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
collapse (mean) ip_index (firstnm) date, by(month)
label var ip_index "Industrial Production Index"
tsset month
foreach x in `horizon' {
local y=`x'+1
gen ipg_`x'=100*(log(f`x'.ip_index)-log(ip_index))
gen ipg_lag`x'=100*(log(l.ip_index)-log(l`y'.ip_index))
label var ipg_`x' "IP growth, `x' months ahead"
label var ipg_lag`x' "IP growth, Previous `x' months"
}
save "$apath/IP_data.dta", replace


/*
****************
*FACTOR LEVELS**
****************
set more off

* This code loads the factors we use to compute excess returns
use "$fpath/Addition_Vars.dta", clear
drop if ticker != "SPX_Price" & ticker != "VIX" & ticker != "EEMA"
replace ticker = "SPX" if ticker=="SPX_Price"


save "$apath/temp.dta", replace

use "$dpath/CDS_Indices.dta", clear
keep date MCCIG5Y MCCNH5Y
rename MCCIG5Y closeIG5Yr
rename MCCNH5Y closeHY5Yr
reshape long close, i(date) j(ticker) string

append using "$apath/temp.dta"
append using "$apath/commodity_prices.dta"

gen bdate = bofd("basic",date)
format bdate %tbbasic
encode ticker, gen(tid)

sort tid bdate
tsset tid bdate
keep date ticker close
reshape wide close, i(date) j(ticker) str
renpfix close
tempfile factor_temp
save "`factor_temp'", replace
*DON'T GO BACK FAR ENOUGH, USE SUBSTIUTES FOR NOW
*/

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



*TBILL AND FX
tempfile  Tbill_forecasts exchange_rate

use "$apath/Tbill_daily.dta", clear
keep date total_return Ticker
save "`Tbill_forecasts'", replace

*SET UP Exchange rates
use "$apath/blue_rate.dta", clear
keep if Ticker=="ADRBlue"
tsset date
tsfill
carryforward total_return, replace
carryforward Ticker, replace
drop px_close px_open
save "`exchange_rate'", replace


*MERGE IT WITH EQUITIES
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
encode Ticker, gen(tid)
tsset tid date
tsfill
carryforward total_return, replace
carryforward Ticker, replace
keep date Ticker total
rename total t_
replace Ticker="APSA" if Ticker=="IRCP"
keep if Ticker=="APSA" | Ticker=="BFR" | Ticker=="BMA" | Ticker=="BSAR" | Ticker=="CRESY" | Ticker=="EDN" | Ticker=="GGAL" | Ticker=="IRS" | Ticker=="PAM" | Ticker=="PZE" | Ticker=="TEO" | Ticker=="TGS" | Ticker=="YPF"
append using "`Tbill_forecasts'"
append using "`exchange_rate.dta'"
replace t_=total if Ticker=="Tbill" | Ticker=="ADRBlue"
drop total
gen quarter=qofd(date)
format quarter %tq
*RECREATE VALUE INDEX
encode Ticker, gen(tid)
tsset tid date
tsfill
carryforward t_, replace
mmerge quarter Ticker using "$dpath/ADR_weighting.dta", ukeep(weight_)
replace weight=.1 if Ticker=="Tbill"
drop if date < mdy(1,1,1995)
drop if date>mdy(4,1,2015)
mmerge date using "$apath/IP_data.dta"
keep if _merge==3
drop ip* _merge

sort Ticker month
tsset tid month
foreach x in `horizon' {
gen ret`x'=(t_/l`x'.t_)-1
}

replace weight=0 if ret12==.
replace weight=0 if Ticker=="Tbill"
bysort date: egen total_w=sum(weight)
replace weight=0.9*weight/total_w 
drop if total_w==0
replace weight=0.1 if Ticker=="Tbill"
replace weight=0 if Ticker=="ADRBlue"
by date: egen valid = count(t_)
ta Ticker valid
drop if valid <= 6
drop valid

foreach x in `horizon' {
by date: egen ValueIndex`x' = sum(weight*ret`x')
}



expand 2 if Ticker=="Tbill", gen(index)
replace Ticker="ValueIndex" if index==1 
foreach x in `horizon' {
replace ret`x'=ValueIndex`x' if index==1 
}

keep date Ticker ret*
foreach x in `horizon' {
replace ret`x'=100*log(1+ret`x')
}
levelsof Ticker, local(tick)
reshape wide ret*, i(date) j(Ticker) string

foreach x of local tick {
foreach y in `horizon' {
rename  ret`y'`x' `x'ret`y'
}
}
reshape long `tick', i(date) j(type) string
mmerge date using "$apath/IP_data.dta"
keep if _merge==3
mmerge month using "$apath/monthly_controls.dta"
drop if _merge==2
drop _merge
save "$apath/IP_Dataset.dta", replace

use  "$apath/IP_Dataset.dta", clear
*NEED TO THINK ABOUT WHAT TO DO ABOUT CONTROLS

rename ValueIndex ValueIndex_US
local controls SPX VIX emasia igbonds oil soybean

foreach x in `horizon' {
*reg ipg_`x' Value  ADRBlue `controls' if type=="ret`x'" & yofd(date)>=2003, r
reg ipg_`x' Value  ADRBlue ipg_lag`x' `controls' if type=="ret`x'" & yofd(date)>=2003, r
*reg ipg_12 Value  ADRBlue  if type=="ret12", r
matrix temp = e(b)
matrix ipg`x'_b=temp[1,1..2]'
matrix temp = e(V)
matrix ipg`x'_V=temp[1..2,1..2]
}
