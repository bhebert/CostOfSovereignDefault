***************************
*Quarterly Characteristics*
***************************
tempfile ds1 ds2
set more off
import excel "$dpath/Datastream_042915.xlsx",  sheet("Sheet2") clear
foreach x of varlist _all {
	 if `x'[1]=="#ERROR" {
	 drop `x'
	 }
	 }
local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	
	drop if _n==1
	foreach x of varlist _all {
		replace `x'=subinstr(`x',"AG:","",.) if _n==1
		replace `x'=subinstr(`x',"(","_",.) if _n==1
		replace `x'=subinstr(`x',")","",.) if _n==1
		local temp=`x'[1]
		rename `x' vv`temp'
		}
rename vvCode quarter
drop if _n==1
reshape long vv, i(quarter) j(firm_var) string
split firm,p("_")
rename firm_var1 Ticker
rename firm_var2 var
drop firm_var
reshape wide vv, i(quarter Ticker) j(var) string
renpfix vv
label var WC05476 "Book Value Per Share"
label var WC05301 "Common Shares Outstanding"
label var WC01706 "Net Income - Basic"
label var WC01705 "Net Income - Diluted"
label var WC05101 "Dividends Per Share"
label var WC05376 "Common Dividends (Cash)"
label var WC05350 "Date Of Fiscal Year End"
label var WC03101 "Current Liabilities-Total"
label var WC03251 "Long Term Debt"
label var WC03451 "Preferred Stock"
label var WC08231 "Total Debt % Common Equity"
label var WC03051 "Short Term Debt & Current Port"
label var MV "Market Value"

foreach x in MV WC01705 WC01706 WC03051 WC03101 WC03251 WC03451 WC05101 WC05301  WC05376 WC05476 WC08231 {
	destring `x', replace force
	}
	replace WC05350="" if WC05350=="NA"
	rename WC05350 WC05350str
	gen WC05350=date(WC05350str,"DMY")
	format WC0530 %td
	label var WC05350 "Date Of Fiscal Year End"
	drop WC05350str
	replace quarter=subinstr(quarter,"Q","",.)
	replace quarter=subinstr(quarter," ","",.)
	rename quarter quarterstr
	gen quarter=substr(quarterstr,1,1)
	gen year=substr(quarterstr,2,4)
	destring quarter, replace
	destring year, replace
	gen qtr=yq(year,quarter)
	format qtr %tq
	drop quarter* year
	rename qtr quarter
	order quarter
	sort Ticker quarter
	save "`ds1'", replace
	
**********************************
*CONSTRUCT 	quarter_data.dta
*Originally in Datastream_clean_v2
set more off
import excel "$dpath/Datastream_Static_0302.xlsx",  sheet("Quarterly") clear
foreach x of varlist _all {
	 if `x'[1]=="#ERROR" {
	 drop `x'
	 }
	 }
local i=1
foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	
	drop if _n==1
	foreach x of varlist _all {
		replace `x'=subinstr(`x',"AG:","",.) if _n==1
		replace `x'=subinstr(`x',"(","_",.) if _n==1
		replace `x'=subinstr(`x',")","",.) if _n==1
		local temp=`x'[1]
		rename `x' vv`temp'
		}
rename vvCode quarter
drop if _n==1
reshape long vv, i(quarter) j(firm_var) string
split firm,p("_")
rename firm_var1 Ticker
rename firm_var2 var
drop firm_var
reshape wide vv, i(quarter Ticker) j(var) string
renpfix vv
	label var EPS "Earnings Per Shr"
label var WC18193 "Earnings Per Share-As Reported"
label var WC10010 "Fiscal Eps - Basic - Yr"
label var WC05901 "Earnings Per Share-Reprt Dt-Q1"
label var WC05902 "Earnings Per Share-Reprt Dt-Q2"
label var WC05903 "Earnings Per Share-Reprt Dt-Q3"
label var WC05904 "Earnings Per Share-Reprt Dt-Q4"
label var WC05291 "Eps - Fully Diluted Shares-Q 1"
label var WC05294 "Eps - Fully Diluted Shares-Q 4"
label var WC05292 "Eps - Fully Diluted Shares-Q 2"
label var WC05293 "Eps - Fully Diluted Shares-Q 3"
label var WC18191 "Earnings Bef Interest & Taxes"
label var DWEB "Ebit"
label var WC18198 "Ebit & Depreciation"
label var WC02999 "Total Assets"
label var WC03351 "Total Liabilities"
label var WC03255 "Total Debt"
label var WC03101 "Current Liabilities-Total"
label var WC03501 "Common Shareholders' Equity"
label var WC03998 "Total Capital"
label var WC08221 "Total Debt % Total Capital/Std"
label var WC08201 "Equity % Total Capital"
label var WC08205 "Equity % Total Capital - 5 Yr"
label var WC08416 "Capital Expendt % Total Assets"
label var WC15121 "Total Capital % Assets"
label var WC08736 "Foreign Assets % Total Assets"
label var WC07151 "International Assets"
label var WC07151R "International Assets Alt."
label var WC07161 "Exports"

foreach x in DWEB EPS EPS1FD12 EPS1TR12 WC02999 WC03019 WC03101 WC03255 WC03351 WC03501 WC03998 WC05291 WC05292 WC05293 WC05294 WC05901 WC05902 WC05903 WC05904 WC07151 WC07151R WC07161 WC08201 WC08205 WC08221 WC08416 WC08736 WC10010 WC15121 WC18191 WC18193 WC18198 {
	destring `x', replace force
	}
	replace quarter=subinstr(quarter,"Q","",.)
	replace quarter=subinstr(quarter," ","",.)
	rename quarter quarterstr
	gen quarter=substr(quarterstr,1,1)
	gen year=substr(quarterstr,2,4)
	destring quarter, replace
	destring year, replace
	gen qtr=yq(year,quarter)
	format qtr %tq
	drop quarter* year
	rename qtr quarter
	order quarter
	
sort Ticker quarter
gen leverage=WC02999/WC03998
label var leverage "WC02999 (Total Assets) /WC03998 (Total Capital)"
mmerge quarter Ticker using "`ds1'"

* Build a better EPS number

gen qtnum = quarter(dofq(quarter))

gen EPSNew = WC05291 
replace EPSNew = WC05292 if qtnum == 2
replace EPSNew = WC05293 if qtnum == 3
replace EPSNew = WC05294 if qtnum == 4


save "$apath/Datastream_Quarterly.dta", replace
	



