
***************************
*FILES NOW BACK FROM MATLAB
***************************

tempfile temp1 temp2
set more off
foreach y in "" "_europe" "_newyork" {

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
*VERSION WILL ALL OF THE DEFAULT PROBABILITIES*
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
foreach y in "_europe" "_newyork"{

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

foreach y in "" "_europe" "_newyork" {
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
save  "$apath/Default_Prob_All.dta", replace

