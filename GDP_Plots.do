*Forecast figures
local droppath /Users/jesseschreger/Dropbox
*local droppath C:/Users/Benjamin/Dropbox
*local droppath /Users/bhebert/Dropbox

global bbpath "`droppath'/Cost of Sovereign Default/Bloomberg/Datasets"
global apath "`droppath'/Cost of Sovereign Default/Analysis/Datasets"
global opath "`droppath'/Cost of Sovereign Default/Notes"
global rpath "`droppath'/Cost of Sovereign Default/Results/DefaultProbFeb28_test"
global dir_gdp "`droppath'/Cost of Sovereign Default/GDP Weighting"
global mdata "`droppath'/Cost of Sovereign Default/Misc Data"
global fpath "`droppath'/Cost of Sovereign Default/Forecasts"
global figures "`droppath'/Cost of Sovereign Default/Slides/Figures"

discard

import delimited  "$fpath/term.txt", clear 
local beta_value=-42.82
local beta_adr=31.95
drop if _n==1
foreach x of varlist _all {

	local temp=`x'[1]
	rename `x' `temp'
	}
	drop if _n==1 | _n==2
	rename VAR Ticker
	drop if Ticker=="" 
	drop if Ticker=="Constant"
	foreach var of varlist _all {
		if "`var'" ~="Ticker" {
		destring `var', replace
		}
		}
		
		forvalues i=0/9 {
			replace GDP`i'=GDP`i'*`beta_value'/100 if Ticker=="ValueIndex"
			replace GDP`i'=GDP`i'*`beta_adr'/100 if Ticker=="ADRBlue"
			}
		collapse (sum) GDP*	
		gen temp="temp"
		reshape long GDP, i(temp) j(horizon)
		drop temp
		label var GDP "Real GDP Growth Rate, % Change"
		label var horizon "Horizon (Quarters)"
		twoway (line GDP horizon,lwidth(medthick)), name("Forecast_IRF") graphregion(fcolor(white) lcolor(white)) 

		graph export "$figures/Forecast_IRF.png", replace
		rename GDP d_rgdp_con
		save "$fpath/Forecast_IRF.dta", replace
		
**********************
*IMPULSE RESPONSE,VAR*
**********************
discard
import excel "$figures/IRF.xlsx", sheet("Sheet1") firstrow clear
tsset horizon
rename log_usd_gdp d_y
rename log_e d_e
rename log_us d_p
rename log_rer rer
gen d_rer=rer-l.rer
replace d_rer=rer if horizon==0
gen d_rgdp=d_y+d_rer
label var d_rgdp "Real GDP Growth"
label var horizon "Horizon (Quarters)"
save "$figures/IRF.dta", replace
twoway (line d_rgdp horizon,lwidth(medthick)),  graphregion(fcolor(white) lcolor(white)) name("d_rgdp_quarterly")
graph export "$figures/d_rgdp_quarterly.png", replace

gen y_var=1
replace y_var=y_var*exp(d_rgdp/100) if horizon==0
tsset horizon
replace y_var=l.y_var*exp(d_rgdp/100) if horizon>=1
replace y_var=y_var-1	
replace y_var=y_var*100
twoway (line y_var horizon,lwidth(medthick)), ylabel(0(3)-15, gmax) xtitle("Horizon (Quarters)") ytitle("GDP, % Change") graphregion(fcolor(white) lcolor(white)) name("GDP_VAR_IRF_quarterly")
graph export "$figures/GDP_VAR_IRF_quarterly.png", replace

gen test=round(-.5+horizon/4)
collapse (sum) d_rgdp (lastnm) y_var, by(test)
rename test horizon
label var horizon "Horizon (Years)"
replace d_rgdp=d_rgdp*4 if horizon==5
label var d_rgdp "Real GDP Growth Rate, % Change"
twoway (line d_rgdp horizon,lwidth(medthick)), name("y") graphregion(fcolor(white) lcolor(white)) 
graph export "$figures/d_rgdp_annual.png", replace
mmerge horizon using  "$fpath/Forecast_IRF.dta"
drop _merge
tsset horizon
gen y_con=1

*gen y_var=1
*replace y_var=y_var*exp(d_rgdp/100) if horizon==0
*replace y_var=l.y_var*exp(d_rgdp/100) if horizon>=1
*replace y_var=y_var-1	

replace y_con=y_con*exp(d_rgdp_con/100) if horizon==0
tsset horizon
replace y_con=l.y_con*exp(d_rgdp_con/100) if horizon>=1
replace y_con=y_con-1
replace y_con=y_con*100	

twoway (line y_var horizon,lwidth(medthick)) (line y_con horizon,lwidth(medthick)), ylabel(0(3)-15, gmax) xtitle("Horizon (Years)") ytitle("Real GDP, % Change") legend(order(1 "VAR" 2 "Survey")) graphregion(fcolor(white) lcolor(white)) name("IRF_y_annual")
graph export "$figures/GDP_IRF_annual.png", replace

twoway (line d_rgdp horizon,lwidth(medthick)) (line d_rgdp_con horizon,lwidth(medthick)), ylabel() xtitle("Horizon (Years)") ytitle("Real GDP Growth Rate, % Change") legend(order(1 "VAR" 2 "Survey")) graphregion(fcolor(white) lcolor(white)) name("IRF_g_annual")
graph export "$figures/GDPgrowth_IRF_annual.png", replace

twoway (line y_var horizon,lwidth(medthick)) (line y_con horizon,lwidth(medthick))if horizon<=5, ylabel(0(3)-15, gmax) xtitle("Horizon (Years)") ytitle("Real GDP, % Change") legend(order(1 "VAR" 2 "Survey")) graphregion(fcolor(white) lcolor(white)) name("IRF_y_annual_5y")
graph export "$figures/GDP_IRF_annual_5y.png", replace
twoway (line y_var horizon,lwidth(medthick)) (line y_con horizon,lwidth(medthick))if horizon<=5, ylabel(0(3)-15, gmax) title("Real GDP Level") xtitle("Horizon (Years)") ytitle("Real GDP, % Change") legend(order(1 "VAR" 2 "Survey")) graphregion(fcolor(white) lcolor(white)) name("IRF_y_annual_5y2")
graph export "$figures/GDP_IRF_annual_5y_label.eps", replace

twoway (line d_rgdp horizon, lwidth(medthick)) (line d_rgdp_con horizon, lwidth(medthick)) if horizon<=5, ylabel() xtitle("Horizon (Years)") ytitle("Real GDP Growth Rate, % Change") legend(order(1 "VAR" 2 "Survey")) graphregion(fcolor(white) lcolor(white)) name("IRF_g_annual_5y")
graph export "$figures/GDPgrowth_IRF_annual_5y.png", replace
twoway (line d_rgdp horizon, lwidth(medthick)) (line d_rgdp_con horizon, lwidth(medthick)) if horizon<=5, ylabel() title("Real GDP Growth Rate") xtitle("Horizon (Years)") ytitle("Real GDP Growth Rate, % Change") legend(order(1 "VAR" 2 "Survey")) graphregion(fcolor(white) lcolor(white)) name("IRF_g_annual_5y2")
graph export "$figures/GDPgrowth_IRF_annual_5y_label.eps", replace



************
*NGF PLOTS
***********
local droppath /Users/jesseschreger/Dropbox

use "$fpath/forecast_dataset.dta", clear
keep date N_GDP_ft N10_GDP_ft Value ADR
gen quarter=qofd(date)
mmerge quarter using "`droppath'/Cost of Sovereign Default/GDP Weighting/VAR_data.dta", ukeep(gnews gn_proxy)
order quarter
format quarter %tq
sort quarter
gen gnews_cum=.
order gnews_cum, after(gnews)
tsset quarter
replace gnews_cum=gnews+l.gnews+l2.gnews+l3.gnews

replace gnews_cum=gnews_c*100
replace N_GDP_ft=N_GDP_ft*100
replace Value=Value*100
label var Value "Value-Weighted Index, % Change"
twoway (line gnews_cum quarter, lwidth(medthick)) (line N_GDP_ft quarter, lwidth(medthick)) if N_GDP_ft~=. & quarter>=tq(2004q1), name("compare") legend(order(1 "VAR" 2 "Survey")) graphregion(fcolor(white) lcolor(white)) ytitle("Change in PV of GDP Growth, %")
graph export "$figures/NGF.png", replace
twoway (line gnews_cum quarter, lwidth(medthick)) (line N_GDP_ft quarter,lwidth(medthick)) (line Value quarter,yaxis(2) lwidth(medthick)) if N_GDP_ft~=. & quarter>=tq(2004q1) ,name("compare2")  legend(order(1 "VAR" 2 "Survey" 3 "Value-Weighted Index")) ytitle("Change in PV of GDP Growth, %") graphregion(fcolor(white) lcolor(white))
graph export "$figures/NGF_Value.png", replace
*twoway (line gnews_cum quarter) (line N_GDP_ft quarter) (line Value quarter,yaxis(2)) (line ADR_neg quarter) if N_GDP_ft~=. & quarter>=tq(2004q1) ,  legend(order(1 "VAR" 2 "Survey" 3 "Value-Weighted Index")) ytitle("Change in PV of GDP Growth, %") graphregion(fcolor(white) lcolor(white))

 

