use "$forpath/Longterm_Forecasts.dta", clear



local rho=10/11
*local macrovar C GDP IP invest infl
*local macrovarstar C* GDP* IP* invest* infl*

local macrovar  GDP C
local macrovarstar GDP* C*

gen horizon=year-fyear
gen discount=`rho'^horizon
gen discount2=discount
replace discount2=0 if horizon==0
gen discount3=discount2/`rho'
gen discount4=discount3
replace discount4=0 if horizon==1


foreach x in `macrovar' {
	replace `x'=`x'/100
	}
foreach x in `macrovar'   {
	gen `x'_LT_temp=`x' if horizon==10
	bysort fdate: egen LT_`x'=max(`x'_LT_temp)
	drop `x'_LT_temp
	gen PV_`x'_cont=(LT_`x')*(`rho'^11)/(1-`rho')
	gen PV_`x'_cont_calc=(LT_`x')*(`rho'^10)/(1-`rho')
	gen NGF_`x'_10cont=(LT_`x')*(`rho'^10)
	}
	
	
foreach x in `macrovar'   {
	gen `x'_2=`x'*discount2
	gen `x'_3=`x'*discount3
	gen `x'_4=`x'*discount4
	replace `x'=`x'*discount
}
drop CA 
collapse (sum) `macrovarstar' (lastnm) LT* PV* NGF*, by(fdate)
order fdate `macrovarstar'


foreach x in `macrovar'  {
	gen PV_`x'=`x'+PV_`x'_cont
	gen PV_`x'_2=`x'_2+PV_`x'_cont
	gen PV_`x'_tmin1=`x'_3+PV_`x'_cont_calc
	gen PV_`x'_2_tmin1=`x'_4+PV_`x'_cont_calc
	gen NGF_`x'_10tmin1=`x'_3+NGF_`x'_10cont
	gen NGF_`x'_2_10tmin1=`x'_4+NGF_`x'_10cont
	}
	*THIS IS FOR CALCULATING THE NEW PV

gen n=_n
tsset n

foreach x in C C_2 GDP GDP_2 IP IP_2 invest invest_2 infl infl_2 PV_C PV_C_2 PV_GDP PV_GDP_2 PV_IP PV_IP_2 PV_invest PV_invest_2 PV_infl PV_infl_2 LT_C LT_GDP LT_IP LT_invest LT_infl{
	cap {
	gen d_`x'=`x'-l2.`x'
	 }
	}
	foreach x in GDP {
		 gen N_`x'_ft=PV_`x'-l2.PV_`x'_tmin1
		 gen N_`x'_2_ft=PV_`x'_2-l2.PV_`x'_2_tmin1
		 gen N10_`x'_ft=GDP-l2.NGF_`x'_10tmin1
		 gen N10_`x'_2_ft=GDP_2-l2.NGF_`x'_2_10tmin1
		 }

drop n

save "$apath/Simple_Weight.dta", replace



/*
*REGRESSIONS FOR DATA EXPLORATION BELOW, NOTHING RIGOROUS
*MERGE IT
set more off

*use "`apath'/FirmTable.dta", clear
*mmerge Ticker using "`dpath'/Datastream_local_long2.dta"


*JUST INDEX
set more off
use "$fpath/Simple_Weight.dta", clear
rename fdate date
mmerge date using  "$bbpath/Indices_Full.dta", ukeep(total_return Ticker)
keep if _merge==3
keep if Ticker=="Merval" | Ticker=="MervalD" 
gen merval_temp=total_return if Ticker=="Merval"
gen mervald_temp=total_return if Ticker=="MervalD"

bysort date:egen merval=max(merval_temp)
bysort date:egen mervald=max(mervald_temp)
keep if Ticker=="MervalD"
drop Ticker _merge merval_ mervald_ total_return

mmerge date using "$fpath/BB_Indices_Wide.dta", ukeep(SPX VIX W0G1 MXEF)

tsset date
carryforward W0G1, replace
carryforward SPX, replace
carryforward VIX, replace
carryforward MXEF, replace
keep if _merge==3

*gen mxar_temp=total_return if Ticker=="MXAR"
*bysort date:egen mxar=max(mxar_temp)
*keep if Ticker=="MXAR"
*drop Ticker _merge mxar_


gen n=_n
tsset n
foreach x in merval mervald MXEF SPX VIX W0G1{
gen r_`x'=log(`x'/l2.`x')
}

mmerge date using "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Analysis/Datasets/blue_rate.dta", ukeep(px_close Ticker)
keep if Ticker=="ADRBlue" 
gen ADR=px_close if Ticker=="ADRBlue"
tsset date
carryforward ADR, replace
keep if _merge==3
drop Ticker _merge 
tsset n
sort n 
gen r_ADR=log(ADR/l2.ADR)

*ER
reg r_mervald r_MXEF r_SPX r_VIX 
predict er_mervald, resid

*twoway (connected d_GDP_2 date) (connected r_mervald date, yaxis(2)), legend(order(1 "Change in PV of GDP Growth" 2 "MXAR Return")) ytitle("Change in PV of GDP Growth") ytitle("MXAR Return", axis(2)) 
*twoway (connected d_GDP_2 date) (connected r_merval date, yaxis(2)), legend(order(1 "Change in PV of GDP Growth" 2 "Merval Return")) ytitle("Change in PV of GDP Growth") ytitle("Merval Return", axis(2)) 

*twoway (connected d_C_2 date) (connected r_mervald date, yaxis(2)), legend(order(1 "Change in PV of C Growth" 2 "Merval Return")) ytitle("Change in PV of GDP Growth") ytitle("Merval Return", axis(2)) 
*twoway (connected d_GDP_2 date) (connected r_merval date, yaxis(2)), legend(order(1 "Change in PV of C Growth" 2 "Merval Return")) ytitle("Change in PV of GDP Growth") ytitle("Merval Return", axis(2)) 

local lhs d_C_2 d_invest_2 d_infl_2 d_GDP d_C d_invest  d_infl
local lhspv d_PV_C_2 d_PV_invest_2 d_PV_infl_2 d_PV_GDP d_PV_C d_PV_invest  d_PV_infl
local lhslt d_PV_C_2 d_PV_invest_2 d_PV_infl_2 d_PV_GDP d_PV_C d_PV_invest  d_PV_infl
local factors r_MXEF r_SPX r_VIX



reg d_GDP_2 r_mervald, r
outreg2 using "$fpath/Results/Simple.xls", replace
foreach x in  `lhs'  {
reg `x' r_mervald, r
outreg2 using "$fpath/Results/Simple.xls"
}

reg d_GDP_2 er_mervald, r
outreg2 using "$fpath/Results/Simple_EX.xls", replace
foreach x in  `lhs'  {
reg `x' er_mervald, r
outreg2 using "$fpath/Results/Simple_EX.xls"
}


reg d_PV_GDP_2 r_mervald, r
outreg2 using "$fpath/Results/Simple_PV.xls", replace
foreach x in `lhspv' {
reg `x' r_mervald, r
outreg2 using "$fpath/Results/Simple_PV.xls"
}

reg d_PV_GDP_2 r_mervald, r
outreg2 using "$fpath/Results/Simple_PV_FX.xls", replace
foreach x in `lhspv' {
reg `x' r_mervald r_ADR, r
outreg2 using "$fpath/Results/Simple_PV_FX.xls"
}

reg d_PV_GDP_2 er_mervald r_ADR, r
outreg2 using "$fpath/Results/Simple_PV_FX_ER.xls", replace
foreach x in `lhspv' {
reg `x' er_mervald r_ADR, r
outreg2 using "$fpath/Results/Simple_PV_FX_ER.xls"
}

reg d_PV_GDP_2 er_mervald , r
outreg2 using "$fpath/Results/Simple_PV_ER.xls", replace
foreach x in `lhs' {
reg `x' er_mervald , r
outreg2 using "$fpath/Results/Simple_PV_ER.xls"
}


*ALL GDP 2

reg d_GDP_2 r_mervald, r
outreg2 using "$fpath/Results/Simple_GDP.xls", replace
reg d_GDP_2 r_mervald r_ADR, r
outreg2 using "$fpath/Results/Simple_GDP.xls"
reg d_GDP_2 er_mervald r_ADR, r
outreg2 using "$fpath/Results/Simple_GDP.xls"
reg d_GDP_2 r_mervald r_ADR `factors' , r
outreg2 using "$fpath/Results/Simple_GDP.xls"
foreach x in d_LT_GDP d_PV_GDP_2 {
reg `x' r_mervald, r
outreg2 using "$fpath/Results/Simple_GDP.xls"
reg `x' r_mervald r_ADR, r
outreg2 using "$fpath/Results/Simple_GDP.xls"
reg `x' er_mervald r_ADR, r
outreg2 using "$fpath/Results/Simple_GDP.xls"
reg `x' r_mervald r_ADR `factors' , r
outreg2 using "$fpath/Results/Simple_GDP.xls"
}







use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Forecasts/Longterm_Forecasts.dta", clear
local rho=.9
gen horizon=year-fyear
gen discount=`rho'^horizon
order fdate horizon fyear
keep fdate horizon  GDP

replace GDP=1+GDP/100
reshape wide GDP, i(fdate) j(horizon)
gen GDPlong=GDP10
gen disc_GDP0=GDP0
gen term1=GDP0

forvalues i=1/10 {
local j=`i'-1
replace GDP`i'=GDP`i'*GDP`j'
gen disc_GDP`i'=GDP`i'*`rho'^`i'
replace term1=term1+disc_GDP`i'
}

gen term2=`rho'^10*(GDP10)*(`rho'*GDPlong)/(1-`rho'*GDPlong)
gen pv=term1+term2
gen n=_n
tsset n
gen d_pv=log(pv/l2.pv)
gen d_10y=log(term1/l2.term1)
gen d_lt=log(GDPlong/l2.GDPlong)
*gen d_GDP10=log(disc_GDP10/l2.disc_GDP10)
*gen d_GDP5=log(disc_GDP5/l2.disc_GDP5)

rename fdate date
drop n
save "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Forecasts/PV_GDP.dta", replace










*JUST INDEX with PV
*JUST INDEX
set more off
use "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Forecasts/PV_GDP.dta", clear
mmerge date using  "$bbpath/Indices_Full.dta", ukeep(total_return Ticker)
keep if _merge==3
keep if Ticker=="Merval" | Ticker=="MervalD"
gen merval_temp=total_return if Ticker=="Merval"
gen mervald_temp=total_return if Ticker=="MervalD"
bysort date:egen merval=max(merval_temp)
bysort date:egen mervald=max(mervald_temp)
keep if Ticker=="MervalD"
drop Ticker _merge merval_ mervald_
gen n=_n
tsset n
gen r_merval=log(merval/l2.merval)
gen r_mervald=log(mervald/l2.mervald)


reg d_pv r_mervald,r 
reg d_lt r_mervald,r
reg d_10y r_mervald,r
