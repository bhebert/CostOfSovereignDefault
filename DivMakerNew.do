
set more off

local best_gdp Real_GDP_cpi

foreach outcome in gdp ip {

	use "$apath/ValueIndex_US_New.dta", clear

	keep if Ticker == "ValueIndexNew"
	//keep if Ticker == "ValueAcctNew"
	
	if "`outcome'" == "gdp" {
		local time quarter
		local ovars $real_gdps
		local yearlen 4
	}
	else {
		local time month
		local ovars IndustrialProduction
		local yearlen 12
		
		gen month = mofd(date)
	}

	collapse (lastnm) px_close total_return DivPerShare DPS2 EPS EPSgrowth, by(`time')
	sort `time'

	*ADDING IN SOME ADDITIONAL VARIABLES
	mmerge `time' using "$apath/rer_`outcome'_dataset.dta", unmatched(master) ukeep(`ovars' ADRBlue cpi us_cpi OfficialRate)
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
	gen cum_div_check = sum(div_real != .)
	gen log_annual_div = log(cum_div - L`yearlen'.cum_div)
	replace log_annual_div = . if cum_div_check - L`yearlen'.cum_div_check != `yearlen'
	drop cum_div cum_div_check
	
	foreach ovar in `ovars' {
		gen cum_ovar = sum(`ovar')
		gen cum_ovar_check = sum(`ovar' != .)
		gen log_annual_`ovar' = log(cum_ovar - L`yearlen'.cum_ovar)
		replace log_annual_`ovar' = . if cum_ovar_check - L`yearlen'.cum_ovar_check != `yearlen'

		drop cum_ovar cum_ovar_check
	}
	
	//gen log_pd = log(px_close / us_cpi) - log_annual_div
	gen log_pd = log(px_close * OfficialRate / cpi) - log_annual_div
	
	if `yearlen' == 4 {
	
		gen epsgrowth_real = log(EPS / EPSgrowth / cpi * L.cpi)
		//gen epsgrowth_real = EPSgrowth * L.px_close / cpi * L.cpi
		
		gen gdp_growth = log(`best_gdp' / L.`best_gdp')
		
		gen cum_growth = sum(gdp_growth)
		gen cum_earn = sum(epsgrowth_real)
		
		gen cum_earn_check = sum(epsgrowth_real != .)
		gen cum_growth_check = sum(gdp_growth != .)
		
		replace cum_earn = . if  cum_earn_check - L`yearlen'.cum_earn_check != `yearlen'
		replace cum_growth = . if  cum_growth_check - L`yearlen'.cum_growth_check != `yearlen'
		drop cum_earn_check cum_growth_check
		
		capture graph drop growth_comp
		twoway (tsline cum_growth) (tsline cum_earn, yaxis(2)) if quarter >= yq(2003,1), name(growth_comp) xlabel(, labsize(medium)) xtitle("") ylabel(,nogrid) graphregion(fcolor(white) lcolor(white))
	
	
		gen e_real = EPS * L.px_close / cpi
		gen cum_e = sum(e_real)
		gen cum_e_check = sum(e_real != .)
		replace cum_e = . if  cum_e_check - L`yearlen'.cum_e_check != `yearlen'
	
		gen log_annual_e = log(cum_e- L`yearlen'.cum_e)
		drop cum_e cum_e_check
		
		gen log_pe = log(px_close * OfficialRate / cpi) - log_annual_e
		gen peratio = exp(log_pe)
		gen pdratio = exp(log_pd)
		
		gen payout_ratio = exp(log_annual_div - log_annual_e)
		
		gen div_real_acct = DivPerShare * L.px_close / cpi
		gen div_real2_acct = DPS2 * L.px_close / cpi
		
		gen cum_div_acct = sum(div_real_acct)
		gen cum_div2_acct = sum(div_real2_acct)
		gen log_annual_div_acct = log(cum_div_acct - L`yearlen'.cum_div_acct)
		gen log_annual_div2_acct = log(cum_div2_acct - L`yearlen'.cum_div2_acct)
		replace log_annual_div_acct = . if F.L`yearlen'.div_real_acct == .
		replace log_annual_div2_acct = . if F.L`yearlen'.div_real2_acct == .
		
		capture graph drop DivComparison
		tsline div_real div_real_acct div_real2_acct
		
		
		capture graph drop DivEarnDataComparison
		tsline div_real e_real if e_real != . & quarter >= yq(2003,1), name(DivEarnDataComparison)
		
		capture graph drop PayoutRatio
		tsline payout_ratio if quarter >= yq(2003,1), name(PayoutRatio)
		
		capture graph drop PEPD
		tsline log_pd log_pe if quarter >= yq(2003,1), name(PEPD)
		
		capture graph drop `best_gdp'_vs_e
		twoway (tsline log_annual_`best_gdp') (tsline log_annual_e, yaxis(2)), name(`best_gdp'_vs_e) xlabel(, labsize(medium)) xtitle("") ylabel(,nogrid) graphregion(fcolor(white) lcolor(white))
	
		capture graph drop `best_gdp'_vs_div2
		twoway (tsline log_annual_`best_gdp') (tsline log_annual_div log_annual_div_acct log_annual_div2_acct, yaxis(2)), name(`best_gdp'_vs_div2) xlabel(, labsize(medium)) xtitle("") ylabel(,nogrid) graphregion(fcolor(white) lcolor(white))
	
		su pdratio peratio
		
		su pdratio peratio if quarter == yq(2010,4)

	}
	
	
	su log_pd

	local mean_pd = `r(mean)'

	
	
	global rho_`time' = (exp(`mean_pd') / (exp(`mean_pd') + 1)) ^ (1/`yearlen')
	disp "rho_est: ${rho_`time'}"

	rename ADRBlue ExRate
	
	save "$apath/dataset_`outcome'.dta", replace
}

