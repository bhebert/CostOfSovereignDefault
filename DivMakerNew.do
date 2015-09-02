
set more off

foreach outcome in gdp /*ip*/ {

	use "$apath/ValueIndex_US_New.dta", clear

	if "`outcome'" == "gdp" {
		local time quarter
		local ovar Real_GDP_cpi
		//local ovar Real_GDP_SA
		local yearlen 4
	}
	else {
		local time month
		local ovar IndustrialProduction
		local yearlen 12
		
		gen month = mofd(date)
	}

	collapse (lastnm) px_close total_return DivPerShare EPS, by(`time')
	sort `time'

	*ADDING IN SOME ADDITIONAL VARIABLES
	mmerge `time' using "$apath/rer_`outcome'_dataset.dta", unmatched(master) ukeep(`ovar' ADRBlue cpi us_cpi OfficialRate)
	gen log_rer = log((ADRBlue / cpi) * us_cpi)
	gen log_orer = log((OfficialRate / cpi) * us_cpi)
	gen log_rel_cpi = log(cpi / us_cpi)
	
	sort `time'
	tsset `time'
	
	gen ValueINDEXNew_US = total_return / L.total_return
	gen div = total_return / L.total_return * L.px_close - px_close

	//gen div_real = div / us_cpi
	gen div_real = div * OfficialRate / cpi
	
	gen cum_div = sum(div_real)
	
	gen cum_ovar = sum(`ovar')
	
	gen log_annual_div = log(cum_div - L`yearlen'.cum_div)
	gen log_annual_`outcome' = log(cum_ovar - L`yearlen'.cum_ovar)
	
	drop cum_div cum_ovar
	replace log_annual_div = . if F.L`yearlen'.div_real == .
	replace log_annual_`outcome' = . if F.L`yearlen'.`ovar' == .
	
	//gen log_pd = log(px_close / us_cpi) - log_annual_div
	gen log_pd = log(px_close * OfficialRate / cpi) - log_annual_div
	
	if `yearlen' == 4 {
		gen e_real = EPS / cpi
		gen cum_e = sum(e_real)
		gen log_annual_e = log(cum_e- L`yearlen'.cum_e)
		drop cum_e
		
		replace log_annual_e = . if F.L`yearlen'.e_real == .
		
		gen log_pe = log(px_close * OfficialRate / cpi) - log_annual_e
		gen payout_ratio = exp(log_annual_div - log_annual_e)
		
		capture graph drop DivEarnDataComparison
		tsline div_real e_real if e_real != ., name(DivEarnDataComparison)
		
		capture graph drop PayoutRatio
		tsline payout_ratio, name(PayoutRatio)
		
		capture graph drop PEPD
		tsline log_pd log_pe, name(PEPD)
		
		capture graph drop `outcome'_vs_e
		twoway (tsline log_annual_`outcome') (tsline log_annual_e, yaxis(2)), name(`outcome'_vs_e) xlabel(, labsize(medium)) xtitle("") ylabel(,nogrid) graphregion(fcolor(white) lcolor(white))
	}
	
	
	su log_pd

	local mean_pd = `r(mean)'

	global rho_`time' = (exp(`mean_pd') / (exp(`mean_pd') + 1)) ^ (1/`yearlen')
	disp "rho_est: ${rho_`time'}"

	rename ADRBlue ExRate
	
	save "$apath/dataset_`outcome'.dta", replace
}

