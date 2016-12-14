
set more off


* This dummy controls the CDS data source.
* This is 0 for bberg London and NY closes
* 1 is for bberg "i" variables, open and close
* 2 for markit, with Datastream appended
* 3 for Markit NYC EOD and Europe Close
* 4 for Markit Composite EOD only
* 5 for Markit Composite EOD and Europe Close
* 6 for Markit implied default prob, 5yr, Composite and Europe
* If 2/4 is chosen, there is only 1 day and 2day events.

local cds_i_marks 8

* 0: second day 1: first day 2: exclude 2 3: exclude 3 (incl 27Nov12) from ref report
* 4: exclude 3 (incl 4Mar13) from ref report, 5: exclude all 4 from ref report
local alt_dates 1

local defprobfile "$apath/Default_Prob_All.dta"
capture confirm file `defprobfile'
if _rc != 0 {
	local defprobfile "$mpath/Default_Prob_All.dta"
}


if "$RSalt_dates" == "1" {
	local alt_dates 0
}
if "$RSalt_dates" == "2" {
	local alt_dates 2
}
if "$RSalt_dates" == "3" {
	local alt_dates 3
}
if "$RSalt_dates" == "4" {
	local alt_dates 4
}
if "$RSalt_dates" == "5" {
	local alt_dates 5
}

if "$cds_robust"=="1" {
	if "$RSdaytype" == "twodayL" {
		local cds_i_marks 10
	}
	else{
		local cds_i_marks 7
	}
}

if "$hetero_event" == "1" {
	local cds_i_marks 6
}

if "$RSwarrants_run" == "1" {
	local cds_i_marks 10
}


* This code loads CDS returns
* The procedure depends on the data source.
if `cds_i_marks' < 2 {
	use "$bbpath/CDS_BB.dta" , clear

	keep date px_last px_open rep_id reporter

	su rep_id if regexm(reporter,"BGT")
	local tokyo = `r(mean)'

	su rep_id if regexm(reporter,"BGL")
	local london = `r(mean)'

	su rep_id if regexm(reporter,"BGN")
	local nyc = `r(mean)'

	su rep_id if regexm(reporter,"BIT")
	local tokyo_i = `r(mean)'

	su rep_id if regexm(reporter,"BIL")
	local london_i = `r(mean)'

	su rep_id if regexm(reporter,"BIN")
	local nyc_i = `r(mean)'


	drop reporter

	sort date rep_id

	reshape wide px_last px_open, i(date) j(rep_id)
}
else if `cds_i_marks' == 2{
	use "$cpath/CDS_Merged.dta", clear

	drop if regexm(type,"open")

	gen CDS = Markit

}
else if `cds_i_marks' == 3 | `cds_i_marks' == 5 {
	use "$mpath/Sameday_USD.dta", clear
	drop if abs(time_est-15.5) > 0.1 & abs(time_est-9.5) > 0.1
	drop if date < mdy(1,1,`startyear')
	drop if date >= mdy(7,30,2014)
	
	keep date Spread5y Timezone
	
	replace Spread5y = Spread5y * 100
	
	reshape wide Spread5y, i(date) j(Timezone) string
	
	if `cds_i_marks' == 5 {
		drop Spread5yN
		mmerge date using "$mpath/Composite_USD.dta", ukeep(Spread5y) unmatched(none)
		rename Spread5y Spread5yN
		replace Spread5yN = Spread5yN * 100
		drop _merge
	}

}
else if `cds_i_marks' == 4 {
	use "$mpath/Composite_USD.dta", clear
		
	drop if date < mdy(1,1,`startyear')
	drop if date >= mdy(7,30,2014)
	
	ta CompositeDepth5y
	gen CDS = Spread5y * 100
	keep date CDS
}
else if `cds_i_marks' == 6 {
	*use "$mpath/Default_Prob.dta", clear
	*rename europe Spread5yE
	*rename composite Spread5yN
	use "`defprobfile'", clear
	/*keep date ust_def5y ust_def5y_europe 
	rename ust_def5y_europe Spread5yE
	rename ust_def5y Spread5yN*/
	keep date def5y def5y_europe 
	rename def5y_europe Spread5yE
	rename def5y Spread5yN
	
	* why is the line here?
	global cds_app ""
}

else if `cds_i_marks' == 7 {
	use "`defprobfile'", clear
	keep date  $cds_n
	rename $cds_n Spread5yN
}

else if `cds_i_marks' == 8  {
	use "`defprobfile'", clear
	keep date mC5_5y 
	rename  mC5_5y Spread5yN
}

else if `cds_i_marks' == 9  {
	use "$apath/bondlevel.dta", clear
	keep if Ticker=="defbond_eur"
	keep date px_close
	replace px_close=log(px_close)
	rename  px_close Spread5yN
}
else if `cds_i_marks' == 10 {
	use "`defprobfile'", clear

	if "$cds_robust" == 1 {
		local cdsname $cds_n
	}
	else {
		local cdsname def5y_london
	}
	
	keep date def5y $cds_n
	rename $cds_n Spread5yE
	rename def5y Spread5yN
}


* We use a business day calendar to figure out
* the financial returns. This only deals with 
* weekends, not holidays.
format date %td

gen bdate = bofd("basic",date)
format bdate %tbbasic

drop if bdate == .

sort bdate
tsset bdate


* For each type of window, compute the relevant return
* The procedure depends on the data source.
if `cds_i_marks' ==  0 {

	* I think the tokyo marks are often stale.
	gen cds_intra = px_last`nyc' - px_last`london'
	gen cds_nightbefore = px_last`london' - L.px_last`nyc'

	* This is used for holiday issues
	gen cds_1_5 = px_last`london' - L2.px_last`nyc'
	gen cds_onedayN = px_last`nyc' - L.px_last`nyc'
	gen cds_onedayL = px_last`london' - L.px_last`london'
	gen cds_twoday = px_last`nyc' - L2.px_last`nyc'
	gen cds_twodayL = px_last`london' - L.px_last`london'
	
	keep bdate date cds_intra cds_nightbefore cds_1_5 cds_onedayN cds_onedayL cds_twoday cds_twodayL
}
else if `cds_i_marks' == 2 | `cds_i_marks' == 4 {
	*gen mark = abs(D.DS) < 0.001
	*replace DS = . if mark == 1
	*drop mark
	
	if `cds_i_marks' == 2 {
		* Append Datastream data to Markit, since Markit cuts off
		replace CDS = DS if CDS == . & date > mdy(5,12,2014)
	}
	
	* Many of these events cannot be computed with close-to-close data
	gen cds_intra = .
	gen cds_nightbefore = .

	gen cds_1_5 = .
	gen cds_onedayN = D.CDS
	gen cds_onedayL = .
	gen cds_twoday = CDS - L2.CDS
	gen cds_twodayL = .
	
	keep bdate date cds_intra cds_nightbefore cds_1_5 cds_onedayN cds_onedayL cds_twoday cds_twodayL

}
else if `cds_i_marks' == 3 | `cds_i_marks' == 5 | `cds_i_marks' == 6 | `cds_i_marks' == 10 {

	gen cds_intra = Spread5yN - Spread5yE
	gen cds_nightbefore = Spread5yE - L.Spread5yN

	* This is used for holiday issues
	gen cds_1_5 = Spread5yE - L2.Spread5yN
	gen cds_onedayN = Spread5yN - L.Spread5yN
	gen cds_onedayL = Spread5yE - L.Spread5yE
	
	gen cds_twoday = Spread5yN - L2.Spread5yN
	gen cds_twodayL = Spread5yE - L2.Spread5yE

	keep bdate date cds_intra cds_nightbefore cds_1_5 cds_onedayN cds_onedayL cds_twoday cds_twodayL

}

else if `cds_i_marks' == 8 | `cds_i_marks' == 7 | `cds_i_marks' == 9 {

	gen cds_intra = .
	gen cds_nightbefore = .

	* This is used for holiday issues
	gen cds_1_5 = .
	gen cds_onedayN = Spread5yN - L.Spread5yN
	gen cds_onedayL = .
	gen cds_twoday = Spread5yN - L2.Spread5yN
	gen cds_twodayL = .

	keep bdate date cds_intra cds_nightbefore cds_1_5 cds_onedayN cds_onedayL cds_twoday cds_twodayL

}

else{
	* I think the tokyo marks are often stale.
	gen cds_intra = px_last`nyc_i' - px_open`nyc_i'
	gen cds_nightbefore = px_open`nyc_i' - L.px_last`nyc_i'

	* This is used for holiday issues
	gen cds_1_5 = px_open`nyc_i' - L2.px_last`nyc_i'
	gen cds_onedayN = px_last`nyc_i' - L.px_last`nyc_i'
	gen cds_onedayL = px_open`nyc_i' - L.px_open`nyc_i'
	
	gen cds_twoday = px_last`nyc_i' - L2.px_last`nyc_i'
	gen cds_twodayL = px_open`nyc_i' - L2.px_open`nyc_i'

	keep bdate date cds_intra cds_nightbefore cds_1_5 cds_onedayN cds_onedayL cds_twoday cds_twodayL

}

* Some information for reference.
* Argentina trading hours: 
* 11am to 5pm ART. http://www.wikinvest.com/wiki/Buenos_Aires_Stock_Exchange

* Lexis Nexus search terms:
* [((Argentina AND (Griesa OR Debt OR Sovereign OR Default OR Case or NML)) and Date(geq(10/8/2012) and leq(10/8/2014)))]
* Sources: [Associated Press Financial Wire;The Associated Press;Associated Press International;Reuters Knowledge Direct;UPI (United Press International);Thomson Reuters ONE;Associated Press Online]

* This code labels all of the events.

gen event_intra=0
gen event_nightbefore=0
gen event_1_5 = 0
gen event_onedayN = 0
gen event_onedayL = 0
gen eventexcluded = 0
gen event_twoday = 0
gen event_twodayL = 0

gen eventday = 0
gen eventdayL = 0

* The first court ruling.
replace eventexcluded = 1 if date==td(07dec2011)

*replace WSJ_date=1 if date==td(23feb2012)
* I cannot find any contemporaneous news articles for this one.
replace eventexcluded = 1 if date==td(23feb2012)

*replace WSJ_date=1 if date==td(05mar2012)
* Another one without much contemporaneous new coverage.
* The D_CDS is missing because of business day issues.
replace eventexcluded = 1 if date==td(05mar2012)

* This is a non-WSJ date.
* http://www.bloomberg.com/news/2012-08-20/argentina-sovereign-immunity-argument-rejected-by-u-s-court.html


*replace event_1_5 = 1 if date==td(29oct2012)
replace eventexcluded = 1 if date==td(29oct2012)
* This was the day they lost their appeal.
* It is definitely intra-day here.
* The below story was filed at 2:14pm EDT/3:14pm ART
* http://www.bloomberg.com/news/2012-10-26/u-s-appeals-court-upholds-ruling-against-argentina-over-bonds.html
* Earliest AP/UPI newswire article at 6:13pm EDT.
* The decision pdf was created on 10/25 at 12:43pm.
* The 26th was the Friday before Hurricane Sandy hit
* http://money.cnn.com/2012/10/29/investing/hurricane-sandy-stock-markets/
* Therefore, we use London close on Monday vs NY close on Thursday night.

* There is a 21Nov2012 date that is very problematic.
* http://www.bloomberg.com/news/2012-11-22/argentine-stocks-drop-on-ruling-not-publicly-available.html
* This information shows up in CDS between nov 23 and 26.
* Thanksgiving was Nov 22, and markets were probably closed on the 22/23.
* Here is reference to an article published at 5am EST on the 22nd.
* "Court orders Argentina to pay US$1.33bn to defaulted bondholders." Business News Americas - English. November 22, 2012 Thursday 10:33 AM GMT . Date Accessed: 2014/10/15. www.lexisnexis.com/hottopics/lnacademic.
*replace event_nightbefore = 1 if date== td(22nov2012)
*replace event_1_5 = 1 if date == td(23nov2012)

* Griesa denies exchange bondholders request for stay
* Date on PDF is 3:43pm.
* the 26th is an argentine holiday
*replace event_1_5 = 1 if date == td(27nov2012)

* CHange this is 1 to run code with this date
*replace event_special = 1 if date == td(27nov2012)
*replace eventexcluded = 1 if date == td(26nov2012)
replace eventexcluded = 1 if date == td(22nov2012)
*replace event_twoday = 1 if date == td(23nov2012)


if `alt_dates' == 3 | `alt_dates' == 5 {
	replace eventexcluded = 1 if date == td(27nov2012)
}
else {
	replace event_onedayL = 1 if date == td(27nov2012)
	replace eventday = 1 if date == td(27nov2012)
	replace eventdayL = 1 if date == td(28nov2012)
}

*replace WSJ_date=1 if date==td(28nov2012)
* The appeals court granted an emergency stay.
* http://www.bloomberg.com/news/2012-11-28/argentina-wins-stay-of-order-forcing-payment-on-defaulted-bonds.html
* The bberg article was filed the next morning, and the CDS moved a lot on the 29th.
* The earlier AP/UPI story was filed at 8:26pm EDT on the 28th.
* Modification date for PDF is 11/28 at 5:05pm.
*replace WSJ_date=1 if date==td(29nov2012)

replace event_nightbefore = 1 if date==td(29nov2012)
replace eventday = 1 if date == td(29nov2012)
replace eventdayL = 1 if date == td(30nov2012)

* Appeals court denies to stay order requiring Argentina to post security.
* 1:15pm time stamp on order.
replace event_intra = 1 if date == td(04dec2012)
replace eventdayL = 1 if date == td(05dec2012)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(05dec2012)
}
else {
	replace eventday = 1 if date == td(04dec2012)
}

* Appeals court allows BoNY to appear as interested party
* 1:50pm time stamp on order.
* This is misleading. Order created 
replace event_onedayN = 1 if date == td(06dec2012)
replace eventdayL = 1 if date == td(07dec2012)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(07dec2012)
}
else {
	replace eventday = 1 if date == td(06dec2012)
}



* Appeals court denies exchange bondholder's motion for stay
* Document created at 4:50pm Jan 10, modified on Jan 11.
* Listed as Jan10.
* Therefore, I beleive this event was overnight.
replace event_nightbefore = 1 if date==td(11jan2013)
replace eventday = 1 if date == td(11jan2013)
replace eventdayL = 1 if date == td(11jan2013)


* Appeals court denies appeal for panel rehearing.
* Document created at 3:27, posted at 4pm.
* On the 27th, argentina said they would default.
* So we need to look at the intraday here.
* http://www.shearman.com/~/media/Files/NewsInsights/Publications/2013/02/Dont-Cry-for-Me-Argentine-Bondholders-Important-__/Files/View-full-memo-Dont-Cry-for-Me-Argentine-Bondhol__/FileAttachment/DontCryforMeArgentineBondholdersImportantArgumen__.pdf
*replace event_intra = 1 if date==td(28feb2013)
*replace event_nightbefore = 1 if date==td(01mar2013)

* Sadly, this date is not usable, because the announcement was made at the beginning of a trial.
replace eventexcluded = 1 if date==td(28feb2013)


*replace WSJ_date=1 if date==td(01mar2013)
* This one, the story was filed at midnight
* http://www.bloomberg.com/news/2013-03-01/argentina-asked-by-u-s-court-to-provide-bondholder-pay-formula.html
* However, this one was filed before market close:
* http://ftalphaville.ft.com/2013/03/01/1406782/give-us-a-formula-argentina/
* 27Feb2013 is problematic, because Argentina threatened to default that day.
* The earliest AP/UPI story is 3:54pm EST/5:54pm ART


*replace event_intra = 1 if date==td(01mar2013)
*replace event_nightbefore = 1 if date==td(04mar2013)
if `alt_dates' < 4 {
	replace event_onedayL = 1 if date == td(04mar2013)
	replace eventday = 1 if date == td(04mar2013)
	replace eventdayL = 1 if date == td(04mar2013)
}
else {
	replace eventexcluded = 1 if date == td(04mar2013)
}

* March 26 date in WSJ, missing in initial list
* 2:38pm EST/3:38pm ART AP/UPI story
* http://www.bloomberg.com/news/2013-03-26/argentina-loses-bid-for-full-court-rehearing-on-bonds.html
* 2:35pm BBerg story
*replace WSJ_date=1 if date==td(26mar2013)
replace event_onedayL = 1 if date==td(27mar2013)
replace eventday = 1 if date == td(27mar2013)
replace eventdayL = 1 if date == td(27mar2013)


*replace WSJ_date=1 if date==td(29mar2013)
*replace WSJ_date=1 if date==td(01apr2013)
* This one is definitely an over-the-weekend move.
* Argentina submitted its payment plan just before midnight on Friday.
* earliest AP/UPI story is 11:07pm EDT on Friday.
* Mar29 was good Friday, and the 28th is a catholic holiday.
* Need to check when the stock exchange was closed.
*replace event_nightbefore = 1 if date == td(01apr2013)
*This one doesn't seem like an event-- no Griesa ruling.
*replace eventexcluded = 1 if date==td(01apr2013)

*replace WSJ_date=1 if date==td(20apr2013)
*replace WSJ_date=1 if date==td(22apr2013)
* Holdouts reject payment plan. Also not an event.
* http://www.bloomberg.com/news/2013-04-20/argentina-bondholders-reject-plan-to-pay-defaulted-debt.html
* legal document: http://www.shearman.com/~/media/Files/Old-Site-Files/Arg24_-NMLCapitalvArgentina20132004.pdf
* BBerg story is 12:01am EDT on the 20th, which is a Saturday.
* This one should be friday-monday
* There is no AP/UPI story.
*replace eventexcluded = 1 if date==td(22apr2013)


* Griesa's decision was upheld. This is the event that got more news.
* http://www.shearman.com/~/media/Files/Services/Argentine-Sovereign-Debt/2013/Arg33_NML_Second_Circuit_Decision.pdf
* http://www.bloomberg.com/news/2013-08-23/argentina-loses-u-s-appeal-of-defaulted-bonds-case.html
* Bberg story is 4:02pm EDT.
* AP story is 5:24pm EDT/6:24pm ART.
* It looks like this is post-close for the MERVAL.
* So there may be alignment problems.
* this timestamp must be wrong: http://www.bnamericas.com/story.jsp?sector=3&noticia=625408&idioma=I&source=
* In lexis-nexus, it has a time stamp of 10:35am GMT-- which seems wrong.
* However, the ruling is listed at 10:17am
*replace WSJ_date=1 if date==td(23aug2013)
replace event_onedayN = 1 if date==td(23aug2013)
replace eventdayL = 1 if date == td(26aug2013)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(26aug2013)
}
else {
	replace eventday = 1 if date == td(23aug2013)
}

* This one shows up as the supreme court agreeing to a re-hearing
* http://www.bnamericas.com/story.jsp?sector=3&noticia=627132&idioma=I&source=
* http://www.bloomberg.com/news/2013-09-11/top-u-s-court-may-act-in-october-on-argentina-bond-case.html
* The latter is Sep 11, 2:35pm EST
*replace event_intra =1 if date==td(11sep2013)
* I think this is a "fake news" story. The SC had to schedule anyways.

* This is another story but no AP/other docs:
* http://www.bloomberg.com/news/2013-09-25/argentina-loses-motion-to-dismiss-suit-over-central-bank.html
replace eventexcluded = 1 if date==td(26sep2013)


* Here, Griesa barred a new exchange offer:
* http://www.bloomberg.com/news/2013-10-03/argentina-barred-by-u-s-judge-from-evading-bonds-order.html
* http://www.shearman.com/~/media/Files/Services/Argentine-Sovereign-Debt/2013/Arg36NML20131013Order.pdf
* Bberg story at 6:27pm EDT. 
*replace WSJ_date=1 if date==td(04oct2013)
*replace event_nightbefore = 1 if date==td(07oct2013)
* The actual order was signed on the 3rd at 2:46pm.
replace event_onedayL = 1 if date==td(04oct2013)
replace eventday = 1 if date == td(04oct2013)
replace eventdayL = 1 if date == td(04oct2013)

if `alt_dates' < 2 {
	* This was the denial of supreme court appeal
	replace event_intra = 1 if date==td(07oct2013)
	* must be the 8th, not 7th, to avoid overlap with the 4th
	replace eventday = 1 if date == td(08oct2013)
	replace eventdayL = 1 if date == td(08oct2013)
	* AP story at 9:35am EDT/10:35am ART.
}
else {
	replace eventexcluded = 1 if date == td(08oct2013)
}

* Some appeals were denied here.
*http://www.bloomberg.com/news/2013-11-18/argentina-loses-bid-for-full-court-rehearing-of-bonds-appeal.html
* The order was created at 11am and modified at 5pm.
*replace WSJ_date=1 if date==td(18nov2013)
replace event_onedayL = 1 if date==td(19nov2013)
replace eventday = 1 if date == td(19nov2013)
replace eventdayL = 1 if date == td(19nov2013)

* Supreme court grants cert.
if `alt_dates' < 2 {
	replace event_intra = 1 if date==td(10jan2014)
	replace eventdayL = 1 if date == td(13jan2014)
	if `alt_dates' > 0 {
		replace eventday = 1 if date == td(13jan2014)
	}
	else {
		replace eventday = 1 if date == td(10jan2014)
	}
}
else {
	replace eventexcluded = 1 if date == td(10jan2014)
}

* Supreme court appeal rejection.
* http://www.bloomberg.com/news/2014-06-16/argentine-bonds-plunge-after-u-s-supreme-court-rejects-appeal.html
* This one is intraday. BBerg story 2:13pm EDT.
* AP story filed at 12:52pm EDT/1:52 ART.
*replace event_intra = 1 if date==td(16jun2014)
replace event_intra = 1 if date==td(16jun2014)
replace eventday = 1 if date == td(16jun2014)
replace eventdayL = 1 if date == td(16jun2014)

* Griesa forbids argentine law exchange
* possible confound: Argentina proposes debt swap plan on 19th
* Doc written at 2:54pm

* Changed to be post-close, due to Christina's speech during the day and
* media reports of a later afternoon release.
//replace event_onedayL = 1 if date==td(23jun2014)
replace event_nightbefore = 1 if date==td(23jun2014)
replace eventdayL = 1 if date==td(23jun2014)

* Griesa appoints special master. 1:05pm
* http://www.bloomberg.com/news/2014-06-23/argentina-bond-judge-picks-special-master-to-guide-negotiations.html
* 7:35pm on the article
* 
replace event_onedayL = 1 if date==td(24jun2014)
replace eventday = 1 if date == td(24jun2014)
replace eventdayL = 1 if date==td(25jun2014)

* Griesa denies stay.
* http://www.bloomberg.com/news/2014-06-26/argentina-bond-fight-judge-rejects-stay-of-debt-ruling.html
* 2:05pm EDT.
* Possible confound: Argentina said some stuff at the UN on the same day.
replace event_intra = 1 if date==td(26jun2014)
replace eventdayL = 1 if date == td(27jun2014)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(27jun2014)
}
else {
	replace eventday = 1 if date == td(26jun2014)
}

* Griesa allows Citi to pay Repsol bonds this month.
* http://www.shearman.com/~/media/Files/Services/Argentine-Sovereign-Debt/2014/Arg134-072814-Order-re-payment.pdf
* File dated 3:51pm.
* http://www.bloomberg.com/news/2014-07-28/argentina-bond-judge-says-nation-may-pay-repsol-bonds.html
* bberg story 12:01am
*replace event_onedayL = 1 if date==td(29jul2014)
replace eventexcluded = 1 if date==td(29jul2014)
replace eventexcluded = 1 if date==td(28jul2014)

* This was the default date.
*http://www.bloomberg.com/news/2014-07-30/argentina-defaults-according-to-s-p-as-debt-meetings-continue.html
drop if date >= td(30jul2014)

* Citi loses appeal regarding Argentine law bonds.
* http://www.shearman.com/~/media/Files/Services/Argentine-Sovereign-Debt/2014/Arg167-091914-142689-Doc-167.pdf
* http://www.bloomberg.com/news/2014-09-19/citibank-loses-bid-to-appeal-argentina-bond-payment-case.html
* bberg story dated a day later
* The AP story summarizes oral arguments from the 18th. So hard to date this event.

* Griesa gives Citi a delay:
* http://www.shearman.com/~/media/Files/Services/Argentine-Sovereign-Debt/2014/Arg178-092914-08cv6978-Doc-683.pdf
* http://www.bloomberg.com/news/2014-09-26/argentina-bond-judge-lets-citibank-make-sept-30-payment-1-.html
* Bberg story 7:51pm EST.
*replace WSJ_date=1 if date==td(29sep2014)

* Contempt order.
* http://www.shearman.com/~/media/Files/Services/Argentine-Sovereign-Debt/2014/Arg182-093014-086978-Doc-687.pdf
* http://www.bloomberg.com/news/2014-09-29/argentina-found-in-contempt-of-court-by-bond-fight-judge.html
* Bberg story dated 12:01am on the 30th.
* AP story dated 10:04pm EDT.
*replace WSJ_date=1 if date==td(30sep2014)


* If we're using Markit/DS data, a lot of these event windows must be 
* widened. This code implements that.

if `cds_i_marks' == 2 | `cds_i_marks' == 4 | `cds_i_marks' == 8 | `cds_i_marks' == 7 | `cds_i_marks' == 9 {

	replace event_onedayN = 1 if event_intra == 1
	replace event_intra = .

	//replace event_twoday = 1 if event_nightbefore == 1
	replace event_onedayN = 1 if event_nightbefore == 1
	replace event_nightbefore = .

	replace event_twoday = 1 if event_1_5 == 1
	replace event_1_5 = .

	replace event_twoday = 1 if event_onedayL == 1
	replace event_onedayL = .

}


save "$apath/CDS_Data.dta", replace
