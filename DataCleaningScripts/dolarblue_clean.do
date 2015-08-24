*dolarblue
import delimited "$miscdata/dolarblue/dolarbluenet.csv",  clear
local i=1
foreach x of varlist _all {
 rename `x' var`i'
 local i=`i'+1
 }
 keep if var1=="DÓLAR BLUE"
replace var1="dolarblue" if var1~="official"
rename var1 Ticker
rename var2 date
split date, p(" ")
drop date date2
gen date=date(date1,"MDY", 2015)
format date %td
drop date1
order date
rename var3 total_return
drop var4
gen bdate = bofd("basic",date)
tsset bdate
gen px_close=total_return
gen px_open=.
label var Ticker "Ticker"
label var total_return ""
*twoway (line dolarblue date) (line official date)
drop bdate
save "$apath/dolarblue.dta", replace

*use "$miscdata/dolarblue/Dolarblue.dta", clear
*gen quarter=qofd(date)
*format quarter %tq
*collapse (lastnm) dolarblue official, by(quarter)
*save "$miscdata/dolarblue/Dolarblue_q.dta"
