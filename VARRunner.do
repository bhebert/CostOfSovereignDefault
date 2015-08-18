
set more off


*DROP RER pre 2003 if post2003=1
local post2003=1

//options: log_div4_real log_div_real log_div_real_sa
local divvar log_div4_real

local useqtr 0
local use_dummies 1
local nwlags 4
local dols_lags 4

local run_svar 0

use "$apath/dataset_temp.dta", clear

gen qtr = mod(quarter,4)
gen q1 = qtr == 0
gen q2 = qtr == 1
gen q3 = qtr == 2


gen log_div_real = log(div) - log(us_cpi)

reg log_div_real q1 q2 q3

predict log_div_real_sa, residuals



gen log_div4_real = log(div/us_cpi+L.div/L.us_cpi+L2.div/L2.us_cpi+L3.div/L3.us_cpi)

tsline log_div_real log_div_real_sa log_div4_real

gen log_pd = log(px_last / us_cpi) - log_div4_real

su log_pd

local mean_pd = `r(mean)'

local rho_est = (exp(`mean_pd') / (exp(`mean_pd') + 1)) ^ (1/4)
disp "rho_est: `rho_est'"

local rho `rho_est'


gen log_rgdp = log(Nominal_GDPusd) - log(us_cpi)
gen log_rgdp4 = log(Nominal_GDPusd/us_cpi+L.Nominal_GDPusd/L.us_cpi+L2.Nominal_GDPusd/L2.us_cpi+L3.Nominal_GDPusd/L3.us_cpi)

gen log_exrate = log(ADRBlue)
gen log_cpi = log(cpi)
gen log_us_cpi = log(us_cpi)

if `post2003'==1 {
	replace log_exrate=. if year<2002
}

/* DOLS + SVAR APPROACH-- MAYBE A BETTER APPROACH? */
// http://www.ssc.wisc.edu/~bhansen/390/390Lecture22.pdf

if `useqtr' == 1 {
	local qname quarter
	local qadd - _b[quarter]*quarter
}

if `use_dummies' == 1 {
	local dnames q1 q2 q3
	local dadd - _b[q1]*q1 - _b[q2]*q2 - _b[q3]*q3 - _b[_cons]
}

// DOLS to estimate phi //quarter
newey log_rgdp `divvar' L(-`dols_lags'/`dols_lags').D.`divvar' `dnames' `qname', lag(`nwlags')

// Construct time series of stationary variable
gen gdratio = log_rgdp - _b[`divvar']*`divvar' - _b[_cons] `dadd' `qadd'

local phi = _b[`divvar']

local phi_se = _se[`divvar']

disp "phi_se: `phi_se'"

matrix dols_b = J(1,1,`phi')
matrix dols_V = J(1,1,`phi_se'*`phi_se')

matrix rownames dols_b = ValueIndex_US
matrix rownames dols_V = ValueIndex_US
matrix colnames dols_V = ValueIndex_US

// Test cointegrating relationship for relative CPI and exchange rate
newey log_rel_cpi log_exrate L(-`dols_lags'/`dols_lags').D.log_exrate `dnames' `qname', lag(`nwlags')

gen D_log_us_cpi = D.log_us_cpi
gen D_log_rgdp = D.log_rgdp
gen D_log_exrate = D.log_exrate

//constraint 1 [D_log_us_cpi]D_log_nngdp = 0


* number of assets in the tracking portfolio
local numbeta 2

* number of variables in the VAR
local numvar 5

* number of exogenous variables (include 1 for constant)
local numexog 5

local fullsize = `numvar' + `numexog'

var D_log_rgdp gdratio log_rer D.log_exrate log_pd , lag(1) exog(q1 q2 q3 D_log_us_cpi) //constraints(1)

matrix varb = e(b)
matrix varsig = e(Sigma)
matrix vec_V = e(V)

* Matrix version of the VAR, absent constants/exogenous variables
matrix matb = J(`numvar',`numvar',0)

matrix selvars = J(`numvar'*`numvar',`numvar'*`fullsize',0)

forvalues i = 1/`numvar' {
	local js = `fullsize'*(`i'-1)
	local js2 = `numvar'*(`i'-1)
	forvalues j = 1/`numvar' {
		matrix matb[`i',`j'] = varb[1,`js'+`j']
		matrix selvars[`js2'+`j',`js'+`j'] = 1
	}
}

//matrix list varb
//matrix list matb

matrix varV = selvars * vec_V * selvars'

//matrix list vec_V
//matrix list varV

* Matrix to select dividend growth news
matrix dsel = J(5,1,0)
matrix dsel[1,1] = 1/`phi'
matrix dsel[2,1] = -(1-`rho')/`phi'
matrix dsel[3,1] = -(1-`rho')

* matrix to select real gdp growth news
matrix gsel = J(5,1,0)
matrix gsel[1,1] = 1
*matrix gsel[4,1] = -1

matrix matv = inv(I(5)-`rho'*matb)
matrix dnews_mat = dsel' * matv
matrix gnews_mat = gsel' * matv


/* select surprise returns... different idea
matrix rsel = J(5,1,0)
matrix rsel[1,1] = 1/`phi'
matrix rsel[2,1] = -1/`phi'
matrix rsel[3,1] = `rho'*/


gen gnews = 0
gen dnews = 0
//gen rets = 0

forvalues i = 1/5 {
	predict resid_`i', equation(#`i') residuals
	
	local gcoef = gnews_mat[1,`i']
	local dcoef = dnews_mat[1,`i']
	//local rcoef = rsel[`i',1]
	replace gnews = gnews + `gcoef' * resid_`i'
	replace dnews = dnews + `dcoef' * resid_`i'
	
	//replace rets = rets + `rcoef' * resid_`i' 
}

rename resid_4 exnews

tsline gnews dnews //rets

* matrix of high-frequency predictors (return + ex rate )
matrix xsel = J(2,5,0)
* first one is dshock
matrix xsel[1,1] = dnews_mat
* second is exchange rate
matrix xsel[2,4] = 1

/*matrix xsel2 = J(2,5,0)
* first one is returns
matrix xsel2[1,1] = rsel'
* second is exchange rate
matrix xsel2[2,4] = 1*/

matrix xx = xsel * varsig * xsel'

matrix xy = xsel * varsig * gnews_mat'

//matrix xx2 = xsel2 * varsig * xsel2'

//matrix xy2 = xsel2 * varsig * gnews_mat'

matrix var_b = inv(xx) * xy
//matrix svar_b2 = inv(xx2) * xy2

//matrix list var_b
//matrix list svar_b2

gen gn_proxy = dnews * svar_b[1,1] + exnews*svar_b[2,1]

tsline gnews gn_proxy





matrix delb = J(`numbeta',`numvar'*`numvar',0)

* Outcome variables
forvalues i = 1/`numvar' {
	local js = `numvar'*(`i'-1)
	
	forvalues j = 1/`numvar' {
		
		matrix dBij = J(`numvar',`numvar',0)
		matrix dBij[`i',`j'] = 1
		
		matrix dxsel = J(`numbeta',`numvar',0)
		matrix dxsel[1,1] = `rho'*dsel'*matv*dBij*matv
		
		//matrix dxselt = (xselt - xsel) / `tstep'
		//matrix list dxsel
		//matrix list dxselt
		
		
		matrix dgsel = `rho'*matv'*dBij'*matv'*gsel
		
		//matrix dgnselt = (gnselt - gnsel) / `tstep'
		//matrix list dgnsel
		//matrix list dgnselt
		
		
		matrix t1 = inv(xx)*xsel*varsig*dgsel 
		//matrix list t1
		//matrix t1t = (t1test - betas) / `tstep'
		//matrix list t1t
		
		matrix t2 = inv(xx)*dxsel*varsig*gnews_mat'
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

matrix var_V = delb * varV * delb'

matrix rownames var_b = ValueIndex_US ADRBlue
matrix rownames var_V = ValueIndex_US ADRBlue
matrix colnames var_V = ValueIndex_US ADRBlue

matrix list var_b
matrix list var_V

matrix list dols_b
matrix list dols_V

matrix vd = vecdiag(var_V)
matmap vd sd, map(sqrt(@))
matrix list sd

matrix vd = vecdiag(dols_V)
matmap vd sd, map(sqrt(@))
matrix list sd


if `run_svar' != 0 {

	matrix sshocks = I(5)
	matrix sshocks[1,1] = rsel' //dnews_mat
	matrix sshocks[2,1] = gnews_mat
	
	matrix list sshocks
	
	* results from Rigobon-Sack estimator
	matrix cmat = I(5)
	matrix cmat[1,1] = -42.82
	matrix cmat[2,1] = -42.82 * svar_b2[1,1] + 35.33 * svar_b2[2,1]
	matrix cmat[3,1] = -42.82 * `rho'
	matrix cmat[4,1] = 35.33
	matrix cmat[5,1] = 35.33
	
	matrix list cmat
	
	matrix atilde = inv(cmat)*sshocks
	
	matrix btilde = (1,.,.,.,.\0,.,.,.,.\0,0,.,.,.\0,0,0,.,.\0,0,0,0,.)
	
	matrix list atilde
	matrix list btilde
	
	svar D.log_rgdp gdratio log_pd D.log_exrate log_rer, lag(1) exog(q1 q2 q3 D_log_us_cpi) aeq(atilde) beq(btilde) var
	
	irf create temp, set("$rpath/svar_irf",replace) step(20) nose
	irf table sirf, impulse(D.log_rgdp)
	irf graph sirf, impulse(D.log_rgdp)
	
	graph export "$rpath/Default_irf.pdf", as(pdf) replace
}

