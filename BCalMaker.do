
clear

set obs 2

gen date = mdy(1,1,1995)
format date %td

replace date = mdy(8,1,2015) if _n == 2

tsset date
tsfill

gen dow=dow(date)
drop if dow==0 | dow==6

bcal create basic, from(date) replace
