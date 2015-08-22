
set more off

* Implement Lamont-2001 style tracking returns

local factors SPX hybonds oil soybean VIX emasia igbonds

use "$apath/monthly_controls.dta", clear

gen quarter = qofd(dofm(month))

collapse (sum) SPX VIX emasia hybonds igbonds oil soybean, by(quarter)

mmerge quarter using "$apath/dataset_temp.dta", unmatched(both)

sort quarter
tsset quarter

//use "$apath/dataset_temp.dta", clear

gen log_div4_real = log(div/us_cpi+L.div/L.us_cpi+L2.div/L2.us_cpi+L3.div/L3.us_cpi)

gen log_pd = log(px_last / us_cpi) - log_div4_real


su log_pd

local mean_pd = `r(mean)'

local rho_est = (exp(`mean_pd') / (exp(`mean_pd') + 1)) ^ (1/4)
disp "rho_est: `rho_est'"

local rho `rho_est'


gen log_rgdp = log(Real_GDP_cpi)

gen gdp_growth = (F12.log_rgdp - log_rgdp)


gen log_exrate = log(ADRBlue)

newey gdp_growth ret `factors' L.S4.log_rgdp L.log_pd if quarter > tq(2002,4), lag(4)

newey gdp_growth ret D.log_exrate `factors' L.S4.log_rgdp L.log_pd L.log_rer if quarter > tq(2002,4), lag(4)
