
use "${crsp_path}/ArgentinaADRHoldings.dta", clear

append using "${crsp_path}/ArgentinaADRHoldingsCRESY.dta"

gen quarter = qofd(rdate)
format quarter %tq

keep quarter mgrname mgrno country shares ticker shrout2 prc

drop if quarter < yq(2011,1)
drop if quarter > yq(2014,2)

// would drop Argentina holdings if there were any
drop if country == "ARGENTINA"

sort ticker mgrno country

tempfile temp

save "`temp'.dta", replace

collapse (sum) shares (firstnm) shrout2, by(quarter ticker)

gen inst_perc = shares / shrout2 / 1000 * 100

sort ticker quarter

collapse (mean) inst_perc, by(ticker)

export excel using "${rpath}/InstOwnByTicker.xls", replace

use "`temp'.dta", clear

gen dollars = prc * shares

gen dollarsout = shrout2 * 1000 * prc

collapse (sum) dollars (firstnm) mgrname country, by(quarter mgrno)
replace dollars = 0 if dollars == .
collapse (mean) dollars (firstnm) mgrname country, by(mgrno)

replace dollars = dollars / 1000000

gsort - dollars

gen rank = _n

order rank mgrname country dollars mgrno

export excel using "${rpath}/TopInstitutionalOwners.xls", replace
