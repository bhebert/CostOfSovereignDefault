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

gen bdate = bofd("basic",date)
format bdate %tbbasic
encode ticker, gen(tid)

sort tid bdate
tsset tid bdate

* For each window size, compute the associated return
gen factor_intra = 100*log(close/open)
gen factor_nightbefore = 100*log(open/L.close)

gen factor_onedayN = 100*log(close / L.close)
gen factor_onedayL = 100*log(open / L.open)
gen factor_twoday = 100*log(close / L2.close)

gen factor_1_5 = factor_twoday - factor_intra


drop bdate tid open close

save "$apath/MarketFactorsNew.dta", replace
