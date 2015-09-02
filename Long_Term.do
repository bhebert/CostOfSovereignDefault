use "$forpath/Longterm_Forecasts_Apr2013.dta", clear


if $alt_rho == 0 {
		local rho = ${rho_quarter}^4
}
else {
	local rho = $alt_rho 
}

*local macrovar C GDP IP invest infl
*local macrovarstar C* GDP* IP* invest* infl*

local macrovar  GDP IP
local macrovarstar GDP* IP* C*

gen horizon=year-fyear
gen discount=`rho'^horizon
gen discount2=discount
replace discount2=0 if horizon==0
gen discount3=discount2/`rho'
*Adjust so we only use 0-9 years
gen discount4=discount
replace discount4=0 if horizon==10


foreach x in `macrovar' {
	replace `x'=`x'/100
	gen `x'_miss_temp=1 if `x'==.
	bysort fdate: egen miss_`x'=max(`x'_miss_temp)
	replace `x'=. if miss_`x'==1
	}
foreach x in `macrovar'   {
	gen `x'_LT_temp=`x' if horizon==10
	bysort fdate: egen LT_`x'=max(`x'_LT_temp)
	drop `x'_LT_temp
	gen PV_`x'_cont=(LT_`x')*(`rho'^11)/(1-`rho')
	gen PV_`x'_cont_calc=(LT_`x')*(`rho'^10)/(1-`rho')
	gen PV_`x'_cont_trunc=(LT_`x')*(`rho'^10)
	}
	
	

	
foreach x in `macrovar'   {
	gen `x'_2=`x'*discount2
	gen `x'_3=`x'*discount3
	gen `x'_new=`x'*discount4
	replace `x'=`x'*discount
}



collapse (sum) `macrovarstar' (lastnm) LT* PV* miss*, by(fdate)

foreach x in `macrovar' {
	replace `x'=. if miss_`x'==1 
	replace `x'_2=. if miss_`x'==1
	replace `x'_3=. if miss_`x'==1
	replace `x'_new=. if miss_`x'==1	
	}
	
	
order fdate `macrovarstar'


foreach x in `macrovar'  {
	gen PV_`x'=`x'+PV_`x'_cont
	gen PV_`x'_tmin1=`x'_3+PV_`x'_cont_calc
	gen PV_trunc_`x'_tmin1=`x'_3+PV_`x'_cont_trunc
	}
	*THIS IS FOR CALCULATING THE NEW PV

gen n=_n
tsset n

foreach x in `macrovar'  {
		 gen N_`x'_ft=PV_`x'-l2.PV_`x'_tmin1
		 gen N_`x'_ft_trunc=`x'-l2.PV_trunc_`x'_tmin1	 
		 *VERSION WITH 6 month gaps
		 gen N_`x'_ft_6m=PV_`x'-l.PV_`x' if month(fdate)==10
		 replace N_`x'_ft_6m=PV_`x'-l.PV_`x'_tmin1 if month(fdate)==4
		 gen N_`x'_ft_6m_trunc=`x'-l.`x' if month(fdate)==10
		 replace N_`x'_ft_6m_trunc=`x'-l.PV_trunc_`x'_tmin1 if month(fdate)==4	
		 
		 *NEW VERSION TRUNCATING AT 9
		 *`x'new=0-9, `x'=1-10
		 gen N_`x'_ft_new=`x'_new-l2.`x'_3
		 
		 *`6m
		 gen N_`x'_ft_6m_new=`x'_new-l.`x'_new if month(fdate)==10			 
		 replace N_`x'_ft_6m_new=`x'_new-l.`x'_3 if month(fdate)==4
}

drop n

save "$apath/Simple_Weight.dta", replace


