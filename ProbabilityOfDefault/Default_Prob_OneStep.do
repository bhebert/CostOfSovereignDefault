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
*Open Matlab and Run the Bootstrapping
**************************************************
*Declare whether user is Jesse or Ben. Jesse is 1. Ben is 2.
*test=0 means full run, test=1 is a test;
global test=0
if "$whoami"=="JesseS" {
global user=1
}

if regexm("$whoami","BenH") {
global user=2
}

cd $csd_dir/ProbabilityOfDefault
shell $matlab -nosplash -nodesktop -r "user=$user; test=$test; DefProb_Bootstrap"

***************************
*FILES NOW BACK FROM MATLAB
***************************

tempfile temp1 temp2
set more off
foreach y in "" "_europe" "_newyork" "_london" "_londonmidday" "_asia" "_japan" {

forvalues i=1/4 {
if `i'==1 {
import delimited "$apath/Bootstrap`y'_results.csv", clear
local name="cumdef_hazard`y'"
}
else if `i'==2 {
import delimited "$apath/Bootstrap`y'_resultsConH.csv", clear
local name="cumdef_hazard_ConH`y'"
}
else if `i'==3 { 
import delimited "$apath/Bootstrap`y'_results_UST.csv", clear
local name "cumdef_hazard_UST`y'"
}
else if `i'==4 { 
import delimited "$apath/Bootstrap`y'_resultsConH_UST.csv", clear
local name "cumdef_hazard_ConH_UST`y'"
}

rename v1 date
format date %td
rename v2 def6m
rename v3 def1y 
rename v4 def2y 
rename v5 def3y 
rename v6 def4y 
rename v7 def5y 
rename v8 def7y 
rename v9 def10y 
rename v10 def15y 
rename v11 def20y 
rename v12 def30y 
rename v13 haz6m
rename v14 haz1y
rename v15 haz2y 
rename v16 haz3y 
rename v17 haz4y 
rename v18 haz5y 
rename v19 haz7y 
rename v20 haz10y 
rename v21 haz15y 
rename v22 haz20y 
rename v23 haz30y
cap {
replace haz20y="" if haz20y=="Inf" | haz20y=="NaN"
}
cap {
replace haz30y="" if haz30y=="Inf" | haz30y=="NaN"
}
destring haz20y, replace
destring haz30y, replace

gen problem=0
foreach x in haz6m haz1y haz2y haz3y haz4y haz5y haz7y haz10y haz15y haz20y haz30y {
destring `x', force replace
replace problem=1 if `x'<=0 | `x'==.
}

save "$apath/`name'.dta", replace
}
}

**************************
*Bloomberg and Datastream
foreach x in "DS" "BB" {
import delimited "$apath/Bootstrap_results_`x'UST.csv", encoding(ISO-8859-1)clear
rename v1 date
format date %td
rename v2 def1y 
rename v3 def2y 
rename v4 def3y 
rename v5 def4y 
rename v6 def5y 
rename v7 haz1y
rename v8 haz2y 
rename v9 haz3y 
rename v10 haz4y 
rename v11 haz5y 
save "$apath/cumdef_`x'.dta", replace
}


***************
*June 16, 2014
import delimited "$apath/Bootstrap_June16.csv", clear
rename v1 date
format date %td
rename v2 def6m
rename v3 def1y 
rename v4 def2y 
rename v5 def3y 
rename v6 def4y 
rename v7 def5y 
rename v8 def7y 
rename v9 def10y 
rename v10 def15y 
rename v11 def20y 
rename v12 def30y 
rename v13 haz6m
rename v14 haz1y
rename v15 haz2y 
rename v16 haz3y 
rename v17 haz4y 
rename v18 haz5y 
rename v19 haz7y 
rename v20 haz10y 
rename v21 haz15y 
rename v22 haz20y 
rename v23 haz30y
rename v24 time_est
order date time_est
sort time_est
gen snaptime="Japan"
replace snaptime="Asia" if time_est==4
replace snaptime="LondonMidday" if time_est==7
replace snaptime="Europe" if time_est==9.5
replace snaptime="London" if time_est==10.5
replace snaptime="NewYork" if time_est==15.5
order date time_est snaptime haz*

gen haz_upto1=(haz6m+haz1y)/2
gen haz_1to3=(haz2y+haz3y)/2
gen haz_3to5=(haz4y+haz5y)/2
gen haz_5more=(2*haz7y+3*haz10y+5*haz15y)/10
order date time_est haz_upto1 haz_1to3 haz_3to5 haz_5more
save "$apath/cumdef_hazard_June16.dta", replace


*********
*MERGE***
*********
*THIS IS THE VERSION  CURRENTLY USED
use "$apath/cumdef_hazard.dta", 
keep date def5y
rename def5y composite_def5y
*label var europe "Cumulative Default Probability, Europe"
label var composite "Cumulative Default Probability, Composite"
save "$apath/Default_Prob.dta", replace


***********************************************
*VERSION WITH ALL OF THE DEFAULT PROBABILITIES*
***********************************************
use "$apath/cumdef_hazard_ConH.dta", clear
keep date def6m def1y def2y def3y def4y def5y def7y def10y 
foreach x in def6m def1y def2y def3y def4y def5y def7y def10y {
	rename `x' conh_`x'
}	

mmerge date using "$apath/cumdef_hazard_UST.dta", ukeep(def6m def1y def2y def3y def4y def5y def7y def10y)
foreach x in def6m def1y def2y def3y def4y def5y def7y def10y {
	rename `x' ust_`x'
}	

mmerge date using "$apath/cumdef_hazard_ConH_UST.dta", ukeep(def6m def1y def2y def3y def4y def5y def7y def10y)
foreach x in def6m def1y def2y def3y def4y def5y def7y def10y {
	rename `x' conh_ust_`x'
}	


drop _merge 

mmerge date using "$mpath/PUF_NY.dta", ukeep(Upfront*)
drop if _merge==2
save "$apath/Default_Prob_All.dta", replace

use "$apath/Default_Prob_All.dta", clear
foreach y in "_europe" "_newyork" "_london" "_londonmidday" "_asia" "_japan" {

mmerge date using "$apath/cumdef_hazard_ConH`y'.dta", ukeep(def6m def1y def2y def3y def4y def5y def7y def10y )
foreach x in def6m def1y def2y def3y def4y def5y def7y def10y {
	rename `x' conh_`x'`y'
}	

mmerge date using "$apath/cumdef_hazard_UST`y'.dta", ukeep(def6m def1y def2y def3y def4y def5y def7y def10y)
foreach x in def6m def1y def2y def3y def4y def5y def7y def10y {
	rename `x' ust_`x'`y'
}	

mmerge date using "$apath/cumdef_hazard_ConH_UST`y'.dta", ukeep(def6m def1y def2y def3y def4y def5y def7y def10y)
foreach x in def6m def1y def2y def3y def4y def5y def7y def10y {
	rename `x' conh_ust_`x'`y'
}	
mmerge date using  "$apath/cumdef_hazard`y'.dta", ukeep(def6m def1y def2y def3y def4y def5y def7y def10y)
foreach x in def6m def1y def2y def3y def4y def5y def7y def10y {
	rename `x' `x'`y'
}

mmerge date using  "$apath/cumdef_hazard_triangle`y'.dta", ukeep(tri*)
drop tri_def15y tri_conH_def15y tri_def20y tri_conH_def20y tri_def30y tri_conH_def30y

foreach x in 6m 1y 2y 3y 4y 5y 7y 10y {
	rename tri_def`x' tri_def`x'`y'
	rename tri_conH_def`x' tri_conH_def`x'`y' 
}	
}
save  "$apath/Default_Prob_All.dta", replace

mmerge date using "$apath/cumdef_hazard.dta", ukeep(def6m def1y def2y def3y def4y def5y def7y def10y)
mmerge date using "$apath/cumdef_hazard_triangle.dta", ukeep(tri*)
drop tri_def15y tri_conH_def15y tri_def20y tri_conH_def20y tri_def30y tri_conH_def30y

foreach y in "" "_europe" "_newyork" "_london" "_londonmidday" "_asia" "_japan"{
foreach x in 6m 1y 2y 3y 4y 5y 7y 10y {
	label var def`x'`y' "`x' Cumulative Default Probability, Composite, IRS Zero, `y'"
	label var conh_def`x'`y' "`x' Cumulative Default Probability, Composite Constant 39.5% Recovery, IRS Zero, `y'"
	label var conh_ust_def`x'`y' "`x' Cumulative Default Probability, Composite Constant 39.5% Recovery, UST Zero, `y'"
	label var ust_def`x'`y' "`x' Cumulative Default Probability, UST Zero, `y'"
	label var tri_def`x'`y' "`x' Cumulative Default Probability, Credit Triangle, `y'"
	label var tri_conH_def`x'`y' "`x' Cumulative Default Probability, Constant 39.5% Recovery, Credit Triangle, `y'"
	}	
	}

	mmerge date using "$mpath/Sensitivities_Merge.dta", ukeep (markitC5_def10y  markitC5_def1y  markitC5_def2y markitC5_def3y markitC5_def4y markitC5_def5y markitC5_def6m markitC5_def7y PUF_markitC1_def7y PUF_markitC5_def10y  PUF_markitC5_def1y  PUF_markitC5_def2y  PUF_markitC5_def3y PUF_markitC5_def4y PUF_markitC5_def5y PUF_markitC5_def6m PUF_markitC5_def7y)
foreach x in 6m 1y 2y 3y 4y 5y 7y 10y {
	label var markitC5_def`x' "`x' Cumulative Default Probability, Markit, "
	label var PUF_markitC5_def`x' "`x' Points Upfront, Markit, "	
	rename markitC5_def`x' mC5_`x'
	rename PUF_markitC5_def`x' PUF_`x'
	}	
	
	mmerge date using "$mpath/Composite_USD.dta", ukeep (Spread6m Spread1y Spread2y Spread3y Spread4y Spread5y Spread7y Spread10y Spread20y Spread30y)
	save "`temp1'", replace

use "$mpath/Sameday_USD.dta", clear
keep if snaptime=="NewYork" | snaptime=="Europe"
replace snaptime="_newyork" if snaptime=="NewYork"
replace snaptime="_europe" if snaptime=="Europe"
keep date snaptime Spread6m Spread1y Spread2y Spread3y Spread4y Spread5y Spread7y Spread10y
reshape wide Spread*, i(date) j(snaptime) str
mmerge date using "`temp1'"
keep if date>=td(01jan2011) 

foreach y in "" "_europe" "_newyork" {
	foreach x in 6m 1y 2y 3y 4y 5y 7y 10y {
		label var Spread`x'`y' "`x' Par Spread, `y'"
	}
	}
	
	foreach x in 6M 1Y 2Y 3Y 4Y 5Y 7Y 10Y {
		label var Upfront`x' "Points Upfront, 5% coupon, `x'"
		}
mmerge date using "$apath/triangle_bbds.dta"
mmerge date using "$apath/cumdef_BB.dta", uname(bb_)
mmerge date using "$apath/cumdef_ds.dta", uname(ds_)
mmerge date using "$apath/cumdef_hazard_triangle_bb.dta", uname(bb_) ukeep(tri*)
mmerge date using "$apath/cumdef_hazard_triangle_ds.dta", uname(ds_) ukeep(tri*)
mmerge date using "$apath/bond_dprob_merge.dta"


** code to generate triangles for bonds

gen g17_bbg_tri = 1-(1-g17ys / (1-`recov'))^`tenor'
gen g17_eurotlx_tri = 1-(1-g17ys_eurotlx / (1-`recov'))^`tenor'
gen rsbond_bbg_tri = 1-(1-rsbondys / (1-`recov'))^`tenor'

save  "$apath/Default_Prob_All.dta", replace

*Default Probability Figures
*****************
*Make CDS Figures for Presentation
**********************************

discard
use "$mpath/Composite_USD.dta", clear
twoway (line Spread6m date) (line Spread1y date) (line Spread2y date) (line Spread3y date) (line Spread4y date) (line Spread5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Par Spread") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("CDS")
graph export "$rpath/CDS_Plot.eps", replace

use "$mpath/Composite_USD.dta", clear
twoway (line Spread6m date) (line Spread1y date) (line Spread2y date) (line Spread3y date) (line Spread4y date) (line Spread5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Par Spread") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("CDS_title") title("Daily Composite CDS Spreads")
graph export "$rpath/CDS_Plot_title.eps", replace


twoway (line Recovery date)if date>=td(01jan2011) & date<=td(30jul2014),  ytitle("Recovery Rate") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Recovery")
graph export "$rpath/Recovery_Plot.eps", replace


twoway (line Recovery date)if date>=td(01jan2011) & date<=td(30jul2014),  ytitle("Recovery Rate") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Recovery_title") title("Dealer-Reported Recovery Rate")
graph export "$rpath/Recovery_Plot_title.eps", replace

capture confirm file "$apath/cumdef_hazard_UST.dta"

if _rc == 0 {
	use "$apath/cumdef_hazard_UST.dta", clear
	twoway (line haz6m date) (line haz1y date) (line haz2y date) (line haz3y date) (line haz4y date) (line haz5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "0-6 Months" 2  "6 Months-1 Year" 3 "1-2 Years"  4 "2-3 Years" 5 "3-4 Years" 6 "4-5 Years")) ytitle("Hazard Rate") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Hazard")
	graph export "$rpath/Hazard_Plot.eps", replace

		use "$apath/cumdef_hazard_UST.dta", clear
	twoway (line haz6m date) (line haz1y date) (line haz2y date) (line haz3y date) (line haz4y date) (line haz5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "0-6 Months" 2  "6 Months-1 Year" 3 "1-2 Years"  4 "2-3 Years" 5 "3-4 Years" 6 "4-5 Years")) ytitle("Hazard Rate") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Hazardtitle") title("Estimated Hazard Rate")
	graph export "$rpath/Hazard_Plot_title.eps", replace

	twoway (line def6m date) (line def1y date) (line def2y date) (line def3y date) (line def4y date) (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Cumulative Default Probability") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default")
	graph export "$rpath/Default_Plot.eps", replace

	twoway (line def6m date) (line def1y date) (line def2y date) (line def3y date) (line def4y date) (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Cumulative Default Probability") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default_title") title("Risk-Neutral Cumulative Default Probability")
	graph export "$rpath/Default_Plot_title.eps", replace

	twoway (line def6m date, lcolor(white)) (line def1y date, lcolor(white)) (line def2y date, lcolor(white)) (line def3y date, lcolor(white)) (line def4y date, lcolor(white)) (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Cumulative Default Probability") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default2")
	graph export "$rpath/Default_Plot2.eps", replace
	
	twoway  (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014),  ytitle("Cumulative Default Probability") ///
	xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default5yonly")
	graph export "$rpath/Default_Plot_5yonly.eps", replace
}

