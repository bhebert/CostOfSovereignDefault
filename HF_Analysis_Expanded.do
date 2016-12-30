global hf "$mainpath/HF_Data"
global hftemp "$apath/hf"
cap mkdir $hftemp

*CLOSING MARKS
use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear
*add missing equity
append using "$apath/TGNO4.dta"
drop if date == .
drop if Ticker==""
keep if market=="US"
keep if inlist(Ticker,"BFR","BMA","EDN","GGAL","IRS")==1 | inlist(Ticker,"PAM","PZE","TEO","TGS","YPF")==1
keep date px_open px_last Ticker
reshape long px, i(date Ticker) j(timestr) str
gen timemin="09:30" if timestr=="_open"
replace timemin="16:00" if timestr=="_last"
drop times
rename Ticker symbol
gen month=month(date)
gen year=year(date)
gen day=day(date)
foreach x in month year day {
	tostring `x', replace
}
rename px mid
gen psource="bloomberg"
keep if date>=td(01jan2011) & date<=td(31jul2014)
save "$apath/open_close_forhf.dta", replace


*DATASET OF HF default profs
*RISK NEUTRAL PROBS
use date ust_def5y* mC5_5y  using "$apath/Default_Prob_All.dta", clear
rename ust_def5y ust_def5y_composite
*drop ust_def5y
*rename mC5_5y ust_def5y_composite
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
gen psource="taq"

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
*Last 2 minutes just close quotes
drop if timeminfl<9.3 | timeminfl>15.55
drop timeminfl
drop if bid==0 | ofr==0 | bidsiz==0 | ofrsiz==0

*MERGE IN THE BLOOMBERG DATA
append using "$apath/open_close_forhf.dta"

*gen  clockstr=month+"/"+day+"/"+year+" "+time
gen  clockstr=month+"/"+day+"/"+year+" "+timemin	
order clockstr 
gen double date_obs=clock(clockstr,"MDYhm")
format date_obs %tc
order date_obs
drop clockstr month year time


*only keep 12
*Regular (NASD open) (12) - Indicates normal trading environment. May be used by NASD
*market makers in place of Mode 10 to indicatethe first quote of the day 
*or if a market maker re-opens a security during the day (see Mode 8). */
keep if mode==12 | psource=="bloomberg"
gen bidask=ofr-bid
drop if bidask<0 & psource~="bloomberg"
levelsof (symbol), local(sum)
foreach x of local sym {
	summ bidask if sym=="`x'" & psource~="bloomberg", detail
	drop if bidask>r(p90) & sym=="`x'" & psource~="bloomberg"
}

replace mid=(ofr+bid)/2 if mid==.
collapse (median)  mid, by(symbol date_obs psource)

bysort symbol: egen double starttime=min(date_obs) 
bysort symbol: egen starttemp=median(mid) if date_obs==starttime 
bysort symbol: egen start=max(starttemp) 
drop start*
gen msci=0
replace msci=1 if sym=="YPF" |  sym=="BMA" |  sym=="GGAL" |  sym=="PZE" |  sym=="TEO" | sym=="BFR"
gen date=dofc(date_obs)
format date %td
save "$hftemp/master.dta", replace



*******************
*CREATE INDEX******
*******************
discard
set more off
forvalues x=1/15 {
use "$hftemp/master.dta", clear
append using "$apath/dprob_hf_all.dta" 
gen minute=mm(date_obs)
gen hour=hh(date_obs)
*0.99 "Close 0" 
*1.1875 "Open 1" 
*2 "Close 1 " 
*2.1875 "Open 2 "
*3 "Close 2"
local c0=.99
local o1=1.1875
local c1=2
local o2=2.1875
local c2=3
local prestart=`c0'
	if `x'==1 {
	local sd=td(23nov2012) 
	local ld=td(27nov2012) 
	local titledate="November 27, 2012"
	local preend=`o1'
	local winend=`o2'
	}
	if `x'==2 {
	local sd=td(27nov2012) 
	local ld=td(29nov2012) 
	local titledate="November 29, 2012"
	local preend=`c1'
	local winend=`o2'
	}		
	if `x'==3 {
	local sd=td(03dec2012) 
	local ld=td(05dec2012) 
	local titledate="December 5, 2012"	
	local preend=`o1'
	local winend=`c1'
	}		
		if `x'==4 {
	local sd=td(05dec2012) 
	local ld=td(07dec2012) 
	local titledate="December 7, 2012"	
	local preend=`c1'
	local winend=`c2'
	}		
		if `x'==5 {
	local sd=td(09jan2013) 
	local ld=td(11jan2013) 
	local titledate="January 11, 2013"
	local preend=`c1'	
	local winend=`o2'
	}		
		if `x'==6 {
	local sd=td(28feb2013) 
	local ld=td(04mar2013) 
	local titledate="March 4, 2013"	
	local preend=`o1'
	local winend=`o2'
	}		
		if `x'==7 {
	local sd=td(25mar2013) 
	local ld=td(27mar2013) 
	local titledate="March 27, 2013"
	local preend=`o1'
	local winend=`o2'
	}		
		if `x'==8 {
	local sd=td(22aug2013) 
	local ld=td(26aug2013) 
	local titledate="August 26, 2013"
	local preend=`c0'
	local winend=`c1'	
	}		
		if `x'==9 {
	local sd=td(02oct2013) 
	local ld=td(04oct2013) 
	local titledate="October 4, 2013"
	local preend=`o1'	
	local winend=`o2'
	}		
		if `x'==10 {
	local sd=td(04oct2013) 
	local ld=td(08oct2013) 
	local titledate="October 8, 2013"
	local preend=`o1'
	local winend=`c1'	
	}				
	if `x'==11 {
	local sd=td(15nov2013) 
	local ld=td(19nov2013) 
	local titledate="November 19, 2013"	
	local preend=`o1'
	local winend=`o2'
	}		
		if `x'==12 {
	local sd=td(09jan2014) 
	local ld=td(13jan2014) 
	local titledate="January 13, 2014"	
	local preend=`o1'
	local winend=`c1'
	}		
		if `x'==13 {
	local sd=td(12jun2014) 
	local ld=td(16jun2014) 
	local titledate="June 16, 2014"	
	local preend=`o2'
	local winend=`c2'
	}		
		if `x'==14 {
	local sd=td(20jun2014) 
	local ld=td(24jun2014) 
	local titledate="June 24, 2014"	
	local preend=`o1'
	local winend=`o2'
	}	
	if `x'==15 {
	local sd=td(25jun2014) 
	local ld=td(27jun2014) 
	local titledate="June 27, 2014"	
	local preend=`o1'
	local winend=`c1'
	}		
	
local winstart=`preend'
	
	
keep if date>=`sd' & date<=`ld'
drop if date==`sd' & symbol~="dprob" & (psource~="bloomberg" | hour<15)
bysort symbol: gen startpricetemp=mid if date==`sd' & psource=="bloomberg"
bysort symbol: egen startprice=max(startpricetemp)
replace date=. if psource=="bloomberg" & date==`sd'
drop if date==`sd' 
gen time=hour+minute/60
gen timeround=round(hour*10+minute/6+.49)
order time timeround
collapse (median) mid (lastnm) minute hour startprice, by(symbol date timeround)

gen return=100*((mid-startprice)/startprice)
drop if return==.

*WINSORIZE
levelsof (symbol), local(sym)
foreach xxx of local sym {
summ return if symbol=="`xxx'" & return~=., detail
	replace return=r(p1) if return<r(p1) & symbol=="`xxx'"
	replace return=r(p99) if return>r(p99) & symbol=="`xxx'"
}

gen quarter=qofd(date)
mmerge quarter symbol using  "$apath/US_weighting.dta", umatch(quarter Ticker) ukeep(weight weight_exypf)
keep if _merge==3 | symbol=="dprob"
bysort timeround date: egen weight_sum=sum(weight)
replace weight=weight/weight_sum
bysort timeround date: egen weight_exypf_sum=sum(weight_exypf)
replace weight_exypf=weight_exypf/weight_exypf_sum
gen return_weight=return*weight
gen return_weight_exypf=return*weight_exypf

*bysort date timeround: egen countnm=count(return)
collapse (mean) return (sum) return_weight return_weight_exypf (lastnm) minute hour, by(timeround date)

*GO TO LOG RETURNS
foreach ret in return return_weight return_weight_exypf {
	replace `ret'=100*log((`ret'/100)+1)
}	


**************
*default prob*
**************
append using "$apath/dprob_hf_all.dta" 
keep if (date>=`sd' & date<=`ld') | date==.
replace minute=mm(date_obs) if minute==.
replace hour=hh(date_obs) if hour==.
gen startdprobtemp=dprob if date==`sd' & close=="composite"
egen startdprob=max(startdprobtemp)
drop startdprobtemp
drop if date==`sd' & close~="composite"
replace hour=. if date==`sd' & close=="composite"
replace minute=. if date==`sd' & close=="composite"
replace date=. if date==`sd' & close=="composite"

gen delta_dprob=dprob-startdprob

replace minute=15 if hour==7
replace hour=9 if hour==7 & symbol=="dprob"
replace minute=45 if hour==4 & symbol=="dprob"
replace hour=8 if hour==4 & symbol=="dprob"
replace minute=15 if hour==2 & symbol=="dprob"
replace hour=8 if hour==2 & symbol=="dprob"
replace hour=hour-8
gen time=hour+minute/60
replace time=time/8
gen datestr=date
tostring datestr, replace
encode datestr, gen(did)
gen timedate=did+time-1
replace timedate=.99 if date==.
drop if timedate<.99

summ return
local tempmin=abs(r(min))
local tempmax=abs(r(max))
local temp=ceil(max(`tempmin',`tempmax'))
local temp=ceil(`temp'/3)*3
local ticksize=`temp'/3

summ delta
local tempmind=abs(r(min))
local tempmaxd=abs(r(max))
local tempd=ceil(max(`tempmind',`tempmaxd'))
local tempd=ceil(`tempd'/3)*3
local ticksized=`tempd'/3

local tempcombo=ceil(max(`tempd',`temp'))
local tempcombo=ceil(`tempcombo'/3)*3
local ticksizecombo=`tempcombo'/3

drop if return==. & symbol~="dprob"
*twoway (line return timedate if date==`ld', lcolor(blue) sort) (line delta_dprob timedate, yaxis(2) sort) (line return timedate if date~=`ld' & date~=., lcolor(blue) sort)  (scatter return timedate if date==., mcolor(blue) sort), title("`titledate'") name("f`x'") xlabel(, labsize(vsmall) ) legend(order(1 "Index Return" 2 "Change in Prob. of Default" 3 "test" 4 "test"))  xtitle("") graphregion(color(white)) ylabel(-`temp'(`ticksize')`temp', labels) ymtick(none) ylabel(-`tempd'(`ticksized')`tempd', labels axis(2)) ymtick(none, axis(2)) ytitle("") ytitle("",axis(2))
*graph export "$rpath/f`x'.eps", replace

*twoway (line return timedate if date==`ld', lcolor(blue) sort ) (connected delta_dprob timedate, sort lcolor(maroon) mcolor(maroon)) (line return timedate if date~=`ld' & date~=., lcolor(blue) sort)  (scatter return timedate if date==., mcolor(blue) sort), title("`titledate'") name("event`x'") xlabel(, labsize(vsmall) ) legend(order(1 "Index Return" 2 "Change in  Prob. of Default"))  ytitle("Percent") xtitle("") graphregion(color(white)) ylabel(-`tempcombo'(`ticksizecombo')`tempcombo', labels) ymtick(none) ytitle("") xlabel(0.99 "Close" 1.1875 "Open" 2 "Close" 2.1875 "Open" 3 "Close", labsize(small) angle(45))
*graph export "$rpath/event`x'.eps", replace

*twoway (line return_weight timedate if date==`ld', lcolor(blue) sort ) (connected delta_dprob timedate, sort lcolor(maroon) mcolor(maroon)) (line return_weight timedate if date~=`ld' & date~=., lcolor(blue) sort)  (scatter return_weight timedate if date==., mcolor(blue) sort), title("`titledate'") name("f`x'_weight") xlabel(, labsize(vsmall) ) legend(order(1 "Index Return" 2 "Change in  Prob. of Default"))  ytitle("Percent") xtitle("") graphregion(color(white)) ylabel(-`tempcombo'(`ticksizecombo')`tempcombo', labels) ymtick(none) ytitle("") xlabel(0.99 "Close" 1.1875 "Open" 2 "Close" 2.1875 "Open" 3 "Close", labsize(small) angle(45))
*graph export "$rpath/event`x'_weight.eps", replace

*twoway (line return_weight_exypf timedate if date==`ld', lcolor(blue) sort ) (connected delta_dprob timedate, sort lcolor(maroon) mcolor(maroon))  (scatter delta_dprob timedate if close=="composite", sort  mcolor(green) msize(large)) (line return_weight_exypf timedate if date~=`ld' & date~=., lcolor(blue) sort)  (scatter return_weight_exypf timedate if date==., mcolor(blue) sort), title("`titledate'") name("f`x'_weight_exypf") xlabel(, labsize(vsmall) ) legend(order(1 "Index Return" 2 "Change in  Prob. of Default" 3 "Composite CDS" ))  ytitle("Percent") xtitle("") graphregion(color(white)) ylabel(-`tempcombo'(`ticksizecombo')`tempcombo', labels) ymtick(none) ytitle("") xlabel(0.99 "Close" 1.1875 "Open" 2 "Close" 2.1875 "Open" 3 "Close", labsize(small) angle(45))
*graph export "$rpath/event`x'_weight_exypf.eps", replace

*SHADING
twoway (scatteri -`tempcombo' `prestart' -`tempcombo' `preend' `tempcombo' `preend' `tempcombo' `prestart', recast(area) color(grey*0.3)) (line return_weight_exypf timedate if date==`ld', lcolor(blue) sort ) (connected delta_dprob timedate, sort lcolor(maroon) mcolor(maroon))  (scatter delta_dprob timedate if close=="composite", sort  mcolor(green) msize(large)) (line return_weight_exypf timedate if date~=`ld' & date~=., lcolor(blue) sort)  (scatter return_weight_exypf timedate if date==., mcolor(blue) sort) , title("`titledate'") name("f`x'_weight_exypf_shade") xlabel(, labsize(vsmall) ) legend(order(1 "Pre-Event" 2 "Index Return" 3 "Change in  Prob. of Default" 4 "Composite CDS"))  ytitle("Percent") xtitle("") graphregion(color(white)) ylabel(-`tempcombo'(`ticksizecombo')`tempcombo', labels) ymtick(none) ytitle("") xlabel(0.99 "Close" 1.1875 "Open" 2 "Close" 2.1875 "Open" 3 "Close", labsize(small) angle(45))
graph export "$rpath/event`x'_weight_exypf_shade.eps", replace


*SHADING EVENT
twoway (scatteri -`tempcombo' `winstart' -`tempcombo' `winend' `tempcombo' `winend' `tempcombo' `winstart', recast(area) color(blue*0.3)) (line return_weight_exypf timedate if date==`ld', lcolor(blue) sort ) (connected delta_dprob timedate, sort lcolor(maroon) mcolor(maroon))  (scatter delta_dprob timedate if close=="composite", sort  mcolor(green) msize(large)) (line return_weight_exypf timedate if date~=`ld' & date~=., lcolor(blue) sort)  (scatter return_weight_exypf timedate if date==., mcolor(blue) sort), title("`titledate'") name("f`x'_weight_exypf_shade_event") xlabel(, labsize(vsmall) ) legend(order(1 "Event Window" 2 "Index Return" 3 "Change in  Prob. of Default" 4 "Composite CDS"))  ytitle("Percent") xtitle("") graphregion(color(white)) ylabel(-`tempcombo'(`ticksizecombo')`tempcombo', labels) ymtick(none) ytitle("") xlabel(0.99 "Close" 1.1875 "Open" 2 "Close" 2.1875 "Open" 3 "Close", labsize(small) angle(45))
graph export "$rpath/event`x'_weight_exypf_shade_event.eps", replace
graph export "$rpath/writeup_`x'.eps", replace


*EVENT ONLY
twoway (line return_weight_exypf timedate, lcolor(blue) sort) (connected delta_dprob timedate, sort lcolor(maroon) mcolor(maroon))  (scatter delta_dprob timedate if close=="composite", sort  mcolor(green) msize(large)) if timedate>=`winstart' & timedate<=`winend', title("`titledate'") name("f`x'_windowonly") xlabel(, labsize(vsmall) ) legend(order(1 "Index Return" 2 "Change in  Prob. of Default"))  ytitle("Percent") xtitle("") graphregion(color(white)) ylabel(-12(2)12, labels) ymtick(none) ytitle("") 
graph export "$rpath/event`x'_windowonly.eps", replace



keep if date==`ld'
keep if timeround==160  | close=="composite"
collapse (lastnm) delta_dprob return return_weight return_weight_exypf , by(date)
gen eventnum=`x'
save "$apath/`x'_hf.dta", replace
}

use "$apath/1_hf.dta", clear
erase "$apath/1_hf.dta"
forvalues x=2/15 {
	append using "$apath/`x'_hf.dta"
	erase "$apath/`x'_hf.dta"
}
order event date delta return return_weight return_weight_exypf
save "$apath/hf_summary.dta", replace
twoway (scatter return delta, ml(eventnum)) (scatter return_weight delta, ml(eventnum)) (scatter return_weight_exypf delta, ml(eventnum)), ytitle("Equity Return") xtitle("Change in Default Probability") graphregion(color(white)) name("HF_Scatter") 
graph export "$rpath/hf_scatter.eps", replace
export excel using "$rpath/hf_summ.xls", firstrow(variables) replace











************
*EVENT ONLY*

*******************
*CREATE INDEX******
*******************
discard
set more off
forvalues x=1/5 {
use "$hftemp/master.dta", clear
gen minute=mm(date_obs)
gen hour=hh(date_obs)


	if `x'==1 {
	local sd=td(04dec2012) 
	local ld=td(04dec2012) 
	local titledate="December 4, 2012"	
	}		
	
	if `x'==2 {
	local sd=td(07oct2013) 
	local ld=td(07oct2013) 
	local titledate="October 7, 2013"
	}
	
	if `x'==3 {
	local sd=td(10jan2014) 
	local ld=td(10jan2014) 
	local titledate="January 10, 2014"	
	}		
	
	if `x'==4 {
	local sd=td(16jun2014) 
	local ld=td(16jun2014) 
	local titledate="June 16, 2014"	

	}		

	if `x'==5 {
	local sd=td(26jun2014) 
	local ld=td(26jun2014) 
	local titledate="June 26, 2014"	
	}		

		
	
keep if date>=`sd' & date<=`ld'
bysort symbol: gen startpricetemp=mid if date==`sd' & psource=="bloomberg" & hour==9
bysort symbol: egen startprice=max(startpricetemp)
gen time=hour+minute/60
gen timeround=round(hour*10+minute/6+.49)
order time timeround
collapse (median) mid (lastnm) minute hour startprice, by(symbol date timeround)

gen return=100*((mid-startprice)/startprice)
drop if return==.

*WINSORIZE
levelsof (symbol), local(sym)
foreach xxx of local sym {
summ return if symbol=="`xxx'" & return~=., detail
	replace return=r(p1) if return<r(p1) & symbol=="`xxx'"
	replace return=r(p99) if return>r(p99) & symbol=="`xxx'"
}

gen quarter=qofd(date)
mmerge quarter symbol using  "$apath/US_weighting.dta", umatch(quarter Ticker) ukeep(weight weight_exypf)
keep if _merge==3 | symbol=="dprob"
bysort timeround date: egen weight_sum=sum(weight)
replace weight=weight/weight_sum
bysort timeround date: egen weight_exypf_sum=sum(weight_exypf)
replace weight_exypf=weight_exypf/weight_exypf_sum
gen return_weight=return*weight
gen return_weight_exypf=return*weight_exypf

*bysort date timeround: egen countnm=count(return)
collapse (mean) return (sum) return_weight return_weight_exypf (lastnm) minute hour, by(timeround date)

*GO TO LOG RETURNS
foreach ret in return return_weight return_weight_exypf {
	replace `ret'=100*log((`ret'/100)+1)
}	


**************
*default prob*
**************
append using "$apath/dprob_hf_all.dta" 
keep if date>=`sd' & date<=`ld'
replace minute=mm(date_obs) if minute==.
replace hour=hh(date_obs) if hour==.
gen startdprobtemp=dprob if date==`sd' & close=="europe"
egen startdprob=max(startdprobtemp)
drop startdprobtemp
drop if close=="japan" | close=="asia" | close=="londonmidday"


gen delta_dprob=dprob-startdprob

gen time=hour+minute/60

*EVENT ONLY
twoway (line return_weight_exypf time, lcolor(blue) sort) (scatter delta_dprob time, sort lcolor(maroon) mcolor(maroon) ml(close)) if time>=9.5 & time<=16, title("xx") name("xx") xlabel(, labsize(vsmall) ) legend(order(1 "Index Return" 2 "Change in  Prob. of Default"))  ytitle("Percent") xtitle("") graphregion(color(white)) ylabel(-12(2)12, labels) ymtick(none) ytitle("") 
graph export "$rpath/event`x'_windowonly.eps", replace










/*
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

twoway (line return timedate if symbol=="YPF") (connected dprob timedate if symbol=="dprob", yaxis(2)) (scatter dprob timedate if symbol=="dprob" & close=="composite", yaxis(2)) (scatter return timedate if symbol=="YPF" & psource=="bloomberg")  if date>=td(`date')-1 & date<=td(`date')+1, title("`date'") name("test_`date'") xlabel(, labsize(vsmall) ) legend(order(1 "YPF Return" 2 "Prob. of Default" 3 "Composite CDS" 4 "Bloomberg YPF O/C")) xlabel(`d1_open' "D-1 9:30 am" `d1_close' "D-1 4:00 pm" `d2_open' "D 9:30 am" `d2_close' "D 4:00 pm" `d3_open' "D+1 9:30 am" `d3_close' "D+1 4:00 pm", labsize(small) angle(45)) xtitle("") graphregion(color(white))
graph export "$rpath/hf_`date'_newaxis.png", replace
}
*/

/*


*****************************
*NEW FIGURES THAT MATCH REGRESSIONS
************************************

forvalues x=1/15 {
use "$hftemp/master_winsor.dta", clear
keep if symbol=="YPF"
append using "$apath/dprob_hf_all.dta" 
gen minute=mm(date_obs)
gen hour=hh(date_obs)
	if `x'==1 {
	local sd=td(23nov2012) 
	local ld=td(27nov2012) 
	}
	if `x'==2 {
	local sd=td(27nov2012) 
	local ld=td(29nov2012) 
	}		
	if `x'==3 {
	local sd=td(03dec2012) 
	local ld=td(05dec2012) 
	}		
		if `x'==4 {
	local sd=td(05dec2012) 
	local ld=td(07dec2012) 
	}		
		if `x'==5 {
	local sd=td(09jan2013) 
	local ld=td(11jan2013) 
	}		
		if `x'==6 {
	local sd=td(28feb2013) 
	local ld=td(04mar2013) 
	}		
		if `x'==7 {
	local sd=td(25mar2013) 
	local ld=td(27mar2013) 
	}		
		if `x'==8 {
	local sd=td(22aug2013) 
	local ld=td(26aug2013) 
	}		
		if `x'==9 {
	local sd=td(02oct2013) 
	local ld=td(04oct2013) 
	}		
		if `x'==10 {
	local sd=td(04oct2013) 
	local ld=td(08oct2013) 
	}				
	if `x'==11 {
	local sd=td(15nov2013) 
	local ld=td(19nov2013) 
	}		
		if `x'==12 {
	local sd=td(09jan2013) 
	local ld=td(13jan2013) 
	}		
		if `x'==13 {
	local sd=td(12jun2014) 
	local ld=td(16jun2014) 
	}		
		if `x'==14 {
	local sd=td(20jun2014) 
	local ld=td(24jun2014) 
	}	
	if `x'==15 {
	local sd=td(25jun2014) 
	local ld=td(27jun2014) 
	}			
	keep if date>=`sd' & date<=`ld'

drop if date==`sd' & symbol~="dprob" & (psource~="bloomberg" | hour<15)
drop if date==`sd' & symbol=="dprob" & close~="composite"
drop return
gen startpricetemp=mid if date==`sd' & psource=="bloomberg"
egen startprice=max(startpricetemp)
gen startdprobtemp=dprob if date==`sd' & close=="composite"
egen startdprob=max(startdprobtemp)
order  startprice startdprob
drop *temp
drop if date==`sd'
gen return=100*(log(mid)-log(startprice))
gen delta_dprob=dprob-startdprob

replace hour=9 if hour==7 & symbol=="dprob"
replace minute=30 if hour==4 & symbol=="dprob"
replace hour=8 if hour==4 & symbol=="dprob"
replace hour=8 if hour==2 & symbol=="dprob"
replace hour=hour-8
gen time=hour+minute/60
replace time=time/8
gen datestr=date
tostring datestr, replace
encode datestr, gen(did)

gen timedate=did+time-1
twoway (line return timedate if symbol=="YPF") (connected delta_dprob timedate if symbol=="dprob", yaxis(2)), title("`x'") name("f`x'") xlabel(, labsize(vsmall) ) legend(order(1 "YPF Return" 2 "Prob. of Default" 3 "Composite CDS" 4 "Bloomberg YPF O/C"))  xtitle("") graphregion(color(white))
}

*****************************************
*Declare start to be price at start close
*Calculate returns
*then only keep 2 day window
*rescale so we have date_obs is 0+time and 1+time.






*******************
*OLD WAY
*************
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



