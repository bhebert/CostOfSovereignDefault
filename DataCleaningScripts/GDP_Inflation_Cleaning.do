set more off
tempfile monthtemp
*Inflation
/*import excel "$miscdata/Inflation/PriceStats_Argentina_monthly_series_Oct2015.xlsx", sheet("Pricestats_Argentina_monthly_se") firstrow clear
tostring TRADE_DATE, replace
gen date=date(TRADE_DATE,"YMD")
format date %td
order date
drop TRADE
rename Argentina ps_inflation
gen month=mofd(date)
format month %tm
save "$miscdata/Inflation/ps_daily.dta", replace

use  "$miscdata/Inflation/ps_daily.dta", clear
bysort month: egen max_date=max(date)
keep if date==max_date
drop date max_date
save "$miscdata/Inflation/ps_month.dta", replace
*/

import excel "$miscdata/Inflation/GFD Inflation.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
format date %td
gen month=mofd(date)
format month %tm
drop Date Ticker date
order month
tsset month
save "`monthtemp'", replace

use "$miscdata/PriceStatsAlberto/pricestats_index_ARGENTINA/pricestats_index_ARGENTINA.dta", clear
replace date=date-1
drop month day year
gen month=mofd(date)
format month %tm
order month
drop date
rename index psa_index
rename cpi psa_offcpi
summ month, detail
local ps_start=r(min)
mmerge month using "`monthtemp'"
sort month
foreach x in psa_index psa_offcpi cpi {
	gen `x'_start=`x' if month==`ps_start'
	egen `x'_start2=max(`x'_start)
	replace `x'=`x'/`x'_start2
	drop `x'_start `x'_start2
}	
replace cpi=psa_index if month>=`ps_start'	
drop psa* _merge
gen inflation=((cpi-l.cpi)/l.cpi)*100
gen inflation_log=(ln(cpi)-ln(l.cpi))*100

keep cpi month inflation inflation_log
gen day=dofm(month)
gen quarter=qofd(day)
format quarter %tq
gen year=yofd(day)
drop day
keep if month>=tm(1995m1)
sort month
save "$apath/inflation_month.dta", replace

use "$apath/inflation_month.dta", clear
*drop if year==2015
collapse (lastnm) cpi , by(quarter)
tsset quarter
gen inflation=((cpi-l.cpi)/l.cpi)*100
save "$apath/inflation_quarter.dta", replace


use "$apath/inflation_month.dta", clear
collapse (lastnm) cpi , by(year)
drop if year==2015
tsset year
gen inflation=((cpi-l.cpi)/l.cpi)*100
save "$apath/inflation_year.dta", replace
*gen inf_test=100*(cpi-l.cpi)/(l.cpi)
*gen inf_log_test=100*(ln(cpi)-ln(l.cpi))



import excel "$miscdata/Inflation/USA_Inflation.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
format date %td
gen month=mofd(date)
format month %tm
gen year=yofd(date)
gen quarter=qofd(date)
format quarter %tq
drop Date Ticker  date
order month
tsset month
keep if month>=tm(1995m1)

gen us_inflation_log=(ln(us_cpi)-ln(l.us_cpi))*100
save "$apath/us_inflation_month.dta", replace

use "$apath/us_inflation_month.dta", clear
drop if year==2015
collapse (sum) us_inflation_log (lastnm) us_cpi, by(quarter)
tsset quarter
save "$apath/us_inflation_quarter.dta", replace


*GDP Cleaning, IFS
import excel "$miscdata/IFS/Data.xlsx", sheet("DATA") firstrow clear
gen var=""
replace var="Nominal_GDP" if ConceptCode=="NGDP"
replace var="Real_GDP" if ConceptCode=="NGDP_R"
replace var="GDP_Deflator" if ConceptCode=="NGDP_D"
drop Concept* Country* DataSou* Statu* Freq*
gen quarter=quarterly(TimeCode,"YQ")
format quarter %tq

drop if var=="Real_GDP" & UnitCode=="NC1993AA" | UnitCode=="F"
gen unit=""
replace unit="Index_2010" if UnitCode=="IND2010"
replace unit="ARS" if UnitCode=="NAA"
drop Unit* Time*
rename Val value
order quarter var val unit
replace value=value/1000 if var=="Nominal_GDP"
save "$apath/IFS_GDP.dta", replace

*GDP, GFD
import excel "$miscdata/GFD_Argentina_GDP.xlsx", sheet("Price Data") firstrow clear
gen date=date(Date,"MDY")
format date %td
gen quarter=qofd(date)
format quarter %tq
order quarter 
drop date Date
gen var="Nominal_GDP_GFD"
rename Close value
drop Ticker
gen unit="ARS"
save "$apath/GDP_GFD.dta", replace

use "$apath/IFS_GDP.dta", clear
append using "$apath/GDP_GFD.dta"
replace value=value/1000000 if var=="Nominal_GDP" | var=="Nominal_GDP_GFD"
drop unit
reshape wide value, i(quarter) j(var) string
renpfix value
label var GDP_Deflator "GDP Deflator (Index, IMF)"
label var Nominal_GDP "Nominal GDP (ARS, IMF)"
label var Nominal_GDP_GFD "Nominal GDP (ARS, GFD)"
label var Real_GDP "Real GDP (Index, GFD)"
tsset quarter

foreach x in GDP_Deflator Nominal_GDP Nominal_GDP_GFD Real_GDP {
gen `x'_change=100*(log(`x')-log(l.`x'))
}

mmerge quarter using "$apath/us_inflation_quarter.dta"
mmerge quarter using "$apath/inflation_quarter.dta"
drop _merge
*rename us_inflation_log us_inflation
*rename inflation_log inflation
save "$apath/GDP_inflation.dta", replace
