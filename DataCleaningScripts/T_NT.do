import excel "$tpath/SIC_ISIC.xlsx", sheet("Sheet1") firstrow clear
keep SIC ISIC1 ISIC2 ISIC3 ISIC4
gen ISIC=ISIC1
tostring ISIC, replace
replace ISIC="0"+ISIC if ISIC1<1000
replace ISIC=substr(ISIC,1,2)

save "$apath/SIC_ISIC.dta", replace


	
*********
*IO Tables.
import excel "$tpath/OECD IO.xls", sheet("OECD.Stat export") allstring clear
drop if _n<7
drop if _n==2
foreach x of varlist _all {
	if `x'[1]=="" {
		drop `x'
		}
		}
		
		local i=1
		foreach x of varlist _all {
		rename `x' v`i'
		local i=`i'+1
		}
		rename v1 column
		split column, p(" ")
		order column1
		rename column1 name
		gen varlabel=column2+" "+column3+" "+column4+" "+column5+" "+column6+" "+column7+" "+column8+" "+column9+" "+column10+" "+column11
		replace varlabel=trim(varlabel)
		drop if name=="Domestic" | name=="Non-comparable" | name=="VALU" | name=="INTI" | name=="GOPS" | name=="LABR" |  name=="Taxes," | name=="Data" | name=="OTXS"
		replace name="total_imports" if column=="Total Imports"
		replace name="total_intermediate" if column=="Total Intermediate consumption /final use at basic prices"
		replace name="total_production" if name=="PROD"
		drop column*
			forvalues i=2/38 {
			local temp=varlabel[`i']
			label var v`i' "`temp'"
			}
			
		forvalues i=2/38 {
		local temp=name[`i']
		rename v`i' `temp'
		}

		drop if _n==1
		rename v39 TIC
		rename v40 HHFC 
		rename v41 NPISH 
		rename v42 GGFC
		rename v43 GFGC
		rename v44 CHINV
		rename v45 VLBL
		rename v46 Exports
		rename v47 Imports
		drop v48
		label var TIC "Total Intermediate Consumption"
		label var HHFC "Households Final Consumption"
		label var NPISH "Non-Profit Institutions Serving Households"
		label var GGFC "General Government Final Consumption"
		label var GFGC "Gross Fixed Capital Formation"
		label var CHINV "Changes in Inventories"
		label var VLBL "Valuables"
		
		foreach x in  C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30 C31 C32 C33 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73 C74 C75 C80 C85 C90T93 C95 TIC HHFC NPISH GGFC GFGC CHINV VLBL Exports Imports {
			destring `x', replace force
			}
			drop varlabel
		save "$apath/OECD_IO_Temp.dta", replace	
		use "$apath/OECD_IO_Temp.dta", clear
		gen total_production=.
		order total_production
		local i=1
		foreach x in C01T05 C10T14 C15T16 C17T19 C20 C21T22 C23 C24 C25 C26 C27 C28 C29 C30 C31 C32 C33 C34 C35 C36T37 C40T41 C45 C50T52 C55 C60T63 C64 C65T67 C70 C71 C72 C73 C74 C75 C80 C85 C90T93 C95 {
			local temp=`x'[40]
			replace total_production=`temp' if _n==`i'
			local i=`i'+1
		}	
		
		gen export_share=Exports/total_production	
		keep name export_share Exports total
		drop if name=="total_imports" | name=="total_intermediate" | name=="total_production"
			save "$apath/Temp2.dta", replace	

		use "$apath/Temp2.dta", clear
		gen var=name
		order var
		replace var=subinstr(var,"C","",.)
		split var,p("T")
		drop var
		destring var1, replace
		destring var2, replace
		gen n=_n

		order var1
		reshape long var,i(name export_share) j(type)
		encode name, gen(range)
		tsset n var
		tsfill
		bysort n: carryforward export_share, replace
		rename var ISIC
		order ISIC export_share
		drop if ISIC==.
		keep ISIC export_share
		gen ISICnum=ISIC
		tostring ISIC, replace
		replace ISIC="0"+ISIC if ISICnum<10
		drop ISICnum
		rename export_share es_industry
		save "$apath/Temp3.dta", replace	

		
		mmerge ISIC using "$apath/SIC_ISIC.dta"
		keep ISIC SIC es_industry               
		save "$apath/es_industry.dta", replace
		
		
******************************
*INTERMEDIATE INPUT SHARE
*****************************
		import excel "$tpath/OECD IO Import.xlsx", sheet("Imports_by_Ind") firstrow clear
		split column, p(" ")
		order column1
		rename column1 name
		drop if _n>37
		keep name total_imports
		mmerge name using "$apath/Temp2.dta", ukeep(total_production)
		drop _merge
		gen import_intensity=total_imports/total_produ
		gen var=name
		order var
		replace var=subinstr(var,"C","",.)
		split var,p("T")
		drop var
		destring var1, replace
		destring var2, replace
		gen n=_n

		order var1
		reshape long var,i(name import) j(type)
		encode name, gen(range)
		tsset n var
		tsfill
		bysort n: carryforward import, replace
		rename var ISIC
		order ISIC import
		drop if ISIC==.
		keep ISIC import
		gen ISICnum=ISIC
		tostring ISIC, replace
		replace ISIC="0"+ISIC if ISICnum<10
		drop ISICnum
		mmerge ISIC using "$apath/SIC_ISIC.dta"
		keep ISIC SIC imp            
		save "$apath/im_industry.dta", replace
		
		
		
		
		use "$apath/DS_BB_Static.dta", clear
		gen SIC=sic_code_1
		destring SIC, replace force
		mmerge SIC using "$apath/es_industry.dta"
		drop if _merge==2
		gen es_direct=PCT_OF
		destring es_direct, force replace
		replace es_industry=es_industry
		mmerge SIC using "$apath/im_industry.dta"
		drop if _merge==2
		
		save "$apath/DS_BB_Static_v2.dta", replace
		
		use "$apath/DS_BB_Static_v2.dta", clear
		keep Ticker name isin_code es_industry im ISIC SIC
		order Ticker es_industry im
		save "$apath/es_im_industry_Ticker.dta", replace

		
		
