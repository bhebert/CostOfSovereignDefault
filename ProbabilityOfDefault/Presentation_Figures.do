*MAKE figure for presentation
discard
use "$mpath/Composite_USD.dta", clear
twoway (line Spread6m date) (line Spread1y date) (line Spread2y date) (line Spread3y date) (line Spread4y date) (line Spread5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Par Spread") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("CDS")
graph export "$rpath/CDS_Plot.eps", replace

twoway (line Recovery date)if date>=td(01jan2011) & date<=td(30jul2014),  ytitle("Recovery Rate") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Recovery")
graph export "$rpath/Recovery_Plot.eps", replace


use "$apath/cumdef_hazard.dta", clear
twoway (line haz6m date) (line haz1y date) (line haz2y date) (line haz3y date) (line haz4y date) (line haz5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "0-6 Months" 2  "6 Months-1 Year" 3 "1-2 Years"  4 "2-3 Years" 5 "3-4 Years" 6 "4-5 Years")) ytitle("Hazard Rate") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Hazard")
graph export "$rpath/Hazard_Plot.eps", replace

twoway (line def6m date) (line def1y date) (line def2y date) (line def3y date) (line def4y date) (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Cumulative Default Probability") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default")
graph export "$rpath/Default_Plot.eps", replace

twoway (line def6m date, lcolor(white)) (line def1y date, lcolor(white)) (line def2y date, lcolor(white)) (line def3y date, lcolor(white)) (line def4y date, lcolor(white)) (line def5y date) if date>=td(01jan2011) & date<=td(30jul2014), legend(order(1 "6 Months" 2  "1 Year" 3 "2 Year"  4 "3 Year" 5 "4 Year" 6 "5 Year")) ytitle("Cumulative Default Probability") ///
xtitle("") graphregion(fcolor(white) lcolor(white)) xlabel(18628 "2011" 18993 "2012" 19359 "2013" 19724 "2014", labsize(medium)) xtitle("") ylabel(,nogrid) name("Default2")
graph export "$rpath/Default_Plot2.eps", replace
