*Cleaning Bloomberg data
global dir_home "~/Dropbox/Cost of Sovereign Default/Bloomberg"
global dir_inter "~/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate"
global dir_datasets "~/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets"

ssc install sxpose
ssc install carryforward


*INDEX Static
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Data/Argentina Indices.xlsx", sheet("indices") firstrow allstring clear
rename Security ticker
save "$dir_datasets/Nov_Indices_chars.dta", replace


*ADR Static
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Data/Argentina Nov2.xlsx", sheet("Static Values") firstrow allstring clear
order Ticker ULT_PARENT_TICKER_EXCHANGE
rename Ticker adr_ticker
rename ADR_UNDL_Ticker underlying_ticker
split underlying_ticker, p(" ")
drop underlying_ticker2
rename underlying_ticker1 Ticker
order Ticker adr underlying_ticker
mmerge Ticker using "~/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets/Industries.dta"
keep if _merge==3
rename Ticker ticker_short
rename adr_ticker ticker

encode ticker_short, gen(firm_number)
order firm_number
save "$dir_datasets/ADR_Static.dta", replace

****************************
****************************
*ADRs
****************************
****************************
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Data/Argentina Nov1.xlsx", sheet("Time Series") clear
gen n=_n
order n
gen mod9=mod(n,9)
drop if mod9==0
drop mod9 n

gen n=_n
order n
tsset n
gen name=""
replace name=A if A~="Date" & A~="PX_LAST"  & A~="PX_OPEN"  & A~="TOT_RETURN_INDEX_GROSS_DVDS"  & A~="PX_VOLUME"  & A~="PX_BID" & A~="PX_ASK" 
carryforward name, replace
drop if B==""
encode name, gen(firm_id)
order firm_id
drop n
order name
save "$dir_inter/ADR_temp.dta", replace

forvalues i=1/27 {
use "$dir_inter/ADR_temp.dta", clear
keep if firm_id==`i'
*keep if firm_id==1
drop firm_id
sxpose, clear
local nametemp=_var1[1]
gen ticker="`nametemp'"
order ticker
drop if _n==1

forvalues j=1/7 { 
	replace _var`j'=lower(_var`j')
	local temp=_var`j'[1]
	rename _var`j' `temp'
}	
drop if _n==1
gen datenew=date(date,"MDY")
format datenew %td
drop date
rename datenew date
order date
save "$dir_inter/ADR_`i'.dta", replace
}


use "$dir_inter/ADR_1.dta", clear
forvalues i=2/27 {
append using "$dir_inter/ADR_`i'.dta"
}
foreach x in px_last px_open tot_return_index_gross_dvds px_volume px_bid px_ask {
replace `x'="" if `x'=="#n/a n/a"
destring `x', replace
}
mmerge ticker using "$dir_datasets/ADR_Static.dta"

gen data_avail=0
replace data_avail=1 if px_last~=.
bysort ticker: egen data_sum=sum(data_avail)
drop if data_sum==0
drop data_sum data_avail _merge
save "$dir_datasets/ADR_data.dta", replace


*************************
****************************
*Indices
****************************
****************************
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Bloomberg/Data/Argentina Indices.xlsx", sheet("Sheet2") allstring clear
sxpose, clear

gen n=_n
order n
gen mod5=mod(n,5)
drop if mod5==0
drop mod5 n

gen n=_n
order n
tsset n
carryforward _var1, replace
encode _var1, gen(firm_id)
order firm_id
drop n
save "$dir_inter/Indices_temp.dta", replace

forvalues i=1/63 {
use "$dir_inter/Indices_temp.dta", replace
keep if firm_id==`i'
*keep if firm_id==1

drop firm_id
rename _var1 _var1old
rename _var2 _var2old
rename _var3 _var3old
rename _var4 _var4old

sxpose, clear
local nametemp=_var1[1]
gen ticker="`nametemp'"
order ticker
drop if _n==1

forvalues j=1/4 { 
	replace _var`j'=lower(_var`j')
	local temp=_var`j'[1]
	rename _var`j' `temp'
}	
drop if _n==1
gen datenew=date(date,"MDY")
format datenew %td
drop date
rename datenew date
order date
save "$dir_inter/index_`i'.dta", replace

}

use "$dir_inter/index_1.dta", clear
forvalues i=2/63 {
append using "$dir_inter/index_`i'.dta"
}

foreach x in px_last px_open tot_return_index_gross_dvds {
replace `x'="" if `x'=="#n/a n/a"
destring `x', replace
mmerge ticker using "$dir_datasets/Nov_Indices_chars.dta"
drop if _merge==2
drop _merge
save "$dir_datasets/Nov_Indices.dta", replace
}



