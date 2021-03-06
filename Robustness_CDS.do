******************
*Robustness Table*
******************

*do ${csd_dir}/SetupPaths.do

*do ${csd_dir}/StaticTable.do

*do ${csd_dir}/ADR_Value.do

*do ${csd_dir}/BlueRateMaker.do

*do ${csd_dir}/GlobalFactors.do

* This can only be run from RunEverything

global cds_robust 1
foreach x in  log_g17px_eurotlx logg17 g17ys g17ys_eurotlx def5y_london def5y_europe PUF_1y PUF_3y PUF_5y  Spread1y Spread3y Spread5y   mC5_1y mC5_3y mC5_5y  conh_ust_def1y conh_ust_def3y conh_ust_def5y tri_conH_def1y tri_conH_def3y tri_conH_def5y tri_def5y bb_tri_def5y  ds_tri_def5y  rsbondys logrsbond  {
	global cds_app "_`x'"
	global cds_n "`x'"

	
	if "`x'" == "log_g17px_eurotlx" | "`x'" == "def5y_london" | "`x'" == "g17ys_eurotlx" {
		global RSdaytype twodayL
		global RSexclude_SC_day 1
		global RSuse_warrant 0
		global RSuse_bonds 0
	}
	else if "`x'" == "def5y_europe" {
		global RSdaytype twodayL
		global RSexclude_SC_day 1
		global RSuse_warrant 0
		global RSuse_bonds 0
	}
	else {
		global RSdaytype twoday
		global RSexclude_SC_day 0
		global RSuse_warrant 0
		global RSuse_bonds 0
	}
	
	do ${csd_dir}/CDSMaker.do
	do ${csd_dir}/ThirdAnalysis.do
	
	do "$csd_dir/RigobonSack_v3.do"	
	//do ${csd_dir}/RunDataCode.do
	//do ${csd_dir}/RunAnalysis.do
}

global RSdaytype twoday
global RSexclude_SC_day 0

*ORGANIZE RESULTS
import excel "$rpath/RS_CDS_IV_reshapeADRs_PUF_1y.xls", firstrow sheet("Sheet1") clear
gen cds_type="PUF_1y"
keep if variables=="cds2" | variables=="Robust_SE" | variables=="Full_SE" | variables=="CI_95"
save "$rpath/temp.dta", replace

foreach x in   PUF_3y PUF_5y  Spread1y Spread3y Spread5y   mC5_1y mC5_3y mC5_5y  conh_ust_def1y conh_ust_def3y conh_ust_def5y tri_conH_def1y tri_conH_def3y tri_conH_def5y tri_def5y bb_tri_def5y  ds_tri_def5y  rsbondys logrsbond NoSC_log_g17px_eurotlx NoSC_def5y_london NoSC_def5y_europe logg17 g17ys NoSC_g17ys_eurotlx {
	**cap{
	if regexm("`x'","Warrants") {
		import excel "$rpath/RS_CDS_IV_reshapeADRs`x'.xls", sheet("Sheet1") firstrow clear
	}
	else {
		import excel "$rpath/RS_CDS_IV_reshapeADRs_`x'.xls", sheet("Sheet1") firstrow clear
	}
	keep if variables=="cds2" | variables=="Robust_SE" | variables=="Full_SE" | variables=="CI_95"
	gen cds_type="`x'"
	append using "$rpath/temp.dta"
	save "$rpath/temp.dta", replace
	**}
}	


	foreach var of varlist _all {
		rename `var' x_`var'
	}
	rename x_cds_type cds_type
	rename x_variables variables
	reshape long x_, i(cds var) j(temp) str
	bysort cds_type: gen se_temp=x_ if variables=="Full_SE"
	destring se_temp, replace force
	bysort cds: egen se_temp2=max(se_temp)
	tostring se_temp2, replace force
	replace x_="("+se_temp2+")" if variables=="Robust_SE" & (temp=="consensus" | temp=="consensus03" | temp=="consensus036m" | temp=="consensus6m" | temp=="vecm")
	drop if var=="Full_SE"
	drop se*
	reshape wide x_, i(cds var) j(temp) str
	renpfix x_
	drop est_type
	gen varnum=2
	replace varnum=1 if vari=="cds2"
	replace varnum=3 if vari=="Robust_SE"

	sort cds_type varnum
		//drop adrminusds contado_ambito dsblue eqindex_us valueindex_us varnum
	//order cds_type variables dolarblue adrblue bcs  valueindexnew_us valuebankindexnew_us   valuenonfinindexnew_us
	
	save "$rpath/Robustness_Table.dta", replace
export excel using "$rpath/Robustness_Table.xls", firstrow(variables) replace

use "$rpath/Robustness_Table.dta", clear
keep if variables=="cds2"
export excel using "$rpath/Robustness_Table_Compact.xls", firstrow(variables) replace

global cds_robust 0
global cds_app ""
global cds_n ""

/*
forvalues cdsii=1/14 {
if `cdsii'==1 {
	global cds_app "_3y"
	global cds_n "def3y"
}	
else if `cdsii'==2 {
	global cds_app "_7y"
	global cds_n "def7y"
}

else if `cdsii'==3 {
	global cds_app "_3yConR"
	global cds_e "conh_def3y_europe"
	global cds_n "conh_def3y"

}

else if `cdsii'==4 {
	global cds_app "_5yConR"
	global cds_e "conh_def5y_europe"
	global cds_n "conh_def5y"
}

else if `cdsii'==5 {
	global cds_app "_7yConR"
	global cds_e "conh_def7y_europe"
	global cds_n "conh_def7y"

}

else if `cdsii'==6 {
	global cds_app "_3yTri"
	global cds_e "tri_def3y_europe"
	global cds_n "tri_def3y"

}

else if `cdsii'==7 {
	global cds_app "_5yTri"
	global cds_e "tri_def5y_europe"
	global cds_n "tri_def5y"
}

else if `cdsii'==8 {
	global cds_app "_7yTri"
	global cds_e "tri_def7y_europe"
	global cds_n "tri_def7y"
}

else if `cdsii'==9 {
	global cds_app "_3yUST"
	global cds_e "ust_def3y_europe"
	global cds_n "ust_def3y"

}

else if `cdsii'==10 {
	global cds_app "_5yUST"
	global cds_e "ust_def5y_europe"
	global cds_n "ust_def5y"
}

else if `cdsii'==11 {
	global cds_app "_7yUST"
	global cds_e "ust_def7y_europe"
	global cds_n "ust_def7y"
}


else if `cdsii'==12 {
	global cds_app "_3yNY"
	global cds_e "def3y_europe"
	global cds_n "def3y_newyork"
}

else if `cdsii'==13 {
	global cds_app "_5yNY"
	global cds_e "def5y_europe"
	global cds_n "def5y_newyork"
}

else if `cdsii'==14 {
	global cds_app "_7yNY"
	global cds_e "def7y_europe"
	global cds_n "def7y_newyork"
}



