*Back of envelope costs
*COEFFICIENT
set more off
local value_coeff=-54.50
local ypf_coeff=-95.22
local a_value_coeff=exp(`value_coeff'/100)-1
local a_ypf_coeff=exp(`ypf_coeff'/100)-1
*$B, from WDI, 2011
local gdp_usd=560
local rho=0.9956^4


*MAKE FIRM TABLE WITH ALL EQUITIES
*NEED TO CONVERT TO ARITHMETIC
local market_cut 200
tempfile adrtemp firmtabletemp
use "$bbpath/ADR_Static.dta", clear
keep ticker ticker_short Primary_Exchange
rename ticker ADRticker
gen ADRratio=2 if ADRticker != ""
replace ADRratio=10 if regexm(ADRticker,"BMA") | regexm(ADRticker,"GGAL")| regexm(ADRticker,"PZE")
replace ADRratio=3 if regexm(ADRticker,"BFR") 
replace ADRratio=5 if regexm(ADRticker,"TEO")
replace ADRratio=25 if regexm(ADRticker,"PAM")

save "`adrtemp'", replace
use "$dpath/DS_BB_Static_v2.dta", clear
keep Ticker isin_code indicator_adr //Industry_sector industry_Group
rename isin_code ID_ISIN
mmerge ID_ISIN using "$dpath/Market_Cap_Ticker_2011.dta", unmatched(both)
drop _merge
split bb_ticker, gen(ticker_short) limit(1)
rename ticker_short ticker_short
mmerge ticker_short using "`adrtemp'", unmatched(both)
* This is a telecom argentina holding company
drop if Ticker == ""
rename market_cap market_cap2011
drop if market_cap2011 == . 
gen market_ind=1 if market_cap2011 > `market_cut'
keep market_cap* ticker_short
save "`firmtabletemp'", replace

*use "$apath/firmtable.dta", clear
*drop if Ticker == ""
*keep if market_cap2011 >200


*Calculate 2011 exchange rate (using official)
use "$dpath/ARS_Blue.dta", clear
keep  TDARSSP date
rename TDARSSP Official
keep if yofd(date)==2011
summ Official
local fx=r(mean)


*FULL MARKET Cap
use  "$dpath/Market_Cap_Ticker_2011.dta", clear
gen market_cap_exypf=market_cap
replace market_cap_exypf=. if Ticker=="YPF"
collapse (sum) market_cap market_cap_exypf
replace market_cap=market_cap/`fx'
replace market_cap_exypf=market_cap_exypf/`fx'
local market_cap_usd_total=market_cap[1]
local market_cap_usd_total_exypf=market_cap_exypf[1]


use  "$apath/firmtable.dta", clear
gen ypf_market_temp=market if name=="YPF"
egen ypf_market=max(ypf_market_temp) 
drop if  name=="YPF"
gen market_adr=market if ADRticker~="" & ADRticker~="BSAR US Equity"
collapse (sum) market_c market_adr (firstnm) ypf_market
gen market_usd=(market_cap/`fx')
gen market_adr_usd=(market_adr/`fx')
gen market_ypf_usd=ypf_market/`fx'
gen loss_adr_exypf=market_adr_usd*`a_value_coeff'/1000
gen loss_exypf=market_usd*`a_value_coeff'/1000
gen loss_all_exypf=`market_cap_usd_total_exypf'*`a_value_coeff'/1000
gen loss_ypf=market_ypf_usd*`a_ypf_coeff'/1000

gen loss_adr=loss_adr_exypf+loss_ypf
gen loss=loss_exypf+loss_ypf
gen loss_all=loss_all_exypf+loss_ypf
keep loss*
 

foreach x in loss_adr_exypf loss_exypf loss_ypf loss_adr loss loss_all loss_all_exypf {
	gen `x'60=`x'*.6
	rename `x' `x'100
}
gen temp="temp"
reshape long loss_adr_exypf loss_exypf loss_ypf loss_adr loss loss_all loss_all_exypf, i(temp) j(num)
drop temp

*aggregate loss
*my lazy average, try a bunch fo results
gen stock_market_cap=.138

*YPF AND TEO, and internet say 7
gen PE=7
gen aggregate_loss=loss_all/(stock_market_cap/PE)
drop stock_market PE
gen aggregate_gdp=100*aggregate/`gdp_usd'
gen aggregate_pvgdp=aggregate_gdp*(1-`rho')

foreach x in  loss_adr_exypf loss_exypf loss_all_exypf loss_ypf loss_adr loss loss_all aggregate_loss aggregate_gdp aggregate_pvgdp {
	rename `x' estimate_`x'
	}
	reshape long estimate_, i(num) j(var) str
	order var
	reshape wide estimate_, i(var) j(num)
gen unit="USD Billions"
replace unit="% Delta G" if var=="aggregate_pvgdp"
replace unit="% of 2011 GDP" if var=="aggregate_gdp"
replace var="loss_dataset" if var=="loss"
gsort -unit -estimate_60
export excel using "$rpath/Costs.xls", firstrow(variables) replace


/*

*Use the local coefficients
tempfile temp
*THIS USES OLD COEFFICIENTS, NEED TO UPDATE
import excel "$mainpath/Misc answers/RS_CDS_IVLocalFull.xlsx", sheet("Sheet1") clear
keep if _n==2| _n==4
sxpose, clear
drop if _n==1
rename _var1 Ticker
replace Ticker=subinstr(Ticker,"_AR","",.)
gen length=length(Ticker)
drop if length>5 & Ticker~="EqIndex"
drop length
rename _var2 coeff_est
rename Ticker ticker_short
drop if ticker_short=="INDEX"
destring coeff_est, replace

gen eqtemp=coeff_est if ticker=="EqIndex"
egen index_coeff=max(eqtemp)
drop eqtemp
drop if ticker=="EqIndex"
save "`temp'", replace

use "`firmtabletemp'", clear
mmerge ticker_short using "`temp'"
summ index_coeff
replace index_coeff=r(max)
*Use the index for the one missing firm. 
gen coeff_est_alt=coeff_est
replace coeff_est_alt=index_coeff if coeff_est_alt==.
order ticker_short market coeff_est
keep ticker_ market_ coeff* index
replace market=market/`fx'
replace market=market/1000
gen arith_coeff=exp(coeff_est/100)-1
gen loss=market*(exp(coeff_est/100)-1)*.6
gen loss_alt=market*(exp(coeff_est_alt/100)-1)*.6
gen loss_index=market*(exp(index_coeff/100)-1)*.6
collapse (sum) loss*

*World bank
gen stock_market_cap2010=.138
gen stock_market_cap2011=.78
*my lazy average
gen stock_market_cap=.10

*YPF AND TEO, and internet say 7
gen PE=7
gen aggregate_loss=loss/(stock_market_cap/PE)
gen aggregate_loss_alt=loss_alt/(stock_market_cap/PE)
gen aggregate_loss_index=loss_index/(stock_market_cap/PE)
* so we say argentina lost $1 trillion. GDP is $600 b



