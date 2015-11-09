
set more off

* Implement Lamont-2001 style tracking returns

local factors SPX

local forecast_years 3
local nw_years 1

foreach outcome in gdp ip {

	use "$apath/monthly_controls.dta", clear
	
	if "`outcome'" == "gdp" {
		local time quarter
		local ovar Real_GDP_cpi
		gen quarter = qofd(dofm(month))
		collapse (sum) SPX VIX emasia hybonds igbonds oil soybean, by(`time')
		local yearlen 4
		local timecut quarter > tq(2002,4)
	}
	else {
		local time month
		local ovar IndustrialProduction
		local yearlen 12
		local timecut month > tm(2002m12)
	}
	disp "`ovar' `time'"
	
	local forlen = `forecast_years' * `yearlen'
	local nw_len = `nw_years' * `yearlen'
	
	mmerge `time' using "$apath/dataset_`outcome'.dta", unmatched(both)

	//drop if `timecut'
	
	sort `time'
	tsset `time'

	gen log_outcome = log(`ovar')

	gen outcome_growth = (F`forlen'.log_outcome - log_outcome)

	gen log_exrate = log(ExRate)

	//newey gdp_growth ret `factors' L.S4.log_rgdp L.log_pd if quarter > tq(2002,4), lag(4)

	keep if `timecut'
	
	sort `time'
	tsset `time'

	capture drop ADRBlue
	gen ADRBlue = D.log_exrate
	
	ivreg2 outcome_growth ValueINDEXNew_US ADRBlue `factors' L.S`yearlen'.log_outcome L.log_pd L.log_rer if `timecut', robust bw(`nw_len')

	matrix temp = e(b)
	matrix `outcome'_tracking_b=temp[1,1..2]'
	//matrix list `outcome'_tracking_b
	//matrix list e(b)
	matrix temp = e(V)
	matrix `outcome'_tracking_V=temp[1..2,1..2]
	//matrix list `outcome'_tracking_V
	//matrix list e(V)
	
		matrix rownames `outcome'_tracking_b = ValueINDEXNewGDP_US GDPExRate
		matrix rownames `outcome'_tracking_V = ValueINDEXNewGDP_US GDPExRate
		matrix colnames `outcome'_tracking_V = ValueINDEXNewGDP_US GDPExRate
}











