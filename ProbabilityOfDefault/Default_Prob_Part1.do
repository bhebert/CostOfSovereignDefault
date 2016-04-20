*Bloomberg and DS credit triangles. 
tempfile bbds
set more off
local recov=.395
local tenor=5
use "$mainpath/CDS Comparison/CDS_Merged.dta", clear
keep if type=="close"
keep date BB_CBGN DS 
rename BB bb
rename DS ds
gen dsfix=ds
replace dsfix=. if date>=td(15oct2013) & date<=td(01dec2013)
foreach x in bb ds dsfix  {
	gen haz_tri_`x'=(`x'/10000)/(1-`recov') 
	replace haz_tri_`x'=. if haz_tri_`x'<0
	gen tri_`x'=1-exp(-haz_tri_`x'*`tenor')
}	
	keep if year(date)>=2011 
	keep if date<=td(30jul2014)
keep date tri* haz*
foreach x in haz_tri_bb tri_bb haz_tri_ds tri_ds haz_tri_dsfix tri_dsfix {
	rename `x' `x'_5y
}	
keep date tri*
save "$apath/triangle_bbds.dta", replace


*SIMPLE CREDIT TRIANGLE, Datastream, Bloomberg
set more off
use "$apath/Datastream_CDS",  clear
local Recov=.395
foreach x in "1y" "2y" "3y" "4y" "5y" {
	gen haz_tri_`x'=(cdsds_`x'/10000)/(1-`Recov')
	replace haz_tri_`x'=. if haz_tri_`x'<0
	}
foreach x in 1 2 3 4 5  {
	gen tri_def`x'y =1-exp(-haz_tri_`x'y*`x')
	}
	drop cds*
	keep if year(date)>=2011 
	keep if date<=td(30jul2014)
	save "$apath/cumdef_hazard_triangle_ds.dta", replace
	
	
*Bloomberg
set more off
use "$apath/Bloomberg_CDS",  clear
local Recov=.395
foreach x in "1y" "2y" "3y" "4y" "5y" {
	gen haz_tri_`x'=(cdsbb_`x'/10000)/(1-`Recov')
	replace haz_tri_`x'=. if haz_tri_`x'<0
	}
foreach x in 1 2 3 4 5  {
	gen tri_def`x'y =1-exp(-haz_tri_`x'y*`x')
	}
	drop cds*
	keep if year(date)>=2011 
	keep if date<=td(30jul2014)
	save "$apath/cumdef_hazard_triangle_bb.dta", replace	


*SIMPLE CREDIT TRIANGLE, Composite
set more off
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
mmerge date using "$mpath/swaprates.dta"
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
mmerge date using "$mpath/swaprates.dta"
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
mmerge date using "$mpath/UST_Zero.dta"
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
mmerge date using "$mpath/UST_Zero.dta"
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


********************************
*BLOOMBERG and Datastream DATA*
********************************
foreach xx in "Bloomberg" "Datastream" {
use  "$apath/`xx'_CDS", clear
foreach x of varlist cds* {
	replace `x'=`x'/100
	}
mmerge date using "$mpath/UST_Zero.dta"
gen Recovery=39.5
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

if "`xx'"=="Bloomberg" {
export delimited using "$apath/Matlab_BBspreads_zero_UST.csv", replace novarnames
}
if "`xx'"=="Datastream" {
export delimited using "$apath/Matlab_DSspreads_zero_UST.csv", replace novarnames
}
}




**************
*JUNE 16******
**************
use  "$mpath/Sameday_USD.dta", clear
keep if date==td(16jun2014)
keep date Spread* Recovery time_est
mmerge date using "$mpath/swaprates.dta"
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

