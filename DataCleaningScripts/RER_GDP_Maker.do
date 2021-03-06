set more off

*global real_gdps Real_GDP_cpi Real_GDP_cpigfd Real_GDP_defl Real_GDP_official gdpr_cpipseiu gdpr_cpicalc gdpr_wage gdpr_ppi gdpr_gfd gdpr_nsa_eiu gdpr_sa_eiu gdpr_indec gdpr_ifs
global  real_gdps  Real_GDP_cpi gdpr_indec gdpr_ifs

use "$apath/blue_rate.dta", clear
browse
gen quarter=qofd(date)
format quarter %tq
collapse (lastnm) px_close, by(quarter Ticker)
reshape wide px_close, i(quarter) j(Ticker) string
renpfix px_close

keep quarter ADRBlue OfficialRate
replace OfficialRate = 1 if quarter < yq(2001,4)
replace OfficialRate = ADRBlue if quarter >= yq(2001,4) & quarter <= yq(2007,3)

save "$apath/ADRBlue_quarter.dta", replace

use  "$miscdata/GDP_November2015/GDP_CPI_November2015.dta", clear
mmerge quarter using  "$apath/GDP_inflation.dta"
*TOGGLE ON TO USE SEASONALLY ADJUST DATA
mmerge quarter using "$csd_dir/Seasonal/Seasonally_Adjusted_GDP.dta"
mmerge quarter using "$apath/ADRBlue_quarter.dta"
drop if quarter==tq(2015q1)
browse
order quarter ADRB
foreach x in ADRBlue us_cpi cpi {
gen temp=`x' if quarter==tq(2003q4)
egen maxtemp=max(temp)
local ltemp=maxtemp[1]
gen `x'_r=`x'/`ltemp'
drop maxtemp temp
}
gen rer_r=ADRBlue_r*us_cpi_r/cpi_r
 gen rer=ADRBlue*us_cpi/cpi

*SWITCH Nominal_GDP to Nominal_GDP_SA here.  We probably no longer want to add these 
*two extras quarters anymore.
replace Nominal_GDP=Nominal_GDP_GFD if quarter==tq(2014q3) | quarter==tq(2014q4)
*drop Nominal_GDP_GFD
gen Real_GDP_cpiold=Nominal_GDP/cpi
gen Real_GDP_cpigfd=Nominal_GDP_GFD/cpi
gen Real_GDP_defl=Nominal_GDP/GDP_Deflator
rename Real_GDP Real_GDP_official


foreach x of varlist gdpn_gfd {
*gdpn_gfd gdpn_indec are the exact same
	gen gdpr_cpipseiu=`x'/cpi_sa_eiu
	gen gdpr_cpicalc=`x'/cpi
	gen gdpr_wage=`x'/wage
	gen gdpr_ppi=`x'/ppi
}

*drop GDP_Deflator GDP_Deflator_change Nominal_GDP_change Nominal_GDP_GFD_change Real_GDP_change  _merge rer_r cpi_r ADRBlue_r us_cpi_r
label var us_cpi "US CPI"
label var us_inflation "US Inflation"
label var cpi "Argentina CPI"
label var inflation "Argentina Inflation"
label var rer "Real Exchange Rate"
label var Real_GDP_cpigfd "Argentina Real GDP (Constructed as Nominal GDP GFD/CPI)"
label var Real_GDP_defl "Argentina Real GDP (Constructed as Nominal GDP IFS/GDP Deflator)"
label var Real_GDP_official "Argentina Offical Real GDP GFD"
*drop GDP_Deflator GDP_Deflator_change Nominal_GDP_change Nominal_GDP_GFD_change Real_GDP_change  _merge rer_r cpi_r ADRBlue_r us_cpi_r
drop if quarter==. | quarter>tq(2014q4)

rename gdpr_cpicalc Real_GDP_cpi 
save "$apath/rer_gdp_dataset.dta", replace

