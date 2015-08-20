set more off

tempfile Tbill_forecasts exchange_rate

use "$apath/Tbill_daily.dta", clear
mmerge date using "$apath/Simple_Weight.dta", umatch(fdate) ukeep(C)
keep if _merge==3
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


*MERGE IT
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
mmerge quarter Ticker using "$dpath/ADR_weighting.dta", ukeep(weight_)
mmerge date using "$apath/Simple_Weight.dta", umatch(fdate) ukeep(C)
drop C
keep if _merge==3
rename weight weight
sort Ticker date
drop _merge
bysort Ticker: gen n=_n
encode Ticker, gen(tid)
tsset tid n
gen ret1y=(t_/l2.t_)-1
gen ret6m=(t_/l.t_)-1
replace weight=0 if ret1y==.
bysort date: egen total_w=sum(weight)
replace weight=0.9*weight/total_w 
drop if total_w==0
replace weight=0.1 if Ticker=="Tbill"
replace weight=0 if Ticker=="ADRBlue"
by date: egen valid = count(t_)
ta Ticker valid
drop if valid <= 6
drop valid

by date: egen ValueIndex1y = sum(weight*ret1y)
by date: egen ValueIndex6m = sum(weight*ret6m)

expand 2 if Ticker=="Tbill", gen(index)
expand 2 if Ticker=="Tbill", gen(index6m)

replace Ticker="ValueIndex1y" if index==1 & index6m==0
replace ret1y=ValueIndex1y if index==1 & index6m==0
replace ret6m=. if index==1 & index6m==0

replace Ticker="ValueIndex6m" if index==0 & index6m==1
replace ret6m=ValueIndex6m if index==0 & index6m==1
replace ret1y=. if index==0 & index6m==1
drop if index==1 & index6m==1

keep date Ticker ret1y ret6m
replace ret1y=log(1+ret1y)
replace ret6m=log(1+ret6m)

reshape wide ret1y ret6m, i(date) j(Ticker) string
*renpfix ret1y

mmerge date using "$apath/Simple_Weight.dta", umatch(fdate) ukeep(N*)
keep if _merge==3
save "$apath/forecast_dataset_update.dta", replace

*****************
*CREATE WEIGHTS
use "$apath/forecast_dataset_update.dta", clear
*local eq_data BFR CRESY IRS TEO TGS YPF
*local eq_data_ny BFR CRESY IRS TEO TGS
local eq_index ValueIndex ADRBlue

*reg N_GDP_ft `eq_index' , r
*predict N_GDP_ft_xb, xb
*twoway (line N_GDP_ft_xb date) (line N_GDP_ft date)

*reg N_GDP_ft `eq_index' if yofd(date)>=2003, r
*predict N_GDP_ft_xb_03, xb
*twoway (line N_GDP_ft_xb_03 date) (line N_GDP_ft date) if yofd(date)>=2003
drop ret6mValueIndex1y ret1yValueIndex6m
*local eq_data BFR CRESY IRS TEO TGS YPF
rename ret1yValueIndex ValueIndex_US
rename ret1yADRBlue ADRBlue

local addvar IP

reg N_GDP_ft Value  ADRBlue, r
matrix temp = e(b)
matrix consensus_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus_V=temp[1..2,1..2]

reg N_GDP_ft Value  ADRBlue if yofd(date)>2003, r
matrix temp = e(b)
matrix consensus03_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus03_V=temp[1..2,1..2]

foreach x in `addvar' {
reg N_`x'_ft Value  ADRBlue, r
matrix temp = e(b)
matrix consensus`x'_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus`x'_V=temp[1..2,1..2]

reg N_`x'_ft Value  ADRBlue if yofd(date)>2003, r
matrix temp = e(b)
matrix consensus`x'03_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus`x'03_V=temp[1..2,1..2]
}


rename ValueIndex_US ret1yValueIndex
rename ADRBlue ret1yADRBlue 
rename ret6mValueIndex ValueIndex_US
rename ret6mADRBlue ADRBlue

reg N_GDP_ft_6m Value  ADRBlue, r
matrix temp = e(b)
matrix consensus6m_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus6m_V=temp[1..2,1..2]

reg N_GDP_ft_6m Value  ADRBlue if yofd(date)>2003, r
matrix temp = e(b)
matrix consensus036m_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus036m_V=temp[1..2,1..2]

foreach x in `addvar' {
reg N_`x'_ft_6m Value  ADRBlue, r
matrix temp = e(b)
matrix consensus`x'6m_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus`x'6m_V=temp[1..2,1..2]

reg N_`x'_ft_6m Value  ADRBlue if yofd(date)>2003, r
matrix temp = e(b)
matrix consensus`x'036m_b=temp[1,1..2]'
matrix temp = e(V)
matrix consensus`x'036m_V=temp[1..2,1..2]
}





/*
reg d_PV_GDP_2 Value  ADRBlue, r
outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("VIPV")  replace
reg d_GDP_2 Value  ADRBlue, r
outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("VIGDP2") 
reg d_LT_GDP Value  ADRBlue, r
outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("VILT") 
reg N_GDP_ft Value  ADRBlue, r
outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("NGF")
reg N_GDP_2_ft Value  ADRBlue, r
outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("N2GF")
reg N10_GDP_ft Value  ADRBlue, r
outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("N10GF")
reg N10_GDP_2_ft Value  ADRBlue, r
outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("N210GF")
*reg d_PV_GDP_2 `eq_data'  ADRBlue, r
*outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("ADR") replace
*reg d_PV_GDP_2 `eq_data_ny'  ADRBlue, r
*outreg2 using "$fpath/forecast_weights.txt", noaster nor2 noobs nonotes ctitle("ADRny") 

import delimited  "$fpath/forecast_weights.txt", clear 
drop if _n==1
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
	}
	drop if _n==1 | _n==2
	rename VAR Ticker
	drop if Ticker=="" 
	
	local fcasts
	foreach var of varlist _all {
		if "`var'" ~="Ticker" {
		local fcasts="`fcasts'" +" "+ "`var'"
		destring `var', replace
		}
		}
	

	foreach x in `fcasts' {
	rename `x' forecast_`x'
	}
	save "$fpath/forecast_weights.dta", replace

	*MAKE INDICES USING GDPIndexMaker in Analysis folder
	
*****************

*MISC REGS
/*use "$fpath/forecast_dataset.dta", clear
reg d_GDP_2 Value, r
outreg2 using "$fpath/forecast_valueindex.xls", replace
foreach x in d_PV_GDP_2 d_LT_GDP d_C_2  d_PV_C_2  d_LT_C  {
reg `x' Value,r 
outreg2 using "$fpath/forecast_valueindex.xls"
}

local eq_data_full BFR IRS TEO TGS YPF
local eq_data BFR CRESY IRS TEO TGS YPF
local eq_data_short APSA BFR CRESY GGAL IRS TEO TGS YPF

*REPLICATING INDEX
*NEED TO INCLUDE EXchange rate
*Then create time series of d_PV_GDP_2
reg d_PV_GDP_2  `eq_data_short',r
outreg2 using "$fpath/forecast_repindex.xls", replace
reg d_PV_GDP_2  `eq_data_short' Tbill ,r
outreg2 using "$fpath/forecast_repindex.xls"
reg d_PV_GDP_2  `eq_data',r
outreg2 using "$fpath/forecast_repindex.xls"
reg d_PV_GDP_2  `eq_data' Tbill ,r
outreg2 using "$fpath/forecast_repindex.xls"
reg d_PV_GDP_2  `eq_data_full',r
outreg2 using "$fpath/forecast_repindex.xls"
reg d_PV_GDP_2  `eq_data_full' Tbill ,r
outreg2 using "$fpath/forecast_repindex.xls"
*/






