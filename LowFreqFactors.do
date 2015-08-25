set more off
tempfile temp fred_temp SPI_Temp 

global $lf_factors SPX VIX emasia oil soybean igbonds hybonds

*Load Fred
import excel "$miscdata/IP/Fred_Controls.xls", sheet("Daily") firstrow clear
save "`temp'.dta", replace

import excel "$miscdata/IP/Fred_Controls.xls", sheet("Daily,_Close") firstrow clear
mmerge DATE using "`temp'.dta"
browse if yofd(DATE)>=2002

rename BAMLEMRACRPIASIATRIV baml_emasia
rename BAMLEMCBPITRIV baml_em
rename BAMLCC0A1AAATRIV baml_usaaa
rename BAMLCC0A0CMTRIV baml_ig_uscorp
rename BAMLHYH0A3CMTRIV baml_hy_usccc
rename BAMLHYH0A0HYM2TRIV baml_hy_us

label var baml_ig_uscorp "BofA Merrill Lynch US Corp Master Total Return Index Value"
label var baml_usaaa "BofA Merrill Lynch US Corp AAA Total Return Index Value"
label var baml_em "BofA Merrill Lynch Emerging Markets Corporate Plus Index Total Return Index Value"
label var baml_hy_us "BofA Merrill Lynch US High Yield Master II Total Return Index Value"
label var baml_hy_usccc "BofA Merrill Lynch US High Yield CCC or Below Total Return Index Value"
label var baml_emasia "BofA Merrill Lynch Asia Emerging Markets Corporate Plus Sub-Index Total Return Index Value"

foreach x in baml_ig_uscorp baml_usaaa baml_em baml_hy_us baml_hy_usccc baml_emasia {
	replace `x'=. if `x'==0
	}
	rename DATE date 
	keep if yofd(date)>=1995
	keep date baml_ig_uscorp baml_hy_us
save "'fred_temp'.dta", replace


*Load SPI
import excel "$miscdata/IP/SP_IFC_EMAsia_Investable.xls", sheet("Edited") firstrow clear
keep date SPI*
rename SPIFCICompositetotalreturn spifc_total_return
rename SPIFCI spifc_price
keep date spifc_total_return
save "`SPI_temp'.dta", replace

* Load controls data
import excel "$miscdata/IP/Controls_GFD.xlsx", firstrow sheet("Price Data") clear
keep Date Ticker Close
gen date=date(Date,"MDY")
drop Date

gen month=mofd(date)

format date %td
format month %tm

drop if Ticker=="BRT_D" | Ticker=="__Sc1_ID" 
replace Ticker="oil" if Ticker=="__WTC_D"
replace Ticker="soybean" if Ticker=="__SYB_TD"
replace Ticker="hybonds" if Ticker=="__MRLHYD"
replace Ticker="VIX" if Ticker=="_VIXD"
replace Ticker="SPX" if Ticker=="_SPXTRD"
replace Ticker="igbonds" if Ticker=="TRUSACOM"
replace Ticker="emasia" if Ticker=="_IPDASD"
drop if Ticker=="igbonds" | Ticker=="hybonds"

reshape wide Close, i(date month) j(Ticker) str
renpfix Close
mmerge date using "`SPI_temp'.dta"
mmerge date using "'fred_temp'.dta"
rename baml_hy_us hybonds
rename baml_ig_uscorp igbonds

gen n=_n
gen first_date_temp=date if spifc_total_return~=. 
egen first_date2=min(first_date)
gen first_ind_temp=_n if date==first_date2
egen first_ind=max(first_ind_temp)
local start=first_ind[1]
local spifc_norm=spifc_total_ret[`start']
local emasia_norm=emasia[`start']
replace spifc_total_return=spifc_total_return/`spifc_norm'
replace emasia=emasia/`emasia_norm'
replace emasia=spifc_total_return if date>=date[`start']
drop first* spi* n _merge

save "`temp'.dta", replace

foreach x in SPX VIX emasia oil soybean igbonds hybonds {
	rename `x' Close`x'
	}
reshape long Close, i(date month) j(Ticker) str

save "$apath/daily_factors.dta", replace

use "`temp'.dta", clear
collapse (lastnm) SPX VIX emasia oil soybean igbonds hybonds, by(month)

tsset month
sort month
foreach var in SPX VIX emasia hybonds igbonds oil soybean {
gen `var'_n=100*(log(`var')-log(l.`var'))
replace `var'=`var'_n
drop `var'_n
}

save "$apath/monthly_controls.dta", replace
