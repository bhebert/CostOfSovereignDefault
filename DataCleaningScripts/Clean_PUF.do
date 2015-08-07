*JUST GET THE ARGENTINE DATA
import delimited "$mainpath/Markit/Sameday Data/FC-NewYork/Sameday Fixed Coupon CDS-16Jun14.csv", delimiter(comma) rowrange(3) clear
keep if _n==1
save "$apath/PUF_NY.dta", replace

foreach x in "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"  {
	foreach y in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" {
		foreach z in "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" {
		cap {
		import delimited "$mainpath/Markit/Sameday Data/FC-NewYork/Sameday Fixed Coupon CDS-`y'`x'`z'.csv", delimiter(comma) rowrange(3) clear
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
* "$dir_inter/Master_Edit.dta", replace

*use "$dir_inter/Master_Edit.dta", clear
keep if Ccy=="USD"
keep if Tier=="SNRFOR"
keep if DocClause=="CR"
gen year=yofd(date)
drop Date
keep if Running==.05
save "$apath/PUF_NY.dta", replace
* "$mainpath/Markit/Sameday Data/FC-NewYorksets/Composite_USD.dta", replace




