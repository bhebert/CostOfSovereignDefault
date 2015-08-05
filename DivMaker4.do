
set more off


*DROP RER pre 2003 if post2003=1
local post2003=1

*use "`bbpath'/Total_Returns.dta", clear
use "$bbpath/BB_Local_ADR_Indices_April2014.dta", clear
drop if date == .
drop if Ticker == ""
drop if market != "US"
keep date px_open px_last Ticker total_return market

//rename Ticker ticker
//replace ticker = ticker + " US Equity" if market == "US"

drop if date < mdy(1,1,1995)
drop if date>mdy(4,1,2015)
gen quarter=qofd(date)
format quarter %tq
mmerge quarter Ticker using "$dpath/ADR_weighting.dta", ukeep(weight_exypf)
rename weight_exypf weight
keep if _merge==3

sort date Ticker
collapse (lastnm) total_return px_last weight, by(quarter Ticker)

encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
gen ret = total_return / L.total_return - 1
sort quarter Ticker
local rtypes ret px_ret 
replace weight=0 if ret==.
bysort quarter: egen total_w=sum(weight)
replace weight=0.9*weight/total_w 
drop total_w
drop ret tid

append using "$gdppath/Tbill.dta"
keep if quarter>=tq(1995q2)
keep if quarter<=tq(2014q4)


encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
gen ret = total_return / L.total_return - 1
gen div = (1+ret) * L.px_last - px_last
gen px_ret = px_last / L.px_last - 1

sort quarter tid
foreach rtype  in ret px_ret {
	by quarter: egen `rtype'mxar = sum(weight*`rtype')
	by quarter: egen `rtype'mxar_cnt = sum(weight*(`rtype'!=.))
	replace `rtype'mxar = . if `rtype'mxar_cnt == 0
	replace `rtype'mxar = `rtype'mxar / `rtype'mxar_cnt 
	drop `rtype'mxar_cnt 
	}

gen divmxar=.

gen px_lastmxar = 5000


drop weight total_return tid
reshape wide ret px_ret  px_last div, i(quarter) j(Ticker) string
reshape long ret px_ret  px_last div, i(quarter) j(Ticker) string
replace Ticker="ValueIndex" if Ticker=="mxar"

gen log_px_ret = log(1+px_ret)
bysort Ticker (quarter): gen cum_px_ret = sum(log_px_ret)

replace px_last = px_last * exp(cum_px_ret) if Ticker == "ValueIndex"

encode Ticker, gen(tid)
sort tid quarter
tsset tid quarter
replace div = (1+ret) * L.px_last - px_last if Ticker == "ValueIndex"
drop log_px_ret cum_px_ret

drop if Ticker != "ValueIndex"
levelsof Ticker, local(inds_adr) clean


*ADDIGN SOME ADDITIONAL VARIABLES
mmerge quarter using "$miscdata/rer_gdp_dataset.dta", unmatched(master) ukeep(Real_GDP* Nominal_GDP_GFD ADRBlue cpi us_cpi)
gen log_rer = log((ADRBlue / cpi) * us_cpi)
gen log_rel_cpi = log(cpi / us_cpi)
gen Nominal_GDPusd = Nominal_GDP_GFD / ADRBlue
gen year = yofd(dofq(quarter))
sort quarter
tsset quarter


save "$gdppath/dataset_temp.dta", replace


********
*RER****
********


if `post2003'==1 {
	replace log_rer=. if year<2002
}


local rho = (1/1.1) ^ (1/4)


/*
gen exrate=log(ADRBlue)


varsoc D.exrate log_rer, maxlag(6)

matrix Acons = (1,0\.,1)
matrix Bcons = (.,0\0,.)

svar D.exrate log_rer, lags(1) small dfk aeq(Acons) beq(Bcons)

irf create temp, set("$dir_gdp/ex_irf",replace) step(20)
irf graph sirf, impulse(D.exrate) response(log_rer D.exrate)
graph export "$dir_gdp/ex_irf.pdf", replace

var D.exrate log_rer, lags(1) small dfk
varlmar, mlag(4)

//newey D.exrate L.D.exrate L.log_rer, lag(4)
//newey log_rer L.D.exrate L.log_rer, lag(4)

matrix varb = e(b)
matrix varsig = e(Sigma)
matrix varV = e(V)
matrix matb = J(2,2,0)

matrix list varb
matrix list varsig

forvalues i = 1/2 {
	local js = 3*(`i'-1)
	forvalues j = 1/2 {
		matrix matb[`i',`j'] = varb[1,`js'+`j']
	}
}

matrix matv = inv(I(2)-`rho'*matb)

matrix e2 = J(1,2,0)
matrix e2[1,2] = 1

matrix e1 = J(1,2,0)
matrix e1[1,1] = 1

matrix delb = J(1,6,0)
forvalues i = 1/2 {
	local js = 3*(`i'-1)
	
	matrix ei = J(2,1,0)
	matrix ei[`i',1] = 1
	forvalues j = 1/2 {
		matrix ej = J(1,2,0)
		matrix ej[1,`j'] = 1
		
		matrix delb[1,`js'+`j'] = `rho'*(1-`rho')*e2*matv*ei*ej*matv*varsig*(e1')
	}
}

matrix list varb
matrix list delb
matrix list varV

matrix exvar = delb * varV * (delb')

su D.exrate
local exvar=r(Var)
matrix exvals = (1-`rho')*e2*matv*varsig*(e1')/`exvar'
local val = exvals[1,1]
local valsd = sqrt(exvar[1,1]) / `exvar'
clear
set obs 3
gen Ticker=""
replace Ticker="ADRBlue" if _n==1
replace Ticker="ValueIndex" if _n==2
replace Ticker="Constant" if _n==3
gen forecast_rer=0
replace forecast_rer=`val' if Ticker=="ADRBlue"
gen forecast_rer_sd = .
replace forecast_rer_sd=`valsd' if Ticker=="ADRBlue"
save "$dir_gdp/gdp_weights_temp.dta", replace*/

use  "$gdppath/dataset_temp.dta", clear

*** Everything at once
*** I think this is the right way to do it

gen qtr = mod(quarter,4)
gen q1 = qtr == 0
gen q2 = qtr == 1
gen q3 = qtr == 2


gen log_ngdp = log(Nominal_GDPusd)
gen log_div = log(div)
gen log_exrate = log(ADRBlue)
gen log_cpi = log(cpi)
gen log_us_cpi = log(us_cpi)

if `post2003'==1 {
	replace log_exrate=. if year<2002
}

constraint 1 [_ce1]log_div = 0
constraint 2 [_ce1]log_ngdp = 0
constraint 3 [_ce1]log_exrate = 1
constraint 4 [_ce1]log_rel_cpi = -1
constraint 5 [_ce2]log_ngdp = 1
constraint 6 [_ce2]log_exrate = 0
constraint 7 [_ce2]log_rel_cpi = 0
constraint 8 [_ce1]_trend = 0

constraint 9 [_ce1]log_cpi = -1
constraint 10 [_ce1]log_us_cpi = 1
constraint 11 [_ce2]log_cpi = 0
constraint 12 [_ce2]log_us_cpi = 0

local numv = 4
local numr = 2
local numsi = 3
local numbeta = 2

local bsize = `numv' + `numr'


matrix xsel = J(`numbeta',`bsize',0)
matrix egnsel = J(`bsize',1,0)

matrix xselt = J(`numbeta',`bsize',0)
matrix egnselt = J(`bsize',1,0)

//CODE TO RUN EVERYTHING

//vec log_ngdp log_div, rank(1) lags(2) trend(rtrend) sindicators(q1 q2 q3)


vec log_exrate log_rel_cpi log_ngdp log_div, rank(2) lags(2) trend(rtrend) bconstraints(1/8) sindicators(q1 q2 q3)

//vec log_exrate log_cpi log_us_cpi log_ngdp log_div, rank(2) lags(2) trend(rtrend) bconstraints(1/3,5,6,8/12) sindicators(q1 q2 q3)

matrix vec_beta = e(beta)

matrix varb = e(b)
matrix varsig = e(omega)
matrix vec_V = e(V)




*Matrix version of varb
matrix matb = J(`bsize',`bsize',0)

matrix Ibeta = J(`bsize',`numv',0)

local vstart = `numr' + 1
local fullsize = `numv' + `numr' + `numsi' + 1
forvalues i = `vstart'/`bsize' {
	local js = `fullsize'*(`i'-`vstart')
	forvalues j = 1/`bsize' {
		matrix matb[`i',`j'] = varb[1,`js'+`j']
	}
	matrix Ibeta[`i',`i'-`numr'] = 1
}

forvalues i = 1/`numr' {
	* variables, 1 trend, 1 constant
	local js = (`numv'+2)*(`i'-1)+1
	local je = `js' + `numv' - 1
	matrix vecbi = vec_beta[1,`js'..`je']
	matrix Ibeta[`i',1] = vecbi[1,1..`numv']
	matrix temp = vecbi * matb[`vstart'..`bsize',1..`bsize']
	matrix temp[1,`i'] = temp[1,`i'] + 1
	matrix matb[`i',1] = temp[1,1..`bsize']

}

matrix varsig = Ibeta * varsig * (Ibeta')

//matrix list matb
//matrix list varsig

matrix matv = inv(I(`bsize')-`rho'*matb)

matrix e6t = J(1,`bsize',0)
matrix e6t[1,`bsize'] = 1

matrix dnsel = e6t * matv

matrix xsel[2,3] = 1
matrix xsel[1,1] = dnsel

//matrix egnsel[2,1] = 1
matrix egnsel[5,1] = 1
matrix egnsel[4,1] = -1
matrix egnsel[3,1] = 1
//matrix egnsel[1,1] = 1-`rho' 
//matrix egnsel[3,1] = 1
//matrix egnsel[4,1] = -1 

matrix gnsel = matv' * egnsel

matrix xx = xsel * varsig * xsel'
matrix xy = xsel * varsig * gnsel

matrix vecm_b = inv(xx) * xy

//matrix list betas

** The below code was useful for debugging a sign error
/*local tstep 0.01

matrix varbt = varb
matrix varbt[1,2] = varbt[1,2]+`tstep'

matrix list varb
matrix list varbt

*Matrix version of varb
matrix matbt = J(`bsize',`bsize',0)
forvalues i = `vstart'/`bsize' {
	local js = `fullsize'*(`i'-`vstart')
	forvalues j = 1/`bsize' {
		matrix matbt[`i',`j'] = varbt[1,`js'+`j']
	}
}
forvalues i = 1/`numr' {
	* variables, 1 trend, 1 constant
	local js = (`numv'+2)*(`i'-1)+1
	local je = `js' + `numv' - 1
	matrix vecbi = vec_beta[1,`js'..`je']
	matrix temp = vecbi * matbt[`vstart'..`bsize',1..`bsize']
	matrix temp[1,`i'] = temp[1,`i'] + 1
	matrix matbt[`i',1] = temp[1,1..`bsize']
}

matrix list matb
matrix list matbt

matrix matvt = inv(I(`bsize')-`rho'*matbt)


matrix dnselt = e6t * matvt


matrix xselt[1,1] = dnselt


matrix gnselt = matvt' * egnsel

matrix xxt = xselt * varsig * xselt'
matrix xyt = xselt * varsig * gnselt

matrix betast = inv(xxt) * xyt

matrix t1test = inv(xx) * xsel * varsig * gnselt
matrix t2test = inv(xx) * xselt * varsig * gnsel
matrix t3test = inv(xxt) * xy

matrix list betast
matrix list t1test
matrix list t2test
matrix list t3test

matrix testb = (betast - betas) / `tstep'
matrix list testb*/


matrix delb = J(`numbeta',`fullsize'*`numv',0)

* Four outcome variables
forvalues i = 1/`numv' {
	local js = `fullsize'*(`i'-1)
	* Four vars + 2 coint vectors
	forvalues j = 1/`bsize' {
		
		matrix dBij = J(`bsize',`bsize',0)
		matrix dBij[`i'+`numr',`j'] = 1
		
		forvalues k = 1/`numr' {
			matrix dBij[`k',`j'] = Ibeta[`k',`i']
		}
		
		//matrix list dBij
		
		matrix dxsel = J(`numbeta',`bsize',0)
		matrix dxsel[1,1] = `rho'*e6t*matv*dBij*matv
		
		//matrix dxselt = (xselt - xsel) / `tstep'
		//matrix list dxsel
		//matrix list dxselt
		
		
		matrix dgnsel = `rho'*matv'*dBij'*matv'*egnsel
		
		//matrix dgnselt = (gnselt - gnsel) / `tstep'
		//matrix list dgnsel
		//matrix list dgnselt
		
		
		matrix t1 = inv(xx)*xsel*varsig*dgnsel 
		//matrix list t1
		//matrix t1t = (t1test - betas) / `tstep'
		//matrix list t1t
		
		matrix t2 = inv(xx)*dxsel*varsig*gnsel
		//matrix list t2
		//matrix t2t = (t2test - betas) / `tstep'
		//matrix list t2t
		
		matrix t3 = -inv(xx)*(dxsel*varsig*xsel'+xsel*varsig*dxsel')*inv(xx)*xy
		//matrix list t3
		//matrix t3t = (t3test - betas) / `tstep'
		//matrix list t3t
		
		matrix temp = t1 + t2 + t3
		//matrix list temp
		
		matrix delb[1,`js'+`j'] = temp
		//matrix list delb
	}
}
//matrix list delb
//matrix list vec_V
matrix vecm_V = delb * vec_V * delb'

matrix rownames vecm_b = ValueIndex_US ADRBlue
matrix rownames vecm_V = ValueIndex_US ADRBlue
matrix colnames vecm_V = ValueIndex_US ADRBlue

matrix list vecm_b
matrix list vecm_V

matrix vd = vecdiag(vecm_V)
matmap vd sd, map(sqrt(@))
matrix list sd

