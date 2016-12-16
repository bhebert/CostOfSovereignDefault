import excel "$miscdata/EuroTLXData.xlsx", sheet("Sheet1") allstring clear
drop if _n==1
drop I J K L M N
foreach x of varlist _all {
	local temp=lower(`x'[1])
	rename `x' `temp'
}
	drop if _n==1
gen date2=date(date,"MDY")	
order date2
format date2 %td
drop date
rename date date
gen n=_n
tsset n
replace date=f.date-1 if date==.
drop n

foreach x in px_last px_ask px_bid px_volume {
	replace `x'="" if regexm(`x',"#N")==1
	destring `x', replace	
}
*save "$miscdata/EuroTLXData", replace
*use  "$miscdata/EuroTLXData", clear
keep date px_last
gen Ticker="eurotlx"
gen px_open=px_last
gen total_return=.
replace px_last = .
gen market="Index"
gen industry_sector="eurotlx"
drop if px_open == .
save "$apath/eurotlx.dta", replace
