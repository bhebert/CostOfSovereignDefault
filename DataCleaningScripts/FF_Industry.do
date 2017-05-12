*FAMA FRENCH INDUSTRY

*NAMES
import excel "$csd_data/FF/siccodes49.xlsx", sheet("siccodes49.csv") firstrow clear
collapse (firstnm) FFCODE FFDESC, by(FFNUM)
rename FFNUM FFNUM49
rename FFCODE FFCODE49 
rename FFDESC FFDESC49
save "$apath/FF49_names.dta", replace


import excel "$csd_data/FF/siccodes12.xlsx", sheet("siccodes12.csv") firstrow clear
collapse (firstnm) FFCODE FFDESC, by(FFNUM)
rename FFNUM FFNUM12
rename FFCODE FFCODE12
rename FFDESC FFDESC12
save "$apath/FF12_names.dta", replace

import excel "$csd_data/FF/siccodes5.xlsx", sheet("siccodes5.csv") firstrow clear
collapse (firstnm) FFCODE FFDESC, by(FFNUM)
rename FFNUM FFNUM5
rename FFCODE FFCODE5
rename FFDESC FFDESC5
save "$apath/FF5_names.dta", replace


use "$apath/DS_BB_Static_v2.dta", clear
rename sic_code_1 sic1
rename sic_code_2 sic2
rename sic_code_3 sic3
rename sic_code_4 sic4

destring sic1, replace force
destring sic2, replace force
destring sic3, replace force
destring sic4, replace force
drop if sic1==.


gen FFNUM=.
replace FFNUM=1 if sic1>= 100 & sic1<= 999
replace FFNUM=1 if sic1>= 2000 & sic1<= 2399
replace FFNUM=1 if sic1>= 2700 & sic1<= 2749
replace FFNUM=1 if sic1>= 2770 & sic1<= 2799
replace FFNUM=1 if sic1>= 3100 & sic1<= 3199
replace FFNUM=1 if sic1>= 3940 & sic1<= 3989
replace FFNUM=2 if sic1>= 2500 & sic1<= 2519
replace FFNUM=2 if sic1>= 2590 & sic1<= 2599
replace FFNUM=2 if sic1>= 3630 & sic1<= 3659
replace FFNUM=2 if sic1>= 3710 & sic1<= 3711
replace FFNUM=2 if sic1>= 3714 & sic1<= 3714
replace FFNUM=2 if sic1>= 3716 & sic1<= 3716
replace FFNUM=2 if sic1>= 3750 & sic1<= 3751
replace FFNUM=2 if sic1>= 3792 & sic1<= 3792
replace FFNUM=2 if sic1>= 3900 & sic1<= 3939
replace FFNUM=2 if sic1>= 3990 & sic1<= 3999
replace FFNUM=3 if sic1>= 2520 & sic1<= 2589
replace FFNUM=3 if sic1>= 2600 & sic1<= 2699
replace FFNUM=3 if sic1>= 2750 & sic1<= 2769
replace FFNUM=3 if sic1>= 3000 & sic1<= 3099
replace FFNUM=3 if sic1>= 3200 & sic1<= 3569
replace FFNUM=3 if sic1>= 3580 & sic1<= 3629
replace FFNUM=3 if sic1>= 3700 & sic1<= 3709
replace FFNUM=3 if sic1>= 3712 & sic1<= 3713
replace FFNUM=3 if sic1>= 3715 & sic1<= 3715
replace FFNUM=3 if sic1>= 3717 & sic1<= 3749
replace FFNUM=3 if sic1>= 3752 & sic1<= 3791
replace FFNUM=3 if sic1>= 3793 & sic1<= 3799
replace FFNUM=3 if sic1>= 3830 & sic1<= 3839
replace FFNUM=3 if sic1>= 3860 & sic1<= 3899
replace FFNUM=4 if sic1>= 1200 & sic1<= 1399
replace FFNUM=4 if sic1>= 2900 & sic1<= 2999
replace FFNUM=5 if sic1>= 2800 & sic1<= 2829
replace FFNUM=5 if sic1>= 2840 & sic1<= 2899
replace FFNUM=6 if sic1>= 3570 & sic1<= 3579
replace FFNUM=6 if sic1>= 3660 & sic1<= 3692
replace FFNUM=6 if sic1>= 3694 & sic1<= 3699
replace FFNUM=6 if sic1>= 3810 & sic1<= 3829
replace FFNUM=6 if sic1>= 7370 & sic1<= 7379
replace FFNUM=7 if sic1>= 4800 & sic1<= 4899
replace FFNUM=8 if sic1>= 4900 & sic1<= 4949
replace FFNUM=9 if sic1>= 5000 & sic1<= 5999
replace FFNUM=9 if sic1>= 7200 & sic1<= 7299
replace FFNUM=9 if sic1>= 7600 & sic1<= 7699
replace FFNUM=10 if sic1>= 2830 & sic1<= 2839
replace FFNUM=10 if sic1>= 3693 & sic1<= 3693
replace FFNUM=10 if sic1>= 3840 & sic1<= 3859
replace FFNUM=10 if sic1>= 8000 & sic1<= 8099
replace FFNUM=11 if sic1>= 6000 & sic1<= 6999
replace FFNUM=12 if FFNUM==.
rename FFNUM FFNUM12


mmerge FFNUM12 using "$apath/FF12_names.dta"
keep if _merge==3
keep name Ticker FF*
save "$apath/FamaFrench12.dta", replace




***************************
***************************
*FF 49
***************************
***************************
use "$apath/DS_BB_Static_v2.dta", clear
rename sic_code_1 sic1
rename sic_code_2 sic2
rename sic_code_3 sic3
rename sic_code_4 sic4

destring sic1, replace force
destring sic2, replace force
destring sic3, replace force
destring sic4, replace force
drop if sic1==.

gen FFNUM=.
replace FFNUM=1 if sic1>= 100 & sic1<= 199
replace FFNUM=1 if sic1>= 200 & sic1<= 299
replace FFNUM=1 if sic1>= 700 & sic1<= 799
replace FFNUM=1 if sic1>= 910 & sic1<= 919
replace FFNUM=1 if sic1>= 2048 & sic1<= 2048
replace FFNUM=2 if sic1>= 2000 & sic1<= 2009
replace FFNUM=2 if sic1>= 2010 & sic1<= 2019
replace FFNUM=2 if sic1>= 2020 & sic1<= 2029
replace FFNUM=2 if sic1>= 2030 & sic1<= 2039
replace FFNUM=2 if sic1>= 2040 & sic1<= 2046
replace FFNUM=2 if sic1>= 2050 & sic1<= 2059
replace FFNUM=2 if sic1>= 2060 & sic1<= 2063
replace FFNUM=2 if sic1>= 2070 & sic1<= 2079
replace FFNUM=2 if sic1>= 2090 & sic1<= 2092
replace FFNUM=2 if sic1>= 2095 & sic1<= 2095
replace FFNUM=2 if sic1>= 2098 & sic1<= 2099
replace FFNUM=3 if sic1>= 2064 & sic1<= 2068
replace FFNUM=3 if sic1>= 2086 & sic1<= 2086
replace FFNUM=3 if sic1>= 2087 & sic1<= 2087
replace FFNUM=3 if sic1>= 2096 & sic1<= 2096
replace FFNUM=3 if sic1>= 2097 & sic1<= 2097
replace FFNUM=4 if sic1>= 2080 & sic1<= 2080
replace FFNUM=4 if sic1>= 2082 & sic1<= 2082
replace FFNUM=4 if sic1>= 2083 & sic1<= 2083
replace FFNUM=4 if sic1>= 2084 & sic1<= 2084
replace FFNUM=4 if sic1>= 2085 & sic1<= 2085
replace FFNUM=5 if sic1>= 2100 & sic1<= 2199
replace FFNUM=6 if sic1>= 920 & sic1<= 999
replace FFNUM=6 if sic1>= 3650 & sic1<= 3651
replace FFNUM=6 if sic1>= 3652 & sic1<= 3652
replace FFNUM=6 if sic1>= 3732 & sic1<= 3732
replace FFNUM=6 if sic1>= 3930 & sic1<= 3931
replace FFNUM=6 if sic1>= 3940 & sic1<= 3949
replace FFNUM=7 if sic1>= 7800 & sic1<= 7829
replace FFNUM=7 if sic1>= 7830 & sic1<= 7833
replace FFNUM=7 if sic1>= 7840 & sic1<= 7841
replace FFNUM=7 if sic1>= 7900 & sic1<= 7900
replace FFNUM=7 if sic1>= 7910 & sic1<= 7911
replace FFNUM=7 if sic1>= 7920 & sic1<= 7929
replace FFNUM=7 if sic1>= 7930 & sic1<= 7933
replace FFNUM=7 if sic1>= 7940 & sic1<= 7949
replace FFNUM=7 if sic1>= 7980 & sic1<= 7980
replace FFNUM=7 if sic1>= 7990 & sic1<= 7999
replace FFNUM=8 if sic1>= 2700 & sic1<= 2709
replace FFNUM=8 if sic1>= 2710 & sic1<= 2719
replace FFNUM=8 if sic1>= 2720 & sic1<= 2729
replace FFNUM=8 if sic1>= 2730 & sic1<= 2739
replace FFNUM=8 if sic1>= 2740 & sic1<= 2749
replace FFNUM=8 if sic1>= 2770 & sic1<= 2771
replace FFNUM=8 if sic1>= 2780 & sic1<= 2789
replace FFNUM=8 if sic1>= 2790 & sic1<= 2799
replace FFNUM=9 if sic1>= 2047 & sic1<= 2047
replace FFNUM=9 if sic1>= 2391 & sic1<= 2392
replace FFNUM=9 if sic1>= 2510 & sic1<= 2519
replace FFNUM=9 if sic1>= 2590 & sic1<= 2599
replace FFNUM=9 if sic1>= 2840 & sic1<= 2843
replace FFNUM=9 if sic1>= 2844 & sic1<= 2844
replace FFNUM=9 if sic1>= 3160 & sic1<= 3161
replace FFNUM=9 if sic1>= 3170 & sic1<= 3171
replace FFNUM=9 if sic1>= 3172 & sic1<= 3172
replace FFNUM=9 if sic1>= 3190 & sic1<= 3199
replace FFNUM=9 if sic1>= 3229 & sic1<= 3229
replace FFNUM=9 if sic1>= 3260 & sic1<= 3260
replace FFNUM=9 if sic1>= 3262 & sic1<= 3263
replace FFNUM=9 if sic1>= 3269 & sic1<= 3269
replace FFNUM=9 if sic1>= 3230 & sic1<= 3231
replace FFNUM=9 if sic1>= 3630 & sic1<= 3639
replace FFNUM=9 if sic1>= 3750 & sic1<= 3751
replace FFNUM=9 if sic1>= 3800 & sic1<= 3800
replace FFNUM=9 if sic1>= 3860 & sic1<= 3861
replace FFNUM=9 if sic1>= 3870 & sic1<= 3873
replace FFNUM=9 if sic1>= 3910 & sic1<= 3911
replace FFNUM=9 if sic1>= 3914 & sic1<= 3914
replace FFNUM=9 if sic1>= 3915 & sic1<= 3915
replace FFNUM=9 if sic1>= 3960 & sic1<= 3962
replace FFNUM=9 if sic1>= 3991 & sic1<= 3991
replace FFNUM=9 if sic1>= 3995 & sic1<= 3995
replace FFNUM=10 if sic1>= 2300 & sic1<= 2390
replace FFNUM=10 if sic1>= 3020 & sic1<= 3021
replace FFNUM=10 if sic1>= 3100 & sic1<= 3111
replace FFNUM=10 if sic1>= 3130 & sic1<= 3131
replace FFNUM=10 if sic1>= 3140 & sic1<= 3149
replace FFNUM=10 if sic1>= 3150 & sic1<= 3151
replace FFNUM=10 if sic1>= 3963 & sic1<= 3965
replace FFNUM=11 if sic1>= 8000 & sic1<= 8099
replace FFNUM=12 if sic1>= 3693 & sic1<= 3693
replace FFNUM=12 if sic1>= 3840 & sic1<= 3849
replace FFNUM=12 if sic1>= 3850 & sic1<= 3851
replace FFNUM=13 if sic1>= 2830 & sic1<= 2830
replace FFNUM=13 if sic1>= 2831 & sic1<= 2831
replace FFNUM=13 if sic1>= 2833 & sic1<= 2833
replace FFNUM=13 if sic1>= 2834 & sic1<= 2834
replace FFNUM=13 if sic1>= 2835 & sic1<= 2835
replace FFNUM=13 if sic1>= 2836 & sic1<= 2836
replace FFNUM=14 if sic1>= 2800 & sic1<= 2809
replace FFNUM=14 if sic1>= 2810 & sic1<= 2819
replace FFNUM=14 if sic1>= 2820 & sic1<= 2829
replace FFNUM=14 if sic1>= 2850 & sic1<= 2859
replace FFNUM=14 if sic1>= 2860 & sic1<= 2869
replace FFNUM=14 if sic1>= 2870 & sic1<= 2879
replace FFNUM=14 if sic1>= 2890 & sic1<= 2899
replace FFNUM=15 if sic1>= 3031 & sic1<= 3031
replace FFNUM=15 if sic1>= 3041 & sic1<= 3041
replace FFNUM=15 if sic1>= 3050 & sic1<= 3053
replace FFNUM=15 if sic1>= 3060 & sic1<= 3069
replace FFNUM=15 if sic1>= 3070 & sic1<= 3079
replace FFNUM=15 if sic1>= 3080 & sic1<= 3089
replace FFNUM=15 if sic1>= 3090 & sic1<= 3099
replace FFNUM=16 if sic1>= 2200 & sic1<= 2269
replace FFNUM=16 if sic1>= 2270 & sic1<= 2279
replace FFNUM=16 if sic1>= 2280 & sic1<= 2284
replace FFNUM=16 if sic1>= 2290 & sic1<= 2295
replace FFNUM=16 if sic1>= 2297 & sic1<= 2297
replace FFNUM=16 if sic1>= 2298 & sic1<= 2298
replace FFNUM=16 if sic1>= 2299 & sic1<= 2299
replace FFNUM=16 if sic1>= 2393 & sic1<= 2395
replace FFNUM=16 if sic1>= 2397 & sic1<= 2399
replace FFNUM=17 if sic1>= 800 & sic1<= 899
replace FFNUM=17 if sic1>= 2400 & sic1<= 2439
replace FFNUM=17 if sic1>= 2450 & sic1<= 2459
replace FFNUM=17 if sic1>= 2490 & sic1<= 2499
replace FFNUM=17 if sic1>= 2660 & sic1<= 2661
replace FFNUM=17 if sic1>= 2950 & sic1<= 2952
replace FFNUM=17 if sic1>= 3200 & sic1<= 3200
replace FFNUM=17 if sic1>= 3210 & sic1<= 3211
replace FFNUM=17 if sic1>= 3240 & sic1<= 3241
replace FFNUM=17 if sic1>= 3250 & sic1<= 3259
replace FFNUM=17 if sic1>= 3261 & sic1<= 3261
replace FFNUM=17 if sic1>= 3264 & sic1<= 3264
replace FFNUM=17 if sic1>= 3270 & sic1<= 3275
replace FFNUM=17 if sic1>= 3280 & sic1<= 3281
replace FFNUM=17 if sic1>= 3290 & sic1<= 3293
replace FFNUM=17 if sic1>= 3295 & sic1<= 3299
replace FFNUM=17 if sic1>= 3420 & sic1<= 3429
replace FFNUM=17 if sic1>= 3430 & sic1<= 3433
replace FFNUM=17 if sic1>= 3440 & sic1<= 3441
replace FFNUM=17 if sic1>= 3442 & sic1<= 3442
replace FFNUM=17 if sic1>= 3446 & sic1<= 3446
replace FFNUM=17 if sic1>= 3448 & sic1<= 3448
replace FFNUM=17 if sic1>= 3449 & sic1<= 3449
replace FFNUM=17 if sic1>= 3450 & sic1<= 3451
replace FFNUM=17 if sic1>= 3452 & sic1<= 3452
replace FFNUM=17 if sic1>= 3490 & sic1<= 3499
replace FFNUM=17 if sic1>= 3996 & sic1<= 3996
replace FFNUM=18 if sic1>= 1500 & sic1<= 1511
replace FFNUM=18 if sic1>= 1520 & sic1<= 1529
replace FFNUM=18 if sic1>= 1530 & sic1<= 1539
replace FFNUM=18 if sic1>= 1540 & sic1<= 1549
replace FFNUM=18 if sic1>= 1600 & sic1<= 1699
replace FFNUM=18 if sic1>= 1700 & sic1<= 1799
replace FFNUM=19 if sic1>= 3300 & sic1<= 3300
replace FFNUM=19 if sic1>= 3310 & sic1<= 3317
replace FFNUM=19 if sic1>= 3320 & sic1<= 3325
replace FFNUM=19 if sic1>= 3330 & sic1<= 3339
replace FFNUM=19 if sic1>= 3340 & sic1<= 3341
replace FFNUM=19 if sic1>= 3350 & sic1<= 3357
replace FFNUM=19 if sic1>= 3360 & sic1<= 3369
replace FFNUM=19 if sic1>= 3370 & sic1<= 3379
replace FFNUM=19 if sic1>= 3390 & sic1<= 3399
replace FFNUM=20 if sic1>= 3400 & sic1<= 3400
replace FFNUM=20 if sic1>= 3443 & sic1<= 3443
replace FFNUM=20 if sic1>= 3444 & sic1<= 3444
replace FFNUM=20 if sic1>= 3460 & sic1<= 3469
replace FFNUM=20 if sic1>= 3470 & sic1<= 3479
replace FFNUM=21 if sic1>= 3510 & sic1<= 3519
replace FFNUM=21 if sic1>= 3520 & sic1<= 3529
replace FFNUM=21 if sic1>= 3530 & sic1<= 3530
replace FFNUM=21 if sic1>= 3531 & sic1<= 3531
replace FFNUM=21 if sic1>= 3532 & sic1<= 3532
replace FFNUM=21 if sic1>= 3533 & sic1<= 3533
replace FFNUM=21 if sic1>= 3534 & sic1<= 3534
replace FFNUM=21 if sic1>= 3535 & sic1<= 3535
replace FFNUM=21 if sic1>= 3536 & sic1<= 3536
replace FFNUM=21 if sic1>= 3538 & sic1<= 3538
replace FFNUM=21 if sic1>= 3540 & sic1<= 3549
replace FFNUM=21 if sic1>= 3550 & sic1<= 3559
replace FFNUM=21 if sic1>= 3560 & sic1<= 3569
replace FFNUM=21 if sic1>= 3580 & sic1<= 3580
replace FFNUM=21 if sic1>= 3581 & sic1<= 3581
replace FFNUM=21 if sic1>= 3582 & sic1<= 3582
replace FFNUM=21 if sic1>= 3585 & sic1<= 3585
replace FFNUM=21 if sic1>= 3586 & sic1<= 3586
replace FFNUM=21 if sic1>= 3589 & sic1<= 3589
replace FFNUM=21 if sic1>= 3590 & sic1<= 3599
replace FFNUM=22 if sic1>= 3600 & sic1<= 3600
replace FFNUM=22 if sic1>= 3610 & sic1<= 3613
replace FFNUM=22 if sic1>= 3620 & sic1<= 3621
replace FFNUM=22 if sic1>= 3623 & sic1<= 3629
replace FFNUM=22 if sic1>= 3640 & sic1<= 3644
replace FFNUM=22 if sic1>= 3645 & sic1<= 3645
replace FFNUM=22 if sic1>= 3646 & sic1<= 3646
replace FFNUM=22 if sic1>= 3648 & sic1<= 3649
replace FFNUM=22 if sic1>= 3660 & sic1<= 3660
replace FFNUM=22 if sic1>= 3690 & sic1<= 3690
replace FFNUM=22 if sic1>= 3691 & sic1<= 3692
replace FFNUM=22 if sic1>= 3699 & sic1<= 3699
replace FFNUM=23 if sic1>= 2296 & sic1<= 2296
replace FFNUM=23 if sic1>= 2396 & sic1<= 2396
replace FFNUM=23 if sic1>= 3010 & sic1<= 3011
replace FFNUM=23 if sic1>= 3537 & sic1<= 3537
replace FFNUM=23 if sic1>= 3647 & sic1<= 3647
replace FFNUM=23 if sic1>= 3694 & sic1<= 3694
replace FFNUM=23 if sic1>= 3700 & sic1<= 3700
replace FFNUM=23 if sic1>= 3710 & sic1<= 3710
replace FFNUM=23 if sic1>= 3711 & sic1<= 3711
replace FFNUM=23 if sic1>= 3713 & sic1<= 3713
replace FFNUM=23 if sic1>= 3714 & sic1<= 3714
replace FFNUM=23 if sic1>= 3715 & sic1<= 3715
replace FFNUM=23 if sic1>= 3716 & sic1<= 3716
replace FFNUM=23 if sic1>= 3792 & sic1<= 3792
replace FFNUM=23 if sic1>= 3790 & sic1<= 3791
replace FFNUM=23 if sic1>= 3799 & sic1<= 3799
replace FFNUM=24 if sic1>= 3720 & sic1<= 3720
replace FFNUM=24 if sic1>= 3721 & sic1<= 3721
replace FFNUM=24 if sic1>= 3723 & sic1<= 3724
replace FFNUM=24 if sic1>= 3725 & sic1<= 3725
replace FFNUM=24 if sic1>= 3728 & sic1<= 3729
replace FFNUM=25 if sic1>= 3730 & sic1<= 3731
replace FFNUM=25 if sic1>= 3740 & sic1<= 3743
replace FFNUM=26 if sic1>= 3760 & sic1<= 3769
replace FFNUM=26 if sic1>= 3795 & sic1<= 3795
replace FFNUM=26 if sic1>= 3480 & sic1<= 3489
replace FFNUM=27 if sic1>= 1040 & sic1<= 1049
replace FFNUM=28 if sic1>= 1000 & sic1<= 1009
replace FFNUM=28 if sic1>= 1010 & sic1<= 1019
replace FFNUM=28 if sic1>= 1020 & sic1<= 1029
replace FFNUM=28 if sic1>= 1030 & sic1<= 1039
replace FFNUM=28 if sic1>= 1050 & sic1<= 1059
replace FFNUM=28 if sic1>= 1060 & sic1<= 1069
replace FFNUM=28 if sic1>= 1070 & sic1<= 1079
replace FFNUM=28 if sic1>= 1080 & sic1<= 1089
replace FFNUM=28 if sic1>= 1090 & sic1<= 1099
replace FFNUM=28 if sic1>= 1100 & sic1<= 1119
replace FFNUM=28 if sic1>= 1400 & sic1<= 1499
replace FFNUM=29 if sic1>= 1200 & sic1<= 1299
replace FFNUM=30 if sic1>= 1300 & sic1<= 1300
replace FFNUM=30 if sic1>= 1310 & sic1<= 1319
replace FFNUM=30 if sic1>= 1320 & sic1<= 1329
replace FFNUM=30 if sic1>= 1330 & sic1<= 1339
replace FFNUM=30 if sic1>= 1370 & sic1<= 1379
replace FFNUM=30 if sic1>= 1380 & sic1<= 1380
replace FFNUM=30 if sic1>= 1381 & sic1<= 1381
replace FFNUM=30 if sic1>= 1382 & sic1<= 1382
replace FFNUM=30 if sic1>= 1389 & sic1<= 1389
replace FFNUM=30 if sic1>= 2900 & sic1<= 2912
replace FFNUM=30 if sic1>= 2990 & sic1<= 2999
replace FFNUM=31 if sic1>= 4900 & sic1<= 4900
replace FFNUM=31 if sic1>= 4910 & sic1<= 4911
replace FFNUM=31 if sic1>= 4920 & sic1<= 4922
replace FFNUM=31 if sic1>= 4923 & sic1<= 4923
replace FFNUM=31 if sic1>= 4924 & sic1<= 4925
replace FFNUM=31 if sic1>= 4930 & sic1<= 4931
replace FFNUM=31 if sic1>= 4932 & sic1<= 4932
replace FFNUM=31 if sic1>= 4939 & sic1<= 4939
replace FFNUM=31 if sic1>= 4940 & sic1<= 4942
replace FFNUM=32 if sic1>= 4800 & sic1<= 4800
replace FFNUM=32 if sic1>= 4810 & sic1<= 4813
replace FFNUM=32 if sic1>= 4820 & sic1<= 4822
replace FFNUM=32 if sic1>= 4830 & sic1<= 4839
replace FFNUM=32 if sic1>= 4840 & sic1<= 4841
replace FFNUM=32 if sic1>= 4880 & sic1<= 4889
replace FFNUM=32 if sic1>= 4890 & sic1<= 4890
replace FFNUM=32 if sic1>= 4891 & sic1<= 4891
replace FFNUM=32 if sic1>= 4892 & sic1<= 4892
replace FFNUM=32 if sic1>= 4899 & sic1<= 4899
replace FFNUM=33 if sic1>= 7020 & sic1<= 7021
replace FFNUM=33 if sic1>= 7030 & sic1<= 7033
replace FFNUM=33 if sic1>= 7200 & sic1<= 7200
replace FFNUM=33 if sic1>= 7210 & sic1<= 7212
replace FFNUM=33 if sic1>= 7214 & sic1<= 7214
replace FFNUM=33 if sic1>= 7215 & sic1<= 7216
replace FFNUM=33 if sic1>= 7217 & sic1<= 7217
replace FFNUM=33 if sic1>= 7219 & sic1<= 7219
replace FFNUM=33 if sic1>= 7220 & sic1<= 7221
replace FFNUM=33 if sic1>= 7230 & sic1<= 7231
replace FFNUM=33 if sic1>= 7240 & sic1<= 7241
replace FFNUM=33 if sic1>= 7250 & sic1<= 7251
replace FFNUM=33 if sic1>= 7260 & sic1<= 7269
replace FFNUM=33 if sic1>= 7270 & sic1<= 7290
replace FFNUM=33 if sic1>= 7291 & sic1<= 7291
replace FFNUM=33 if sic1>= 7292 & sic1<= 7299
replace FFNUM=33 if sic1>= 7395 & sic1<= 7395
replace FFNUM=33 if sic1>= 7500 & sic1<= 7500
replace FFNUM=33 if sic1>= 7520 & sic1<= 7529
replace FFNUM=33 if sic1>= 7530 & sic1<= 7539
replace FFNUM=33 if sic1>= 7540 & sic1<= 7549
replace FFNUM=33 if sic1>= 7600 & sic1<= 7600
replace FFNUM=33 if sic1>= 7620 & sic1<= 7620
replace FFNUM=33 if sic1>= 7622 & sic1<= 7622
replace FFNUM=33 if sic1>= 7623 & sic1<= 7623
replace FFNUM=33 if sic1>= 7629 & sic1<= 7629
replace FFNUM=33 if sic1>= 7630 & sic1<= 7631
replace FFNUM=33 if sic1>= 7640 & sic1<= 7641
replace FFNUM=33 if sic1>= 7690 & sic1<= 7699
replace FFNUM=33 if sic1>= 8100 & sic1<= 8199
replace FFNUM=33 if sic1>= 8200 & sic1<= 8299
replace FFNUM=33 if sic1>= 8300 & sic1<= 8399
replace FFNUM=33 if sic1>= 8400 & sic1<= 8499
replace FFNUM=33 if sic1>= 8600 & sic1<= 8699
replace FFNUM=33 if sic1>= 8800 & sic1<= 8899
replace FFNUM=33 if sic1>= 7510 & sic1<= 7515
replace FFNUM=34 if sic1>= 2750 & sic1<= 2759
replace FFNUM=34 if sic1>= 3993 & sic1<= 3993
replace FFNUM=34 if sic1>= 7218 & sic1<= 7218
replace FFNUM=34 if sic1>= 7300 & sic1<= 7300
replace FFNUM=34 if sic1>= 7310 & sic1<= 7319
replace FFNUM=34 if sic1>= 7320 & sic1<= 7329
replace FFNUM=34 if sic1>= 7330 & sic1<= 7339
replace FFNUM=34 if sic1>= 7340 & sic1<= 7342
replace FFNUM=34 if sic1>= 7349 & sic1<= 7349
replace FFNUM=34 if sic1>= 7350 & sic1<= 7351
replace FFNUM=34 if sic1>= 7352 & sic1<= 7352
replace FFNUM=34 if sic1>= 7353 & sic1<= 7353
replace FFNUM=34 if sic1>= 7359 & sic1<= 7359
replace FFNUM=34 if sic1>= 7360 & sic1<= 7369
replace FFNUM=34 if sic1>= 7374 & sic1<= 7374
replace FFNUM=34 if sic1>= 7376 & sic1<= 7376
replace FFNUM=34 if sic1>= 7377 & sic1<= 7377
replace FFNUM=34 if sic1>= 7378 & sic1<= 7378
replace FFNUM=34 if sic1>= 7379 & sic1<= 7379
replace FFNUM=34 if sic1>= 7380 & sic1<= 7380
replace FFNUM=34 if sic1>= 7381 & sic1<= 7382
replace FFNUM=34 if sic1>= 7383 & sic1<= 7383
replace FFNUM=34 if sic1>= 7384 & sic1<= 7384
replace FFNUM=34 if sic1>= 7385 & sic1<= 7385
replace FFNUM=34 if sic1>= 7389 & sic1<= 7390
replace FFNUM=34 if sic1>= 7391 & sic1<= 7391
replace FFNUM=34 if sic1>= 7392 & sic1<= 7392
replace FFNUM=34 if sic1>= 7393 & sic1<= 7393
replace FFNUM=34 if sic1>= 7394 & sic1<= 7394
replace FFNUM=34 if sic1>= 7396 & sic1<= 7396
replace FFNUM=34 if sic1>= 7397 & sic1<= 7397
replace FFNUM=34 if sic1>= 7399 & sic1<= 7399
replace FFNUM=34 if sic1>= 7519 & sic1<= 7519
replace FFNUM=34 if sic1>= 8700 & sic1<= 8700
replace FFNUM=34 if sic1>= 8710 & sic1<= 8713
replace FFNUM=34 if sic1>= 8720 & sic1<= 8721
replace FFNUM=34 if sic1>= 8730 & sic1<= 8734
replace FFNUM=34 if sic1>= 8740 & sic1<= 8748
replace FFNUM=34 if sic1>= 8900 & sic1<= 8910
replace FFNUM=34 if sic1>= 8911 & sic1<= 8911
replace FFNUM=34 if sic1>= 8920 & sic1<= 8999
replace FFNUM=34 if sic1>= 4220 & sic1<= 4229
replace FFNUM=35 if sic1>= 3570 & sic1<= 3579
replace FFNUM=35 if sic1>= 3680 & sic1<= 3680
replace FFNUM=35 if sic1>= 3681 & sic1<= 3681
replace FFNUM=35 if sic1>= 3682 & sic1<= 3682
replace FFNUM=35 if sic1>= 3683 & sic1<= 3683
replace FFNUM=35 if sic1>= 3684 & sic1<= 3684
replace FFNUM=35 if sic1>= 3685 & sic1<= 3685
replace FFNUM=35 if sic1>= 3686 & sic1<= 3686
replace FFNUM=35 if sic1>= 3687 & sic1<= 3687
replace FFNUM=35 if sic1>= 3688 & sic1<= 3688
replace FFNUM=35 if sic1>= 3689 & sic1<= 3689
replace FFNUM=35 if sic1>= 3695 & sic1<= 3695
replace FFNUM=36 if sic1>= 7370 & sic1<= 7372
replace FFNUM=36 if sic1>= 7375 & sic1<= 7375
replace FFNUM=36 if sic1>= 7373 & sic1<= 7373
replace FFNUM=37 if sic1>= 3622 & sic1<= 3622
replace FFNUM=37 if sic1>= 3661 & sic1<= 3661
replace FFNUM=37 if sic1>= 3662 & sic1<= 3662
replace FFNUM=37 if sic1>= 3663 & sic1<= 3663
replace FFNUM=37 if sic1>= 3664 & sic1<= 3664
replace FFNUM=37 if sic1>= 3665 & sic1<= 3665
replace FFNUM=37 if sic1>= 3666 & sic1<= 3666
replace FFNUM=37 if sic1>= 3669 & sic1<= 3669
replace FFNUM=37 if sic1>= 3670 & sic1<= 3679
replace FFNUM=37 if sic1>= 3810 & sic1<= 3810
replace FFNUM=37 if sic1>= 3812 & sic1<= 3812
replace FFNUM=38 if sic1>= 3811 & sic1<= 3811
replace FFNUM=38 if sic1>= 3820 & sic1<= 3820
replace FFNUM=38 if sic1>= 3821 & sic1<= 3821
replace FFNUM=38 if sic1>= 3822 & sic1<= 3822
replace FFNUM=38 if sic1>= 3823 & sic1<= 3823
replace FFNUM=38 if sic1>= 3824 & sic1<= 3824
replace FFNUM=38 if sic1>= 3825 & sic1<= 3825
replace FFNUM=38 if sic1>= 3826 & sic1<= 3826
replace FFNUM=38 if sic1>= 3827 & sic1<= 3827
replace FFNUM=38 if sic1>= 3829 & sic1<= 3829
replace FFNUM=38 if sic1>= 3830 & sic1<= 3839
replace FFNUM=39 if sic1>= 2520 & sic1<= 2549
replace FFNUM=39 if sic1>= 2600 & sic1<= 2639
replace FFNUM=39 if sic1>= 2670 & sic1<= 2699
replace FFNUM=39 if sic1>= 2760 & sic1<= 2761
replace FFNUM=39 if sic1>= 3950 & sic1<= 3955
replace FFNUM=40 if sic1>= 2440 & sic1<= 2449
replace FFNUM=40 if sic1>= 2640 & sic1<= 2659
replace FFNUM=40 if sic1>= 3220 & sic1<= 3221
replace FFNUM=40 if sic1>= 3410 & sic1<= 3412
replace FFNUM=41 if sic1>= 4000 & sic1<= 4013
replace FFNUM=41 if sic1>= 4040 & sic1<= 4049
replace FFNUM=41 if sic1>= 4100 & sic1<= 4100
replace FFNUM=41 if sic1>= 4110 & sic1<= 4119
replace FFNUM=41 if sic1>= 4120 & sic1<= 4121
replace FFNUM=41 if sic1>= 4130 & sic1<= 4131
replace FFNUM=41 if sic1>= 4140 & sic1<= 4142
replace FFNUM=41 if sic1>= 4150 & sic1<= 4151
replace FFNUM=41 if sic1>= 4170 & sic1<= 4173
replace FFNUM=41 if sic1>= 4190 & sic1<= 4199
replace FFNUM=41 if sic1>= 4200 & sic1<= 4200
replace FFNUM=41 if sic1>= 4210 & sic1<= 4219
replace FFNUM=41 if sic1>= 4230 & sic1<= 4231
replace FFNUM=41 if sic1>= 4240 & sic1<= 4249
replace FFNUM=41 if sic1>= 4400 & sic1<= 4499
replace FFNUM=41 if sic1>= 4500 & sic1<= 4599
replace FFNUM=41 if sic1>= 4600 & sic1<= 4699
replace FFNUM=41 if sic1>= 4700 & sic1<= 4700
replace FFNUM=41 if sic1>= 4710 & sic1<= 4712
replace FFNUM=41 if sic1>= 4720 & sic1<= 4729
replace FFNUM=41 if sic1>= 4730 & sic1<= 4739
replace FFNUM=41 if sic1>= 4740 & sic1<= 4749
replace FFNUM=41 if sic1>= 4780 & sic1<= 4780
replace FFNUM=41 if sic1>= 4782 & sic1<= 4782
replace FFNUM=41 if sic1>= 4783 & sic1<= 4783
replace FFNUM=41 if sic1>= 4784 & sic1<= 4784
replace FFNUM=41 if sic1>= 4785 & sic1<= 4785
replace FFNUM=41 if sic1>= 4789 & sic1<= 4789
replace FFNUM=42 if sic1>= 5000 & sic1<= 5000
replace FFNUM=42 if sic1>= 5010 & sic1<= 5015
replace FFNUM=42 if sic1>= 5020 & sic1<= 5023
replace FFNUM=42 if sic1>= 5030 & sic1<= 5039
replace FFNUM=42 if sic1>= 5040 & sic1<= 5042
replace FFNUM=42 if sic1>= 5043 & sic1<= 5043
replace FFNUM=42 if sic1>= 5044 & sic1<= 5044
replace FFNUM=42 if sic1>= 5045 & sic1<= 5045
replace FFNUM=42 if sic1>= 5046 & sic1<= 5046
replace FFNUM=42 if sic1>= 5047 & sic1<= 5047
replace FFNUM=42 if sic1>= 5048 & sic1<= 5048
replace FFNUM=42 if sic1>= 5049 & sic1<= 5049
replace FFNUM=42 if sic1>= 5050 & sic1<= 5059
replace FFNUM=42 if sic1>= 5060 & sic1<= 5060
replace FFNUM=42 if sic1>= 5063 & sic1<= 5063
replace FFNUM=42 if sic1>= 5064 & sic1<= 5064
replace FFNUM=42 if sic1>= 5065 & sic1<= 5065
replace FFNUM=42 if sic1>= 5070 & sic1<= 5078
replace FFNUM=42 if sic1>= 5080 & sic1<= 5080
replace FFNUM=42 if sic1>= 5081 & sic1<= 5081
replace FFNUM=42 if sic1>= 5082 & sic1<= 5082
replace FFNUM=42 if sic1>= 5083 & sic1<= 5083
replace FFNUM=42 if sic1>= 5084 & sic1<= 5084
replace FFNUM=42 if sic1>= 5085 & sic1<= 5085
replace FFNUM=42 if sic1>= 5086 & sic1<= 5087
replace FFNUM=42 if sic1>= 5088 & sic1<= 5088
replace FFNUM=42 if sic1>= 5090 & sic1<= 5090
replace FFNUM=42 if sic1>= 5091 & sic1<= 5092
replace FFNUM=42 if sic1>= 5093 & sic1<= 5093
replace FFNUM=42 if sic1>= 5094 & sic1<= 5094
replace FFNUM=42 if sic1>= 5099 & sic1<= 5099
replace FFNUM=42 if sic1>= 5100 & sic1<= 5100
replace FFNUM=42 if sic1>= 5110 & sic1<= 5113
replace FFNUM=42 if sic1>= 5120 & sic1<= 5122
replace FFNUM=42 if sic1>= 5130 & sic1<= 5139
replace FFNUM=42 if sic1>= 5140 & sic1<= 5149
replace FFNUM=42 if sic1>= 5150 & sic1<= 5159
replace FFNUM=42 if sic1>= 5160 & sic1<= 5169
replace FFNUM=42 if sic1>= 5170 & sic1<= 5172
replace FFNUM=42 if sic1>= 5180 & sic1<= 5182
replace FFNUM=42 if sic1>= 5190 & sic1<= 5199
replace FFNUM=43 if sic1>= 5200 & sic1<= 5200
replace FFNUM=43 if sic1>= 5210 & sic1<= 5219
replace FFNUM=43 if sic1>= 5220 & sic1<= 5229
replace FFNUM=43 if sic1>= 5230 & sic1<= 5231
replace FFNUM=43 if sic1>= 5250 & sic1<= 5251
replace FFNUM=43 if sic1>= 5260 & sic1<= 5261
replace FFNUM=43 if sic1>= 5270 & sic1<= 5271
replace FFNUM=43 if sic1>= 5300 & sic1<= 5300
replace FFNUM=43 if sic1>= 5310 & sic1<= 5311
replace FFNUM=43 if sic1>= 5320 & sic1<= 5320
replace FFNUM=43 if sic1>= 5330 & sic1<= 5331
replace FFNUM=43 if sic1>= 5334 & sic1<= 5334
replace FFNUM=43 if sic1>= 5340 & sic1<= 5349
replace FFNUM=43 if sic1>= 5390 & sic1<= 5399
replace FFNUM=43 if sic1>= 5400 & sic1<= 5400
replace FFNUM=43 if sic1>= 5410 & sic1<= 5411
replace FFNUM=43 if sic1>= 5412 & sic1<= 5412
replace FFNUM=43 if sic1>= 5420 & sic1<= 5429
replace FFNUM=43 if sic1>= 5430 & sic1<= 5439
replace FFNUM=43 if sic1>= 5440 & sic1<= 5449
replace FFNUM=43 if sic1>= 5450 & sic1<= 5459
replace FFNUM=43 if sic1>= 5460 & sic1<= 5469
replace FFNUM=43 if sic1>= 5490 & sic1<= 5499
replace FFNUM=43 if sic1>= 5500 & sic1<= 5500
replace FFNUM=43 if sic1>= 5510 & sic1<= 5529
replace FFNUM=43 if sic1>= 5530 & sic1<= 5539
replace FFNUM=43 if sic1>= 5540 & sic1<= 5549
replace FFNUM=43 if sic1>= 5550 & sic1<= 5559
replace FFNUM=43 if sic1>= 5560 & sic1<= 5569
replace FFNUM=43 if sic1>= 5570 & sic1<= 5579
replace FFNUM=43 if sic1>= 5590 & sic1<= 5599
replace FFNUM=43 if sic1>= 5600 & sic1<= 5699
replace FFNUM=43 if sic1>= 5700 & sic1<= 5700
replace FFNUM=43 if sic1>= 5710 & sic1<= 5719
replace FFNUM=43 if sic1>= 5720 & sic1<= 5722
replace FFNUM=43 if sic1>= 5730 & sic1<= 5733
replace FFNUM=43 if sic1>= 5734 & sic1<= 5734
replace FFNUM=43 if sic1>= 5735 & sic1<= 5735
replace FFNUM=43 if sic1>= 5736 & sic1<= 5736
replace FFNUM=43 if sic1>= 5750 & sic1<= 5799
replace FFNUM=43 if sic1>= 5900 & sic1<= 5900
replace FFNUM=43 if sic1>= 5910 & sic1<= 5912
replace FFNUM=43 if sic1>= 5920 & sic1<= 5929
replace FFNUM=43 if sic1>= 5930 & sic1<= 5932
replace FFNUM=43 if sic1>= 5940 & sic1<= 5940
replace FFNUM=43 if sic1>= 5941 & sic1<= 5941
replace FFNUM=43 if sic1>= 5942 & sic1<= 5942
replace FFNUM=43 if sic1>= 5943 & sic1<= 5943
replace FFNUM=43 if sic1>= 5944 & sic1<= 5944
replace FFNUM=43 if sic1>= 5945 & sic1<= 5945
replace FFNUM=43 if sic1>= 5946 & sic1<= 5946
replace FFNUM=43 if sic1>= 5947 & sic1<= 5947
replace FFNUM=43 if sic1>= 5948 & sic1<= 5948
replace FFNUM=43 if sic1>= 5949 & sic1<= 5949
replace FFNUM=43 if sic1>= 5950 & sic1<= 5959
replace FFNUM=43 if sic1>= 5960 & sic1<= 5969
replace FFNUM=43 if sic1>= 5970 & sic1<= 5979
replace FFNUM=43 if sic1>= 5980 & sic1<= 5989
replace FFNUM=43 if sic1>= 5990 & sic1<= 5990
replace FFNUM=43 if sic1>= 5992 & sic1<= 5992
replace FFNUM=43 if sic1>= 5993 & sic1<= 5993
replace FFNUM=43 if sic1>= 5994 & sic1<= 5994
replace FFNUM=43 if sic1>= 5995 & sic1<= 5995
replace FFNUM=43 if sic1>= 5999 & sic1<= 5999
replace FFNUM=44 if sic1>= 5800 & sic1<= 5819
replace FFNUM=44 if sic1>= 5820 & sic1<= 5829
replace FFNUM=44 if sic1>= 5890 & sic1<= 5899
replace FFNUM=44 if sic1>= 7000 & sic1<= 7000
replace FFNUM=44 if sic1>= 7010 & sic1<= 7019
replace FFNUM=44 if sic1>= 7040 & sic1<= 7049
replace FFNUM=44 if sic1>= 7213 & sic1<= 7213
replace FFNUM=45 if sic1>= 6000 & sic1<= 6000
replace FFNUM=45 if sic1>= 6010 & sic1<= 6019
replace FFNUM=45 if sic1>= 6020 & sic1<= 6020
replace FFNUM=45 if sic1>= 6021 & sic1<= 6021
replace FFNUM=45 if sic1>= 6022 & sic1<= 6022
replace FFNUM=45 if sic1>= 6023 & sic1<= 6024
replace FFNUM=45 if sic1>= 6025 & sic1<= 6025
replace FFNUM=45 if sic1>= 6026 & sic1<= 6026
replace FFNUM=45 if sic1>= 6027 & sic1<= 6027
replace FFNUM=45 if sic1>= 6028 & sic1<= 6029
replace FFNUM=45 if sic1>= 6030 & sic1<= 6036
replace FFNUM=45 if sic1>= 6040 & sic1<= 6059
replace FFNUM=45 if sic1>= 6060 & sic1<= 6062
replace FFNUM=45 if sic1>= 6080 & sic1<= 6082
replace FFNUM=45 if sic1>= 6090 & sic1<= 6099
replace FFNUM=45 if sic1>= 6100 & sic1<= 6100
replace FFNUM=45 if sic1>= 6110 & sic1<= 6111
replace FFNUM=45 if sic1>= 6112 & sic1<= 6113
replace FFNUM=45 if sic1>= 6120 & sic1<= 6129
replace FFNUM=45 if sic1>= 6130 & sic1<= 6139
replace FFNUM=45 if sic1>= 6140 & sic1<= 6149
replace FFNUM=45 if sic1>= 6150 & sic1<= 6159
replace FFNUM=45 if sic1>= 6160 & sic1<= 6169
replace FFNUM=45 if sic1>= 6170 & sic1<= 6179
replace FFNUM=45 if sic1>= 6190 & sic1<= 6199
replace FFNUM=46 if sic1>= 6300 & sic1<= 6300
replace FFNUM=46 if sic1>= 6310 & sic1<= 6319
replace FFNUM=46 if sic1>= 6320 & sic1<= 6329
replace FFNUM=46 if sic1>= 6330 & sic1<= 6331
replace FFNUM=46 if sic1>= 6350 & sic1<= 6351
replace FFNUM=46 if sic1>= 6360 & sic1<= 6361
replace FFNUM=46 if sic1>= 6370 & sic1<= 6379
replace FFNUM=46 if sic1>= 6390 & sic1<= 6399
replace FFNUM=46 if sic1>= 6400 & sic1<= 6411
replace FFNUM=47 if sic1>= 6500 & sic1<= 6500
replace FFNUM=47 if sic1>= 6510 & sic1<= 6510
replace FFNUM=47 if sic1>= 6512 & sic1<= 6512
replace FFNUM=47 if sic1>= 6513 & sic1<= 6513
replace FFNUM=47 if sic1>= 6514 & sic1<= 6514
replace FFNUM=47 if sic1>= 6515 & sic1<= 6515
replace FFNUM=47 if sic1>= 6517 & sic1<= 6519
replace FFNUM=47 if sic1>= 6520 & sic1<= 6529
replace FFNUM=47 if sic1>= 6530 & sic1<= 6531
replace FFNUM=47 if sic1>= 6532 & sic1<= 6532
replace FFNUM=47 if sic1>= 6540 & sic1<= 6541
replace FFNUM=47 if sic1>= 6550 & sic1<= 6553
replace FFNUM=47 if sic1>= 6590 & sic1<= 6599
replace FFNUM=47 if sic1>= 6610 & sic1<= 6611
replace FFNUM=48 if sic1>= 6200 & sic1<= 6299
replace FFNUM=48 if sic1>= 6700 & sic1<= 6700
replace FFNUM=48 if sic1>= 6710 & sic1<= 6719
replace FFNUM=48 if sic1>= 6720 & sic1<= 6722
replace FFNUM=48 if sic1>= 6723 & sic1<= 6723
replace FFNUM=48 if sic1>= 6724 & sic1<= 6724
replace FFNUM=48 if sic1>= 6725 & sic1<= 6725
replace FFNUM=48 if sic1>= 6726 & sic1<= 6726
replace FFNUM=48 if sic1>= 6730 & sic1<= 6733
replace FFNUM=48 if sic1>= 6740 & sic1<= 6779
replace FFNUM=48 if sic1>= 6790 & sic1<= 6791
replace FFNUM=48 if sic1>= 6792 & sic1<= 6792
replace FFNUM=48 if sic1>= 6793 & sic1<= 6793
replace FFNUM=48 if sic1>= 6794 & sic1<= 6794
replace FFNUM=48 if sic1>= 6795 & sic1<= 6795
replace FFNUM=48 if sic1>= 6798 & sic1<= 6798
replace FFNUM=48 if sic1>= 6799 & sic1<= 6799
replace FFNUM=49 if sic1>= 4950 & sic1<= 4959
replace FFNUM=49 if sic1>= 4960 & sic1<= 4961
replace FFNUM=49 if sic1>= 4970 & sic1<= 4971
replace FFNUM=49 if sic1>= 4990 & sic1<= 4991
rename FFNUM FFNUM49

mmerge FFNUM49 using "$apath/FF49_names.dta"
keep if _merge==3
keep name Ticker FF*
save "$apath/FamaFrench49.dta", replace



***************************
***************************
*FF 5
***************************
***************************
use "$apath/DS_BB_Static_v2.dta", clear

rename sic_code_1 sic1
rename sic_code_2 sic2
rename sic_code_3 sic3
rename sic_code_4 sic4

destring sic1, replace force
destring sic2, replace force
destring sic3, replace force
destring sic4, replace force
drop if sic1==.

gen FFNUM=.
replace FFNUM=1 if sic1>= 100 & sic1<= 999
replace FFNUM=1 if sic1>= 2000 & sic1<= 2399
replace FFNUM=1 if sic1>= 2700 & sic1<= 2749
replace FFNUM=1 if sic1>= 2770 & sic1<= 2799
replace FFNUM=1 if sic1>= 3100 & sic1<= 3199
replace FFNUM=1 if sic1>= 3940 & sic1<= 3989
replace FFNUM=1 if sic1>= 2500 & sic1<= 2519
replace FFNUM=1 if sic1>= 2590 & sic1<= 2599
replace FFNUM=1 if sic1>= 3630 & sic1<= 3659
replace FFNUM=1 if sic1>= 3710 & sic1<= 3711
replace FFNUM=1 if sic1>= 3714 & sic1<= 3714
replace FFNUM=1 if sic1>= 3716 & sic1<= 3716
replace FFNUM=1 if sic1>= 3750 & sic1<= 3751
replace FFNUM=1 if sic1>= 3792 & sic1<= 3792
replace FFNUM=1 if sic1>= 3900 & sic1<= 3939
replace FFNUM=1 if sic1>= 3990 & sic1<= 3999
replace FFNUM=1 if sic1>= 5000 & sic1<= 5999
replace FFNUM=1 if sic1>= 7200 & sic1<= 7299
replace FFNUM=1 if sic1>= 7600 & sic1<= 7699
replace FFNUM=2 if sic1>= 2520 & sic1<= 2589
replace FFNUM=2 if sic1>= 2600 & sic1<= 2699
replace FFNUM=2 if sic1>= 2750 & sic1<= 2769
replace FFNUM=2 if sic1>= 2800 & sic1<= 2829
replace FFNUM=2 if sic1>= 2840 & sic1<= 2899
replace FFNUM=2 if sic1>= 3000 & sic1<= 3099
replace FFNUM=2 if sic1>= 3200 & sic1<= 3569
replace FFNUM=2 if sic1>= 3580 & sic1<= 3629
replace FFNUM=2 if sic1>= 3700 & sic1<= 3709
replace FFNUM=2 if sic1>= 3712 & sic1<= 3713
replace FFNUM=2 if sic1>= 3715 & sic1<= 3715
replace FFNUM=2 if sic1>= 3717 & sic1<= 3749
replace FFNUM=2 if sic1>= 3752 & sic1<= 3791
replace FFNUM=2 if sic1>= 3793 & sic1<= 3799
replace FFNUM=2 if sic1>= 3830 & sic1<= 3839
replace FFNUM=2 if sic1>= 3860 & sic1<= 3899
replace FFNUM=2 if sic1>= 1200 & sic1<= 1399
replace FFNUM=2 if sic1>= 2900 & sic1<= 2999
replace FFNUM=2 if sic1>= 4900 & sic1<= 4949
replace FFNUM=3 if sic1>= 3570 & sic1<= 3579
replace FFNUM=3 if sic1>= 3622 & sic1<= 3622
replace FFNUM=3 if sic1>= 3660 & sic1<= 3692
replace FFNUM=3 if sic1>= 3694 & sic1<= 3699
replace FFNUM=3 if sic1>= 3810 & sic1<= 3839
replace FFNUM=3 if sic1>= 7370 & sic1<= 7379
replace FFNUM=3 if sic1>= 7370 & sic1<= 7372
replace FFNUM=3 if sic1>= 7373 & sic1<= 7373
replace FFNUM=3 if sic1>= 7374 & sic1<= 7374
replace FFNUM=3 if sic1>= 7375 & sic1<= 7375
replace FFNUM=3 if sic1>= 7376 & sic1<= 7376
replace FFNUM=3 if sic1>= 7377 & sic1<= 7377
replace FFNUM=3 if sic1>= 7378 & sic1<= 7378
replace FFNUM=3 if sic1>= 7379 & sic1<= 7379
replace FFNUM=3 if sic1>= 7391 & sic1<= 7391
replace FFNUM=3 if sic1>= 8730 & sic1<= 8734
replace FFNUM=3 if sic1>= 4800 & sic1<= 4899
replace FFNUM=4 if sic1>= 2830 & sic1<= 2839
replace FFNUM=4 if sic1>= 3693 & sic1<= 3693
replace FFNUM=4 if sic1>= 3840 & sic1<= 3859
replace FFNUM=4 if sic1>= 8000 & sic1<= 8099
replace FFNUM=5 if FFNUM==.
rename FFNUM FFNUM5

mmerge FFNUM5 using "$apath/FF5_names.dta"
keep if _merge==3
keep name Ticker FF*
save "$apath/FamaFrench5.dta", replace

*Combine the 3
use "$apath/FamaFrench5.dta", clear
mmerge Ticker using "$apath/FamaFrench12.dta"
mmerge Ticker using "$apath/FamaFrench49.dta"

order Ticker name FFNUM12 FFNUM49 FFCODE12 FFCODE49 FFDESC12 FFDESC49 FFNUM5 FFCODE5 FFDESC5
sort FFNUM12 FFNUM49 Ticker 
drop _merge
keep if Ticker~=""
save "$apath/FamaFrench_Master.dta", replace
