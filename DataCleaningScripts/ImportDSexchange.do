import excel "$dpath/JMS_ARS_BlueRate.xlsx", sheet("Argentina_FX_Import") firstrow clear
replace ARUSDSR="" if ARUSDSR=="NA"

label var ARSUSDS	"Blue Rate"
label var ARUSDSR	"RASL"
label var ARGPES	"WMR"
label var TDARSSP	"Thomson Reuters"
*rename Code date
gen bm_premium=ARSUSDS-TDARSSP
label var bm_premium "Black Market Premium"
gen bm_premium_pct=100*(ARSUSDS-TDARSSP)/TDARSSP
label var bm_premium_pct "Black Market Premium (Percent)"

tsset date
gen d_bm_premium=D.bm_premium
gen d_bm_premium_pct=D.bm_premium_pct
save "$apath/ARS_Blue.dta", replace
