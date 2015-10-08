use "$mainpath/Slides/Figures/June16/June16.dta", clear
mmerge clocktime using  "/Users/jesseschreger/Dropbox/Cost of Sovereign Default/Slides/Figures/June16/DefProbJune16.dta"
replace def=def*100
discard
twoway (scatter def clocktime if type=="Markit_ARS_CDS", mlabel("snaptime")) (line MXAR_dpx clocktime, lpattern(dash) yaxis(2))  if clocktime>=9.5 & clocktime<=11.75, legend(order(1 "Probability of Default" 2 "MSCI Argentina Index"))  ytitle("Probability of Default (Percent)") ytitle("Equity Log Return Since Close (Percent)", axis(2))  name("defprob") xlabel( 9.5 "9:30 am" 10.5 "10:30 am" 11.5 "11:30 am") xtitle("") graphregion(fcolor(white) lcolor(white))
graph export "$mainpath/ResultsforSlides/June16newfig.eps", as(eps) preview(off) replace
