*Cleaning Bloomberg data


*Placebo chars
import excel "$bbpath/Data/Placebo.xlsx", sheet("Sheet1") first allstring clear
rename Security ticker
save  "$apath/sec_names.dta", replace



*Placebo time serires
import excel "$bbpath/Data/Placebo.xlsx", sheet("All")  allstring clear
sxpose, clear
gen n=_n
order n
gen mod4=mod(n,4)
drop if mod4==0
drop mod4 n

gen n=_n
order n
tsset n
carryforward _var1, replace
encode _var1, gen(sec_id)
order sec_id
drop n
save "$apath/Placebo.dta", replace

forvalues i=1/15 {
use "$apath/Placebo.dta", replace
keep if sec_id==`i'
*keep if firm_id==1

drop sec_id
rename _var1 _var1old
rename _var2 _var2old
rename _var3 _var3old

sxpose, clear
local nametemp=_var1[1]
gen ticker="`nametemp'"
order ticker
drop if _n==1

forvalues j=1/3 { 
	replace _var`j'=lower(_var`j')
	local temp=_var`j'[1]
	rename _var`j' `temp'
}	
drop if _n==1
gen datenew=date(date,"MDY")
format datenew %td
drop date
rename datenew date
order date
drop if date==.
save "$apath/secid_`i'.dta", replace
}

use "$apath/secid_1.dta", clear
forvalues i=2/15 {
append using "$apath/secid_`i'.dta"
}

foreach x in px_last  tot_return_index_gross_dvds {
replace `x'="" if `x'=="#n/a n/a"
destring `x', replace

}

mmerge ticker using "$apath/sec_names.dta"
drop if _merge==2
drop _merge
save "$apath/Dec_Securities.dta", replace

use "$apath/Dec_Securities.dta", clear
keep if sec_type=="CDS"

split ticker, p(" ")
drop ticker ticker1 ticker3
rename ticker2 reporter
drop name sec_type
drop tot_retu
reshape wide px_last, i(date reporter) j(country) str
renpfix px_last
sort reporter date

foreach x in Brazil Chile Mexico Peru {
local temp=`x'[1]
gen `x'_norm=`x'/`temp' if reporter=="CBGN"
}

twoway (line Brazil_n date) (line Chile_n date) (line Mexico_n date) (line Peru_n date)
corr Brazil_n Chile_n Mexico_n Peru_n
save "$apath/Latam_CDS.dta", replace

use "$apath/Dec_Securities.dta", clear
keep if sec_type~="CDS"

drop name sec_type ticker
rename px_last p_
rename tot r_

reshape wide p_ r_, i(date) j(country) str
foreach x in Brazil Chile Mexico Peru {
	rename r_`x' `x'_r
	rename p_`x' `x'_p
	}
reshape long Brazil Chile Mexico Peru, i(date) j(variable) string
replace variable="price" if variable=="_p"
replace variable="return" if variable=="_r"

save "$apath/Latam_equities.dta", replace

