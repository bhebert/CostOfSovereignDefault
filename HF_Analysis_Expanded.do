global hf "$mainpath/HF_Data"
global hftemp "$apath/hf"
cap mkdir $hftemp

*DATASET OF HF default profs
*RISK NEUTRAL PROBS
use date ust_def5y*  using "$apath/Default_Prob_All.dta", clear
rename ust_def5y ust_def5y_composite
renpfix ust_def5y_	

foreach x of varlist _all {
	if "`x'"~="date" {
		destring `x', replace force
		rename `x' type`x'
	}
}
	
reshape long type, i(date) j(close)	 str
gen timemin=""
replace timemin="16:00" if close=="composite"
replace timemin="15:30" if close=="newyork"
replace timemin="09:30" if close=="europe"
replace timemin="10:30" if close=="london"
replace timemin="04:00" if close=="asia"
replace timemin="07:00" if close=="londonmidday"
replace timemin="02:00" if close=="japan"
keep if timemin~=""
rename type dprob
sort date time

gen month=month(date)
gen year=year(date)
gen day=day(date)
order month year day
foreach x in month year day {
	tostring `x', replace
}
gen  clockstr=month+"/"+day+"/"+year+" "+timemin	
order clockstr 
gen double date_obs=clock(clockstr,"MDYhm")
format date_obs %tc
order date_obs
drop clockstr month year time day 
replace dprob=dprob*100
drop if dprob==.
gen symbol="dprob"
save "$apath/dprob_hf_all.dta", replace
	

*Clean November and December 2012
*FIX CLOCK TIME

use "$hf/Argentina_Nov_Dec_2012.dta", clear
foreach x in "Aug_2013" "Jan_2013" "Jan_2014" "Jun_2014" "Mar_2013" "Nov_2013" "Oct_2013" {
	append using "$hf/Argentina_`x'.dta"
}

gen month=month(date)
gen year=year(date)
gen day=day(date)
order month year day
foreach x in month year day {
	tostring `x', replace
}
gen timemin=substr(time,1,5)
gen timeminfl=timemin
replace timeminfl=subinstr(timeminfl,":",".",.)
destring timeminfl, replace

*only within trading hours
drop if timeminfl<9.3 | timeminfl>16
drop timeminfl

*gen  clockstr=month+"/"+day+"/"+year+" "+time
gen  clockstr=month+"/"+day+"/"+year+" "+timemin	
order clockstr 
gen double date_obs=clock(clockstr,"MDYhm")
format date_obs %tc
order date_obs
drop clockstr month year time

drop if bid==0 | ofr==0 | bidsiz==0 | ofrsiz==0

*only keep 12
*Regular (NASD open) (12) - Indicates normal trading environment. May be used by NASD
*market makers in place of Mode 10 to indicatethe first quote of the day 
*or if a market maker re-opens a security during the day (see Mode 8). */
keep if mode==12
gen bidask=ofr-bid
drop if bidask<0
levelsof (symbol), local(sum)
foreach x of local sym {
	summ bidask if sym=="`x'", detail
	drop if bidask>r(p90) & sym=="`x'"
}

collapse (median)  bid ofr, by(symbol date_obs)
gen mid=(bid+ofr)/2

bysort symbol: egen double starttime=min(date_obs) 
bysort symbol: egen starttemp=median(mid) if date_obs==starttime 
bysort symbol: egen start=max(starttemp) 
gen return=100*(log(mid)-log(start))
drop if return==.
drop start*

*WINSORIZE
levelsof (symbol), local(sym)
foreach x of local sym {
summ return if symbol=="`x'" & return~=., detail
	replace return=r(p1) if return<r(p1) & symbol=="`x'"
	replace return=r(p99) if return>r(p99) & symbol=="`x'"
}
gen msci=0
replace msci=1 if sym=="YPF" |  sym=="BMA" |  sym=="GGAL" |  sym=="PZE" |  sym=="TEO" | sym=="BFR"
gen date=dofc(date_obs)
format date %td
save "$hftemp/master_winsor.dta", replace

use "$hftemp/master_winsor.dta", clear
*Nearest 5 minutes
gen minute=mm(date_obs)
gen hour=hh(date_obs)
format date %td
local roundnum=5
gen minute_round=round(minute/`roundnum')
collapse (median) return (firstnm) msci (lastnm) date_obs, by(symbol date hour minute_round)
drop minute* hour

bysort sym: gen n=_n
encode sym, gen(sid)
tsset sid n
gen lchange=return-l.return
gen fchange=f.return-return
save "$hftemp/master_winsor_5m.dta"

use "$hftemp/master_winsor.dta", clear
keep if symbol=="YPF"
append using "$apath/dprob_hf_all.dta" 

foreach date in "27nov2012" "29nov2012" "05dec2012" "07dec2012" "11jan2013" "04mar2013" "27mar2013" "26aug2013" "04oct2013" "08oct2013" "19nov2013" "13jan2014" "16jun2014" "24jun2014" "27jun2014" {
twoway (line return date_obs if symbol=="YPF") (connected dprob date_obs if symbol=="dprob", yaxis(2))  if date>=td(`date')-1 & date<=td(`date')+1, title("`date'") name("hf_`date'") xlabel(, labsize(vsmall) angle(45)) legend(order(1 "YPF Return" 2 "Prob. of Default"))
graph export "$rpath/hf_`date'.png", replace
}

******************
*NICE NEW FIGURES*
******************
use "$hftemp/master_winsor.dta", clear
keep if symbol=="YPF"
append using "$apath/dprob_hf_all.dta" 

gen minute=mm(date_obs)
gen hour=hh(date_obs)

replace hour=9 if hour==7 & symbol=="dprob"
replace minute=30 if hour==4 & symbol=="dprob"
replace hour=8 if hour==4 & symbol=="dprob"
replace hour=8 if hour==2 & symbol=="dprob"
replace hour=hour-8
gen time=hour+minute/60
replace time=time/8
gen timedate=date+time

*twoway (line return timedate if symbol=="YPF") (connected dprob timedate if symbol=="dprob", yaxis(2))  if date>=td(27nov2012) & date<=td(29nov2012), title("SCDAY")  xlabel(, labsize(vsmall) angle(45)) legend(order(1 "YPF Return" 2 "Prob. of Default"))
discard
foreach date in "27nov2012" "29nov2012" "05dec2012" "07dec2012" "11jan2013" "04mar2013" "27mar2013" "26aug2013" "04oct2013" "08oct2013" "19nov2013" "13jan2014" "16jun2014" "24jun2014" "27jun2014" {
local d1_open=td(`date')-1+0.188
local d1_close=td(`date')
local d2_open=td(`date')+0.188
local d2_close=td(`date')+1
local d3_open=td(`date')+1+0.188
local d3_close=td(`date')+2

twoway (line return timedate if symbol=="YPF") (connected dprob timedate if symbol=="dprob", yaxis(2)) (scatter dprob timedate if symbol=="dprob" & close=="composite", yaxis(2))  if date>=td(`date')-1 & date<=td(`date')+1, title("`date'") name("test_`date'") xlabel(, labsize(vsmall) ) legend(order(1 "YPF Return" 2 "Prob. of Default")) xlabel(`d1_open' "D-1 9:30 am" `d1_close' "D-1 4:00 pm" `d2_open' "D 9:30 am" `d2_close' "D 4:00 pm" `d3_open' "D+1 9:30 am" `d3_close' "D+1 4:00 pm", labsize(small) angle(45)) xtitle("") graphregion(color(white))
graph export "$rpath/hf_`date'_newaxis.png", replace
}



*******************
*CREATE INDEX******
*******************
use "$hftemp/master_winsor.dta", clear
levelsof (symbol), local(sum)
discard
gen return_raw=return
gen prob=0
foreach x of local sym {
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
	*twoway (line return time, sort) (line return_raw time, sort) if symbol=="`x'" & time>`stime'-1 & time<`etime'+3 , xline(`stime') xline(`etime') name("`x'date_`datenum'") title("`x': `datenum'")
	*graph export "$rpath/hf_`datenum'_`x'.png", replace
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

**************
*STOPPED HERE*
**************
/*

levelsof (symbol), local(sum)
discard
	gen return_raw=return
gen prob=0
foreach x of local sym {
*keep if time>=9.5 & time<16
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
	*graph export "$rpath/hf_`datenum'_`x'.png", replace
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
	save "$hf/hf_`datenum'_index", replace
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
use "$apath/triangle_merged_hf.dta", clear
replace dprob=dprob*100
*replace date=date-1 if close=="Japan"
*replace time=17 if close=="Japan"
keep if date==td(4dec2012) | date==td(7Oct2013) | date==td(10Jan2014) | date==td(16Jun2014) | date==td(26Jun2014)
gen sym="DPROB"
save "$apath/hf_merge.dta", replace
	
*RISK NEUTRAL PROBS
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

*RISK NEUTRAL PROBS
use date ust_def5y ust_def5y_europe ust_def5y_london using "$apath/Default_Prob_All.dta", clear
rename ust_def5y NewYork
rename ust_def5y_europe Europe
rename ust_def5y_london London

foreach x of varlist _all {
	if "`x'"~="date" {
		destring `x', replace force
		rename `x' type`x'
	}
}
	
reshape long type, i(date) j(close)	 str
gen time=.
replace time=15.5 if close=="NewYork"
replace time=9.5 if close=="Europe"
replace time=10.5 if close=="London"
keep if time~=.
rename type dprob
sort date time
save "$apath/dprob_hf.dta", replace	

use "$apath/dprob_hf.dta", clear
replace dprob=dprob*100
keep if date==td(4dec2012) | date==td(7Oct2013) | date==td(10Jan2014) | date==td(16Jun2014) | date==td(26Jun2014)
gen sym="DPROB"
save "$apath/dprob_hf_merge.dta", replace
	



use  "$hf/spy_4Dec2012_collapse.dta", clear
gen time2round=round(time2/5)
collapse (median) return , by(symbol time1 time2round)
replace time2=time2*5
gen time=time1+time2/60
rename return spy
drop symbol time1 time2r
gen date=td(4Dec2012)
save "$hf/spy_merge", replace

foreach datenum in "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
	use "$hf/spy_`datenum'_collapse.dta", clear
	gen time2round=round(time2/5)
	collapse (median) return , by(symbol time1 time2round)
	replace time2=time2*5
	gen time=time1+time2/60
	rename return spy
	drop symbol time1 time2r
	gen date=td(`datenum')	
	append using "$hf/spy_merge"
	save "$hf/spy_merge", replace
	
}		

*TRY AGAIN WITH SPY
use  "$hf/spy_4Dec2012_collapse.dta", clear
gen date=td(4Dec2012)
save "$hf/spy_merge2", replace
foreach datenum in "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
	use "$hf/spy_`datenum'_collapse.dta", clear
	gen date=td(`datenum')	
	append using "$hf/spy_merge2.dta"
	save "$hf/spy_merge2", replace	
	}
keep return date time
rename return spx 	
format date %td
save "$hf/spy_merge2.dta", replace
	
use  "$hf/hf_4Dec2012_index", clear
foreach datenum in "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
	append using "$hf/hf_`datenum'_index"
}	

*append using "$apath/hf_merge.dta"
append using "$apath/dprob_hf_merge.dta"
replace close="London Midday" if close=="LondonMidday"
replace close="London" if close=="london"
format date %td
replace time=16.5 if time>16.5 & dprob~=.
mmerge time date using "$hf/spy_merge"

bysort date: gen startdprobtemp=dprob if close=="Europe"
bysort date: egen startdprob=max(startdprobtemp) 
gen dprob2=dprob-startdprob

discard
replace return=0 if time==9.5
replace return_msci=0 if time==9.5

foreach datenum in "4Dec2012" "7Oct2013" "10Jan2014" "16Jun2014" "26Jun2014" {
	local stime=`start_`datenum''
	local etime=`end_`datenum''	
	twoway (line return_msci time, sort) (line spy time, sort) (scatter dprob2 time, sort yaxis(2) mlabel(close)) if date==td(`datenum') & time>=9.5 & time<=16, title("`datenum'") name(n`datenum') ylabel(-10(5)15) ylabel(-10(5)15,axis(2)) ytitle("Return") ytitle("Default Probability Change",axis(2)) xline(`etime') legend(order(1  "MSCI-Only Index" 2 "S&P" 3 "Default Probability (Right Axis)")) 
	graph export "$rpath/hf_`datenum'.png", replace
	*CENTER AT 0???
	twoway (line return_msci time, sort) (line spy time, sort) (scatter dprob2 time, sort yaxis(2) mlabel(close)) if date==td(`datenum') & time>=9.5 & time<=16, title("`datenum'") name(n`datenum'ns) ytitle("Return") ytitle("Default Probability Change",axis(2)) xline(`etime') legend(order(1  "MSCI-Only Index" 2 "S&P" 3 "Default Probability (Right Axis)")) 
	graph export "$rpath/hf_`datenum'_noscale.png", replace
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



