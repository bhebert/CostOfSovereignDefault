*OTHER COUNTRIES
use "$mpath/Master_all_EOD.dta", clear
keep if DocC=="CR"
keep if Ccy=="USD"
keep date Ticker Country Spread* Recov
foreach x in "6m" "1y" "2y" "3y" "4y" "5y" "7y" "10y" "15y" "20y" "30y"{
	gen haz_tri_`x'=(Spread`x'/100)/(1-Recovery/100)
	replace haz_tri_`x'=. if haz_tri_`x'<0
	}

	gen tri_def6m=1-exp(-haz_tri_6m*.5)
foreach x in 1 2 3 4 5 7 10 15 20 30 {
	gen tri_def`x'y =1-exp(-haz_tri_`x'y*`x')
}

gen bdate = bofd("basic",date)
format bdate %tbbasic
drop if bdate == .
sort bdate
encode Ticker, gen(tid)
bysort tid bdate: gen n = _n
bysort tid bdate: egen maxn = max(n)
drop if n==2
drop n maxn
tsset tid bdate

keep date Ticker Country tri_def5y
*To keep units sensible vs. cds in ThirdAnalysis.
replace tri_def5y=tri_def5y/100
*make it exp so returns are calculated correctly
replace tri_def5y=exp(tri_def5y)
replace Ticker="HK" if Ticker=="CHINA-HongKong"
bysort Ticker: egen obs_count=count(tri)
keep if obs_count>900
drop Country obs
rename tri_def total_return
gen market="Index"
*keep if Ticker=="ARGENT" |  Ticker=="BRAZIL" |  Ticker=="CHILE" |  Ticker=="COLOM" |  Ticker=="KOREA" |  Ticker=="PERU" |  Ticker=="MEX" 
replace Ticker=Ticker+"_DTRI"
gen industry_sector=Ticker
save "$apath/Other_CDS.dta", replace

	*gen tri5y_oneday = tri_def5y - L.tri_def5y
	*gen tri5y_twoday = tri_def5y - L2.tri_def5y
	*replace tri5y_one=exp(tri5y_one)
	*replace tri5y_two=exp(tri5y_two)
