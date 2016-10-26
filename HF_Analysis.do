global hf "$mainpath/HF_Data"

*TIMES
local start_4Dec2012=13.25 
local end_4Dec2012=13.75
local start_7Oct2013=9.5
local end_7Oct2013=11.75
local start_10Jan2014=14.30
local end_10Jan2014=14.8
local start_16Jun2014=9.55
local end_16Jun2014=9.55
local start_26Jun2014=11.6666666666666667
local end_26Jun2014=14.083333333333333333
*QUOTES
foreach datenum in "4Dec2012" "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
use "$hf/`datenum'_Quote_TAQ.dta", clear
drop if bid==0 | ofr==0 | bidsiz==0 | ofrsiz==0

*only keep 12
*Regular (NASD open) (12) - Indicates normal trading environment. May be used by NASD
*market makers in place of Mode 10 to indicatethe first quote of the day 
*or if a market maker re-opens a security during the day (see Mode 8). */
keep if mode==12

split time, p(":")
destring time1, replace
destring time2, replace
destring time3, replace
gen bidask=ofr-bid
drop if bidask<0
levelsof (symbol), local(sum)
foreach x of local sym {
	summ bidask if sym=="`x'", detail
	drop if bidask>r(p90) & sym=="`x'"
	}

collapse (median)  bid ofr, by(symbol time1 time2)
gen time=time1+time2/60
gen mid=(bid+ofr)/2

bysort symbol: egen starttime=min(time)
replace starttime=9.5 if starttime<9.5
bysort symbol: egen starttemp=median(mid) if time==starttime
bysort symbol: egen start=max(starttemp) 
gen return=100*(log(mid)-log(start))
drop if return==.
drop start*
*WINSORIZE
levelsof (symbol), local(sym)
foreach x of local sym {
summ return if symbol=="`x'" & return~=., detail
	replace return=r(p10) if return<r(p1) & symbol=="`x'"
	replace return=r(p90) if return>r(p99) & symbol=="`x'"
}
gen return2=return

gen msci=0
replace msci=1 if sym=="YPF" |  sym=="BMA" |  sym=="GGAL" |  sym=="PZE" |  sym=="TEO" | sym=="BFR"
save "$apath/`datenum'_winsor.dta", replace
}




discard
foreach datenum in "4Dec2012" "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
use "$apath/`datenum'_winsor.dta", clear
gen time2round=time2/5
collapse (median) return (firstnm) msci, by(symbol time1 time2round)
replace time2=time2*5
gen time=time1+time2/60

bysort sym: gen n=_n
encode sym, gen(sid)
tsset sid n

gen lchange=return-l.return
gen fchange=f.return-return


levelsof (symbol), local(sum)
discard
	gen return_raw=return
gen prob=0
foreach x of local sym {
keep if time>=9.5 & time<16
	summ lchange if sym=="`x'"
	local tempup=r(mean)+r(sd)
	local tempdown=r(mean)-r(sd)
	replace prob=1 if (lchange>`tempup' | lchange<`tempdown') & (fchange>`tempup' | fchange<`tempdown') & sign(fchange)~=sign(lchange) & sym=="`x'"
	replace return=. if prob==1

	local stime=`start_`datenum''
	local etime=`end_`datenum''
	
	*********************************	
	*ONLY KEEP RETURNS <MEDIAN +x*SD*
	*********************************	
	cap bysort time1: egen median=median(return)
	cap bysort time1: egen sd=sd(return)
	local critsd=2
	sort sid n
	replace return=l.return if return>(median+`critsd'*sd) |return<(median-`critsd'*sd) & symbol=="`x'"
	twoway (line return time, sort) (line return_raw time, sort) if symbol=="`x'" & time>`stime'-1 & time<`etime'+3 , xline(`stime') xline(`etime') name("`x'date_`datenum'") title("`x': `datenum'")
	graph export "$rpath/hf_`datenum'_`x'.png", replace
}

	gen return2=return
	gen return_median=return
	gen return_msci=return if msci==1
	gen msci_count=return_msci 
	
	encode sym, gen(ssid)
	sum ssid
	drop ssid
	local returnum=r(max)
	collapse (sum) return return_raw return_msci (median) return_median (count) return2 msci_count, by(time)

	replace return=return/return2
	replace return_msci=return_msci/msci_count
	local stime=`start_`datenum''
	local etime=`end_`datenum''
	twoway (line return time ) (line return_median time ) (line return_msci time )  if time>`stime'-3 & time<`etime'+3 & return2>=`returnum' & time>=9.5 & time<=16, xline(`stime') xline(`etime') name("date_`datenum'") legend(order (1 "Mean" 2 "Median" 3 "MSCI")) title("Index `datenum'")
	graph export "$rpath/hf_`datenum'_all.png", replace
	gen date=td(`datenum')
	save "hf_`datenum'_index", replace
	}

	
	
*use "$mpath/Default_Prob_All.dta", clear
*keep if date==td(4dec2012) | date==td(7Oct2013) | date==td(10Jan2014) | date==td(16Jun2014) | date==td(26Jun2014)
*CREDIT TRIANGLES	
use date tri_def5y using "$mpath/cumdef_hazard_triangle_london.dta", clear
rename tri_def5y london
foreach y in "Europe" "NewYork" "Asia" "Japan"  "LondonMidday" {
	mmerge date using  "$mpath/cumdef_hazard_triangle_`y'.dta", ukeep(tri_def5y)
	rename tri_def5y `y'
}	
drop _m
save "$apath/triangle_merged.dta", replace	

use "$apath/triangle_merged.dta", clear
foreach x of varlist _all {
	if "`x'"~="date" {
		rename `x' type`x'
	}
}
	
reshape long type, i(date) j(close)	 str
gen time=.
replace time=15.5 if close=="NewYork"
replace time=9.5 if close=="Europe"
replace time=10.5 if close=="london"
replace time=4 if close=="Asia"
replace time=7 if close=="LondonMidday"
replace time=2 if close=="Japan"

keep if time~=.
rename type dprob
sort date time
save "$apath/triangle_merged_hf.dta", replace	

use "$apath/triangle_merged_hf.dta", clear
replace dprob=dprob*100
replace date=date-1 if close=="Japan"
replace time=23 if close=="Japan"
keep if date==td(4dec2012) | date==td(7Oct2013) | date==td(10Jan2014) | date==td(16Jun2014) | date==td(26Jun2014)
gen sym="DPROB"
save "$apath/hf_merge.dta", replace
	

use  "hf_4Dec2012_index", clear
foreach datenum in "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
	append using "hf_`datenum'_index"
}	

append using "$apath/hf_merge.dta"
replace close="London Midday" if close=="LondonMidday"
replace close="London" if close=="london"
format date %td
replace time=16.5 if time>16.5 & dprob~=.
replace time=9 if time==7

discard
foreach datenum in "4Dec2012" "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
	local stime=`start_`datenum''
	local etime=`end_`datenum''	
	twoway (line return_msci time) (scatter dprob time, yaxis(2) mlabel(close)) if date==td(`datenum') & time>=9 & time<=17, title("`datenum'") name(n`datenum')  xline(`stime') xline(`etime') legend(order(1  "MSCI-Only Index" 2 "Default Probability (Right Axis)")) 
	graph export "$rpath/hf_tri_`datenum'.png", replace
}





/*
use "/Users/jschreger/Dropbox/Cost of Sovereign Default/HF_Data/8d3f50d1e52fef27.dta", clear
split time_m, p(":")
order time_m1 time_m2 time_m3
destring time_m1, replace
destring time_m2, replace
destring time_m3, replace
gen time=time_m1+time_m2/60+time_m3/3600
order time
twoway (line price time) if time_m1==9 & time_m2>=30 & time_m2<=40
twoway (line price time) if time_m1<12 


use "/Users/jschreger/Dropbox/Cost of Sovereign Default/HF_Data/16Jun2014_TAQ.dta", clear
split time, p(":")
destring time1, replace
destring time2, replace
destring time3, replace
collapse (lastnm) price, by(symbol time1 time2)
gen time=time1+time2/60
order time
browse if time1==9 & time2==30

twoway (line price time) if time_m1==9 & time_m2>=30 & time_m2<=40
twoway (line price time) if time_m1<12 



