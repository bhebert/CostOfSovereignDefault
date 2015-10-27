use "/Users/jesseschreger/Documents/CostOfSovereignDefault/Datasets/FirmTable.dta", clear
local foreign_own_cut 0
local es_industry_cut 0.1
local import_rev_cut .01
gen ind_import=0
replace ind_import=1 if import_rev>`import_rev_cut'>.01 & import_rev~=.
gen ind_export=0
replace ind_export=1 if es_industry>`es_industry_cut'>.01 & es_industry~=.
gen ind_foreign=0
replace ind_foreign=1 if foreign_own==1 & foreign_own~=.

tab ind_export ind_import
tab ind_export ind_foreign
tab ind_export ind_foreign


bysort foreign: tab ind_export ind_import if finvar==0

gen portfolio=.
local i=1
forvalues x=0/1 {
	forvalues y=0/1 {
		forvalues z=0/1 {
			display "`i'"
			replace portfolio=`i' if ind_foreign==`x' & ind_export==`y' & ind_import==`z'
			local i=`i'+1
			}
		}
}		

