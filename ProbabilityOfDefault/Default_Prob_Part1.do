
*SIMPLE CREDIT TRIANGLE, Composite
use "$mpath/Composite_USD.dta",  clear
keep date Spread* Recov
foreach x in "6m" "1y" "2y" "3y" "4y" "5y" "7y" "10y" "15y" "20y" "30y"{
	gen haz_tri_`x'=(Spread`x'/100)/(1-Recovery/100)
	replace haz_tri_`x'=. if haz_tri_`x'<0
	gen haz_tri_conH_`x'=(Spread`x'/100)/(1-.395)
	replace haz_tri_conH_`x'=. if haz_tri_`x'<0
	}

	gen tri_def6m=1-exp(-haz_tri_6m*.5)
	gen tri_conH_def6m=1-exp(-haz_tri_conH_6m*.5)
foreach x in 1 2 3 4 5 7 10 15 20 30 {
	gen tri_def`x'y =1-exp(-haz_tri_`x'y*`x')
	gen tri_conH_def`x'y =1-exp(-haz_tri_conH_`x'y*`x')
	}
	drop Spread* Recov
	keep if year(date)>=2011 
	keep if date<=td(30jul2014)
	save "$apath/cumdef_hazard_triangle.dta", replace
	
*SAMEDAY	
foreach y in "Europe" "NewYork" "Asia" "Japan" "London" "LondonMidday" {
	use "$mpath/Sameday_USD.dta",  clear
	keep if snaptime=="`y'"
keep date Spread* Recovery
foreach x in "6m" "1y" "2y" "3y" "4y" "5y" "7y" "10y" "15y" "20y" "30y"{
	gen haz_tri_`x'=(Spread`x'/100)/(1-Recovery/100)
	replace haz_tri_`x'=. if haz_tri_`x'<0
	gen haz_tri_conH_`x'=(Spread`x'/100)/(1-.395)
	replace haz_tri_conH_`x'=. if haz_tri_`x'<0
	}

	gen tri_def6m=1-exp(-haz_tri_6m*.5)
	gen tri_conH_def6m=1-exp(-haz_tri_conH_6m*.5)
foreach x in 1 2 3 4 5 7 10 15 20 30 {
	gen tri_def`x'y =1-exp(-haz_tri_`x'y*`x')
	gen tri_conH_def`x'y =1-exp(-haz_tri_conH_`x'y*`x')
	}
	drop Spread* Recov
	keep if year(date)>=2011 
	keep if date<=td(30jul2014)
	save "$apath/cumdef_hazard_triangle_`y'.dta", replace
	}

*JUST GET THE ARGENTINE DATA
*Clean the zero curve, swaps
import excel "$mainpath/Markit/Prob of Default/Swap_Rates.xls", sheet("Daily") firstrow clear
drop USD3
order DATE  USD6 DSWP1  DSWP3  DSWP4 DSWP5 DSWP7 DSWP10 DSWP30
rename DATE date
save "$apath/swaprates.dta", replace

*Import the US TREASURY ZEROS
import excel "$mainpath/Markit/Prob of Default/GSW_Zero_Curve.xlsx", sheet("Yields") firstrow clear
rename date datestr
gen date=date(datestr,"YMD")
order date
format date %td
drop datestr
save "$apath/UST_Zero.dta", replace

***
use  "$mpath/Composite_USD.dta", clear
*mmerge date using "$mpath/Sameday_USD.dta"
*mmerge date using "$mpath/Sameday_FC_USD.dta"
*keep if _merge==3
*Credit triangle approximation on page 11 of OpenGamma
*foreach x in 1 2 3 4 5 7 10 15 30 {
*	gen hazard`x'=(Spread`x'y/100)/(1-Recovery/100)
*	}
*	twoway (line hazard1 date, sort) if year(date)>=2012
*		twoway (line hazard5 date, sort) if year(date)>=2012
keep date Spread* Recovery
mmerge date using "$apath/swaprates.dta"
order date Recovery
drop _merge
gen datenum=date
order datenum date 
drop date
keep if year(date)>=2011 
keep if date<=td(30jul2014)
tsset date
foreach x in USD6MTD156N DSWP1 DSWP3 DSWP4 DSWP5 DSWP7 DSWP10 {
replace `x'=. if DSWP30==0
}
replace DSWP30=. if DSWP30==0
tsset date
foreach x in USD6MTD156N DSWP1 DSWP3 DSWP4 DSWP5 DSWP7 DSWP10 DSWP30 {
carryforward `x', replace
}
*export excel using "$mainpath/Markit/Prob of Default/Matlab_spreads_zero.xls", replace 
export delimited using "$apath/Matlab_spreads_zero.csv", replace novarnames

format date %td
gen month=mofd(date)
format month %tm
order month
collapse (mean) Recov *Spread*  USD* DSWP*, by(month)
gen date=dofm(month)
order date
drop month
export delimited using "$apath/Matlab_spreads_zero_month.csv", replace novarnames


***************
*SameDay*******
***************
foreach y in "Europe" "NewYork" "Asia" "Japan" "London" "LondonMidday" {
use  "$mpath/Sameday_USD.dta", clear
keep if snaptime=="`y'"
keep date Spread* Recovery
mmerge date using "$apath/swaprates.dta"
order date Recovery
drop _merge
gen datenum=date
order datenum date 
drop date
keep if year(date)>=2011 
keep if date<=td(30jul2014)
tsset date
foreach x in USD6MTD156N DSWP1 DSWP3 DSWP4 DSWP5 DSWP7 DSWP10 {
replace `x'=. if DSWP30==0
}
replace DSWP30=. if DSWP30==0
tsset date
foreach x in USD6MTD156N DSWP1 DSWP3 DSWP4 DSWP5 DSWP7 DSWP10 DSWP30 {
carryforward `x', replace
}

order datenum Recovery Spread6m Spread1y Spread2y Spread3y Spread4y Spread5y Spread7y Spread10y Spread15y Spread20y Spread30y
export delimited using "$apath/Matlab_`y'_zero.csv", replace novarnames
}

****************************************
*DATASET USING US TREASURY TO DISCOUNT
****************************************

use  "$mpath/Composite_USD.dta", clear
keep date Spread* Recovery
mmerge date using "$apath/UST_Zero.dta"
order date Recovery
drop _merge
gen datenum=date
order datenum date 
drop date
keep if year(date)>=2011 
keep if date<=td(30jul2014)
tsset date

tsset date
forvalues x=1/9 {
carryforward SVENY0`x', replace
}
forvalues x=10/30 {
carryforward SVENY`x', replace
}

export delimited using "$apath/Matlab_spreads_zero_UST.csv", replace novarnames

*FOR SAMEDAY
foreach y in "Europe" "NewYork" "Asia" "Japan" "London" "LondonMidday" {
use  "$mpath/Sameday_USD.dta", clear
keep if snaptime=="`y'"
keep date Spread* Recovery
mmerge date using "$apath/UST_Zero.dta"
order date Recovery
drop _merge
gen datenum=date
order datenum date 
drop date
keep if year(date)>=2011 
keep if date<=td(30jul2014)
tsset date

tsset date
forvalues x=1/9 {
carryforward SVENY0`x', replace
}
forvalues x=10/30 {
carryforward SVENY`x', replace
}

*export excel using "$mainpath/Markit/Prob of Default/Matlab_spreads_zero_UST.xls", replace 
export delimited using "$apath/Matlab_`y'_spreads_zero_UST.csv", replace novarnames
}


**************
*JUNE 16******
**************
use  "$mpath/Sameday_USD.dta", clear
keep if date==td(16jun2014)
keep date Spread* Recovery time_est
mmerge date using "$apath/swaprates.dta"
keep if _merge==3
order date Recovery
drop _merge
gen datenum=date
order datenum date 
drop date
keep if year(date)>=2011 
keep if date<=td(30jul2014)

order datenum Recovery Spread6m Spread1y Spread2y Spread3y Spread4y Spread5y Spread7y Spread10y Spread15y Spread20y Spread30y 
order time_est, last
export delimited using "$apath/Matlab_June16.csv", replace novarnames


**************************************************
*GO TO MATLAB, USE DefProb_Bootstrap.m
**************************************************

