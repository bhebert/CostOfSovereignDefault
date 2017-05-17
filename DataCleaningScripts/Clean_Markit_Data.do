********************
*Clean_Markit_Data**
********************

*Composite
import delimited "$mkpath/Composite Data/V5 CDS Composites-16Jun14.csv", delimiter(comma) rowrange(3) clear
keep if v2=="Ticker" | v2=="ARGENT"
tempfile file2
save `file2'
clear
append using `file2'

*JUST GET THE ARGENTINE DATA
import delimited "$mkpath/Composite Data/V5 CDS Composites-16Jun14.csv", delimiter(comma) rowrange(3) clear
keep if _n==1
save "$apath/Master.dta", replace

foreach x in "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"  {
	foreach y in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" {
		foreach z in "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" {
		cap {
		import delimited "$mkpath/Composite Data/V5 CDS Composites-`y'`x'`z'.csv", delimiter(comma) rowrange(3) clear
		keep if v2=="Ticker" | v2=="ARGENT"
		tempfile file1
		save `file1'
		use "$apath/Master.dta", clear
		append using `file1'
		save "$apath/Master.dta", replace
		}
		}
		}
		}
		
use "$apath/Master.dta", clear
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
}	
drop if Date=="Date"
gen date=date(Date,"DMY",2014)
order date
format date %td
sort date
foreach x in Spread6m Spread1y Spread2y Spread3y Spread4y Spread5y Spread7y Spread10y Spread15y Spread20y Spread30y Recovery {
replace `x'=subinstr(`x',"%","",.)
destring `x', replace
}
save "$apath/Master_Edit.dta", replace

use "$apath/Master_Edit.dta", clear
keep if Ccy=="USD"
keep if Tier=="SNRFOR"
keep if DocClause=="CR"
gen year=yofd(date)
save "$mpath/Composite_USD.dta", replace


*********************
*CLEAN SAMEDAY Data**
foreach w in "Asia" "Europe" "Japan" "London" "LondonMidday" "NewYork" {
import delimited "$mkpath/Sameday data/Par-`w'/Sameday CDS-19Jun14.csv", delimiter(comma) rowrange(3) clear
keep if _n==1
save "$apath/Merge_`w'.dta", replace

foreach x in "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"  {
	foreach y in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" {
		foreach z in "10" "11" "12" "13" "14" {
		cap {
		import delimited "$mkpath/Sameday data/Par-`w'/Sameday CDS-`y'`x'`z'.csv", delimiter(comma) rowrange(3) clear
		display "y'`x'`z'"
		keep if v3=="Ticker" | v3=="ARGENT"
		tempfile file1
		save `file1'
		use "$apath/Merge_`w'.dta", clear
		append using `file1'
		save "$apath/Merge_`w'.dta", replace
		}
		}
		}
		}
		}
foreach w in "Asia" "Europe" "Japan" "London" "LondonMidday" "NewYork" {
use "$apath/Merge_`w'.dta", clear
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
}	
gen snaptime="`w'"
save "$apath/Merge_`w'.dta", replace
}


use "$apath/Merge_Asia.dta", clear

foreach w in "Europe" "Japan" "London" "LondonMidday" "NewYork" {
append using "$apath/Merge_`w'.dta"
}

drop if Date=="Date"
gen date=date(Date,"DMY",2014)
order date
format date %td
sort date
foreach x in Spread6m Spread1y Spread2y Spread3y Spread4y Spread5y Spread7y Spread10y Spread15y Spread20y Spread30y Recovery {
replace `x'=subinstr(`x',"%","",.)
destring `x', replace
}
drop Date
order date snaptime
save "$apath/Sameday_Merge.dta", replace

use "$apath/Sameday_Merge.dta", clear
keep if Ccy=="USD"
keep if Tier=="SNRFOR"
keep if DocClause=="CR"
keep if snaptime=="NewYork"
save "$apath/Sameday_NewYork.dta", replace

use "$apath/Sameday_Merge.dta", clear
keep if Ccy=="USD"
keep if Tier=="SNRFOR"
keep if DocClause=="CR"
gen year=yofd(date)
gen month=month(date)
gen day=day(date)

*NOW MERGE IN TIMES.
gen time_gmt=.
replace time_gmt=7 if snaptime=="Japan"
replace time_gmt=9 if snaptime=="Asia"
replace time_gmt=12 if snaptime=="LondonMidday"
replace time_gmt=14.5 if snaptime=="Europe"
replace time_gmt=15.5 if snaptime=="London"
replace time_gmt=20.5 if snaptime=="NewYork"
gen hour=.
replace hour=7 if snaptime=="Japan"
replace hour=9 if snaptime=="Asia"
replace hour=12 if snaptime=="LondonMidday"
replace hour=14 if snaptime=="Europe"
replace hour=15 if snaptime=="London"
replace hour=20 if snaptime=="NewYork"
gen time_est=time_gmt-5
replace hour=hour-5
gen minute=0
replace minute=30 if  snaptime=="Europe" | snaptime=="London" | snaptime=="NewYork"
gen seconds=0
order time_est
gen clocktime=mdyhms(month,day,year,hour,minute,seconds)
format clocktime %tc
order clocktime
drop hour minute day month 
order date time_est clocktime Spread5y
sort date time_est
save "$mpath/Sameday_USD.dta", replace

******************
*Master_all_eod
*******************
import delimited "mkpath/Composite Data/V5 CDS Composites-16Jun14.csv", delimiter(comma) rowrange(3) clear
keep if _n==1
save "$apath/Master_all.dta", replace

foreach x in "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"  {
	foreach y in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" {
		foreach z in "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" {
		cap {
		import delimited "$mkpath/Composite Data/V5 CDS Composites-`y'`x'`z'.csv", delimiter(comma) rowrange(3) clear
		keep if v6=="USD" & v34=="Government"
		drop if v7=="MR" | v7=="XR"
		display "`y'_`x'_`z'"
		tempfile file1
		disp
		save `file1'
		
		use "$apath/Master_all.dta", clear
		append using `file1'
		save "$apath/Master_all.dta", replace
		}
		}
		}
		}
		
use "$apath/Master_all.dta", clear
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
}	
drop if Date=="Date"
gen date=date(Date,"DMY",2014)
order date
format date %td
sort date
foreach x in Spread6m Spread1y Spread2y Spread3y Spread4y Spread5y Spread7y Spread10y Spread15y Spread20y Spread30y Recovery {
replace `x'=subinstr(`x',"%","",.)
destring `x', replace
}
gen year=yofd(date)
save "$mpath/Master_All_EOD.dta", replace



******************
*POINTS UP FRONT**
******************
import delimited "$mkpath/Sameday Data/FC-NewYork/Sameday Fixed Coupon CDS-16Jun14.csv", delimiter(comma) rowrange(3) clear
keep if _n==1
save "$apath/PUF_NY.dta", replace

foreach x in "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"  {
	foreach y in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" {
		foreach z in "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" {
		cap {
		import delimited "$mkpath/Sameday Data/FC-NewYork/Sameday Fixed Coupon CDS-`y'`x'`z'.csv", delimiter(comma) rowrange(3) clear
		keep if v3=="Ticker" | v3=="ARGENT"
		tempfile file1
		save `file1'
		use "$apath/PUF_NY.dta", clear
		append using `file1'
		save "$apath/PUF_NY.dta", replace
		}
		}
		}
		}
		
use "$apath/PUF_NY.dta", clear
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
}	
drop if Date=="Date"
gen date=date(Date,"DMY",2014)
order date
format date %td
sort date
foreach x in RunningCoupon Upfront6M Upfront1Y Upfront2Y Upfront3Y Upfront4Y Upfront5Y Upfront7Y Upfront10Y Upfront15Y Upfront20Y Upfront30Y RealRecovery AssumedRecovery ConvSpread6M ConvSpread1Y ConvSpread2Y ConvSpread3Y ConvSpread4Y ConvSpread5Y ConvSpread7Y ConvSpread10Y ConvSpread15Y ConvSpread20Y ConvSpread30Y {
replace `x'=subinstr(`x',"%","",.)
destring `x', replace
}

keep if Ccy=="USD"
keep if Tier=="SNRFOR"
keep if DocClause=="CR"
gen year=yofd(date)
drop Date
keep if Running==.05
save "$mpath/PUF_NY.dta", replace


******************
*Sensitivities****
******************
import delimited "$mkpath/Sensitivities/V5 CDS SENSITIVITIES-16Jun14.csv", delimiter(comma) rowrange(3) encoding(ISO-8859-1) clear
keep if _n==1
save "$apath/Sensitivities.dta", replace

foreach x in "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"  {
	foreach y in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" {
		foreach z in "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" {
		cap {
		import delimited "$mkpath/Sensitivities/V5 CDS SENSITIVITIES-`y'`x'`z'.csv", delimiter(comma) rowrange(3) clear
		display "`y'_`x'_`z'"
		tempfile file1
		disp
		save `file1'
		
		use "$apath/Sensitivities.dta", clear
		append using `file1'
		save "$apath/Sensitivities.dta", replace
		}
		}
		}
		}
		
use "$apath/Sensitivities.dta", clear
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
}	
drop if Date=="Date"
gen date=date(Date,"DMY",2014)
order date
format date %td
sort date
foreach x in Coupon Upfront ConvSpread RealRecovery CreditDV01 RiskyPV01 IRDV01 Rec01 DP JTD DTZ {
replace `x'=subinstr(`x',"%","",.)
destring `x', replace
}
gen year=yofd(date)
replace DP=DP/100
keep date Tenor Coupon DP Upfront
replace Coupon=Coupon*100
tostring Coupon, replace
replace Coupon="markitC"+Coupon
replace Tenor=subinstr(Tenor,"Y","y",.)
replace Tenor=subinstr(Tenor,"M","m",.)

replace Tenor="_def"+Tenor
rename Upfront PUF_
reshape wide DP PUF, i(date Tenor) j(Coupon) str
renpfix DP
reshape wide markit* PUF_*, i(date) j(Tenor) str
save "$mpath/Sensitivities_Merge.dta", replace


