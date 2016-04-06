*DTCC Data
set more off
import excel "$miscdata/DTCC/TopSingleNames.xlsx", sheet("12222014_03192015") clear
drop if _n<=3
gen daterange="12222014_03192015"
order daterange
save "$apath/dtcc.dta", replace

foreach x in  "09212014_12212014" "06202014_09212014" "03202014_06192014" "12202013_03192014" "09202013_12192013" "06202013_09192013" "03202013_06192013"  "12202012_03192013" "09202012_12192012" "06202012_09192012" "03202012_06192012"  "12202011_03192012" "09202011_12192011" "06202011_09192011" "03212011_06192011" "12202010_03192011" {
import excel "$miscdata/DTCC/TopSingleNames.xlsx", sheet("`x'") clear
drop if _n<=3
gen daterange="`x'"
append using "$apath/dtcc.dta"
save "$apath/dtcc.dta", replace
}

rename A reference
rename B region
rename C indexconstituent
rename D totalclearingdealers
rename E avgmonthlyclearingdealers
rename F avgdailynotional
rename G avgtradesday
rename H docclause
order date
split date, p("_")
rename  daterange1 start
rename  daterange2 end
save  "$apath/dtcc.dta", replace


replace start=subinstr(start,"2020","20/20",.)
replace start=subinstr(start,"2120","21/20",.)
replace start=subinstr(start,"20/","/20/",.)
replace start=subinstr(start,"21/","/21/",.)
replace start="12/22/2014" if start=="12222014"
replace reference="BOLIVARIAN REPUBLIC OF VENEZUELA" if reference=="BOLIVARIAN REPUBLIC = OF VENEZUELA"
gen datestart=date(start,"MDY")
format datestart %td
replace reference=subinstr(reference,"<= /td>","",.)
order datestart reference avgtradesday
destring avgtradesday, replace force

replace region=lower(region)
browse if regexm(reference,"ARGENTINE")==1 
gsort datestart -avgtradesday
bysort datestart: gen rank=_n


gsort datestart region -avgtradesday
bysort datestart region: gen sovrank=_n
replace sovrank=. if region~="sovereign"


*Bolivarian Republic of Venezuela REPUBLIC OF SOUTH AFRICA JPMORGAN CHASE & CO. FORD MOTOR COMPANY

keep if reference=="BOLIVARIAN REPUBLIC OF VENEZUELA" | reference=="REPUBLIC OF SOUTH AFRICA" | reference=="JPMORGAN CHASE & CO." | reference=="FORD MOTOR COMPANY" | regexm(reference,"ARGENTINE")==1
gen name="Venezuela" if regexm(reference,"VENEZ")==1
replace name="South_Africa" if regexm(reference,"SOUTH")==1
replace name="JPMorgan" if regexm(reference,"JPM")==1
replace name="Ford" if regexm(reference,"FORD")==1
replace name="Argentina" if regexm(reference,"ARGENTINE")==1



order name datestart rank sovrank avgtradesday avgdailynotional
keep name datestart rank sovrank avgtradesday avgdailynotional
destring avgd, replace
rename rank varrank
rename sovrank varsovrank
rename avgt vartrades
rename avgd varnotional
reshape long var, i(name date) j(temp) str
reshape wide var, i(date temp) j(name) str
renpfix var

sort temp datestart
rename temp variable

foreach x in Argentina Ford JPMorgan South_Africa Venezuela {
	replace `x'=`x'/(10^6) if variable=="notional"
	}
	
encode var, gen(vid)	
bysort vid: gen n=_n
tsset vid n
gen dateend=f.datestart-1
format dateend %td
order datestart dateend
keep if datestart<td(20jun2014)
drop vid n
order dates datee var Argentina South Ven For JP
export excel using "$rpath/DTCC_Comparison.xls", firstrow(variables) replace
