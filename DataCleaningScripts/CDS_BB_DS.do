*CLEAN UP Bloomberg and Datastream April 2016
tempfile bball cds1 cds2 cds3 cds4 cds5 cds6
import excel "$miscdata/BB_DS_CDS_April2016/Argentina_BB_Full_April2016.xlsx", allstring sheet("data") clear
foreach x of varlist _all {
	if `x'[2]=="" {
		drop `x'
	}
}	

local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}

save "`bball'", replace


forvalues i=1/5{
use "`bball'", clear
local j=2*`i'-1
local k=2*`i'
keep v`j' v`k'
local temp=v`j'[1]
gen var="`temp'"
drop if _n<=2
rename v`j' date
rename v`k' cdsbb_
save "`cds`i''", replace
}

use "`cds1'"
forvalues i=2/5{
append using "`cds`i''"
}

replace var=subinstr(var," CBGN Curncy","",.)
replace var="1y" if var=="CT350172"
replace var="2y" if var=="CT350176"
replace var="3y" if var=="CT350180"
replace var="4y" if var=="CT350184"
replace var="5y" if var=="CT350188"
rename date datestr
gen date=date(datestr,"MDY")
format date %td
drop datestr
destring cdsbb, force replace
drop if date==. & cdsbb==.
reshape wide cdsbb_, i(date) j(var) string
save "$apath/Bloomberg_CDS", replace



*DATASTREAM 
tempfile dsall cds1 cds2 cds3 cds4 cds5 cds6
import excel "$miscdata/BB_DS_CDS_April2016/Argentina_DS_CDS_April2016.xlsx", sheet("Sheet1") clear
local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
save "`dsall'", replace
rename v1 datestr
rename v2 cdsds_6m
rename v3 cdsds_1y
rename v4 cdsds_2y
rename v5 cdsds_10y
rename v6 cdsds_5y
rename v7 cdsds_3y
rename v8 cdsds_4y
rename v9 cdsds_30y
rename v10 cdsds_20y
drop v11

gen date=date(datestr,"MDY")
format date %td
drop datestr
order date cdsds_6m cdsds_1y cdsds_2y cdsds_3y cdsds_4y cdsds_5y 
keep date cdsds_6m cdsds_1y cdsds_2y cdsds_3y cdsds_4y cdsds_5y 
drop if _n<=2
foreach x in  cdsds_6m cdsds_1y cdsds_2y cdsds_3y cdsds_4y cdsds_5y  {
destring `x', force replace
}
drop cdsds_6m
gen n=_n
tsset n
gen repeat=1 if (cdsds_1y==l.cdsds_1y) & (cdsds_2y==l.cdsds_2y) & (cdsds_3y==l.cdsds_3y) & (cdsds_4y==l.cdsds_4y) & (cdsds_5y==l.cdsds_5y)
foreach x in cdsds_1y cdsds_2y cdsds_3y cdsds_4y cdsds_5y {
	replace `x'=. if repeat==1
}	
drop n repeat
save "$apath/Datastream_CDS", replace

