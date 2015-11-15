


do ${csd_dir}/SetupPaths.do

capture log close
global logname ${rpath}/everything.smcl
log using "$logname", replace


!rm "${apath}/*.dta"
!del "${apath}/*.dta"

matrix drop _all

do ${csd_dir}/RunDataCleaning.do

do ${csd_dir}/RunDataCode.do

do ${csd_dir}/Cost_Table.do


* Configure Rigobon-Sack File
global RSControl 1
global hetero_event 0
global RSuse_local 0
global RSuse_adrs 1
global RSuse_exrates 1
global RSuse_coreonly 0
global RSuse_ndf 0
global RSuse_addeq 1
global RSuse_usbeinf 0
global RSuse_gdpmodels 1
global RSuse_bonds 1
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
global RSregs OLS 2SLS_IV RS_CDS_IV
global RSexclusions 1
global RSdaytype twoday
global RSbstyle rep(1000) strata(eventvar) seed(4251984) cluster(date)
global RSivstderrs robust

// This does most of the main tables
global alt_rho = 0
*do ${csd_dir}/RunAnalysis.do

// This does the local HML files
global RSuse_local 1
global RSuse_adrs 0
global RSuse_exrates 0
global RSuse_addeq 0
global RSuse_gdpmodels 0
global RSuse_bonds 0
global RSuse_hmls 1
global RSuse_industries 0
global RSrelative_perf 1
global RSregs RS_CDS_IV
do ${csd_dir}/RigobonSack_v3.do

// run the version without exchange rate controls
global RSno_exchange 1
do ${csd_dir}/RigobonSack_v3.do

// run the industry version without ex rate controls
global RSuse_industries 1
global RSuse_hmls 0
do ${csd_dir}/RigobonSack_v3.do

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

// CDS measure robustness
global RSuse_adrs 1
global RSuse_exrates 1
global RSuse_otherdefp 0
global RSuse_equityind 0
global RSuse_coreonly 1
global RSregs RS_CDS_IV
do ${csd_dir}/Robustness_CDS.do

// Run alternative rho


global RSuse_gdpmodels 1

foreach arho in 0.8 0.95 {
	matrix drop _all
	global alt_rho = `arho'
	do ${csd_dir}/RunAnalysis.do
}
global alt_rho = 0

// Hetero event study
global hetero_event 1
do ${csd_dir}/RunDataCleaning.do
do ${csd_dir}/RunDataCode.do
do ${csd_dir}/HeteroEventStudy.do

// Make the plots
do ${csd_dir}/Summary_Plots.do

* This has to be run manually after opening and saving the required
* files as a .xlsx
*do ${csd_dir}/BKChartMaker.do


