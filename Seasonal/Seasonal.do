 use "$apath/GDP_inflation.dta", clear
  order quarter   Nominal_GDP Nominal_GDP_GFD Nominal_GDP_GFD_change Nominal_GDP_change Real_GDP Real_GDP_change cpi 
  keep quarter   Nominal_GDP Nominal_GDP_GFD Nominal_GDP_GFD_change Nominal_GDP_change Real_GDP Real_GDP_change 
  replace Nominal_GDP_GFD=. if quarter<=tq(1992q3)
  drop if quarter<=tq(1989q4)
  export excel using "/Users/jesseschreger/Documents/CostOfSovereignDefault/Seasonal/Seasonal.xls", firstrow(variables) replace
  export delimited using "/Users/jesseschreger/Documents/CostOfSovereignDefault/Seasonal/Seasonal.csv", replace

  
  *DATA BACK FROM HBS RESEARCH SERVICES
  import excel "/Users/jesseschreger/Documents/CostOfSovereignDefault/Seasonal/Seasonal_20150821.xlsx", sheet("Sheet2") firstrow clear
	foreach x in Nominal_GDP Nominal_GDP_GFD Nominal_GDP_GFD_Change Nominal_GDP_Change Real_GDP Real_GDP_Change {
		rename `x' `x'_NSA
	}	
	
	foreach x in Nominal_GDP Nominal_GDP_GFD Real_GDP {
		rename `x'_D11 `x'_SA
		}
		
	drop Nominal_GDP_GFD_Change_NSA Nominal_GDP_Change_NSA Real_GDP_Change_NSA
	save "/Users/jesseschreger/Documents/CostOfSovereignDefault/Seasonal/Seasonally_Adjusted_GDP.dta", replace
