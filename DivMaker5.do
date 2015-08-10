
set more off


*DROP RER pre 2003 if post2003=1
local post2003=1

local rho = (1/1.1) ^ (1/4)

use "$apath/dataset_temp.dta", clear

gen qtr = mod(quarter,4)
gen q1 = qtr == 0
gen q2 = qtr == 1
gen q3 = qtr == 2


gen log_div = log(div)

reg log_div q1 q2 q3

predict log_div_sa, residuals



gen log_div4 = log(div+L.div+L2.div+L3.div)

tsline log_div log_div_sa log_div4

gen log_pd = log(px_last) - log_div4

gen log_ngdp = log(Nominal_GDPusd)
gen log_exrate = log(ADRBlue)
gen log_cpi = log(cpi)
gen log_us_cpi = log(us_cpi)

if `post2003'==1 {
	replace log_exrate=. if year<2002
}

/* DOLS + SVAR APPROACH-- MAYBE A BETTER APPROACH? */
// http://www.ssc.wisc.edu/~bhansen/390/390Lecture22.pdf

// DOLS to estimate phi
newey log_ngdp log_div L(-3/3).D.log_div q1 q2 q3 quarter, lag(4)

// Construct time series of stationary variable
gen gdratio = log_ngdp - _b[log_div]*log_div - _b[q1]*q1 - _b[q2]*q2 - _b[q3]*q3 - _b[_cons] +  _b[quarter]*quarter

local phi = _b[log_div]

// Test cointegrating relationship for relative CPI and exchange rate
newey log_rel_cpi log_exrate L(-3/3).D.log_exrate q1 q2 q3, lag(4)

gen D_log_us_cpi = D.log_us_cpi
gen D_log_ngdp = D.log_ngdp
gen D_log_exrate = D.log_exrate

//constraint 1 [D_log_us_cpi]D_log_nngdp = 0

var D_log_ngdp gdratio log_pd D.log_exrate log_rer, lag(1) exog(q1 q2 q3 D_log_us_cpi) //constraints(1)

matrix varb = e(b)
matrix varsig = e(Sigma)
matrix vec_V = e(V)

*Matrix version of varb
matrix matb = J(5,5,0)

local fullsize = 5 + 4
forvalues i = 1/5 {
	local js = `fullsize'*(`i'-1)
	forvalues j = 1/5 {
		matrix matb[`i',`j'] = varb[1,`js'+`j']
	}
}

matrix list varb
matrix list matb


* Matrix to select dividend growth news
matrix dsel = J(5,1,0)
matrix dsel[1,1] = 1/`phi'
matrix dsel[2,1] = -(1-`rho')/`phi'

* matrix to select real gdp growth news
matrix gsel = J(5,1,0)
matrix gsel[1,1] = 1
matrix gsel[5,1] = (1-`rho')
*matrix gsel[4,1] = -1


matrix matv = inv(I(5)-`rho'*matb)
matrix dnews_mat = dsel' * matv
matrix gnews_mat = gsel' * matv


* select surprise returns... different idea
matrix rsel = J(5,1,0)
matrix rsel[1,1] = 1/`phi'
matrix rsel[2,1] = -1/`phi'
matrix rsel[3,1] = `rho'


gen gnews = 0
gen dnews = 0
gen rets = 0
forvalues i = 1/5 {
	predict resid_`i', equation(#`i') residuals
	
	local gcoef = gnews_mat[1,`i']
	local dcoef = dnews_mat[1,`i']
	local rcoef = rsel[`i',1]
	replace gnews = gnews + `gcoef' * resid_`i'
	replace dnews = dnews + `dcoef' * resid_`i'
	replace rets = rets + `rcoef' * resid_`i' 
}

tsline gnews dnews rets

* matrix of high-frequency predictors (return + ex rate )
matrix xsel = J(2,5,0)
* first one is dshock
matrix xsel[1,1] = dnews_mat
* second is exchange rate
matrix xsel[2,4] = 1

matrix xsel2 = J(2,5,0)
* first one is returns
matrix xsel2[1,1] = rsel'
* second is exchange rate
matrix xsel2[2,4] = 1

matrix xx = xsel * varsig * xsel'

matrix xy = xsel * varsig * gnews_mat'

matrix xx2 = xsel2 * varsig * xsel2'

matrix xy2 = xsel2 * varsig * gnews_mat'

matrix svar_b = inv(xx) * xy
matrix svar_b2 = inv(xx2) * xy2

matrix list svar_b
matrix list svar_b2

gen gn_proxy = dnews * svar_b[1,1] + D.log_exrate*svar_b[2,1]

tsline gnews gn_proxy

save "$apath/VAR_data.dta", replace


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

svar D.log_ngdp gdratio log_pd D.log_exrate log_rer, lag(1) exog(q1 q2 q3 D_log_us_cpi) aeq(atilde) beq(btilde) var

irf create temp, set("$rpath/svar_irf",replace) step(20) nose
irf table sirf, impulse(D.log_ngdp)
irf graph sirf, impulse(D.log_ngdp)

graph export "$rpath/Default_irf.pdf", as(pdf) replace

