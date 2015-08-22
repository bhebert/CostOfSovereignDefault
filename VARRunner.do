
set more off


*DROP RER pre 2003 if post2003=1
local varpost2003=1

* do everything (including DOLS) post 2003
local allpost2003 = 1

//options: log_div4_real log_div_real log_div_real_sa
local divvar log_annual_div

local usetime 0
local use_dummies 1
local nw_years 1
local dols_lagyears 1

local qvarlags 1
local mvarlags 3

local run_svar 0

foreach outcome in gdp ip {

	
	if "`outcome'" == "gdp" {
		local time quarter
		local ovar Real_GDP_cpi
		local yearlen 4
		local timecut quarter <= tq(2002,4)
		local varlags = `qvarlags'
	}
	else {
		local time month
		local ovar IndustrialProduction
		local yearlen 12
		local timecut month <= tm(2002m12)
		local varlags = `mvarlags'
	}
	
	disp "`ovar' `time'"
	
	local dols_lags = `dols_lagyears' * `yearlen'
	local nw_len = `nw_years' * `yearlen'
	
	use "$apath/dataset_`outcome'.dta", clear


	gen season = mod(`time',`yearlen')

	gen log_div_real = log(div_real)

	reg log_div_real i.season

	predict log_div_real_sa, residuals

	capture graph drop `time'DivComparison
	tsline log_div_real log_div_real_sa log_annual_div, name(`time'DivComparison)
	
	local rho = ${rho_`time'}
	disp "rho: `rho'"
	
	
	sort `time'
	tsset `time'

	gen log_outcome = log(`ovar')

	gen log_exrate = log(ExRate)
	gen log_cpi = log(cpi)
	gen log_us_cpi = log(us_cpi)

	if `varpost2003'==1 {
		replace log_exrate=. if `timecut'

	}
	if `allpost2003'==1 {
		replace log_outcome = . if `timecut'
	}

	/* DOLS + SVAR APPROACH-- MAYBE A BETTER APPROACH? */
	// http://www.ssc.wisc.edu/~bhansen/390/390Lecture22.pdf

	if `usetime' == 1 {
		local qname `time'
	}

	if `use_dummies' == 1 {
		local dnames i.season
	}
	
	local ddiv_lags
	forvalues i= -`dols_lags'/`dols_lags' {
		local j = `i'+`dols_lags'
		gen ddiv_lag`j' = F`dols_lags'.L`j'.D.`divvar'
		local ddiv_lags `ddiv_lags' ddiv_lag`j'
	}

	// DOLS to estimate phi //quarter
	newey log_outcome `divvar' `ddiv_lags' `dnames' `qname', lag(`nw_len')
	
	foreach lagvar in `ddiv_lags' {
		replace `lagvar' = 0
	}
	
	predict gdratio, residual
	
	local phi = _b[`divvar']

	local phi_se = _se[`divvar']

	disp "phi_se: `phi_se'"

	matrix `outcome'_dols_b = J(1,1,`phi')
	matrix `outcome'_dols_V = J(1,1,`phi_se'*`phi_se')

	matrix rownames dols_b = ValueIndex_US
	matrix rownames dols_V = ValueIndex_US
	matrix colnames dols_V = ValueIndex_US

	// Test cointegrating relationship for relative CPI and exchange rate
	newey log_rel_cpi log_exrate L(-`dols_lags'/`dols_lags').D.log_exrate `dnames' `qname', lag(`nw_len')

	gen D_log_us_cpi = D.log_us_cpi
	gen D_log_outcome = D.log_outcome
	gen D_log_exrate = D.log_exrate

	//constraint 1 [D_log_us_cpi]D_log_nngdp = 0
	
	
	* number of assets in the tracking portfolio
	local numbeta 2
	
	* number of variables in the VAR
	local numvar 5
	
	* number of exogenous variables (include 1 for constant)
	local numexog 1 + `yearlen'
	
	local numv = `numvar' * `varlags'
	
	local fullsize = `numv' + `numexog'
	
	local dummies
	forvalues i = 1/`yearlen' {
		gen dummy`i' = mod(`time',`yearlen') == `i'
		local dummies `dummies' dummy`i'
	}
	
	var D_log_outcome gdratio log_rer D.log_exrate log_pd , lag(1/`varlags') exog(`dummies' D_log_us_cpi) //constraints(1)
	
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
	
	capture graph drop GDPDivNews
	tsline gnews dnews, name(GDPDivNews)
	
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
	
	matrix `outcome'_var_b = inv(xx) * xy
	matrix `outcome'_var_b2 = inv(xx2) * xy2
	
	matrix var_diff = (`outcome'_var_b2 - `outcome'_var_b) / `tstep'
	
	//matrix list var_b
	//matrix list svar_b2
	
	gen gn_proxy = dnews * `outcome'_var_b[1,1] + exnews*`outcome'_var_b[2,1]
	
	capture graph drop `outcome'NewsRegression
	tsline gnews gn_proxy, name(`outcome'NewsRegression)
	
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
	
	
	matrix `outcome'_var_V = delb * varV * delb'
	
	matrix rownames `outcome'_var_b = ValueIndex_US ADRBlue
	matrix rownames `outcome'_var_V = ValueIndex_US ADRBlue
	matrix colnames `outcome'_var_V = ValueIndex_US ADRBlue
	
	matrix list `outcome'_var_b
	matrix list `outcome'_var_V
	
	matrix rownames `outcome'_dols_b = ValueIndex_US
	matrix rownames `outcome'_dols_V = ValueIndex_US
	matrix colnames `outcome'_dols_V = ValueIndex_US
	
	matrix list `outcome'_dols_b
	matrix list `outcome'_dols_V
	
	matrix vd = vecdiag(`outcome'_var_V)
	matmap vd sd, map(sqrt(@))
	matrix list sd
	
	matrix vd = vecdiag(`outcome'_dols_V)
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
		
		svar D.log_outcome gdratio log_pd D.log_exrate log_rer, lag(1) exog(q1 q2 q3 D_log_us_cpi) aeq(atilde) beq(btilde) var
		
		irf create temp, set("$rpath/`outcome'svar_irf",replace) step(20) nose
		irf table sirf, impulse(D.log_outcome)
		irf graph sirf, impulse(D.log_outcome)
		
		graph export "$rpath/`outcome'Default_irf.pdf", as(pdf) replace
	}
}
	
