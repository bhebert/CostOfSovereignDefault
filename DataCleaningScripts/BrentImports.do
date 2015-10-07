tempfile data
import excel "$miscdata/Brent Neiman Data/Match.xlsx", sheet("Raw") firstrow clear
save "`data'", replace
import excel "$miscdata/Brent Neiman Data/Match.xlsx", sheet("FirmTable") firstrow clear
keep name Ticker industry_sector firm
mmerge firm using "`data'"
keep if _merge==3
drop _merge
mmerge Ticker using "/Users/jesseschreger/Documents/CostOfSovereignDefault/Datasets/FirmTable.dta", ukeep(isin_code import_intensity)
keep if _merge==3
mmerge  isin_code year using "$miscdata/Brent Neiman Data/CompustatGlobal.dta", umatch(isin fyear)
keep if _merge==3
replace imports=imports/(10^6)
keep name Ticker isin year import* capx revt
gen import_rev=imports/revt
gen import_capx=imports/capx
collapse (mean) import_rev import_capx, by(Ticker)
save "$apath/Brentimports.dta", replace
