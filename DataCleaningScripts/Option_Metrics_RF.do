use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Markit/Prob of Default/Discount/OptionMetricsZero.dta", clear
gen year=days/365
gen year_mod=mod(year,1)
gen nearest_year=round(year,1)
gen nmod=mod(nearest_year,1)
replace nearest=round(nearest,.001)
keep if nmod==0  | nearest<1 
drop if nearest==0
bysort nearest_year date: egen min_mod=min(year_mod)
bysort nearest_year date: egen max_mod=max(year_mod) if nearest~=0
keep if year_mod==min_mod | year_mod==max_mod
keep if year(date)>=2011
drop if min

sort date nearest
gen type=1 if  year_mod==min_mod
replace type=2 if year_mod==max_mod
keep date rate nearest_ year_mod type
reshape wide rate year_mod, i(date nearest_year) j(type)
order date near rate* year*
replace rate2=rate1 if nearest_year==1
