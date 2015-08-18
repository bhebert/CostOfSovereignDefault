use "$apath/blue_rate.dta", clear
browse
gen quarter=qofd(date)
format quarter %tq
collapse (lastnm) px_close, by(quarter Ticker)
reshape wide px_close, i(quarter) j(Ticker) string
renpfix px_close
keep quarter ADRBlue
save "$apath/ADRBlue_quarter.dta"

use "$miscdata/GDP_inflation.dta", clear
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
label var ADRBlue_r "ADRBlue, rescaled"
label var us_cpi_r "US CPI, rescaled"
label var cpi_r "Argentina CPI, rescaled"
label var rer "Real Exchange rate, 2003q4=1"
replace Nominal_GDP=Nominal_GDP_GFD if quarter==tq(2014q3) | quarter==tq(2014q4)
gen Real_GDP_cpi=Nominal_GDP/cpi_r
*gen Real_GDP_cpi2=Nominal_GDP_GFD/cpi_r
save "$apath/rer_gdp_dataset.dta", replace
