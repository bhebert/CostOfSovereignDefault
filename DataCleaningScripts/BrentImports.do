tempfile data
import excel "$miscdata/Brent Neiman Data/Match.xlsx", sheet("Raw") firstrow clear
save "`data'", replace

import excel "$miscdata/Brent Neiman Data/Match.xlsx", sheet("FirmTable") firstrow clear
keep name Ticker industry_sector firm
mmerge firm using "`data'"
keep if _merge==3
drop _merge
