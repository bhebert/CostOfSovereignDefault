set more off


* Create cumulative returns series for Value Index and controls

use "$apath/daily_factors.dta", clear

rename Close total_return

levelsof Ticker, local(vars)

append using "$apath/ValueIndex_US_New.dta"

append using "$apath/blue_rate.dta"

keep Ticker total_return date


reshape wide total_return, i(date) j(Ticker) string

gen year = yofd(date)
sort year date
by year: carryforward total_return*, replace


rename total_return* *

rename date fdate

mmerge fdate using "$apath/Simple_Weight.dta", unmatched(using) ukeep(fdate N_*)

gen half = hofd(fdate)

tsset half

foreach var in ValueIndexNew ADRBlue $lf_factors {
	gen ret_`var'6m = log(`var' / L.`var')
	gen ret_`var'1y = log(`var' / L2.`var')
	drop `var'
}

keep ret* N_* fdate half

rename N_GDP* N_gdp*
rename N_IP* N_ip*
rename N_*_ft N_*_ft_1y

gen month = mofd(fdate) - 1

sort month fdate

mmerge month using "$apath/dataset_ip.dta", unmatched(master) ukeep(log_pd log_rer)
rename log_pd lag_log_pd
rename log_rer lag_log_rer


sort half
tsset half

gen lagyear6m = year(L.fdate)
gen lagyear1y = year(L2.fdate)

/*
rename fdate date
mmerge date using "$apath/forecast_dataset_update.dta", ukeep(ret1yADRBlue ret1yValueIndex1y)
//keep date ret1y* ret_Val* ret_ADR* half N_*

tsset half
sort half
capture graph drop ValueIndexComp
tsline ret1yValueIndex1y ret_ValueIndexNew1y, name(ValueIndexComp)*/

//ret_*`horizon' lag_log_pd lag_log_rer

foreach var in gdp ip {
	
	foreach horizon in 6m 1y {
		if "`horizon'" == "6m" {
			gen lagnews`var'_`horizon' = L.N_`var'_ft_`horizon'+L2.N_`var'_ft_`horizon'
		}
		else {
			gen lagnews`var'_`horizon' = L2.N_`var'_ft_`horizon'
		}
		
		
		
		//lagnews`var'_`horizon' lag_log_pd lag_log_rer
		
		//ivreg2 N_`var'_ft_`horizon' ret_ValueIndexNew`horizon' ret_ADRBlue`horizon', robust bw(4)
		ivreg2 N_`var'_ft_`horizon' ret_ValueIndexNew`horizon' ret_ADRBlue`horizon' if lagyear`horizon' >= 2003, robust bw(4)
		
		matrix temp = e(b)
		matrix `var'_con`horizon'_b=temp[1,1..2]'
		matrix rownames `var'_con`horizon'_b = ValueINDEXNew_US ADRBlue
		matrix temp = e(V)
		matrix `var'_con`horizon'_V=temp[1..2,1..2]
		matrix rownames `var'_con`horizon'_V = ValueINDEXNew_US ADRBlue
		matrix colnames `var'_con`horizon'_V = ValueINDEXNew_US ADRBlue
	}
}
