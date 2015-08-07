use "$dpath/Exchange_Rates_April2015.dta", clear
keep if obs_type=="ER" | obs_type=="ERS"
drop ARUSDSR

rename PDARS1M NDF1M
rename PDARS2M NDF2M
rename PDARS3M NDF3M
rename PDARS6M NDF6M
rename PDARS1Y NDF12M



tsset date 


foreach x in ARSUSDS ARUSDSR TDARSSP NDF1M NDF2M NDF3M NDF6M NDF12M {
	replace `x'=. if `x'>100
	replace `x'=. if `x'<.75
	}

replace NDF1M=. if (NDF1M/NDF2M)>3 | (NDF2M/NDF1M)>3
	replace NDF2M=. if NDF1M==.
	replace NDF3M=. if NDF1M==.
	replace NDF6M=. if NDF1M==.
	replace NDF12M=. if NDF1M==.
	
replace NDF12M=. if (NDF12M/NDF6M)>3 | (NDF6M/NDF12M)>3
	replace NDF2M=. if NDF12M==.
	replace NDF3M=. if NDF12M==.
	replace NDF6M=. if NDF12M==.
	replace NDF1M=. if NDF12M==.
	
		
replace NDF2M=. if (NDF2M/NDF3M)>2 | (NDF3M/NDF2M)>2
	replace NDF1M=. if NDF2M==.
	replace NDF3M=. if NDF2M==.
	replace NDF6M=. if NDF2M==.
	replace NDF12M=. if NDF2M==.
	
foreach x in ARSUSDS ARUSDSR TDARSSP NDF1M NDF2M NDF3M NDF6M NDF12M {
	gen d`x'=(log(`x')-log(l.`x'))*100
}		
	sort date
twoway (line ARSUSDS date) (line ARUSDSR date)  (line NDF1M date) (line NDF2M date) (line NDF3M date) (line NDF6M date) (line NDF6M date) if obs_type=="ER", legend(order(1 "Onshore, Unofficial" 2 "Official" 3 "1M NDF" 4 "2M NDF" 5 "3M NDF" 6 "6M NDF" 7 "1Y NDF"))
*graph export 

*Format needs to be date Ticker total_return px_close px_open
