set more off


local export_year 2012

local market_cut 200

local freq_cut 0.5

tempfile adrtemp

use "$bbpath/ADR_Static.dta", clear

keep ticker ticker_short Primary_Exchange

rename ticker ADRticker

gen ADRratio=2 if ADRticker != ""
replace ADRratio=10 if regexm(ADRticker,"BMA") | regexm(ADRticker,"GGAL")| regexm(ADRticker,"PZE")
replace ADRratio=3 if regexm(ADRticker,"BFR") 
replace ADRratio=5 if regexm(ADRticker,"TEO")
replace ADRratio=25 if regexm(ADRticker,"PAM")


save "`adrtemp'", replace

use "$dpath/DS_BB_Static_v2.dta", clear

*drop if Ticker == ""

keep Ticker isin_code indicator_adr //Industry_sector industry_Group
//rename Industry_sector industry_sector

mmerge Ticker using "$ffpath/FamaFrench_Master.dta", unmatched(master) ukeep(FFCODE12 FFCODE49)
drop _merge

replace FFCODE12 = "Diverse" if Ticker == "COM"
replace FFCODE12 = FFCODE49 if FFCODE12 == "Money"
replace FFCODE12 = "Telcm" if Ticker == "BOL"
rename FFCODE12 industry_sector
drop FFCODE49

rename isin_code ID_ISIN

mmerge ID_ISIN using "$dpath/Market_Cap_Ticker_2011.dta", unmatched(both)

drop _merge

split bb_ticker, gen(ticker_short) limit(1)
rename ticker_short ticker_short

mmerge ticker_short using "`adrtemp'", unmatched(both)

* this was not correct
*FIX SIDERAR /Ternium
//replace  ADRticker="TX US Equity" if Ticker=="SID"

replace indicator_adr = "X" if ADRticker != ""

gen indicator_adr2 = regexm(indicator_adr,"X")
drop indicator_adr
rename indicator_adr2 indicator_adr

replace ADRticker = "" if regexm(Primary_Exchange,"OTC")
replace ADRratio = . if regexm(Primary_Exchange,"OTC")

* This is a telecom argentina holding company
drop if ticker_short == "NORT6"
drop _merge Primary_Exchange 

egen firstline = tag(Ticker)
drop if firstline == 0
drop firstline

//replace industry_sector="Real Estate" if regexm(industry_Group,"Real Estate")
//replace industry_sector="Consumer" if regexm(industry_sector,"Consumer") | regexm(industry_sector,"Healthcare")

tempfile tempf
save "`tempf'", replace
	
use "$dpath/Export_TS_manual_Ticker.dta", clear
	
drop if year(date) != `export_year'
collapse (mean) export_share, by(ID_ISIN)
	
mmerge ID_ISIN using "`tempf'", unmatched(using)
drop _merge
	
mmerge ID_ISIN using "$dpath/Ownership_Ticker.dta", ukeep(Government) unmatched(both)
drop _merge
	
mmerge ID_ISIN using "$dpath/Foreign_Ownership_Ticker.dta", ukeep(foreign_own) unmatched(both)
drop _merge

rename ID_ISIN isin_code

mmerge isin_code using "$tpath/es_im_industry_Ticker.dta", ukeep(es_industry import_intensity)

drop _merge


drop if Ticker == ""
rename market_cap market_cap2011

drop if market_cap2011 == . | market_cap2011 < `market_cut'

save "$apath/FirmTable.dta", replace

use "$dpath/Datastream_local_long2.dta", clear

collapse (mean) stale_freq, by(Ticker)

mmerge Ticker using "$apath/FirmTable.dta", unmatched(using)

drop if (stale_freq > `freq_cut' | stale_freq == .) & Ticker != "SAM"

ta _merge
drop _merge

gen finvar = 0
replace finvar = 1 if regexm(industry_sector,"Financial") | regexm(industry_sector,"Banks")
replace finvar = . if regexm(industry_sector,"Real Estate") | regexm(industry_sector,"RlEst")


save "$apath/FirmTable.dta", replace
