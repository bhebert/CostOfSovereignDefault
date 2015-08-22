
set more off

foreach outcome in gdp ip {

	use "$apath/ValueIndex_US_New.dta", clear

	if "`outcome'" == "gdp" {
		local time quarter
		local ovar Real_GDP_cpi
		local yearlen 4
	}
	else {
		local time month
		local ovar IndustrialProduction
		local yearlen 12
		
		gen month = mofd(date)
	}

	collapse (lastnm) px_close total_return, by(`time')
	sort `time'

	*ADDING IN SOME ADDITIONAL VARIABLES
	mmerge `time' using "$apath/rer_`outcome'_dataset.dta", unmatched(master) ukeep(`ovar' ADRBlue cpi us_cpi)
	gen log_rer = log((ADRBlue / cpi) * us_cpi)
	gen log_rel_cpi = log(cpi / us_cpi)
	
	sort `time'
	tsset `time'
	
	gen ValueIndex_US = total_return / L.total_return
	gen div = total_return / L.total_return * L.px_close - px_close

	gen div_real = div / us_cpi
	gen cum_div = sum(div_real)
	
	gen log_annual_div = log(cum_div - L`yearlen'.cum_div)
	drop cum_div
	replace log_annual_div = . if F.L`yearlen'.div_real == .
	
	gen log_pd = log(px_close / us_cpi) - log_annual_div
	
	su log_pd

	local mean_pd = `r(mean)'

	global rho_`time' = (exp(`mean_pd') / (exp(`mean_pd') + 1)) ^ (1/`yearlen')
	disp "rho_est: ${rho_`time'}"

	rename ADRBlue ExRate
	
	save "$apath/dataset_`outcome'.dta", replace
}

