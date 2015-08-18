use "$apath/NDF_Datastream.dta", clear
append using  "$apath/blue_rate.dta"
append using "$apath/dolarblue.dta"
append using "$apath/bcs.dta"
*append using "$apath/ADRBluedb_merge.dta" This is the Bloomberg data where the closes are reliable.
append using "$apath/adrdb_altdata.dta"
append using  "$apath/adrdb_merge.dta"
keep date Ticker px_close
rename px px
reshape wide px, i(date) j(Ticker) str
renpfix px

summ ADRBa BCS NDF12M NDF6M dolarblue adrdb


keep date  ADRBaltdata ADRBlue BCS NDF* Official* dolar adrdb

gen bdate = bofd("basic",date)
format bdate %tbbasic
tsset bdate
sort bdate 

foreach x in ADRBaltdata ADRBlue adrdb BCS NDF12M NDF1M NDF2M NDF3M NDF6M OfficialRate dolarblue  { 
	gen d_`x'=100*(log(`x')-log(l.`x'))
	gen d2_`x'=100*(log(`x')-log(l2.`x'))
}	

corr ADRBaltdata adrdb BCS dolarblue NDF12M 
corr d_ADRBaltdata d_adrdb d_BCS d_dolarblue d_NDF12M d_OfficialRate 
corr d2_ADRBaltdata d2_adrdb d2_BCS d2_dolarblue d2_NDF12M d2_OfficialRate

corr  ADRBaltdata adrdb
corr  d_ADRBaltdata d_adrdb
corr  d2_ADRBaltdata d2_adrdb

twoway (line ADRBaltdata date, sort) (line adrdb date, sort) if ADRBaltdata~=. & yofd(date)>=2011
twoway (line d_ADRBaltdata date, sort) (line d_adrdb date, sort) if ADRBaltdata~=. & yofd(date)>=2011 & date<=td(31jul2014)


scatter d2_dol d2_Of if d2_dol~=. & d2_Of~=.
scatter d2_NDF12 d2_Of if d2_NDF12~=. & d2_Of~=.

twoway (line BCS date, sort)  (line ADRBaltdata date, sort) (line dolarblue date, sort) (line NDF12 date, sort) (line Official date, sort) if yofd(date)>=2011 & date<=td(31jul2014), ylabel(0(3)16)  legend(order(1 "Blue Chip Swap" 2 "ADR Blue Rate" 3 "Dolar Blue" 4 "12 Month NDF" 5 "Official")) xtitle("") graphregion(fcolor(white) lcolor(white))          
graph export "$rpath/Exchange_Rate_Compare_Paper.png", replace
