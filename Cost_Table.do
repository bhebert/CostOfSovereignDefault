*Back of envelope costs
*COEFFICIENT
set more off
local value_coeff=-60.43
local ypf_coeff=-93.69
*Value index is 1/10 treasuries. 
local a_value_coeff=exp(`value_coeff'/100)-1
local a_ypf_coeff=exp(`ypf_coeff'/100)-1
*$B, from WDI, 2011
local gdp_usd=560
local rho=0.9956^4
local PEnum= 14.87 //7
local smc= 0.138 //.1

local qyear_cut yq(2009,1)
local qyear_market yq(2011,2)

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


//drop if  name=="YPF"
replace market_c = . if name == "YPF"

replace ADRticker = "" if regexm(ADRticker,"BSAR")
gen market_adr=market if ADRticker~="" & name != "YPF"

replace ADRticker = "IRCP US Equity" if ADRticker == "APSA US Equity"


rename Ticker LocalTicker

//drop if ADRticker==""
split ADRticker, gen(nm)
rename nm1 Ticker
drop nm*

replace Ticker = "MISSING" if Ticker == ""
ta Ticker
ta LocalTicker

mmerge Ticker using "$apath/ADR_CRSP.dta", unmatched(master)

gen year = yofd(dofq(quarter))
ta LocalTicker

//drop if (year < 2009 | year > 2011) & year != .

drop if (quarter > `qyear_market' | quarter < `qyear_cut') & quarter != .

sort LocalTicker quarter

gen earn_adr = epsfxq * commonshares

ta Ticker if earn_adr == . & quarter != .

gen ypf_earn = earn_adr
replace ypf_earn = . if Ticker != "YPF"
replace earn_adr = . if Ticker == "YPF"

collapse (sum) earn_adr ypf_earn (firstnm) market_c market_adr ypf_market, by(LocalTicker)

ta LocalTicker

collapse (sum) market_c market_adr earn_adr ypf_earn (firstnm) ypf_market
disp "fx: `fx'"
gen market_usd=(market_cap/`fx')
gen market_adr_usd=(market_adr/`fx')
gen market_ypf_usd=ypf_market/`fx'
gen earn_adr_exypf_usd=(earn_adr/`fx') / 1000 / (`qyear_market'-`qyear_cut'+1) * 4
gen earn_ypf_usd=ypf_earn/`fx' / 1000 / (`qyear_market'-`qyear_cut'+1) * 4
gen earn_adr_usd = earn_adr_exypf_usd + earn_ypf_usd

gen loss_adr_exypf=market_adr_usd*`a_value_coeff'/1000
gen loss_exypf=market_usd*`a_value_coeff'/1000
gen loss_all_exypf=`market_cap_usd_total_exypf'*`a_value_coeff'/1000
gen loss_ypf=market_ypf_usd*`a_ypf_coeff'/1000

gen loss_adr=loss_adr_exypf+loss_ypf
gen loss_total=loss_exypf+loss_ypf
gen loss_all=loss_all_exypf+loss_ypf

drop earn_adr ypf_earn

rename earn_*_usd earn_*

gen years_adr_exypf = -loss_adr_exypf / earn_adr_exypf
gen years_adr = -loss_adr / earn_adr
gen years_ypf = -loss_ypf / earn_ypf


keep loss* earn* years*
 

foreach x in loss_adr_exypf loss_exypf loss_ypf loss_adr loss_total loss_all loss_all_exypf earn_adr_exypf earn_adr earn_ypf years_adr_exypf years_adr years_ypf {
	gen `x'60=`x'*.6
	rename `x' `x'100
}


gen temp="temp"

reshape long loss_adr_exypf loss_exypf loss_ypf loss_adr loss_total loss_all loss_all_exypf earn_adr_exypf earn_adr earn_ypf years_adr_exypf years_adr years_ypf, i(temp) j(num)
drop temp

gen stock_market_cap=`smc'
gen PE=`PEnum'

gen loss_aggregate=loss_all/(stock_market_cap/PE)
drop stock_market PE
gen earn_aggregate=`gdp_usd'
gen years_aggregate= -loss_aggregate / earn_aggregate


reshape long loss_ earn_ years_, i(num) j(name) string

gen npv_ = -100*years_*(1-`rho')

replace earn_ = . if num == 60

reshape wide earn_ loss_ years_ npv_, i(name) j(num)

drop earn_60

order name loss_60 loss_100 earn_100 years_100 npv_100 years_60 npv_60

gen val = 1 
replace val = 2 if name != "adr_exypf"
replace val = 3 if name == "adr"
replace val = 4 if name == "total"
replace val = 5 if name == "all"
replace val = 6 if name == "exypf"
replace val = 7 if name == "all_exypf"
replace val = 8 if name == "aggregate"

sort val


/*foreach x in  loss_adr_exypf loss_exypf loss_all_exypf loss_ypf loss_adr loss loss_all aggregate_loss aggregate_gdp aggregate_pvgdp {
	rename `x' estimate_`x'
	}
	reshape long estimate_, i(num) j(var) str
	order var
	reshape wide estimate_, i(var) j(num)
gen unit="USD Billions"
replace unit="% Delta G" if var=="aggregate_pvgdp"
replace unit="% of 2011 GDP" if var=="aggregate_gdp"
replace var="loss_dataset" if var=="loss"
gsort -unit -estimate_60*/


export excel using "$rpath/Costs.xls", firstrow(variables) replace


