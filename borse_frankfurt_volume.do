*BORSE FRANKFURT
tempfile bfusd bfeur
import excel "$dir_warrants/Borse_Frankfurt.xlsx", sheet("Data_XS0209139244") firstrow clear
gen date=date(Date,"DMY")
order date
format date %td
drop Date
rename Open open
rename DailyH high
rename DailyL low
rename Last last
rename DailyTurnoverN turnover_nominal
rename Dail turnover
foreach x in open high low last turnover_nominal turnover {
	destring `x', force replace
	}
*SAME BOND AS EF0151748
gen ISIN="XS0209139244"
rename last px_close
rename open px_open
gen Ticker="gdpw_bfeur"
gen market="Index"
gen industry_sector=Ticker
save "`bfeur'", replace
	
import excel "$dir_warrants/Borse_Frankfurt.xlsx", sheet("Data_US040114GM64") firstrow clear
gen date=date(Date,"DMY")
order date
format date %td
drop Date
rename Open open
rename DailyH high
rename DailyL low
rename Last last
rename DailyTurnoverN turnover_nominal
rename Dail turnover
foreach x in open high low last turnover_nominal turnover {
	destring `x', force replace
	}
gen Ticker="gdpw_bfusd"
gen market="Index"
gen industry_sector=Ticker
*THIS IS THE SAME BOND AS "EF0131575"
gen ISIN="US040114GM64"
rename last px_close
rename open px_open
save "`bfusd'", replace

use "`bfusd'", clear
append using "`bfeur'"

twoway (line turnover_nominal date) (line turnover date) if Ticker=="gdpw_bfeur", name("gdpw_bfeur_vol")
twoway (line turnover_nominal date) (line turnover date) if Ticker=="gdpw_bfusd", name("gdpw_bfusd_vol")


