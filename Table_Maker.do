*TABLE MAKER

tempfile temp1 temp2 temp3

*MAIN Equity RESULTS
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Results/BenH_2Sep2015/RS_CDS_IV_reshapeADRs.xls", sheet("Sheet1") clear
sxpose, clear
save "`temp1'"

*Local Results 
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Results/BenH_3Sep2015/RS_CDS_IV_reshapeLocalHML_relative_noex.xls", sheet("Sheet1") clear
sxpose, clear
save "`temp2'"

*Local Results 
import excel "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Results/BenH_3Sep2015/RS_CDS_IV_reshape.xls", sheet("Sheet1") clear
sxpose, clear
save "`temp3'", replace

*
use "`temp1'", clear
replace _var3="("+_var9+")" if _var9~="" & _n~=1
keep _var1 _var2 _var3 _var4 _var10
keep if _var1=="variables" |  _var1=="index_us" |  _var1=="valueindexnew_us" |  _var1=="valuebankindexnew_us" |  _var1=="valuenonfinindexnew_us"
gen output_num=1
replace output_num=2 if _var1=="index_us"
replace output_num=3 if _var1=="valueindexnew_us"
replace output_num=4 if _var1=="valuebankindexnew_us"
replace output_num=5 if _var1=="valuenonfinindexnew_us"
sort output_num
drop output_num
foreach x of varlist _all {
	rename `x' v_`x'
	}
sxpose, clear 

gen order=1
replace order=2 if _var1=="cds2"
replace order=3 if _var1=="Robust_SE"
replace order=4 if _var1=="CI_95"
replace order=5 if _var1=="Observations"
sort order
 drop order

export excel using "$rpath/Table_MainEquity.xls", replace


****************************
*Exchange Rate Results - TABLE 2
use "`temp1'", clear
replace _var3="("+_var9+")" if _var9~="" & _n~=1
keep _var1 _var2 _var3 _var4 _var10
keep if _var1=="variables" |  _var1=="officialrate" |  _var1=="dolarblue" |  _var1=="adrblue" |  _var1=="bcs" |  _var1=="ndf12m"
gen output_num=1
replace output_num=2 if _var1=="officialrate"
replace output_num=3 if _var1=="dolarblue"
replace output_num=4 if _var1=="adrblue"
replace output_num=5 if _var1=="bcs"
replace output_num=6 if _var1=="ndf12m"
sort output_num
drop output_num
foreach x of varlist _all {
	rename `x' v_`x'
	}
sxpose, clear 

gen order=1
replace order=2 if _var1=="cds2"
replace order=3 if _var1=="Robust_SE"
replace order=4 if _var1=="CI_95"
replace order=5 if _var1=="Observations"
sort order
 drop order
export excel using "$rpath/Table_FX.xls", replace

****************************
*Output Results
use "`temp1'", clear
replace _var3="("+_var9+")" if _var9~="" & _n~=1
keep _var1 _var2 _var3 _var4 _var10
keep if _var1=="variables" |  _var1=="gdp_dols" |  _var1=="gdp_var" | _var1=="gdp_con1y" |  _var1=="ip_dols" |  _var1=="ip_var" | _var1=="ip_con1y"
gen output_num=1
replace output_num=2 if _var1=="gdp_dols"
replace output_num=3 if _var1=="gdp_var"
replace output_num=4 if _var1=="gdp_con1y"
replace output_num=5 if _var1=="ip_dols"
replace output_num=6 if _var1=="ip_var"
replace output_num=7 if _var1=="ip_con1y"
sort output_num
drop output_num
foreach x of varlist _all {
	rename `x' v_`x'
	}
sxpose, clear 

gen order=1
replace order=2 if _var1=="cds2"
replace order=3 if _var1=="Robust_SE"
replace order=4 if _var1=="CI_95"
replace order=5 if _var1=="Observations"
sort order
 drop order
export excel using "$rpath/Table_GDP.xls", replace

****************************
*Deleverage results * Table 4
use "`temp1'", clear
replace _var3="("+_var9+")" if _var9~="" & _n~=1
keep _var1 _var2 _var3 _var4 _var10
keep if _var1=="variables" |  _var1=="valueindexdelev_us" |  _var1=="valuebankindexdelev_us" |  _var1=="valuenonfinindexdelev_us" 
gen output_num=1
replace output_num=2 if _var1=="valueindexdelev_us"
replace output_num=3 if _var1=="valuebankindexdelev_us"
replace output_num=4 if _var1=="valuenonfinindexdelev_us"
sort output_num
drop output_num
foreach x of varlist _all {
	rename `x' v_`x'
	}
sxpose, clear 

gen order=1
replace order=2 if _var1=="cds2"
replace order=3 if _var1=="Robust_SE"
replace order=4 if _var1=="CI_95"
replace order=5 if _var1=="Observations"
sort order
 drop order
export excel using "$rpath/Table_Delever.xls", replace

*************
*HML Results*
*************
use "`temp2'", clear
keep _var1 _var2 _var3 _var4 _var9 _var11
keep if _var1=="variables" |  _var1=="hml_es_industry_ar" |  _var1=="hml_import_intensity_ar" |  _var1=="hml_finvar_ar"  |  _var1=="hml_foreign_own_ar"  |  _var1=="eqindex_ar"
gen output_num=1
replace output_num=2 if _var1=="hml_es_industry_ar"
replace output_num=3 if _var1=="hml_import_intensity_ar"
replace output_num=4 if _var1=="hml_finvar_ar"
replace output_num=5 if _var1=="hml_foreign_own_ar"
replace output_num=6 if _var1=="eqindex_ar"

sort output_num
drop output_num
foreach x of varlist _all {
	rename `x' v_`x'
	}
sxpose, clear 

gen order=1
replace order=2 if _var1=="cds2"
replace order=3 if _var1=="Robust_SE"
replace order=4 if _var1=="CI_95"
replace order=5 if _var1=="Index_Beta"
replace order=6 if _var1=="Observations"
sort order
 drop order
export excel using "$rpath/Table_HML.xls", replace

******************
*Industry Results*
******************
use "`temp2'", clear
keep _var1 _var2 _var3 _var4 _var9 _var11
keep if _var1=="variables" |  _var1=="eqindex_ar" |  _var1=="banks_ar" |  _var1=="chems_ar" |  _var1=="diverse_ar" | _var1=="enrgy_ar" |  _var1=="manuf_ar" | _var1=="nodur_ar" |_var1=="nonfinancial_ar" |  _var1=="rlest_ar"  |  _var1=="telcm_ar"  |  _var1=="utils_ar"  
gen output_num=1
replace output_num=2 if _var1=="eqindex_ar"
replace output_num=3 if _var1=="banks_ar"
replace output_num=4 if _var1=="chems_ar"
replace output_num=5 if _var1=="diverse_ar"
replace output_num=6 if _var1=="enrgy_ar"
replace output_num=7 if _var1=="manuf_ar"
replace output_num=8 if _var1=="nodur_ar"
replace output_num=9 if _var1=="nonfinancial_ar"
replace output_num=10 if _var1=="rlest_ar"
replace output_num=11 if _var1=="telcm_ar"
replace output_num=12 if _var1=="utils_ar"

sort output_num
drop output_num
foreach x of varlist _all {
	rename `x' v_`x'
	}
sxpose, clear 

gen order=1
replace order=2 if _var1=="cds2"
replace order=3 if _var1=="Robust_SE"
replace order=4 if _var1=="CI_95"
replace order=5 if _var1=="Index_Beta"
replace order=6 if _var1=="Observations"

sort order
 drop order
export excel using "$rpath/Table_Industry.xls", replace

******************
*Other Countries**
******************
use "`temp3'", clear
split _var1, p("_")
keep if _var12=="dtri"
keep _var1 _var2
mmerge _var1 using "$mainpath/Markit/Other_CDS_labels.dta", umatch(code)
keep if _merge==3
drop _var1 _merge
order country _var2
export excel using "$rpath/Table_Other_CDS.xls", replace



