*JUST THE TWO QUARTERS 
*QUARTERLY
import  excel "/Users/jesseschreger/Dropbox/Argentina NOT SHARED/Cross Section/Oct 2015/RS_CDS_IVLocalFull.xlsx", sheet("Sheet1") clear
drop if _n==1
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
	}
rename VAR var
replace var="se" if _n==4
keep if var=="cds_" | var=="Num Events" | var=="Observations" | var=="VARIABLES" | var=="se" 
drop EqIndex_AR ValueBankINDEXNew_AR ValueINDEXNew_AR ValueIndex_AR ValueNonFinINDEXNew_AR INDEX
sxpose, clear
rename _var1 ticker_short
rename _var2 est
rename _var3 se
rename _var4 obs
rename _var5 events
replace se=subinstr(se,"(","",.)
replace se=subinstr(se,")","",.)

drop if _n==1
destring est, replace
destring obs, replace
destring events, replace
destring se, replace

sort se
replace ticker_short=subinstr(ticker_short,"_AR","",.)
mmerge ticker_short using  "$apath/FirmTable.dta", ukeep(market_ es_industry import_rev finvar TCind indicator foreign isin_code)
keep if _merge==3
*drop banks
keep if finvar==0
summ est, detail
local median=r(p50)
gen loser=0
replace loser=1 if est<`median'

mmerge  isin_code using "$miscdata/CompustatGlobal/Quarterly.dta", umatch(isin)
keep if _merge==3
gen quarter=quarterly(datacqtr,"YQ")
order quarter 
format quarter %tq
mmerge quarter using "$apath/GDP_inflation.dta", ukeep(cpi)
keep if _merge==3
gen qnum=quarter(dofq(quarter))
gen year=yofd(dofq(quarter))
order year
keep if qnum==2

*Data for at least 10 events
keep if events>=10
keep ticker_short est year capxfiy capxy chq gpq gpy oiadpq oibdpq piq piy revtq revty saleq saley loser cpi
bysort ticker_short year: gen n=_n
bysort ticker_short year: egen maxn=max(n)
encode ticker_short, gen(pid)
tsset pid year
foreach x in capxy  revty saley {
	gen d_`x'=100*(ln(`x')-ln(l.`x'))-100*(ln(cpi)-ln(l.cpi))
}
  foreach v of var  capxy  revty saley {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
  	}
  }
  collapse (mean) d_*, by(year loser)
  foreach v in  capxy  revty saley {
 	label var d_`v' "`l`v''"
  }
  
   export excel using "$mainpath/ResultsForSlides/Post_Default/Post_Default_q2.xls" if year==2015, firstrow(varlabels) replace 
order year d*

discard
local i=1
foreach v of var d_capxy d_revty d_saley {
twoway (line `v' year if loser==1, sort) (line `v' year if loser==0, sort) if year>=2008, ytitle("`l`v'' Growth") name("x`i'") title("`l`v''") legend(order(1 "Loser" 2 "Non-Loser"))
graph export "$mainpath/ResultsForSlides/Post_Default/Figure`i'_q2.png", replace
local i=`i'+1
}

 
  *Make 2015 2014Q3 2014Q4 2015 Q1 2015Q2 
  *QUARTERLY
import  excel "/Users/jesseschreger/Dropbox/Argentina NOT SHARED/Cross Section/Oct 2015/RS_CDS_IVLocalFull.xlsx", sheet("Sheet1") clear
drop if _n==1
foreach x of varlist _all {
	local temp=`x'[1]
	rename `x' `temp'
	}
rename VAR var
replace var="se" if _n==4
keep if var=="cds_" | var=="Num Events" | var=="Observations" | var=="VARIABLES" | var=="se" 
drop EqIndex_AR ValueBankINDEXNew_AR ValueINDEXNew_AR ValueIndex_AR ValueNonFinINDEXNew_AR INDEX
sxpose, clear
rename _var1 ticker_short
rename _var2 est
rename _var3 se
rename _var4 obs
rename _var5 events
replace se=subinstr(se,"(","",.)
replace se=subinstr(se,")","",.)

drop if _n==1
destring est, replace
destring obs, replace
destring events, replace
destring se, replace

sort se
replace ticker_short=subinstr(ticker_short,"_AR","",.)
mmerge ticker_short using  "$apath/FirmTable.dta", ukeep(market_ es_industry import_rev finvar TCind indicator foreign isin_code)
keep if _merge==3
*drop banks
keep if finvar==0
summ est, detail
local median=r(p50)
gen loser=0
replace loser=1 if est<`median'

mmerge  isin_code using "$miscdata/CompustatGlobal/Quarterly.dta", umatch(isin)
keep if _merge==3
gen quarter=quarterly(datacqtr,"YQ")
order quarter 
format quarter %tq
gen qnum=quarter(dofq(quarter))
gen year=yofd(dofq(quarter))
mmerge quarter using "$apath/GDP_inflation.dta", ukeep(inflation)
keep if _merge==3
order year
replace year=year+1 if qnum==3  | qnum==4
*piq pretax incom
*revtq 
keep if events>=10
  foreach v of var  gpq gpy oiadpq oibdpq piq  revtq  saleq inflation {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
  	}
  }
  
  foreach x in   gpq gpy oiadpq oibdpq   revtq  saleq {
	bysort ticker_short year: egen count=count(`x')
	replace `x'=. if `x'<4
	drop count 
	}
  
collapse (sum)   gpq oiadpq oibdpq   revtq  saleq inflation, by(year est ticker_short loser)
foreach x in  gpq oiadpq oibdpq   revtq  saleq inflation {
	replace `x'=. if `x'==0
	}
foreach v of var  gpq  oiadpq oibdpq   revtq  saleq inflation {
 	label var `v' "`l`v''"
  }
bysort ticker_short year: gen n=_n
bysort ticker_short year: egen maxn=max(n)
encode ticker_short, gen(pid)
tsset pid year
foreach x in  gpq  oiadpq oibdpq  revtq saleq {
	gen d_`x'=100*(ln(`x')-ln(l.`x'))-inflation
}

foreach v of var  gpq oiadpq oibdpq   revtq  saleq  {
 	label var d_`v' "`l`v''"
}

    foreach v of var  d_gpq d_oiadpq d_oibdpq d_revtq d_saleq {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
  	}
  }
      
 foreach x in d_gpq d_oiadpq d_oibdpq d_revtq d_saleq { 
	ttest `x' if year==2015, by(loser)
	}

collapse (mean) d_*, by(year loser)
foreach v of var d_gpq d_oiadpq d_revtq d_saleq  {
 	label var `v' "`l`v''"
  }
  
 export excel using "$mainpath/ResultsForSlides/Post_Default/Post_Default.xls" if year==2015, firstrow(varlabels) replace 

discard
local i=1
foreach v of var d_gpq d_oiadpq d_revtq d_saleq {
twoway (line `v' year if loser==1, sort) (line `v' year if loser==0, sort) if year>=2008, ytitle("`l`v'' Growth") name("x`i'") title("`l`v''") legend(order(1 "Loser" 2 "Non-Loser"))
graph export "$mainpath/ResultsForSlides/Post_Default/Figure`i'.png", replace
local i=`i'+1
}

