
set more off


* This dummy controls the CDS data source.
* It can take on several values
* The numbering is strange due to deprecated options

* 6: "open" means Europe sameday, "close" means composite close
* 7: controlled externally by the CDS_Robust file. Only closes, no opens.
* 8: "close" means composite close, no opens.
* 10: "open" is controlled externally by the CDS_Robust file, defaults to London. Close is composite close.

local cds_i_marks 8


* This option controls, for events known to occur on a single day, on which day the event occurs.
* 0 means the second day, 1 the first. 1 is the default in the paper.
* values of 2-5 exclude certain dates that a referee asked to see sub-samples without.
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
if `cds_i_marks' == 6 {
	
	use "`defprobfile'", clear
	
	keep date def5y def5y_europe 
	rename def5y_europe Spread5yE
	rename def5y Spread5yN
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
else {
	//if `cds_i_marks' == 10
	use "`defprobfile'", clear

	if "$cds_robust" == "1" {
		local cdsname $cds_n
	}
	else {
		local cdsname def5y_london
	}
	
	keep date def5y `cdsname'
	rename `cdsname' Spread5yE
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
* The procedure depends on whether opens and closes, or just closes, are present.
if `cds_i_marks' == 6 | `cds_i_marks' == 10 {

	gen cds_intra = Spread5yN - Spread5yE
	gen cds_nightbefore = Spread5yE - L.Spread5yN
	gen cds_1_5 = Spread5yE - L2.Spread5yN
	gen cds_onedayN = Spread5yN - L.Spread5yN
	gen cds_onedayL = Spread5yE - L.Spread5yE
	gen cds_twoday = Spread5yN - L2.Spread5yN
	gen cds_twodayL = Spread5yE - L2.Spread5yE

	keep bdate date cds_intra cds_nightbefore cds_1_5 cds_onedayN cds_onedayL cds_twoday cds_twodayL

}
else {
	gen cds_intra = .
	gen cds_nightbefore = .
	gen cds_1_5 = .
	gen cds_onedayN = Spread5yN - L.Spread5yN
	gen cds_onedayL = .
	gen cds_twoday = Spread5yN - L2.Spread5yN
	gen cds_twodayL = .

	keep bdate date cds_intra cds_nightbefore cds_1_5 cds_onedayN cds_onedayL cds_twoday cds_twodayL
}


* This code labels all of the events.
* See appendix J in the paper for more details.

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

replace eventexcluded = 1 if date==td(23feb2012)

replace eventexcluded = 1 if date==td(05mar2012)

* We exclude the 29th in the code, although the table says the 26th.
* Will decide what to do here.
replace eventexcluded = 1 if date==td(26oct2012)
*replace eventexcluded = 1 if date==td(29oct2012)

replace eventexcluded = 1 if date == td(22nov2012)

if `alt_dates' == 3 | `alt_dates' == 5 {
	replace eventexcluded = 1 if date == td(27nov2012)
}
else {
	replace event_onedayL = 1 if date == td(27nov2012)
	replace eventday = 1 if date == td(27nov2012)
	replace eventdayL = 1 if date == td(28nov2012)
}

replace event_nightbefore = 1 if date==td(29nov2012)
replace eventday = 1 if date == td(29nov2012)
replace eventdayL = 1 if date == td(30nov2012)


replace event_intra = 1 if date == td(04dec2012)
replace eventdayL = 1 if date == td(05dec2012)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(05dec2012)
}
else {
	replace eventday = 1 if date == td(04dec2012)
}


replace event_onedayN = 1 if date == td(06dec2012)
replace eventdayL = 1 if date == td(07dec2012)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(07dec2012)
}
else {
	replace eventday = 1 if date == td(06dec2012)
}

replace event_nightbefore = 1 if date==td(11jan2013)
replace eventday = 1 if date == td(11jan2013)
replace eventdayL = 1 if date == td(11jan2013)


replace eventexcluded = 1 if date==td(28feb2013)

if `alt_dates' < 4 {
	replace event_onedayL = 1 if date == td(04mar2013)
	replace eventday = 1 if date == td(04mar2013)
	replace eventdayL = 1 if date == td(04mar2013)
}
else {
	replace eventexcluded = 1 if date == td(04mar2013)
}


replace event_onedayL = 1 if date==td(27mar2013)
replace eventday = 1 if date == td(27mar2013)
replace eventdayL = 1 if date == td(27mar2013)


replace event_onedayN = 1 if date==td(23aug2013)
replace eventdayL = 1 if date == td(26aug2013)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(26aug2013)
}
else {
	replace eventday = 1 if date == td(23aug2013)
}

replace eventexcluded = 1 if date==td(26sep2013)


replace event_onedayL = 1 if date==td(04oct2013)
replace eventday = 1 if date == td(04oct2013)
replace eventdayL = 1 if date == td(04oct2013)

if `alt_dates' < 2 {
	replace event_intra = 1 if date==td(07oct2013)
	* must be the 8th, not 7th, to avoid overlap with the 4th
	replace eventday = 1 if date == td(08oct2013)
	replace eventdayL = 1 if date == td(08oct2013)

}
else {
	replace eventexcluded = 1 if date == td(08oct2013)
}


replace event_onedayL = 1 if date==td(19nov2013)
replace eventday = 1 if date == td(19nov2013)
replace eventdayL = 1 if date == td(19nov2013)


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


replace event_intra = 1 if date==td(16jun2014)
replace eventday = 1 if date == td(16jun2014)
replace eventdayL = 1 if date == td(16jun2014)

* note that this date merges with the next one in the usual two-day windows
replace event_nightbefore = 1 if date==td(23jun2014)
replace eventdayL = 1 if date==td(23jun2014)

replace event_onedayL = 1 if date==td(24jun2014)
replace eventday = 1 if date == td(24jun2014)
replace eventdayL = 1 if date==td(25jun2014)

replace event_intra = 1 if date==td(26jun2014)
replace eventdayL = 1 if date == td(27jun2014)
if `alt_dates' > 0 {
	replace eventday = 1 if date == td(27jun2014)
}
else {
	replace eventday = 1 if date == td(26jun2014)
}


replace eventexcluded = 1 if date==td(29jul2014)

* does excluding this matter?
* This is not in the appendix table-- will investigate if it matters
replace eventexcluded = 1 if date==td(28jul2014)

* This was the default date.
drop if date >= td(30jul2014)



* If we're using data with only closes, a lot of these event windows must be 
* widened. This code implements that.
* Note: This code does not actually affect any results we produce for the paper.

if `cds_i_marks' == 8 | `cds_i_marks' == 7 {

	replace event_onedayN = 1 if event_intra == 1
	replace event_intra = .

	replace event_onedayN = 1 if event_nightbefore == 1
	replace event_nightbefore = .

	replace event_twoday = 1 if event_1_5 == 1
	replace event_1_5 = .

	replace event_twoday = 1 if event_onedayL == 1
	replace event_onedayL = .

}


save "$apath/CDS_Data.dta", replace
