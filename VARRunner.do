
set more off

global VARmodels

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
local dfstyle 

local qvarlags 1
local mvarlags 3

local run_svar 0

local action replace

foreach outcome in gdp ip {

	
	if "`outcome'" == "gdp" {
		local time quarter
		local ovars $real_gdps
		local yearlen 4
		local timecut quarter <= tq(2002,4)
		local varlags = `qvarlags'
	}
	else {
		local time month
		local ovars IP
		local yearlen 12
		local timecut month <= tm(2002m12)
		local varlags = `mvarlags'
	}
	
	foreach ovar in `ovars' {
	
		global VARmodels $VARmodels `ovar'_dols `ovar'_var
	
		disp "`ovar' `time'"
		
		local dols_lags = `dols_lagyears' * `yearlen'
		local nw_len = `nw_years' * `yearlen'
		
		use "$apath/dataset_`outcome'.dta", clear
		
		if `yearlen' == 4 {
			format `time' %tq
		}
		else if `yearlen' == 12 {
			format `time' %tm
			rename IndustrialProduction IP
			rename log_annual_IndustrialProduction log_annual_IP
		}
	
		gen season = mod(`time',`yearlen')
	
		gen log_div_real = log(div_real)
	
		reg log_div_real i.season
	
		predict log_div_real_sa, residuals
	
		capture graph drop `time'DivComparison
		
		tsline log_div_real log_div_real_sa log_annual_div, name(`time'DivComparison)
		
		
		if "$alt_rho" == "0" | "$alt_rho" == "" {
			local rho = ${rho_`time'}
		}
		else {
			local rho = $alt_rho ^ (1/`yearlen')
		}
		
		
		sort `time'
		tsset `time'
	
		gen log_outcome = log(`ovar')
	
		gen log_exrate = log(ExRate)
		gen log_cpi = log(cpi)
		gen log_us_cpi = log(us_cpi)
	
		if `varpost2003'==1 {
			replace log_exrate=. if `timecut'
			replace log_rer = . if `timecut'
			replace log_orer = . if `timecut'
	
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
		
		label var log_annual_`ovar' "ln(real annual `ovar')"
		label var log_annual_div "ln(real annual dividends)"
		
		capture graph drop `ovar'_vs_div
		twoway (tsline log_annual_`ovar') (tsline log_annual_div, yaxis(2)) if log_outcome != ., name(`ovar'_vs_div) xlabel(, labsize(medium)) xtitle("") ylabel(,nogrid) graphregion(fcolor(white) lcolor(white))
		graph export "$rpath/`outcome'_vs_div.png", replace
		
		// DOLS to estimate phi //quarter
		newey log_outcome `divvar' `ddiv_lags' `dnames' `qname', lag(`nw_len')
		outreg2 using "$rpath/dols.xls", `action' stats(coef se ci) level(95) ctitle("`ovar'")
		
		
		foreach lagvar in `ddiv_lags' {
			replace `lagvar' = 0
		}
		
		predict gdratio, residual
		
		local phi = _b[`divvar']
	
		local phi_se = _se[`divvar']
	
		disp "phi_se: `phi_se'"
	
		matrix `ovar'_dols_b = J(1,1,`phi')
		matrix `ovar'_dols_V = J(1,1,`phi_se'*`phi_se')
	
		matrix rownames `ovar'_dols_b = ValueINDEXNew_US
		matrix rownames `ovar'_dols_V = ValueIndex_US
		matrix colnames `ovar'_dols_V = ValueIndex_US
	
		// Estimate
		newey log_rel_cpi log_exrate L(-`dols_lags'/`dols_lags').D.log_exrate `dnames' `qname', lag(`nw_len')
		//outreg2 using "$rpath/rer_`time'.xls", replace stats(coef se ci) level(95)
		
		gen log_official = log(OfficialRate)
		newey log_rel_cpi log_official L(-`dols_lags'/`dols_lags').D.log_official `dnames' `qname', lag(`nw_len')
		//outreg2 using "$rpath/rer_`time'.xls", append stats(coef se ci) level(95)
		
		reg log_outcome `divvar' `dnames' `qname'
		predict gdrdf, residual
		
		dfuller gdrdf, regress lags(`yearlen') `dfstyle'
		dfuller gdratio, regress lags(`yearlen') `dfstyle'
		dfuller log_rer, regress lags(`yearlen') `dfstyle'
		dfuller log_orer, regress lags(`yearlen') `dfstyle'
		
		newey log_rer L.log_rer, lag(`nw_len')
		
		
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
		
		var D_log_outcome gdratio log_orer D.log_exrate log_pd , lag(1/`varlags') exog(`dummies' D_log_us_cpi) //constraints(1)
		
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
		
		tempfile temp
		save "`temp'"
		
		use "$apath/Simple_Weight.dta", clear
		
		if `yearlen' == 4 {
			gen `time' = qofd(fdate)
		}
		else if `yearlen' == 12 {
			gen `time' = mofd(fdate)
		}
		
		keep `time' N_* fdate
		rename N_GDP* N_gdp*
		rename N_IP* N_ip*
		
		mmerge `time' using "`temp'", unmatched(using)
		
		gen half = hofd(fdate)
		format half %th
		
		if `yearlen' == 4 {
			format `time' %tq
		}
		else if `yearlen' == 12 {
			format `time' %tm
		}
		
		
		
		sort `time'
		tsset `time'
		gen cum_news = sum(gnews)
		gen annual_gnews = 100*(cum_news - L`yearlen'.cum_news)
		replace annual_gnews = . if F.L`yearlen'.gnews == .
		replace N_`outcome'_ft_trunc = 100*N_`outcome'_ft_trunc
		
		gen phitr = 100*`phi'*log(total_return / L`yearlen'.total_return)
		label var phitr "Index Return (scaled by phi)"
		
		capture graph drop VARvsConsensus_`ovar'
		label var annual_gnews "VAR"
		label var N_`outcome'_ft "Survey"
		tsline annual_gnews N_`outcome'_ft_trunc phitr if annual_gnews != ., name(VARvsConsensus_`ovar') legend(order(1 "VAR" 2 "Survey" 3 "{&phi}*Return")) xlabel(, labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("Real GDP growth news (%)") graphregion(fcolor(white) lcolor(white))
		//twoway (line annual_gnews `time' ) (line N_`outcome'_ft_trunc `time') if annual_gnews != ., name(VARvsConsensus_`outcome') legend(order(1 "VAR" 2 "Survey")) xlabel(, labsize(medium)) xtitle("") ylabel(,nogrid) ytitle("`outcome' growth news (%)") graphregion(fcolor(white) lcolor(white))
		graph export "$rpath/VARvsConsensus_`ovar'.png", replace
		
		use "`temp'", clear
		
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
		
		matrix `ovar'_var_b = inv(xx) * xy
		matrix `ovar'_var_b2 = inv(xx2) * xy2
		
		matrix var_diff = (`ovar'_var_b2 - `ovar'_var_b) / `tstep'
		
		//matrix list var_b
		//matrix list svar_b2
		
		gen gn_proxy = dnews * `ovar'_var_b[1,1] + exnews*`ovar'_var_b[2,1]
		
		capture graph drop `ovar'NewsRegression
		tsline gnews gn_proxy, name(`ovar'NewsRegression)
		
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
		
		
		matrix `ovar'_var_V = delb * varV * delb'
		
		matrix rownames `ovar'_var_b = ValueINDEXNewGDP_US GDPExRate
		matrix rownames `ovar'_var_V = ValueINDEXNewGDP_US GDPExRate
		matrix colnames `ovar'_var_V = ValueINDEXNewGDP_US GDPExRate
		
		matrix list `ovar'_var_b
		matrix list `ovar'_var_V
		
		matrix rownames `ovar'_dols_b = ValueINDEXNew_US
		matrix rownames `ovar'_dols_V = ValueINDEXNew_US
		matrix colnames `ovar'_dols_V = ValueINDEXNew_US
		
		matrix list `ovar'_dols_b
		matrix list `ovar'_dols_V
		
		matrix vd = vecdiag(`ovar'_var_V)
		matmap vd sd, map(sqrt(@))
		matrix list sd
		
		matrix vd = vecdiag(`ovar'_dols_V)
		matmap vd sd, map(sqrt(@))
		matrix list sd
		
		
		ereturn clear
		matrix temp = `ovar'_var_b'
		matrix temp2 = `ovar'_var_V
		ereturn post temp temp2, depname(`ovar')
		outreg2 using "$rpath/VARcoeffs.xls", `action' stats(coef se ci) level(95) ctitle("`ovar'")
		
		local action append
		
		
		if `run_svar' != 0 & "`outcome'" == "gdp" {
		
			matrix sshocks = I(5)
			matrix sshocks[1,1] = dnews_mat
			matrix sshocks[2,1] = gnews_mat
			
			matrix list sshocks
			
			local coef_v = -39.35
			local coef_e = 14.80
			
			* results from Rigobon-Sack estimator
			matrix cmat = I(5)
			matrix cmat[1,1] = -`coef_v'
			matrix cmat[2,1] = -`coef_v' * `ovar'_var_b[1,1] + `coef_e' * `ovar'_var_b[2,1]
			matrix cmat[5,1] = -`coef_v' * `rho'
			matrix cmat[4,1] = `coef_e'
			matrix cmat[3,1] = `coef_e'
			
			matrix list cmat
			
			matrix atilde = inv(cmat)*sshocks
			
			matrix btilde = (1,.,.,.,.\0,.,.,.,.\0,0,.,.,.\0,0,0,.,.\0,0,0,0,.)
			
			matrix list atilde
			matrix list btilde
			
			svar D.log_outcome gdratio log_rer D.log_exrate log_pd, lag(1) exog(`dummies' D_log_us_cpi) aeq(atilde) beq(btilde) var
			
			irf create temp, set("$rpath/`ovar'svar_irf",replace) step(20) nose
			irf table sirf, impulse(D.log_outcome)
			irf graph sirf, impulse(D.log_outcome)
			
			graph export "$rpath/`ovar'Default_irf.pdf", as(pdf) replace
		}
	}
}
	
