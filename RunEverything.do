
local run_test 0
local run_defprob 1

matrix drop _all
macro drop cds_n cds_app cds_robust

do ${csd_dir}/SetupPaths.do

capture log close
global logname ${rpath}/everything.smcl
log using "$logname", replace

//local files "${apath}/*.dta"

//!rm `files'

rmfiles, folder(${apath}) match(*.dta) 

do ${csd_dir}/RunDataCleaning.do

if `run_defprob' == 1 {
	do ${csd_dir}/ProbabilityOfDefault/Default_Prob_OneStep.do
}


do ${csd_dir}/RunDataCode.do

do ${csd_dir}/Cost_Table.do

do ${csd_dir}/HoldingsTable.do

* Configure Rigobon-Sack File
global RSControl 1

global RSexclusions 1
global RSdaytype twoday
global RSbstyle rep(1000) strata(eventvar) seed(4251984) cluster(date)
global RSivstderrs robust
global alt_rho = 0

global RSwarrants_run 0
global hetero_event 0
global RSuse_local 0
global RSuse_adrs 1
global RSuse_exrates 1
global RSuse_indexonly 0

// Code for testing only
 if `run_test' == 1 {
	global RSuse_ndf 0
	global RSuse_addeq 0
	global RSuse_usbeinf 0
	global RSuse_otherdefp 0
	global RSuse_coreonly 1
	global RSuse_warrant 0
	global RSuse_gdpmodels 0
	global RSuse_bonds 0
	global RSuse_mexbrl 0
	global RSuse_otherdefp 0
	global RSuse_equityind 0
	global RSuse_singlenames 0
	global RSuse_highlow_ports 0
	global RSuse_hmls 0
	global RSuse_industries 0
	global RSrelative_perf 0
	global RSuse_index_beta 0
	global RSno_exchange 0
	global RSuse_holdout 0
	global RSexclude_SC_day 0
	global RSregs RS_CDS_IV
	
	do ${csd_dir}/RunAnalysis.do
	exit
}


global RSuse_coreonly 0
global RSuse_ndf 0
global RSuse_addeq 1
global RSuse_usbeinf 0

// turning off for AER revision
global RSuse_gdpmodels 0


global RSuse_bonds 1
global RSuse_mexbrl 1
global RSuse_warrant 0
global RSuse_otherdefp 0
global RSuse_equityind 0
global RSuse_singlenames 0
global RSuse_highlow_ports 0
global RSuse_hmls 0
global RSuse_industries 0
global RSrelative_perf 0
global RSuse_index_beta 0
global RSno_exchange 0
global RSuse_holdout 0
global RSexclude_SC_day 0
global RSregs OLS 2SLS_IV RS_CDS_IV


// This does most of the main tables
do ${csd_dir}/RunAnalysis.do


// Make the plots
do ${csd_dir}/Summary_Plots.do

// Run alternative CDS dates
global RSuse_addeq 0
global RSuse_gdpmodels 0
global RSuse_bonds 0
global RSuse_mexbrl 0
global RSuse_coreonly 1
global RSregs RS_CDS_IV

global RSalt_dates 1
do ${csd_dir}/CDSMaker.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/RigobonSack_v3.do

global RSalt_dates 2
do ${csd_dir}/CDSMaker.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/RigobonSack_v3.do

global RSalt_dates 3
do ${csd_dir}/CDSMaker.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/RigobonSack_v3.do

global RSalt_dates 4
do ${csd_dir}/CDSMaker.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/RigobonSack_v3.do

global RSalt_dates 5
do ${csd_dir}/CDSMaker.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/RigobonSack_v3.do

global RSalt_dates 0
global RSsoycontrols SPX_ VIX_ EEMA_ IG5Yr_ HY5Yr_ oil_ soybean_
do ${csd_dir}/CDSMaker.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/RigobonSack_v3.do
global RSsoycontrols


// Run one-day windows
global RSdaytype closes
global RSbstyle rep(1000) strata(eventvar) seed(4251984) cluster(eventclosedate)

do ${csd_dir}/CDSMaker.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/RigobonSack_v3.do

// This does the local HML files
global RSuse_local 1
global RSuse_adrs 0
global RSuse_exrates 0
global RSuse_hmls 1
global RSrelative_perf 1
global RSuse_coreonly 0
global RSdaytype twoday
global RSbstyle rep(1000) strata(eventvar) seed(4251984) cluster(date)
do ${csd_dir}/RigobonSack_v3.do

// run the version without exchange rate controls
global RSno_exchange 1
do ${csd_dir}/RigobonSack_v3.do

// run the industry version without ex rate controls
global RSuse_industries 1
global RSuse_hmls 0
do ${csd_dir}/RigobonSack_v3.do

// Make the industry and HML Charts
do ${csd_dir}/BKChartMaker.do


// Standard Event Study
do ${csd_dir}/StandardEventStudy.do

// Run other countries
global RSuse_local 0
global RSuse_otherdefp 1
global RSuse_equityind 1
global RSuse_hmls 0
global RSuse_industries 0
global RSrelative_perf 0
global RSregs OLS RS_CDS_IV
do ${csd_dir}/RigobonSack_v3.do


global RSuse_adrs 1
global RSuse_exrates 1
global RSuse_otherdefp 0
global RSuse_equityind 0
global RSuse_coreonly 1
global RSregs RS_CDS_IV

// Run alternative rho
// Turned off for AER revision
/*global RSuse_gdpmodels 1

foreach arho in 0.8 0.95 {
	matrix drop _all
	global alt_rho = `arho'
	do ${csd_dir}/RunAnalysis.do
}

global alt_rho = 0
do ${csd_dir}/SetupPaths.do*/




// CDS measure robustness
global RSuse_gdpmodels 0
*global RSuse_indexonly 1
do ${csd_dir}/Robustness_CDS.do

// Hetero event study
global hetero_event 1
global RSuse_indexonly 0

do ${csd_dir}/CDSMaker.do
do ${csd_dir}/ThirdAnalysis.do

do ${csd_dir}/HeteroEventStudy.do


global RSuse_adrs 1
global RSuse_exrates 1
global RSuse_otherdefp 0
global RSuse_equityind 0
global RSuse_coreonly 1
global RSuse_indexonly 1
global RSuse_warrant 1
global RSuse_bonds 1
global RSregs OLS RS_CDS_IV
global RSdaytype twodayL
global RSwarrants_run 1
global RSexclude_SC_day 1

do ${csd_dir}/CDSMaker.do
do ${csd_dir}/ThirdAnalysis.do

do ${csd_dir}/RigobonSack_v3.do


*WARRANTS FIGURE
global RSuse_adrs 1
global RSuse_exrates 1
global RSuse_otherdefp 0
global RSuse_equityind 0
global RSuse_coreonly 1
global RSuse_indexonly 1
global RSuse_warrant 1
global RSuse_bonds 0
global RSregs OLS RS_CDS_IV
global RSdaytype twodayL
global RSwarrants_run 1
global RSexclude_SC_day 0

do ${csd_dir}/CDSMaker.do
do ${csd_dir}/ThirdAnalysis.do
do ${csd_dir}/Summary_Plots_Warrants.do



//DTCC Table
do ${csd_dir}/DataCleaningScripts/DTCC_Clean.do




