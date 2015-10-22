set more off

global forecast_path "`droppath'/Cost of Sovereign Default/Forecasts"


*GDP Indices
// Don't do this at all now
local forecast 0
*if 0, no forecast
*if 1, only consensus and var
*if 2, consensus and weo/DON'T USE THIS, IT IS NOT DONE YET

*1 to use crsp, 0 bloomberg
local crsp_adr 1

* This controls which Exchange Rates to use
global exrates ADRBlue DSBlue OfficialRate dolarblue NDF12M NDF6M NDF3M NDF1M FWDP12M FWDP6M FWDP3M FWDP1M US10YBE US5YBE BCS ADRB_PBRTS Contado_Ambito

* This controls which Latam equity/cds indices to use
global latam Brazil Mexico

* Drop data before this year
* One of the data sources doesn't go before 2011, so this doesn't help
global startyear 2011


* Choose ADRBlue or DSBlue
*local excontrol ADRBlue
local excontrol ADRBlue

local file ThirdAnalysis

global static_vars export_share Government foreign_own indicator_adr es_industry import_intensity finvar market_cap2011 TCind import_rev import_capx

local export_share_cut 25
local Government_cut 0
local foreign_own_cut 0
local indicator_adr_cut 0
local es_industry_cut 0.1
local import_intensity_cut 0.03
local finvar_cut 0
local market_cap2011_cut 2000
local TCind_cut 0
local import_rev_cut .01
local import_capx_cut 0.0968


use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear
drop if date == .
drop if Ticker == ""
drop if market != "US" & market != "AR" & Ticker != "MXAR" & Ticker != "Merval"

if `crsp_adr'==1 {
	drop if market=="US"
	append  using "$apath/CRSP_ADRs.dta"
	drop if date >= td(30jul2014)
	drop if date < td(1jan$startyear)
	replace bb_ticker=Ticker +" US Equity" if market=="US"
	replace ticker_full=Ticker+"_US" if market=="US"
}

drop if date >= td(30jul2014)
drop if date < td(1jan$startyear)



gen ADRticker = bb_ticker if market == "US"
replace ADRticker = "none" if market == "AR" | market == "Index"
mmerge bb_ticker using "$apath/FirmTable.dta", unmatched(master) ukeep(industry_sector $static_vars) update

* The firm table uses the old IRSA ADR ticker
replace ADRticker = "APSA US Equity" if ADRticker == "IRCP US Equity"

mmerge ADRticker using "$apath/FirmTable.dta", unmatched(master) ukeep(industry_sector $static_vars) update

replace industry_sector = "INDEX" if Ticker == "MXAR"
replace market = "US" if Ticker == "MXAR"

replace industry_sector = "INDEX" if Ticker == "Merval"
replace market = "AR" if Ticker == "Merval"

drop if industry_sector == ""
drop ADRticker
rename px_last px_close

sort Ticker 


tempfile temp

//took out AR value indices, since they aren't correct.
foreach mark in US AR {
	foreach indtype in ValueBank ValueNonFin Value {
		local filename= "`indtype'Index_`mark'_New"
		append using "$apath/`indtype'Index_`mark'_New.dta"
		
		drop if date >= td(30jul2014)
		drop if date < td(1jan$startyear)
		
		replace industry_sector = "`indtype'INDEXNew" if regexm(industry_sector,"`indtype'IndexNew")
		replace industry_sector = "`indtype'INDEXDelev" if regexm(industry_sector,"`indtype'IndexDelev")
	}
}

save "`temp'", replace

use "$apath/blue_rate.dta", clear
append using "$apath/NDF_Datastream.dta"
append using "$apath/dolarblue.dta"
append using "$apath/US_Breakeven.dta"
append using "$apath/bcs.dta"
append using "$apath/ADRB_PBRTS.dta"
append using "$apath/Contado.dta"

*append using "$apath/adrdb_altdata.dta"
*append using "$apath/adrdb_merge.dta"

drop if ~regexm("$exrates",Ticker)
gen industry_sector = Ticker
gen market = "Index"

append using "`temp'"
*Append Additional equities
append using "$apath/Additonal_Securities.dta"

*Append Bond level data
append using "$apath/bondlevel.dta"
append using "$apath/domestic_bonds.dta"
save "`temp'", replace

use "$bbpath/Latam_equities.dta", clear
drop if regexm(variable,"return")
keep date $latam
foreach cntry in $latam {
	rename `cntry' total_return`cntry'Equity
}
reshape long total_return, i(date) j(Ticker) string
gen industry_sector = Ticker
gen market = "Index"
append using "$apath/GFD_Equity.dta"
append using "`temp'"
save "`temp'", replace


use "$bbpath/Latam_CDS.dta", clear
drop if regexm(reporter,"CBIN")
keep date $latam
foreach cntry in $latam {
	rename `cntry' total_return`cntry'CDS
}
reshape long total_return, i(date) j(Ticker) string
append using "$apath/Other_CDS.dta"

gen industry_sector = Ticker
gen market = "Index"

append using "`temp'"

drop if date >= td(30jul2014)
drop if date < td(1jan$startyear)

gen temp = Ticker + market
encode temp, gen(firm_id)
drop temp


save "`temp'", replace



* Merge in the saved factor data

use "$apath/MarketFactorsNew.dta", clear

* Save the names of each factor variable, which will
* be needed to avoid dropping them later
levelsof ticker, local(factors)

* Now there is a factor_intraSPX, factor_intraVIX, etc...
reshape wide factor_intra factor_nightbefore factor_onedayN factor_onedayL factor_1_5 factor_twoday, i(date) j(ticker) string

local fnames
local fprefs

foreach nm in `factors' {
	local fprefs `fprefs' `nm'_
	foreach et in intra nightbefore onedayN onedayL 1_5 twoday {
		rename factor_`et'`nm' `nm'_`et'
		local fnames `fnames' `nm'_`et'
		
	}
}

disp "`fnames'"
disp "`fprefs'"

tempfile factor_temp
save "`factor_temp'", replace

use "`temp'", clear

mmerge date using "`factor_temp'", unmatched(master)
drop _merge


* Here I am dropping dates that have fewer than 5 returns
* This elminates some oddities when weekends/holidays
* have bad data that is not coded as missing
sort date Ticker
by date: egen valid = count(total_return)
ta Ticker valid

drop if valid <= 7
drop valid


* Compute the returns for various event windows
gen bdate = bofd("basic",date)
format bdate %tbbasic

sort firm_id bdate
tsset firm_id bdate

local rtypes return_intra return_onedayN return_onedayL return_nightbefore return_1_5 return_twoday
global rtypes `rtypes'

gen return_intra = 100*log(px_close/px_open)
gen return_onedayN = 100*log(total_return / L.total_return)
gen return_onedayL = 100*log(total_return / L.total_return) - return_intra + L.return_intra
gen return_nightbefore = return_onedayN - return_intra
gen return_twoday = 100*log(total_return / L2.total_return) 
gen return_1_5 = return_twoday - return_intra
 
append using "$apath/ValueIndex_ADR.dta"
append using "$apath/LocalValueIndex.dta"
drop if date >= td(30jul2014)
drop if date < td(1jan$startyear)

*USE THIS DATASET TO CONSTRUCT NEW INDICES
save "$apath/Index_Maker.dta", replace

if `forecast'==0 {
local gdp_indices  
}
else if `forecast'==1 {

// I don't think this file exists any more
append using "$apath/GDP_indices.dta"
*Create list of indices
levelsof(Ticker), local(tickers)
local gdp_indices
foreach x of local tickers {
	if regexm("`x'","GDP")==1 {
	local gdp_indices ="`gdp_indices'" +" " +"`x'"
	}
	}

}
else if `forecast'==2 {
// These also don't exist any more
append using "$apath/GDP_indices.dta"
append using "$apath/weo_forecast_GDP.dta"
levelsof(Ticker), local(tickers)
local gdp_indices
foreach x of local tickers {
	if regexm("`x'","GDP")==1 {
	local gdp_indices ="`gdp_indices'" +" " +"`x'"
	}
	}
}


keep date bdate Ticker `rtypes' `fnames' industry_sector firm_id $static_vars market

gen isstock = (market == "US" | market == "AR") & ~regexm(industry_sector,"INDEX") & ~regexm(industry_sector,"Index")

foreach x in  `gdp_indices' {
	replace isstock=0 if industry_sector=="`x'"
	}
	
//gen isstock = ~regexm(industry_sector,"ADRBlue") & ~regexm(industry_sector,"Official") & ~regexm(industry_sector,"DSBlue") & ~regexm(industry_sector,"Brazil") & ~regexm(industry_sector,"Mexico") & ~regexm(industry_sector,"INDEX") & ~regexm(industry_sector,"ETF")
gen nonfinancial = isstock == 1 & finvar == 0

* clean up ticker names

split Ticker, gen(nm1) limit(1)
replace Ticker = nm1
drop nm1

expand 2 if isstock == 1, gen(ports)

expand 2 if nonfinancial == 1 & ports == 1, gen(nf)

expand 2 if ports == 1 & nf == 0, gen(allstocks)

replace industry_sector = "NonFinancial" if nf == 1

	
foreach svar in $static_vars {
	disp "svar: `svar' ``svar'_cut'"
	
	if "`svar'" != "finvar" & "`svar'" != "foreign_own" & "`svar'" != "indicator_adr" {
		expand 2 if nf == 1 & `svar' != ., gen(counter2)
	}
	else {
		expand 2 if allstocks == 1 & `svar' != ., gen(counter2)
	}
	
	replace industry_sector = "High_`svar'" if counter2 == 1 & `svar' > ``svar'_cut'
	replace industry_sector = "Low_`svar'" if counter2 == 1 & `svar' <= ``svar'_cut'
	replace nf = 0 if counter2 == 1
	replace allstocks = 0 if counter2 == 1
	drop counter2
}

drop if allstocks == 1

replace Ticker = "" if ports == 1

local crtypes
foreach rt in `rtypes' {
	local crtypes `crtypes' cnt_`rt'=`rt'
}

* Equal-weight returns at the industry_sector level.
* For ADRs, this does nothing right now.
collapse (mean) `rtypes' `fnames' isstock nonfinancial ports (count) `crtypes', by(date industry_sector Ticker market)


replace Ticker="ValueIndex" if industry_sector=="ValueIndex"

*This creates GDP=beta_G$*ValueIndex+beta_RER*ADR, now unncessary

/*
mmerge industry_sector using "$apath/gdp_weights.dta", unmatched(master)

*save "$apath/temp_gdp.dta", replace
*use  "$apath/temp_gdp.dta", clear
*create 2 ADR Blues to use one for the index
expand 2 if ports == 0 & regexm(industry_sector,"ADRBlue"), gen(gdp_adr_us)
replace gdp_adr_us=1 if ports==1 & industry_sector=="ValueIndex"

foreach rt in $rtypes {
	gen ADR_GDP_temp_`rt'=`rt'*gdp_beta_adr if gdp_adr_us==1 & industry_sector=="ADRBlue"
	bysort date: egen ADR_GDP_`rt'=max(ADR_GDP_temp_`rt')
	*Replace one of the ValueIndex with GDP=beta_G$*ValueIndex+beta_RER*ADR
	replace `rt'=gdp_beta_adr*`rt'+ADR_GDP_`rt' if gdp_adr_us==1 & industry_sector=="ValueIndex"
	*drop ADR_GDP*
}	
replace industry_sector="GDP_Real" if industry_sector=="ValueIndex" & gdp_adr==1
replace Ticker="GDP_Real" if industry_sector=="GDP_Real" 
drop if Ticker=="ADRBlue" & gdp_adr_us==1
replace isstock=0 if industry_sector=="GDP_Real" | industry_sector=="ValueIndex"
replace ports=0 if industry_sector=="GDP_Real" | industry_sector=="ValueIndex"
*/




collapse (mean) $rtypes `fnames' isstock nonfinancial ports cnt_* , by(date industry_sector Ticker market)
	
expand 2 if regexm(industry_sector,"High_") | regexm(industry_sector,"Low_"), gen(ishml)
	
gen ptype = 1
foreach svar in $static_vars {
	
	foreach rt in `rtypes' {
		replace `rt' = -`rt' if regexm(industry_sector,"Low_`svar'") & ishml == 1
		replace cnt_`rt' = cnt_`rt'/100 if regexm(industry_sector,"Low_`svar'") & ishml == 1
	}
	replace industry_sector = "HML_`svar'" if (regexm(industry_sector,"Low_`svar'") | regexm(industry_sector,"High_`svar'")) & ishml == 1
	replace isstock = 0 if regexm(industry_sector,"HML_`svar'") & ishml == 1
}

expand 2 if (regexm(industry_sector,"DSBlue") | regexm(industry_sector,"ADRBlue")), gen(counter3)
replace industry_sector = "ADRMinusDS" if counter3 == 1
replace ports = 1 if counter3 == 1
foreach rt in $rtypes {
		replace `rt' = -`rt' if regexm(Ticker,"DSBlue") & counter3 == 1
}
replace ishml = 1 if counter3 == 1
replace Ticker = "" if counter3 == 1
drop counter3

local crtypes2
foreach rt in $rtypes {
	local crtypes2 `crtypes2' cnt2_`rt'=`rt'
}
				
collapse (mean) `fnames' isstock nonfinancial `rtypes' ports (sum) cnt_* (count) `crtypes2', by(date industry_sector Ticker market ishml)


foreach rt in `rtypes' {
	replace `rt' = . if ishml == 1 & cnt2_`rt' < 2
	replace `rt' = cnt2_`rt' * `rt' if ishml == 1
	drop cnt2_`rt'
}

gen firmname = industry_sector
replace firmname = Ticker if ports == 0 & isstock == 1
drop Ticker
	
	
gen temp = firmname+market
encode temp, gen(ind_id)
drop temp

* Merge in the CDS data.
mmerge date using "$apath/CDS_Data.dta", unmatched(master)

drop _merge


sort ind_id bdate
tsset ind_id bdate

* event_day is a dummy that says whether an event occurred on that day
* We move the intraday events to include the next day
* even if the event was of a different window size than the current data point.

//gen eventday = event_nightbefore == 1 | event_1_5 == 1 | L.event_onedayN == 1 | event_onedayL == 1 | event_twoday == 1 | L.event_intra == 1
//gen eventday_test = event_nightbefore == 1 | event_1_5 == 1 | event_onedayN == 1 | event_onedayL == 1 | event_twoday == 1 | event_intra == 1

gen eventopens = event_nightbefore == 1 | event_1_5 == 1 | F.event_1_5 == 1 | event_onedayN == 1 | L.event_onedayN == 1 | event_onedayL == 1 | L.event_twoday == 1 | event_twoday == 1 | F.event_twoday == 1 | L.event_intra == 1
gen eventcloses = event_nightbefore == 1 | event_1_5 == 1 | F.event_1_5 == 1 | event_onedayN == 1 | F.event_onedayL == 1 | event_onedayL == 1 | event_twoday == 1 | F.event_twoday == 1 | event_intra == 1

* Reshape the data to have one data point for each (day X window-size)
* day_type is the window_size variable
reshape long return_ cds_ event_ `fprefs' cnt_return_, i(date ind_id) j(day_type) string

rename cnt_ nfirms

rename eventday event_day

gen adrreturn = .
		
replace adrreturn = return_ if regexm(firmname,"`excontrol'")
		
sort date day_type firmname
		
by date day_type: egen madrreturn = mean(adrreturn)

gen return_local=return_
replace return_ = return_ - madrreturn if market == "AR" & ishml != 1
replace return_local = return_local + madrreturn if market == "US"  & ishml != 1

drop adrreturn

gen holdout_ret2 = .
replace holdout_ret2 = return_ if regexm(firmname,"defbond_eur")
sort date day_type firmname
by date day_type: egen holdout_ret = mean(holdout_ret2)
drop holdout_ret2



gen temp_ = .

replace temp_ = return_ if isstock == 1 & ports == 0
ta nfirms if isstock == 1 & ports == 0 & temp_ != .
sort date day_type market firmname
by date day_type market: egen eqreturn_ = sum(temp_*nfirms)
by date day_type market: egen firmavg = sum(nfirms*(temp_!=.))
replace eqreturn_ = eqreturn_ / firmavg
drop firmavg

replace temp_ = .
replace temp_ = return_ if industry_sector=="INDEX"
sort date day_type market firmname
by date day_type market: egen indreturn_ = mean(temp_)
drop temp_

expand 2 if industry_sector=="INDEX", gen(eqind)
replace return_ = eqreturn_ if eqind
replace return_local = eqreturn_ + madrreturn if eqind
replace firmname = "EqIndex" if eqind
replace industry_sector = "EqIndex" if eqind
drop eqind

* Create an "index" for YPF
/*expand 2 if regexm(firmname,"YPF"), gen(ypfind)
replace isstock = 0 if ypfind
drop ypfind*/
replace isstock = 0 if regexm(firmname,"YPF")


replace firmname = firmname+"_"+market if market == "AR" | market == "US"
drop ind_id
encode firmname, gen(ind_id)

sort day_type ind_id date

ta day_type

* Remove window sizes that don't have any events.
* For the Markit CDS, this removes the stuff that needed intraday data.
by day_type: egen cnt = count(event_)
ta cnt
drop if cnt == 0
drop cnt


* Generate a number, daynum, that goes from 1 to X, where X is the 
* number of window sizes, for each day.
* Choosing daynum == 1 will select the first window size on that day.
* This is useful because the  2 day returns exist for each window size.
sort  ind_id date day_type
by ind_id date: gen daynum = _n


* Generate a panel variable
* This will help when we need to look at two-day return windows.
gen pvar = ind_id * 10 + daynum
sort pvar bdate
tsset pvar bdate
*by pvar: gen dayindex = _n
by pvar: egen minbdate = min(bdate)
gen dayindex = bdate - minbdate + 1

gen prevdate = L.bdate
format prevdate %tbbasic

* Code to fix the issue of overlapping twoday event windows
* For ADRs, this uses June24, whereas for locals, exchange rates, and indices it uses Jun23
* The reason is that the ADRBlue is available only on the 23rd.

replace return_ = . if regexm(day_type,"twoday") & event_day == 1 & F.event_day == 1 & market == "US"
replace cds_ = . if regexm(day_type,"twoday") & event_day == 1 & F.event_day == 1 & market == "US"
replace return_local = . if regexm(day_type,"twoday") & event_day == 1 & F.event_day == 1 & market == "US"

replace return_ = . if regexm(day_type,"twoday") & event_day == 1 & F.event_day == 1 & market != "US"
replace cds_ = . if regexm(day_type,"twoday") & event_day == 1 & F.event_day == 1 & market != "US"
replace return_local = . if regexm(day_type,"twoday") & event_day == 1 & F.event_day == 1 & market != "US"

/*replace return_ = . if regexm(day_type,"twoday") & event_day == 1 & L.event_day == 1 & market != "US"
replace cds_ = . if regexm(day_type,"twoday") & event_day == 1 & L.event_day == 1 & market != "US"
replace return_local = . if regexm(day_type,"twoday") & event_day == 1 & L.event_day == 1 & market != "US"

replace return_ = . if regexm(day_type,"twoday") & event_day == 1 & L.event_day == 1 & market == "US"
replace cds_ = . if regexm(day_type,"twoday") & event_day == 1 & L.event_day == 1 & market == "US"
replace return_local = . if regexm(day_type,"twoday") & event_day == 1 & L.event_day == 1 & market == "US"*/


* Exclude days with missing S&P 500
drop if SPX_ == .

replace firmname = strtoname(firmname)
replace industry_sector = strtoname(industry_sector)

* this is a totally useless byproduct of the code.
drop if regexm(firmname,"HML_indicator_adr_US")

save "$apath/`file'.dta", replace

