
* This is a standard event studay with 2-day windows


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

* Names of factors
local factors SPX_ VIX_ EEMA_ IG5Yr_ HY5Yr_

* These determine the earliest and latest days to use for non-events
local mindate = mdy(1,1,2011)
local maxdate = mdy(1,1,2015)

set more off


use "$apath/ThirdAnalysis.dta", clear


* The code below is copied from RigobonSack_v3.do

gen eventvar = .
drop if ~regexm(day_type,"twoday")
replace eventvar = event_day
local clause mod(dayindex,2)==0 &

gen nonevent = `clause' eventvar == 0 & (L.eventvar == 0 | L.eventvar == .) & (F.eventvar == 0 | F.eventvar == .)
* Exclusions were defined earlier. This implements them.

if `exclusions' == 1 {

	gen excludedday = eventexcluded == 1 | L.eventexcluded == 1 | F.eventexcluded == 1
	
	replace nonevent = 0 if excludedday
	replace eventvar = 0 if excludedday
	
}

replace nonevent = 0 if nonevent == 1 & (date < `mindate' | date > `maxdate')

drop if eventvar == 0 & nonevent == 0
drop if return_ == . | cds_ == .


* Generate missing dummies for factors, so we don't drop
* any days where only the factors are missing.
local factors2 `factors'
foreach ft in `factors' {
	gen `ft'_missing = `ft' == .
	replace `ft' = 0 if `ft'_missing == 1
	local factors2 `factors2' `ft'_missing
}

*** done with setup code. 

* Classify events

* Predict CDS residuals.
reg cds_ `factors2' if (nonevent == 1 & regexm(industry_sector,"INDEX"))
predict cdsresids, residuals
local cds_sd = `e(rmse)'

su cds_ cdsresids if eventvar == 1

* Classify shocks based on CDS residuals.
gen shocktype = .

replace shocktype = 1 if  eventvar == 1 & -cdsresids >= `threshold'*`cds_sd'
replace shocktype = -1 if eventvar == 1 & cdsresids >= `threshold'*`cds_sd'
replace shocktype = 0 if eventvar == 1 & cdsresids < `threshold'*`cds_sd' & cdsresids > -`threshold'*`cds_sd'



sort firmname date
levelsof firmname, local(industries)

gen L1 = .
gen resids = .
gen resid_zs = .
gen sdevs = .



foreach ind_name in `industries' {
	disp "Industry: `ind_name'"

	* Build the factor model for returns
	reg return_ `factors2' if (nonevent == 1 & regexm(firmname,"`ind_name'"))
	
	* Save the sample size and error rmse
	replace L1 = `e(N)' if regexm(firmname,"`ind_name'")
	replace sdevs = `e(rmse)' if regexm(firmname,"`ind_name'")
	
	* Generate abnormal returns
	predict temp if regexm(firmname,"`ind_name'"), residuals
	
	* Save the abnormal returns and z-scores.
	replace resids = temp if regexm(firmname,"`ind_name'")
	replace resid_zs = resids / sdevs if regexm(firmname,"`ind_name'")

	drop temp
	
}


* Generate cumulative abnormal returns, CDS changes, Z-scores, and variances
* by whether the shock was up, down, or unclear
sort ind_id shocktype date
by ind_id shocktype: egen N = count(resid_zs)
by ind_id shocktype: egen CAR = sum(resids)
by ind_id shocktype: egen DCDS = sum(cdsresids*(resid_zs!=.))
by ind_id shocktype: egen Vest = sum(sdevs*sdevs/N/N*(resid_zs!=.))
by ind_id shocktype: egen J2 = mean(resid_zs)

* Compute the J1 and J2 stats defined in CLM textbook
replace J2 = J2 * sqrt(N*(L1-4)/(L1-2))
gen J1 = CAR / sqrt(Vest) / N


* Get rid of extra data and save the results.
drop if shocktype == .
collapse (mean) N CAR DCDS J1 J2, by(firmname shocktype)

sort shocktype firmname

export excel using "$rpath/StandardEventStudy.xls", firstrow(variables) replace
keep if firmname=="INDEX_US"
export excel using "$rpath/StandardEventStudy_Index.xls", firstrow(variables) replace
