*GSW_Clean
***********************
*GURKAYNAK SACK WRIGHT*
***********************
import excel "$miscdata/GSW/feds200628.xlsx", sheet("Yields") clear
drop if _n<10
replace A="datestr" if _n==1
foreach x of  varlist _all {
	local temp=lower(`x'[1])
	rename `x' `temp'
	}
drop if _n==1
foreach x of  varlist _all {
	if "`x'" ~="datestr" {
		destring `x', replace
		}
		}
gen date=date(datestr,"YMD")	
order date
format date %td
drop datestr
save "$apath/GSW_Data.dta", replace
