use "$apath/Default_Prob_All.dta", clear
mmerge date using"$mpath/Default_Prob.dta", uname(old_)
corr def5y old_comp
corr def5y_europe old_europe_def5y
summ def5y old_comp
summ def5y_eu old_eu
browse if def5y~=old_com
order date def5y old_com
browse if def5y~=old_com
browse if def5y_eur~=old_e
