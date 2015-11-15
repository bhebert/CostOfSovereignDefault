*Back of envelope costs
*COEFFICIENT
set more off
local value_coeff=-54.70
local ypf_coeff=-95.78
*Value index is 1/10 treasuries. 
local a_value_coeff=exp((10/9)*`value_coeff'/100)-1
local a_ypf_coeff=exp(`ypf_coeff'/100)-1
*$B, from WDI, 2011
local gdp_usd=560
local rho=0.9956^4
local PEnum= 14.87 //7
local smc= 0.138 //.1

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

gen stock_market_cap=`smc'
gen PE=`PEnum'

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


