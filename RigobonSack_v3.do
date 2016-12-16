

set more off

* Choose which data to use

* These determine the earliest and latest days to use for non-events
local mindate = mdy(1,1,2011)
local maxdate = mdy(1,1,2015)

* Determine what to use for the summary statistics
local sumname ValueINDEXNew_US

*local factors
//local factors SPX_ VIX_ EEMA_ IG5Yr_ HY5Yr_ soybean_ oil_
local factors $all_factors

if "$RSControl" == "" {
	
	* One of these four must be run, to do anything useful
	* Run with local data
	local use_local 0
	
	* Run with ADR data
	local use_adrs 0
	
	* Run with exchange rates
	local use_exrates 0
	
	local use_coreonly 0
	local use_indexonly 0
	
	*Run with NDF rates
	local use_ndf 0
	
	*Run with additional equities (Arcos Dorados, Petrobras, Tenaris)
	local use_addeq 0
	
	*Run with US Breakeven Inflation Rates
	local use_usbeinf 0
	
	* Run with the GDP models
	* Requires use_adrs and use_exrates
	local use_gdpmodels 0
	
	* Run with individual bond returns
	local use_bonds 0
	
	* Run with mexico and brazil CDS/equity [NOTE, can add other countries]
	local use_mexbrl 0
	
	* Run with other default probabilities
	local use_otherdefp 0
	
	* Run with other equity indices
	local use_equityind 0
	
	*Run with GDP Warrants
	local use_warrant 1
	
	* Each of these will run with both local and ADR versions
	* Run with single name stocks
	local use_singlenames 0
	
	* Run with "high" and "low" portfolios
	local use_highlow_ports 0
	
	* Run with high minus low portfolios
	local use_hmls 0
	
	* Run with industries
	local use_industries 0
	
	* add in market and exchange controls
	local relative_perf 0
	
	* If 0, uses equal-weighted index for relative performance.
	* if nonzero, uses MXAR or MERVAL (as appropriate).
	local use_index_beta 0
	
	* if using the relative perf, don't add in the exchange rate
	local no_exchange 0
	
	* use holdout bonds
	* must be on to run MULTI_CDS_IV, off otherwise
	local use_holdout 0
	
	* exclude SC day
	local exclude_SC_day 0
	
	* Different kinds of regressions that can be run
	* Options are: OLS OLS_LC RS_CDS_IV RS_CDS_IV RS_Return_IV RS_Return_IV_LC 2SLS_IV 2SLS_IV_LC RS_N_CDS_IV MULTI_CDS_IV
	* RS_N_CDS_IV predicts the next return, rather than the contemporaneous return
	
	local regs RS_CDS_IV
	//local regs MULTI_CDS_IV MULTI_OLS
	
	* This excludes days on which legal events occurred, but
	* there are other events or holidays that render the date unusable
	local exclusions 1
	
	* Determines which kind of day to use
	* Options are opens, closes, and twoday
	* Opens doesn't fully work right now
	local daytype twodayL
	
	* use date for twoday, eventclosedate for closes, and eventopendate for opens
	local cvar date
	
	* This controls the standard error commands in the IV regressions
	* This controls the bootstrap part
	local bstyle rep(100) strata(eventvar) seed(4251984) cluster(`cvar') //noisily
	
	* This is the asymptotic estimator used in each bootstrap replication
	local ivstderrs robust
	//local ivstderrs
	
	* turn off if not running with soy
	*local soycontrols SPX_ VIX_ EEMA_ IG5Yr_ HY5Yr_ oil_ soybean_

}
else {

	foreach lname in use_local use_adrs use_exrates use_coreonly use_ndf use_addeq use_usbeinf use_gdpmodels use_bonds use_mexbrl use_otherdefp use_equityind use_singlenames use_highlow_ports use_hmls use_industries relative_perf use_index_beta no_exchange use_holdout use_warrant exclude_SC_day regs exclusions daytype bstyle ivstderrs soycontrols use_indexonly {
		local `lname' ${RS`lname'}
		disp "`lname': ``lname''"
	}
}



*** options end here. start of the actual code.


local ext_style

* Setup code for running relative performance
if `relative_perf' == 1 {
	
	local ext_style _relative_noex
	
	if `use_index_beta' == 0 {
		local factors `factors' eqreturn_ 
	}
	else {
		local factors `factors' indreturn_ 
	}
	
	if `no_exchange' != 1 {
		local factors `factors' madrreturn
		local ext_style _relative
	}
}	


if `exclusions' == 0 {
	local ext_style `ext_style'_noexcl
}

if "$RSalt_dates" != "" & "$RSalt_dates" != "0" {
	local ext_style `ext_style'_altdates$RSalt_dates
}

if "`soycontrols'" != "" {
	local factors $RSsoycontrols
	local ext_style `ext_style'_soy
	local nodropsoy | regexm(firmname,"SoybeanFutures_US")
}

if `use_warrant'==1 {
	local nodropwarrants | regexm(industry_sector,"gdpw") | regexm(industry_sector,"eurotlx")
}

local ext 

use "$apath/ThirdAnalysis.dta", clear
//use "`apath'/SecondAnalysis.dta", clear
* Code to implement choice of which assets to run
if `use_industries' == 0 {
	drop if isstock == 1 & ports == 1 & ishml == 0 & ~regexm(industry_sector,"High_") & ~regexm(industry_sector,"Low_")
}
if `use_local' != 0 {
	local ext Local
}
else {
	drop if market == "AR"
}
if `use_adrs' != 0 {
	local ext `ext'ADRs
}
else {
	drop if market == "US"
}

if `use_exrates' == 0 {
	drop if regexm(industry_sector,"Blue") | regexm(industry_sector,"Official") | regexm(industry_sector,"ADRMinusDS") | regexm(industry_sector,"dolarblue") | regexm(industry_sector,"BCS") | regexm(industry_sector,"ADRB_PBRTS") | regexm(industry_sector,"Contado_Ambito")
}

if `use_coreonly' == 1 {
	drop if market == "US" & ~(regexm(industry_sector,"ValueINDEXNew") | regexm(industry_sector,"ValueBankINDEXNew") | regexm(industry_sector,"ValueNonFinINDEXNew") | regexm(firmname,"INDEX_US") | regexm(firmname,"YPF_US") `nodropsoy')
	drop if market != "US" & ~(regexm(industry_sector,"ADRBlue") | regexm(industry_sector,"dolarblue") | regexm(industry_sector,"BCS") | regexm(industry_sector,"Official") `nodropwarrants')
}

if `use_indexonly' == 1 {
	keep if (market == "US" & regexm(industry_sector,"ValueINDEXNew")) `nodropwarrants'
}

if `use_ndf'==0 {
	drop if regexm(industry_sector,"NDF")  | regexm(industry_sector,"FWDP") 
}

if `use_usbeinf'==0 {
	drop if regexm(industry_sector,"US10YBE")  | regexm(industry_sector,"US5YBE") 
}
	
if `use_mexbrl' == 0 {
	drop if regexm(industry_sector,"Mexico") | regexm(industry_sector,"Brazil")
}

if `use_otherdefp' == 0 {
	drop if regexm(industry_sector,"DTRI")
}

if `use_equityind' == 0 {
	drop if regexm(industry_sector,"EquityInd")
}

if `use_warrant'==0 {
	drop if regexm(industry_sector,"gdpw")
}	
else { 
	local ext `ext'Warrants
}

if `use_bonds' == 0 {
	drop if regexm(industry_sector,"defbond") | regexm(industry_sector,"rsbond") | regexm(industry_sector,"bonar") | regexm(industry_sector,"boden") | regexm(industry_sector,"NMLbond") | regexm(industry_sector,"nmlbond") | regexm(industry_sector,"eurotlx")
}
	

if `use_addeq' == 0 {
	drop if regexm(industry_sector,"ARCO") | regexm(industry_sector,"PBR")  | regexm(industry_sector,"TS") | regexm(industry_sector,"TX")
}

if `use_singlenames' == 0  {
	if `use_coreonly' != 1 {
		drop if isstock == 1 & ports == 0
	}
}
else {
	local ext `ext'Full
}
if `use_highlow_ports' == 0 {
	drop if regexm(industry_sector,"High_") | regexm(industry_sector,"Low_")
}
if `use_hmls' == 0 {
	drop if ishml == 1 & ~regexm(industry_sector,"ADRMinusDS")
}
else {
	local ext `ext'HML
}

if `use_holdout' == 1 {
	local ext_style `ext_style'_holdout
	
	/*rename cds_ cdscontrol
	rename holdout_ret cds_
	
	if `no_cds_control' == 0 {
		local factors `factors' cdscontrol
	}
	else {
		local ext_style `ext_style'nocdscontrol
	}*/
	
	drop if holdout_ret == .
}

local ext_style `ext'`ext_style'

* Code to choose event and non-event days
gen eventvar = .

if "`daytype'"=="twoday" {
	drop if day_type!="twoday"
	replace eventvar = event_day
	local clause mod(dayindex,2)==0 &
}
else if "`daytype'"=="twodayL" {
	drop if day_type!="twodayL"
	replace eventvar = event_dayL
	local clause mod(dayindex,2)==0 &
}
else if regexm("`daytype'","opens") {
	drop if ~regexm(day_type,"onedayL")
	replace eventvar = eventopens
	local clause
	local ext_style `ext_style'_opens
	* Have to drop stuff with missing open/close
	drop if regexm(industry_sector,"Mexico") | regexm(industry_sector,"Brazil") | regexm(industry_sector,"DSBlue") | regexm(industry_sector,"Official")
}
else {
	drop if ~regexm(day_type,"onedayN")
	replace eventvar = eventcloses
	local clause
	local ext_style `ext_style'_closes
}


gen next_return = F2.return_

levelsof firmname, local(industries)

//gen nonevent = `clause' eventvar == 0 & (L.eventvar == 0 | (L.eventvar == . & L2.eventvar == 0)) & (F.eventvar == 0 | (F.eventvar == . & F2.eventvar == 0))

gen nonevent = `clause' eventvar == 0 & (L.eventvar == 0 | L.eventvar == .) & (F.eventvar == 0 | F.eventvar == .)
* Exclusions were defined earlier. This implements them.

if `exclusions' == 1 {

	gen excludedday = eventexcluded == 1 | L.eventexcluded == 1 | F.eventexcluded == 1
	
	replace nonevent = 0 if excludedday
	replace eventvar = 0 if excludedday
	
}

replace nonevent = 0 if nonevent == 1 & (date < `mindate' | date > `maxdate')

if `exclude_SC_day' == 1 {
	drop if (date == mdy(6,16,2014) | date == mdy(6,17,2014)) & ~(regexm(industry_sector,"gdpw") | regexm(industry_sector,"eurotlx"))
	local ext_style `ext_style'_NoSC
}


drop if eventvar == 0 & nonevent == 0
drop if return_ == . | cds_ == .



if `use_adrs' != 0 & `use_exrates' != 0 & `use_gdpmodels' != 0 {	
	expand 2 if firmname == "ValueINDEXNew_US" | firmname == "$HFExName", gen(vGDP)
	replace firmname = "ValueINDEXNewGDP_US" if vGDP == 1 & firmname == "ValueINDEXNew_US"
	replace industry_sector = "ValueINDEXNewGDP" if firmname == "ValueINDEXNewGDP_US"
	replace firmname = "GDPExRate" if vGDP == 1 & firmname == "${HFExName}"
	replace industry_sector = "GDPExRate" if firmname == "GDPExRate"
	
	
	sort date firmname
	by date: egen excnt = sum(firmname == "$HFExName")
	by date: egen vicnt = sum(firmname == "ValueINDEXNew_US")
	drop if (firmname == "ValueINDEXNewGDP_US" | firmname == "GDPExRate") & (excnt == . | excnt == 0)
	drop if (firmname == "ValueINDEXNewGDP_US" | firmname == "GDPExRate") & (vicnt == . | vicnt == 0)
	drop excnt vicnt vGDP
}



*Save dataset at this point to construct summary states
save "$apath/data_for_summary.dta", replace

* This constructs the factor variables.
* On some days, some factor returns are missing but the 
* returns/CDS are not. Constructing these missing dummies
* is used to avoid dropping those dates.

* Don't want to use the extra factors for the index or the exchange rate
if `relative_perf' == 1 {
	replace madrreturn = 0 if regexm(industry_sector,"INDEX") |  regexm(industry_sector,"EqIndex") | regexm(firmname,"ADRBlue") | regexm(firmname,"DSBlue") | regexm(firmname,"ADRMinusDS") | regexm(firmname,"OfficialRate")
	replace eqreturn_ = 0 if regexm(industry_sector,"INDEX") | regexm(industry_sector,"EqIndex")  | regexm(firmname,"ADRBlue") | regexm(firmname,"DSBlue") | regexm(firmname,"ADRMinusDS") | regexm(firmname,"OfficialRate")
	drop if eqreturn_ == .
	
	if `no_exchange' != 1 {
		//replace eqreturn_ = 0 if regexm(firmname,"ADRBlue") | regexm(firmname,"DSBlue") | regexm(firmname,"ADRMinusDS")
		drop if madrreturn == .
	}
}



local factors2 `factors'
foreach ft in `factors' {
	gen `ft'_missing = `ft' == .
	replace `ft' = 0 if `ft'_missing == 1
	local factors2 `factors2' `ft'_missing
}

* These counts are used to weight the events and non-events correctly.
* See Rigobon and Sack, footnote 10.

sort firmname date

by firmname: egen enum = sum(eventvar)
by firmname: egen nnum = sum(nonevent)


gen ins_cds = eventvar * cds_ * (enum+nnum)/(enum) - (1-eventvar)*cds_*(enum+nnum)/(nnum)
gen ins_ret = eventvar * return_ * (enum+nnum)/(enum) - (1-eventvar)*return_*(enum+nnum)/(nnum)
gen ins_holdout = eventvar * holdout_ret * (enum+nnum)/(enum) - (1-eventvar)*holdout_ret*(enum+nnum)/(nnum)

* These are the IV-style estimates (not Rigobon and Sack).
* Just the simple event-style IV.

gen cds_iv = eventvar * cds_


levelsof firmname, local(names) clean

local numnames 0
foreach ind_name in `names' {
	local numnames = `numnames' + 1
}
matrix cds_betas = J(`numnames',1,0)
matrix rownames cds_betas = `names'

* Add in the names of the GDP models
disp "`use_adrs' `use_exrates' `use_gdpmodels'"
disp "`names' $GDP_models"
if `use_adrs' != 0 & `use_exrates' != 0 & `use_gdpmodels' != 0 {
	local names `names' $GDP_models
}

tsset, clear


if `use_adrs' == 1 & regexm("`daytype'","twoday") {

	** code to make some summary stats *
	capture log close
	log using "$rpath/summary_log$cds_app.smcl", replace

	summ return_ cds_ if nonevent==1 & cds_~=. & return_~=. & regexm(firmname,"`sumname'")
	summ return_ cds_ if eventvar==1 & cds_~=. & return_~=. & regexm(firmname,"`sumname'")

	corr return_ cds_ if nonevent==1 & cds_~=. & return_~=. & regexm(firmname,"`sumname'"), covariance
	corr return_ cds_ if eventvar==1 & cds_~=. & return_~=. & regexm(firmname,"`sumname'"), covariance 
	
	tempfile temp bsfile
	
	save "`temp'", replace
	drop if ~regexm(firmname,"`sumname'")
	
	robvar cds_, by(eventvar)
	
	local w0 = r(w0)
	local w10 = r(w10)
	local w50 = r(w50)
	
	bootstrap r0=(r(w0)/`w0') r1=(r(w10)/`w10') r2=(r(w50)/`w50'), `bstyle' saving("`bsfile'", replace): robvar cds_ if regexm(firmname,"`sumname'"), by(eventvar)
	
	use "`bsfile'", clear
	su r*, detail
	
	use "`temp'", clear
	
	/*sort date industry_sector

	by date: egen mexcds2 = mean(day_return2*regexm(industry_sector,"MexicoCDS"))

	summ day_return2 mexcds2 if nonevent==1 & cds2~=. & day_return2~=. & regexm(industry_sector,"MexicoEquity")
	summ day_return2 mexcds2 if event_day==1 & cds2~=. & day_return2~=. & regexm(industry_sector,"MexicoEquity")

	corr day_return2 mexcds2 if nonevent==1 & cds2~=. & day_return2~=. & regexm(industry_sector,"MexicoEquity"), covariance
	corr day_return2 mexcds2 if event_day==1 & cds2~=. & day_return2~=. & regexm(industry_sector,"MexicoEquity"), covariance*/

	log close
	if "$logname" != "" {
		log using "$logname", append
	}
}

local OLS ivreg2 return_ cds_ `factors2' 
local OLS_LC ivreg2 return_local cds_ `factors2' 
local RS_CDS_IV ivreg2 return_  `factors2' (cds_ = ins_cds)
local RS_CDS_IV_DM ivreg2 return_  `factors2' eventvar (cds_ = ins_cds)
local RS_CDS_IV_LC ivreg2 return_local  `factors2' (cds_ = ins_cds)
local RS_Return_IV ivreg2 return_  `factors2' (cds_ = ins_ret)
local RS_Return_IV_LC ivreg2 return_local  `factors2' (cds_ = ins_ret)
local 2SLS_IV ivreg2 return_ `factors2' eventvar (cds_ = cds_iv)
local 2SLS_IV_LC ivreg2 return_local `factors2' eventvar (cds_ = cds_iv)

local RS_N_CDS_IV ivreg2 next_return  `factors2' (cds_ = ins_cds)

local MULTI_CDS_IV ivreg2 return_  `factors2' (cds_ holdout_ret = ins_cds ins_holdout)
local MULTI_OLS ivreg2 return_ cds_ holdout_ret `factors2' 

sort firmname date

tempfile backupfile // bsfile 

local bsfile "$apath/bsfile.dta"

gen rtype = "ADRs"
replace rtype = "FX" if regexm(industry_sector,"ADRBlue") | regexm(industry_sector,"DSBlue") | regexm(industry_sector,"Official")
replace rtype = "Other" if regexm(industry_sector,"Mexico") | regexm(industry_sector,"Brazil")


foreach rg in `regs' {
	
	disp "Reg: `rg'"
	local action replace
	
	local namenum 0
	
	foreach ind_name in `names' {

		disp "Industry: `ind_name'"
		local namenum = `namenum' + 1
		
		local stderrs `ivstderrs'
		if ~regexm("`rg'","OLS") {
			local extrastat WID F-Stat, e(widstat)
		}
		else {
			local extrastat F-Stat, e(F)
		}
		
		if ~regexm("`rg'","MULTI") {
			local outopts keep(cds_) nocons ctitle("`ind_name'")
		}
		else {
			local outopts keep(cds_ holdout_ret) nocons ctitle("`ind_name'")
		}
		
		if regexm("$GDP_models","`ind_name'") {
			local extrastat `extrastat', Full_SE, e(se1), Num Events, e(num_e)
		}
		else {
			su nfirms if regexm(firmname,"`ind_name'")
			local nf = `r(mean)'
			su enum if regexm(firmname,"`ind_name'")
			local num_e = `r(mean)'
			
			local extrastat `extrastat', Num Firms, `nf', Num Events, `num_e'
		}
		

		
		
		
		*RUN THE REGRESSION
		if regexm("$GDP_models","`ind_name'") {
			GDP_BS_helper ``rg'', model_name(`ind_name') stderrs("`stderrs'") coef_name(cds_betas)
			
			local coef1 = _b[cds_]
			local se1 = e(se1)
		}
		else {
			``rg'' if regexm(firmname,"`ind_name'"), `stderrs'
			
			local coef1 = _b[cds_]
			local se1 = _se[cds_]
			matrix cds_betas[`namenum',1] = `coef1'
		}

		


		if `relative_perf' == 1 {
			//`no_exchange' != 1 &
			if regexm("`ind_name'","INDEX") | regexm("`ind_name'","EqIndex") |  ( regexm("`ind_name'","ADRBlue") | regexm("`ind_name'","MERVAL") | regexm("`ind_name'","MXAR") | regexm("`ind_name'","DSBlue") | regexm("`ind_name'","DSMinusADR") | regexm("`ind_name'","ADRMinusDS") | regexm("`ind_name'","OfficialRate") ){
				local beta_ind 0
				local beta_ex 0
			}
			else {
				local beta_ind = _b[eqreturn_]
				if `no_exchange' != 1 {
					local beta_ex = _b[madrreturn]
				}
				else {
					local beta_ex = 0
				}
			}
			local extrastat `extrastat', Index Beta, `beta_ind', Exchange Rate Beta, `beta_ex'
		}
		
		if regexm("$GDP_models","`ind_name'") {
			local bsvars ((_b[cds_]-`coef1')/e(se1))
		}
		else {
			local bsvars ((_b[cds_]-`coef1')/_se[cds_])
		}
		local bsN 1
		
		estimates store etemp
		save "`backupfile'", replace
		
		*Run bootstrap
		if regexm("$GDP_models","`ind_name'") {
			bootstrap `bsvars', `bstyle' saving("`bsfile'", replace): GDP_BS_helper ``rg'', model_name(`ind_name') stderrs("`stderrs'") randomize coef_name(cds_betas)
		}
		else {
			disp "``rg'', `stderrs'"
			bootstrap `bsvars', `bstyle' saving("`bsfile'", replace): ``rg'' if regexm(firmname,"`ind_name'"), `stderrs'
		}
		
		*Open bootstrap file
		use "`bsfile'", clear
		
		su _bs_*, detail
		
		//histogram _bs_2, bin(40)
		* NOT DOING ANY LOOPING, ARTEFACT OF GMM
		forvalues i = 1/`bsN' {
		
			_pctile _bs_`i', p(0.5 2.5 5 95 97.5 99.5) altdef
		
			local cip`i'_L_90=`r(r3)'
			local cip`i'_H_90=`r(r4)'
			local cip`i'_L_95=`r(r2)'
			local cip`i'_H_95=`r(r5)'
			local cip`i'_L_99=`r(r1)'
			local cip`i'_H_99=`r(r6)'
		}
		
		*RELOADING WHAT WE SAVED, GET CONFIDENCE INTERVALS
		use "`backupfile'", clear	
		estimates restore etemp
		
		local cis
		forvalues i = 1/`bsN' {
			foreach lvl in 90 95 99 {
			
				matrix temp=(`cip`i'_L_`lvl'' \ `cip`i'_H_`lvl'')
				matrix ci=temp*`se`i''+J(2,1,`coef`i'')

				
				local ci`i'_L_`lvl'=ci[1,1]
				local ci`i'_H_`lvl'=ci[2,1]
				
				matrix drop temp ci
				
				disp "i: `i' level: `lvl' CI: `ci`i'_L_`lvl'' to `ci`i'_H_`lvl''"
				local cis `cis' CI_`i'_`lvl'_L, `ci`i'_L_`lvl'',CI_`i'_`lvl'_H,`ci`i'_H_`lvl'',
			}
		}
			
		*disp "cis: `cis'"
		*disp "`rpath'/`rg'.xls"
		outreg2 using "$rpath/`rg'`ext_style'$cds_app.xls", stats(coef se) `action' addstat(`cis' `extrastat') noaster nonotes `outopts'
		
		local action append
	}
}

local exnames
if `use_coreonly' != 0 {
	local inames INDEX ValueINDEXNew ValueBankIndexNew ValueNonFinIndexNew YPF
	local exnames OfficialRate dolarblue ADRBlue  BCS
	if "`daytype'" == "twodayL" | "`daytype'" == "opens" {
		local inames ValueINDEXNew ValueBankIndexNew ValueNonFinIndexNew YPF
		local exnames ADRBlue
	}
	
}
else {
	local inames INDEX EqIndex
}
if `use_indexonly' != 0 {
	local inames ValueINDEXNew
	local exnames
}

if `use_adrs' != 0 & `use_coreonly' == 0 {
	local inames `inames' ValueIndex
}

if `use_industries' != 0 {
	local inames `inames' Banks NonFinancial RlEst Enrgy NoDur Telcm Utils
}

local inames2
if `use_local' != 0 {
	foreach inm in `inames' {
		local inames2 `inames2' `inm'_AR
	}
}
if `use_adrs' != 0  {
	foreach inm in `inames' {
		local inames2 `inames2' `inm'_US
	}
}


if `use_exrates' != 0 & `use_coreonly' == 0 {
	local exnames OfficialRate dolarblue ADRBlue  BCS DSBlue ADRMinusDS
}

local gdpnames
if `use_adrs' != 0 & `use_exrates' != 0 & `use_gdpmodels' != 0 {
	local gdpnames $GDP_models
}

local hmlnames
if `use_hmls' != 0 {
	local hmlnames HML_es_industry HML_finvar HML_import_intensity HML_Government HML_export_share HML_foreign_own HML_indicator_adr
}

local mexbrl
if `use_mexbrl' != 0 {
	local mexbrl BrazilCDS BrazilEquity MexicoCDS MexicoEquity
}

local highlow_names
if `use_highlow_ports' != 0 {
	local hmlnames High_es_industry Low_es_industry High_finvar Low_finvar High_import_intensity Low_import_intensity High_Government Low_Government High_export_share Low_export_share High_foreign_own Low_foreign_own High_indicator_adr Low_indicator_adr

}

local varorder `inames2' `exnames' `gdpnames' `hmlnames' `mexbrl' `highlow_names'
disp "varorder: `varorder'"

foreach x in  `regs' { 
 
	import delimited "$rpath/`x'`ext_style'$cds_app.txt", clear

	drop if (v2=="" | v2 == "(1)" | v2 == "( - )") & v1 ~= "Full_SE"
	
	
	replace v1 = "cds2" if v1 == "cds_"
	replace v1 = "Robust_SE" if v1[_n-1] == "cds2"
	local bsN = 1
	
	sxpose, clear
	foreach var of varlist * {
		replace `var'=trim(`var')
		replace `var'=subinstr(`var'," ","_",.) if ~regexm(`var'[1],"CI")
		if `var'[1]~="excess_cds" & `var'[1]~="cds2" & ~regexm(`var'[1],"CI") & `var'[1]~="Constant" & `var'[1]~="Index_Beta" & `var'[1]~="Exchange_Rate_Beta" {
			replace `var'=subinstr(`var',"-","_",.)
		}
		local temp=`var'[1]
		rename `var' `temp'
	}
		
	rename VAR firm
	
		
	destring CI_*, replace force
	
	gen aster = ""
	replace aster = "*" if CI_1_90_L > 0 | CI_1_90_H < 0
	replace aster = "**" if CI_1_95_L > 0 | CI_1_95_H < 0
	replace aster = "***" if CI_1_99_L > 0 | CI_1_99_H < 0
	replace aster = "" if _n == 1
	
	tostring CI_*, replace force format(%9.1f)
	
	gen CI_95 = "[" + CI_1_95_L + "," + CI_1_95_H + "]"
	replace cds2 = cds2 + aster
	drop aster CI_1* 
	
	replace CI_95 = "CI_95" if _n == 1
		
	cap {
		rename cds2 Coef_`x'
	}
	cap {
		rename excess_cds Coef_`x'
	}

	/*gen core=0
	replace core=1 if firm=="OfficialRate" | firm=="DSBlue" |  firm=="ADRBlue"
	replace core=2 if firm=="BrazilCDS" | firm=="BrazilEquity" | firm=="MexicoEquity" | firm=="MexicoCDS" 
	sort core firm 
	drop core */
	sxpose ,   clear

	foreach y of varlist _all {
	local temp=lower(`y'[1])
	rename `y' `temp'
	}
	drop if _n==1
	
	local varorder2 = lower("`varorder'")
	order variables `varorder2'
	
	gen est_type="`x'"
	
	
	save "$rpath/`x'_reshape`fext'.dta", replace
	export excel using "$rpath/`x'_reshape`ext_style'$cds_app.xls", firstrow(varlabels) replace

	
	use "$rpath/`x'_reshape`fext'.dta", clear

	keep variables `varorder2'

	export excel using "$rpath/`x'_Body`ext_style'$cds_app.xls", firstrow(varlabels) replace
	use "$rpath/`x'_reshape`fext'.dta", clear
	
	if `use_mexbrl' != 0 {
		keep variables brazilcds brazilequity mexicocds mexicoequity
		export excel using "$rpath/`x'_Appendix`ext_style'$cds_app.xls", firstrow(varlabels) replace
	}
}

