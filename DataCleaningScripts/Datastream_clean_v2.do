set more off

*FIX ISIN MISMATCH IN 
use "$bbpath/BB_Static_0304.dta", clear
replace ID_ISIN ="ARTGNO010117" if ID_ISIN=="ARP930811186"
save  "$apath/BB_Static_0304.dta", replace

************************
*Static Characteristics*
************************
import excel "$dpath/Datastream_Static_0302.xlsx",  sheet("Static") clear
replace F="Industry_group_num" if F=="INDUSTRY GROUP"
foreach x of varlist _all {
	replace `x'=subinstr(`x'," ","_",.) if _n==1
	replace `x'=subinstr(`x',".","",.) if _n==1
	replace `x'=lower(`x') if _n==1
	replace `x'=subinstr(`x'," - ","_",.) if _n==1
    replace `x'=subinstr(`x',"-","_",.) if _n==1
    replace `x'=subinstr(`x',"__","_",.) if _n==1
    replace `x'=subinstr(`x',"__","_",.) if _n==1
}	
	
foreach x of varlist _all {
cap {
		local temp=`x'[1]
		rename `x' `temp'
}		
}

drop if _n==1
split type, p(":")
rename type2 Ticker
order Ticker
drop type1		
save "$apath/Datastr_Static_Chars_v2.dta", replace


*MERGE BB STATIC with Datastream Static
use "$apath/Datastr_Static_Chars_v2.dta", clear
mmerge isin_code using "$bbpath/BB_Static_0304.dta", umatch(ID_ISIN)
keep if _merge==3

save "$apath/DS_BB_Static.dta", replace





	
	
	
