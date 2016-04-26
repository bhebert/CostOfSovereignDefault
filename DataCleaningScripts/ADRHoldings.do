*Clean ADR Data

import excel "$miscdata/ADR_ownership/BloombergArgADRHolders_update.xlsx", sheet("2014Select")  clear
foreach x of varlist _all {
	local temp=`x'[1]
	label var `x' "`temp'"
	}
rename A ticker
rename B name
rename C portfolioname
rename D adrshares_2014q1
rename E adrshares_2014q2
rename F ds_float_2014q1
rename G ds_float_2014q2
rename H bb_adr_share_2014q1
rename I bb_adr_share_2014q2
drop if _n==1
foreach x in adrshares_2014q1 adrshares_2014q2 ds_float_2014q1 ds_float_2014q2 bb_adr_share_2014q1 bb_adr_share_2014q2 {
	destring `x', force replace
	}

collapse (sum) adr* (firstnm) ds* bb*, by(ticker)
gen asf_2014q1=ds_float_2014q1*bb_adr_share_2014q1/100
gen asf_2014q2=ds_float_2014q2*bb_adr_share_2014q2/100
gen ratio_q1=adrshares_2014q1/asf_2014q1
gen ratio_q2=adrshares_2014q1/asf_2014q1


***************************
*Cleaning the Factset data*
***************************
*foreach x in "BMA-US" "CRESY-US" "EDN-US" "BFR-US" "PAM-US" "GGAL-US" "IRS-US" "PZE-US" "TEO-US" "IRCP-US" "TGS-US" "YPF-US"
import excel "$miscdata/ADR_ownership/FactsetOwnership.xlsx", sheet("BMA-US") clear
drop if _n<=4

local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
}	
save "$miscdata/ADR_ownership/temp/BMA.dta", replace

use 











