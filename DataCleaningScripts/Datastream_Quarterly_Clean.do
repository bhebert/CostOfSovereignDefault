***************************
*Quarterly Characteristics*
***************************
import excel "$dpath/Datastream_042915.xlsx",  sheet("Sheet2") clear
foreach x of varlist _all {
	 if `x'[1]=="#ERROR" {
	 drop `x'
	 }
	 }

foreach x of varlist _all {
	rename `x' v`i'
	local i=`i'+1
	}
	rename v date
	
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

	save "$apath/Datastream_Quarterly.dta", replace
	


	
