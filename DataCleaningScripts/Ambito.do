*Clean Contado con Liqui from Ambito
import excel "$miscdata/Ambito/Contado.xlsx", sheet("Sheet1") firstrow clear
gen date=date(Date,"DMY")
format date %td
order date 
drop Date Value
gen Ticker="Contado_Ambito"
rename px_last px_close
gen total_return=px_close
gen px_open=.
save "$apath/Contado.dta", replace
