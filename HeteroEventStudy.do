

* This file implements the heterogenous time size event study.

* Standard deviations needed to classify events
* Suppose threshold is 1. Then CDS moves >1 SD will be "up" days
* and CDS moves <1 SD will be "down" days
* Events must be signed for the purpose of pooling them.
* In theory, we could negate the returns on the "up" events, and 
* pool them with the down events. I'm not so sure about this, though.
* In Campbell, Lo, and MacKinlay, they just split them 3 ways for
* earnings announcements.
local threshold 1

* Whether or not to exclude days for which there are both legal and non-legal
* events, or holidays.
local exclusions 1


//local example_sec INDEX_US
local example_sec ValueINDEXNew_US


local use_singlenames 0

* Factor names to control for.
* Why aren't HY/IG turned on? no open/close data
//local factors  SPX_ VIX_ EEMA_ // HY5Yr_ IG5Yr_
local factors $all_factors

set more off


use "$apath/ThirdAnalysis.dta", clear


* The datastream and official rate can't be used for this analysis
* neither can Brazil or Mexico. The issue is no open/close data, just close to close.
//drop if regexm(industry_sector,"DSBlue") | regexm(industry_sector,"OfficialRate") | regexm(industry_sector,"Brazil") | regexm(industry_sector,"Mexico") | regexm(industry_sector,"ADRMinusDS")


// Right now, this cannot be run, because it is misssing open/close data.
//drop if regexm(firmname,"INDEX_US")

sort ind_id date daynum
by ind_id: egen icount = sum( return_ != . & day_type == "intra")
drop if icount == 0

if `use_singlenames' == 0 {
	drop if isstock == 1 & ports == 0
}

gen shocktype = .

sort ind_id daynum date


levelsof firmname, local(industries)

levelsof day_type if event_ == 1, local(dtypes)

gen L1 = .
gen resids = .
gen resid_zs = .
gen sdevs = .
gen cds_resids = .
gen cds_sdevs = .
gen exclude = (eventexcluded == 1)*`exclusions'

* Generate missing dummies for factors so we don't drop event dates.

local factors2 `factors'
foreach ft in `factors' {
	gen `ft'_missing = .
	local factors2 `factors2' `ft'_missing
}

* We start by looping through different event types.
* For example, we might have both 1day and 2day events, or
* something even more fine-grained. In other words, each calendar
* day has returns and event dummies for multiple window sizes.
* This depends on what was done in the SecondAnalysis.do file.

foreach dt in `dtypes' {

	disp "dt: `dt'"

	* The information on whether factor returns are missing
	* needs to be produced for each day type,
	* because some returns could be missing while others are not.
	foreach ft in `factors' {
		replace `ft'_missing = `ft' == . if day_type == "`dt'"
		replace `ft' = 0 if `ft'_missing == 1 & day_type == "`dt'"
	}
	
	* We predict CDS excess returns, which we will use to classify events.
	* The classification depends on the volatility of the CDS for that kind of
	* day (1-day, 2-day, etc...)
	reg cds_ `factors2' if (event_ == 0 & day_type == "`dt'" & regexm(firmname,"`example_sec'") & exclude == 0)
	
	local cds_sd = `e(rmse)'
	predict temp if day_type == "`dt'", residuals
	replace cds_resids = temp if day_type == "`dt'"
	drop temp
	replace cds_sdevs = `cds_sd' if day_type == "`dt'"
	
	disp "cds_sd: `cds_sd'"

	replace shocktype = 1 if event_ == 1 & -cds_resids >= `threshold'*`cds_sd' & day_type == "`dt'"
	replace shocktype = -1 if event_ == 1 & cds_resids >= `threshold'*`cds_sd' & day_type == "`dt'"
	replace shocktype = 0 if event_ == 1 & cds_resids < `threshold'*`cds_sd' & cds_resids > -`threshold'*`cds_sd' & day_type == "`dt'"

	* Next, we loop through different industries.

	foreach ind_name in `industries' {
		disp "Industry: `ind_name' day type: `dt'"

		* Predict the return based on non-event days of that day type.
		* That is, we estimate 1 factor model for 1day returns, and another for 2day returns.
		reg return_ `factors2' if (event_ == 0 & regexm(firmname,"`ind_name'") & day_type == "`dt'" & exclude == 0)
		
		* Save the sample size and rmse.
		replace L1 = `e(N)' if regexm(firmname,"`ind_name'") & day_type == "`dt'"
		replace sdevs = `e(rmse)' if regexm(firmname,"`ind_name'") & day_type == "`dt'"
		
		* Compute the abnormal return
		predict temp if regexm(firmname,"`ind_name'") & day_type == "`dt'", residuals 
		
		* Save the abnormal return and z-score.
		* The z-score is scaled by the small sample adjustment, because that
		* small sample adjustment depends on the window size (1 day, 2day, etc..)
		* and therefore cannot be pooled across different window sizes.
		replace resids = temp if regexm(firmname,"`ind_name'") & day_type == "`dt'"
		replace resid_zs = resids / sdevs * sqrt((L1-4)/(L1-2)) if regexm(firmname,"`ind_name'") & day_type == "`dt'"

		drop temp
		
	}
	

}

ta L1

* Compute cumulative statistics by stock and up/down/nothing event.
* This pools the results across different window types.
sort ind_id shocktype date day_type
by ind_id shocktype: egen N = count(resid_zs)
by ind_id shocktype: egen CAR = sum(resids)
by ind_id shocktype: egen DCDS = sum(cds_resids*(resid_zs!=.))
by ind_id shocktype: egen Vest = sum(sdevs*sdevs/N/N*(resid_zs!=.))
by ind_id shocktype: egen J2 = mean(resid_zs)

* Compute the J1 and J2 from CLM textbook.
replace J2 = J2 * sqrt(N)
gen J1 = CAR / sqrt(Vest) / N

by ind_id shocktype: egen Nintra = count(resid_zs) if day_type=="intra"
by ind_id shocktype: egen CARintra = sum(resids) if day_type=="intra"
by ind_id shocktype: egen DCDSintra = sum(cds_resids*(resid_zs!=.)) if day_type=="intra"
by ind_id shocktype: egen Vestintra = sum(sdevs*sdevs/N/N*(resid_zs!=.)) if day_type=="intra"
by ind_id shocktype: egen J2intra = mean(resid_zs) if day_type=="intra"

* Compute the J1 and J2 from CLM textbook.
replace J2intra = J2intra * sqrt(Nintra)
gen J1intra = CARintra / sqrt(Vestintra) / Nintra


tempfile temp
save "`temp'", replace
keep if firmname=="`example_sec'"
keep if day_type=="intra"
keep if event_ == 1
keep firmname day_type date cds_resids resids sdevs cds_sdevs
export excel using "$rpath/HeteroEventStudy_IntraData.xls", firstrow(variables) replace

use "`temp'", clear

* Save the results.
drop if shocktype == .
collapse (mean) N* CAR* DCDS* J1* J2*, by(firmname shocktype)
sort shocktype firmname

order firmname shocktype N CAR DCDS J1 J2

export excel using "$rpath/HeteroEventStudy.xls", firstrow(variables) replace
keep if firmname=="`example_sec'"
export excel using "$rpath/HeteroEventStudy_Index.xls", firstrow(variables) replace

