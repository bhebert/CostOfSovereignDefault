*Bond level data]
set more off

*Cleaning exchange rate data
tempfile eur bondtemp
import excel "$csd_data/GFD/EURUSD_20150914_excel2007.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
format date %td
keep  date Close
rename Close eur
tsset date
tsfill
carryforward eur, replace
save "`eur'", replace


*Cleaning Bloomberg data
*global dir_inter "~/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate"
*global dir_datasets "~/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets"
tempfile Gov_time_series

set more off
local stale_thresh=.2
import excel "$bbpath/Data/Debt_Securities.xlsx", sheet("Gov_all") firstrow clear
foreach x in Bond Name ISSUE_DT maturity market_issue ID_ISIN currency COLLECTIVE_ACTION_CLAUSE GOVERNING_LAW Defaulted cpn_typ CREDIT_EVENT_RESTRUCTURING AMT_OUTSTANDING AMT_ISSUED INFLATION_LINKED_INDICATOR security_typ CNTRY_ISSUE_ISO {
local temp=lower("`x'")
rename `x' `temp'
}

drop credit_eve governing security_t cntry
destring amt_issued, replace force
gen issue_date=date(issue_dt,"MDY")
format issue_date %td
gen mat_date=date(maturity,"MDY")
format mat_date %td
replace issue_dt="9/30/2009" if id_isin=="XS0501195993"
*http://www.boerse-frankfurt.de/en/bonds/argentina+10+38+pars+XS0501195993
replace issue_dt="9/24/2009" if id_isin=="XS0501196025"
*http://www.bondpdf.com/bonds/XS0501196025
replace issue_dt="4/1/2005" if id_isin=="ARARGE03E659"
*http://isin1.findex.com/ARARGE03E659-ARGENTINA-2005-G-R-31-12-38-S-8.php
replace issue_dt="4/1/2005" if id_isin=="ARARGE03E667"
*http://isin1.findex.com/ARARGE03E667-ARGENTINA-2005-G-R-31-12-33-S-9.php
replace issue_dt="6/25/2010" if id_isin=="XS0501195720"
*http://em.cbonds.com/emissions/issue/88549
replace issue_dt="" if id_isin=="ARARGE03E642"
*http://em.cbonds.com/emissions/issue/95707
replace issue_dt="4/15/2010" if id_isin=="ARARGE03G712"
*http://em.cbonds.com/emissions/issue/95799
replace issue_dt="1/20/2005" if id_isin=="ARARGE03E634"
*http://em.cbonds.com/emissions/issue/95771
*replace issue_dt="" if id_isin=="ARP04981AA75"
drop if issue_dt==""
drop issue_dt maturity
gen ticker=subinstr(bond," Corp","",.)
order ticker
save "$apath/Gov_bonds_static.dta", replace

import excel "$bbpath/Data/Debt_Securities.xlsx", sheet("Gov_Prices_Value")  allstring clear
foreach x of varlist _all {
tostring `x', replace
	if `x'[3]=="" | `x'[3]=="#N/A N/A" | `x'[3]=="#N/A" {
		drop `x'
		}
		}
local i=1
foreach x of varlist _all {		
	rename `x' v`i'
	local i=`i'+1
	}		
local ii=`i'-2		
save "`Gov_time_series'", replace

*STOPPED HERE
forvalues i=1(3)`ii' {
use "`Gov_time_series'", clear
local y=`i'+1
local z=`i'+2
keep v`i' v`y' v`z'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Corp","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' ytm_mid
rename v`z' px_last
drop if _n==1 | _n==2
local x=`z'/3
save "$apath/govbond_`x'.dta", replace
}	



use "$apath/govbond_1.dta", clear
forvalues i=2/131 {
append using "$apath/govbond_`i'.dta"
}
rename date datestr
gen date=date(datestr,"MDY")
format date %td
order date
drop datestr
destring ytm_mid, replace force
destring px_last, replace force
drop if date==.
mmerge ticker using "$apath/Gov_bonds_static.dta"
keep if _merge==3

gen exchange_bond=0
replace exchange_bond=1 if issue_date==td(29nov2005)
replace exchange_bond=1 if issue_date==td(02jun2010)

bysort ticker: egen obscount=count(px_last)
drop if id_isin=="#N/A Field Not Applicable"

gen bdate = bofd("basic",date)
format bdate %tbbasic
encode ticker, gen(tid)
tsset tid bdate
sort tid bdate


/*CALCULATE HOLDOUTS
drop if exchange_bond==1
drop if market_issue=="DOMESTIC"
collapse (firstnm) bb_ticker ticker bond name market_issue  currency collective_action_clause defaulted cpn_typ amt_outstanding amt_issued inflation_linked_indicator issue_date mat_date, by(id_isin)
save "$miscdata/Holdout Bonds/Bond_Characteristics.dta"
*/

gen nml_bond = regexm(id_isin,"FB19") | regexm(id_isin,"4GB0")

gen stale_ind=0
replace stale_ind=1 if px_last==l.px_last
bysort tid: egen stale_ratio=sum(stale_ind)
replace stale_ratio=stale_ratio/obscount

keep if stale_ratio<.25 | nml_bond==1 | id_isin=="XS0501195480"

sort tid bdate
gen px_change=100*log(px_last/l.px_last)
gen px_change2=100*log(px_last/l2.px_last)


tostring exchange_bond, replace
gen stale_ratio_str=round(stale_ratio*1000)
tostring stale_ratio_str, replace
gen ticker_exch=ticker+"_"+exchange_bond+"_"+curr+"_"+stale_ratio_str
sort ticker date



*KEEP EURO AND DOLLAR BONDS with at least 500 days
drop if obscount<500 & (nml_bond == 0)
levelsof(ticker_exch), local(tickid)
discard
/*foreach x of local tickid {
	twoway (line px_last date) if ticker_exch=="`x'" & date>=td(01jan2011) & date<=td(30jul2014), title("`x'") name("`x'")
	graph export "$rpath/`x'.png", replace
	}
*/	
	*usable restructured bond is EI233619
	*most frequently traded defaulted is EC131761 
	keep if ticker=="EI233619" | ticker=="EC131761" | id_isin=="US040114GK09" | nml_bond == 1 | id_isin=="XS0501195480"
	replace ticker="rsbond_usd_disc" if ticker=="EI233619"
	replace ticker="defbond_eur" if ticker=="EC131761"
	replace ticker="NMLbond2030" if ticker=="EC273735"
	replace ticker="NMLbond2020" if ticker=="EC221478"
	replace ticker="rsbond_usd_par" if id_isin=="US040114GK09"
	replace ticker="global17" if id_isin=="XS0501195480"

		mmerge date using "`eur'"
	replace px_last=px_last/eur if ticker=="defbond_eur"
	drop eur

	//twoway (line ytm_mid date if ticker=="rsbond_usd_disc") (line ytm_mid date if ticker=="NMLbond2030"), legend(order(1 "Restructured" 2 "Holdout")) ytitle("YTM")
	//graph export "$rpath/bond_ytm_compare.png", replace
	twoway (line px_last date if ticker=="rsbond_usd_disc") (line px_last date if ticker=="NMLbond2030"), legend(order(1 "Restructured" 2 "Holdout")) ytitle("Price")
	graph export "$rpath/bond_px_compare.png", replace
	
	save "`bondtemp'"
	drop if ticker=="global17" 
	keep date px_last ticker
	rename px_last px_close
	gen px_open=.
	gen total_return=px_close
	gen market="Index"
	gen industry_sector=ticker
	rename ticker Ticker
	save "$apath/bondlevel.dta", replace
	
use "`bondtemp'", clear	
keep date px_last ticker ytm_mid
keep if ticker=="rsbond_usd_disc" | ticker=="global17" 
reshape wide ytm px, i(date) j(ticker) string 
rename px_lastrs rsbond
rename ytm_midrs rsbondy
rename px_lastg g17
gen g17_fixed=g17
replace g17_fixed=. if date>=td(08nov2011) | date<=td(04may2012)
rename ytm_midg g17y
gen logrsbond=log(rsbond)
gen logg17=log(g17)
mmerge date using "$apath/GSW_Data.dta", ukeep(svenpy05 svenpy18 svenpy19 svenpy20)
drop if _merge==2
gen rsbondys=rsbondy-svenpy20
gen g17ys=g17y-svenpy05
drop sven* _merge
save "$apath/bond_dprob_merge.dta", replace

use "$apath/eurotlx.dta", clear
keep if Ticker=="eurotlx"
gen log_g17px_eurotlx = log(px_open)
keep date log_g17px_eurotlx

mmerge date using "$apath/bond_dprob_merge.dta", unmatched(using)
drop _merge

sort date

save "$apath/bond_dprob_merge.dta", replace


keep date logg17 log_g17px_eurotlx g17y

rename g17y yieldbbg
rename logg17 logpricebbg
rename log_g17px_eurotlx logpriceeurotlx

reshape long yield logprice, i(date) j(source) string

reg yield c.logprice##c.logprice##c.logprice##c.date if date <= mdy(7,31,2014)
predict pyield

drop if source=="bbg"
drop if pyield==.
keep date pyield
rename pyield g17y_eurotlx
mmerge date using "$apath/bond_dprob_merge.dta", unmatched(using)

gen g17ys_eurotlx = g17y_eurotlx - g17y + g17ys

save "$apath/bond_dprob_merge.dta", replace


