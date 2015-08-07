use "$dpath/Exchange_Rates_April2015.dta", clear
keep if obs_type=="ER" 
drop ARUSDSR

rename PDARS1M NDF1M
rename PDARS2M NDF2M
rename PDARS3M NDF3M
rename PDARS6M NDF6M
rename PDARS1Y NDF12M

*Mid is 5, Mid Unpadded is 6

keep if date>=td(01jan2011) & date<=td(30jul2014)
gen bdate = bofd("basic",date)
format bdate %tbbasic

tsset bdate 
foreach x in ARSUSDS TDARSSP NDF1M NDF2M NDF3M NDF6M NDF12M {
	gen d`x'=(log(`x')-log(l.`x'))*100
}		

* STOP GETTING BIG BLOCKS OF NO CHANGES BY JUNE 6, 2012
keep if date>=td(06jun2012)

*discard
*twoway (line ARSUSDS date) (line TDARSSP date) (line NDF1M date) (line NDF2M date) (line NDF3M date) (line NDF6M date) (line NDF12M date) if obs_type=="ER", legend(order(1 "Onshore, Unofficial" 2 "Official" 3 "1M NDF" 4 "2M NDF" 5 "3M NDF" 6 "6M NDF" 7 "1Y NDF")) name("Raw")

gen problem=0
foreach x in ARSUSDS TDARSSP NDF1M NDF2M NDF3M NDF6M NDF12M {
	replace problem=1 if `x'>100 | `x'<.75
	}

replace problem=1 if NDF1M==NDF12M
replace problem=1 if NDF6M==NDF12M

replace problem=1 if (NDF1M/NDF2M)>3 | (NDF2M/NDF1M)>3
replace problem=1 if (NDF12M/NDF6M)>3 | (NDF6M/NDF12M)>3
replace problem=1 if (NDF2M/NDF3M)>2 | (NDF3M/NDF2M)>2

*ON FEB 4 and 5 the 1-6m plunge 5-10% and then come back 5-10% the next day, the 12m doesn't move.  This looks like a data problem.
replace problem=1 if date==td(04feb2013)

*ON Aug 29 2013 NDF2m plunges, then comes right back.  This looks like a data problem.
replace problem=1 if date==td(29aug2013)

drop dN*

foreach x in 1 2 3 6 12 {
	*gen FWDP`x'M=(log(NDF`x'M)-log(TDARSSP))*100
	gen FWDP`x'M=NDF`x'M-TDARSSP
	}


*twoway (line ARSUSDS date) (line TDARSSP date) (line NDF1M date) (line NDF2M date) (line NDF3M date) (line NDF6M date) (line NDF12M date) if problem==0 , legend(order(1 "Onshore, Unofficial" 2 "Official" 3 "1M NDF" 4 "2M NDF" 5 "3M NDF" 6 "6M NDF" 7 "1Y NDF")) name("Exprob")

drop ARSUSDS TDARSSP dARSUSDS dTDARSSP obs_type obs_num 
foreach x in NDF1M NDF2M NDF3M NDF6M NDF12M FWDP1M FWDP2M FWDP3M FWDP6M FWDP12M {
	replace `x'=. if problem==1
	rename `x' p_`x'
	}

drop problem
reshape long p_, i(bdate date) j(Ticker)	 str
encode Ticker, gen(tid)
tsset tid bdate

rename p_ total_return
gen px_close=total_return
gen px_open=l.total_return
drop tid	
drop bdate
order date Ticker total px_cl px_open
save "$apath/NDF_Datastream.dta", replace

	
	
