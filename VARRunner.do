
set more off


*DROP RER pre 2003 if post2003=1
local varpost2003=1

* do everything (including DOLS) post 2003
local allpost2003 = 1

//options: log_div4_real log_div_real log_div_real_sa
local divvar log_div4_real

local useqtr 0
local use_dummies 1
local nwlags 4
local dols_lags 4

local varlags 1

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


//gen log_rgdp = log(Nominal_GDPusd) - log(us_cpi)
gen log_rgdp = log(Real_GDP_cpi)
gen log_rgdp4 = log(Nominal_GDPusd/us_cpi+L.Nominal_GDPusd/L.us_cpi+L2.Nominal_GDPusd/L2.us_cpi+L3.Nominal_GDPusd/L3.us_cpi)

gen log_exrate = log(ADRBlue)
gen log_cpi = log(cpi)
gen log_us_cpi = log(us_cpi)

if `varpost2003'==1 {
	replace log_exrate=. if year<2002

}
if `allpost2003'==1 {
	replace log_rgdp = . if year < 2002
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

local numv = `numvar' * `varlags'

local fullsize = `numv' + `numexog'

var D_log_rgdp gdratio log_rer D.log_exrate log_pd , lag(1/`varlags') exog(q1 q2 q3 D_log_us_cpi) //constraints(1)

matrix varb = e(b)
matrix varsig = e(Sigma)
matrix vec_V = e(V)

* Matrix version of the VAR, absent constants/exogenous variables
matrix matb = J(`numv',`numv',0)

matrix selvars = J(`numvar'*`numv',`numvar'*`fullsize',0)

matrix removelags = J(`numv',`numvar',0)

forvalues i = 1/`numv' {
	//disp "`i' `numv' `varlags'"
	if `varlags' == 1 | mod(`i',`varlags') == 1 {
		local i2 = (`i'-1)/`varlags' + 1 
		local js = `fullsize'*(`i2'-1)
		local js2 = `numv'*(`i2'-1)
		//disp "`i2' `js' `js2'"
		forvalues j = 1/`numv' {
			matrix matb[`i',`j'] = varb[1,`js'+`j']
			matrix selvars[`js2'+`j',`js'+`j'] = 1
		}
		matrix removelags[`i',`i2'] = 1
	}
	else {
		matrix matb[`i',`i'-1] = 1
	}
}

/*if `varlags' > 1 {
	local start = `numvar' + 1
	forvalues i = `start'/`numv' {
		matrix matb[`i',`i'-`numvar'] = 1
	}
}*/

//matrix list varb
//matrix list matb

//return

matrix list removelags
matrix varsigbig = removelags * varsig * removelags'

matrix varV = selvars * vec_V * selvars'

//matrix list vec_V
//matrix list varV

* Matrix to select dividend growth news

matrix egdp = J(`numv',1,0)
matrix egdp[1,1] = 1
matrix egdratio = J(`numv',1,0)
matrix egdratio[1*`varlags'+1,1] = 1
matrix erer = J(`numv',1,0)
matrix erer[2*`varlags'+1,1] = 1
matrix eexrate = J(`numv',1,0)
matrix eexrate[3*`varlags'+1,1] = 1


matrix dsel = 1/`phi'*egdp - (1-`rho')/`phi'*egdratio - (1-`rho')*erer

* matrix to select real gdp growth news
matrix gsel = egdp

local tstep = 0.001
local testi = 1
local testj = 3

matrix matb2 = matb
matrix matb2[`testi',`testj'] = matb2[`testi',`testj'] + `tstep'

matrix matv = inv(I(`numv')-`rho'*matb)
matrix matv2 = inv(I(`numv')-`rho'*matb2)

matrix dnews_mat = dsel' * matv
matrix gnews_mat = gsel' * matv

matrix dnews_mat2 = dsel' * matv2
matrix gnews_mat2 = gsel' * matv2


/* select surprise returns... different idea
matrix rsel = J(5,1,0)
matrix rsel[1,1] = 1/`phi'
matrix rsel[2,1] = -1/`phi'
matrix rsel[3,1] = `rho'*/


gen gnews = 0
gen dnews = 0
//gen rets = 0

forvalues i = 1/`numvar' {
	predict resid_`i', equation(#`i') residuals
	local ind = (`i'-1)*`varlags' + 1
	local gcoef = gnews_mat[1,`ind']
	local dcoef = dnews_mat[1,`ind']
	
	//local rcoef = rsel[`i',1]
	replace gnews = gnews + `gcoef' * resid_`i'
	replace dnews = dnews + `dcoef' * resid_`i'
	
	//replace rets = rets + `rcoef' * resid_`i' 
}

rename resid_4 exnews

tsline gnews dnews //rets

* matrix of high-frequency predictors (return + ex rate )
matrix xsel = J(`numbeta',`numv',0)
* first one is dshock
matrix xsel[1,1] = dnews_mat
* second is exchange rate
matrix xsel[2,1] = eexrate'

matrix xsel2 = J(`numbeta',`numv',0)
matrix xsel2[1,1] = dnews_mat2
matrix xsel2[2,1] = eexrate'


matrix xx = xsel * varsigbig * xsel'

matrix xy = xsel * varsigbig * gnews_mat'

matrix xx2 = xsel2 * varsigbig * xsel2'

matrix xy2 = xsel2 * varsigbig * gnews_mat2'

matrix var_b = inv(xx) * xy
matrix var_b2 = inv(xx2) * xy2

matrix var_diff = (var_b2 - var_b) / `tstep'

//matrix list var_b
//matrix list svar_b2

gen gn_proxy = dnews * var_b[1,1] + exnews*var_b[2,1]

tsline gnews gn_proxy





matrix delb = J(`numbeta',`numvar'*`numv',0)

* Outcome variables
forvalues i = 1/`numvar' {
	local js = `numv'*(`i'-1)
	
	forvalues j = 1/`numv' {
		
		matrix dBij = J(`numv',`numv',0)
		matrix dBij[`i',`j'] = 1
		
		matrix dxsel = J(`numbeta',`numv',0)
		matrix dxsel[1,1] = `rho'*dsel'*matv*dBij*matv
		
		//matrix dxselt = (xselt - xsel) / `tstep'
		//matrix list dxsel
		//matrix list dxselt
		
		
		matrix dgsel = `rho'*matv'*dBij'*matv'*gsel
		
		//matrix dgnselt = (gnselt - gnsel) / `tstep'
		//matrix list dgnsel
		//matrix list dgnselt
		
		
		matrix t1 = inv(xx)*xsel*varsigbig*dgsel 
		//matrix list t1
		//matrix t1t = (t1test - betas) / `tstep'
		//matrix list t1t
		
		matrix t2 = inv(xx)*dxsel*varsigbig*gnews_mat'
		//matrix list t2
		//matrix t2t = (t2test - betas) / `tstep'
		//matrix list t2t
		
		matrix t3 = -inv(xx)*(dxsel*varsigbig*xsel'+xsel*varsigbig*dxsel')*inv(xx)*xy
		//matrix list t3
		//matrix t3t = (t3test - betas) / `tstep'
		//matrix list t3t
		
		matrix temp = t1 + t2 + t3
		//matrix list temp
		
		matrix delb[1,`js'+`j'] = temp
		//matrix list delb
	}
}

matrix list var_diff
matrix temp = delb[1..`numbeta',(`testi'-1)*`numv'+`testj']
matrix list temp


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

