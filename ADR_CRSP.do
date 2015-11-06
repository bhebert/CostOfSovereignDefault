set more off

use "$apath/Datastream_Quarterly.dta", clear

mmerge Ticker using "$apath/FirmTable.dta"
keep if _merge==3
split ADRticker, p(" ")
drop ADRticker2 ADRticker3
drop Ticker
rename ADRticker1 Ticker

keep Ticker quarter MV EPS EPSNew ADRratio WC05101 leverage WC03255 WC03501 WC02999 WC05301 WC01705
rename WC05101 DivPerShare
rename WC03255 TotalDebt
rename WC03501 BookCommon
rename WC02999 TotalAssets
rename WC05301 CommonOutstanding
rename WC01705 NetIncomeDiluted

drop if Ticker==""

tempfile temp
save "`temp'", replace

use "$miscdata/CRSP Balance Sheet/All_ADRs.dta", clear

* This procedure follows Gorodnichenko & Weber
* However, we use cshoq & prccq (Computstat quarter-end variables)
* instead of CRSP daily market variables.

gen commonshares = cshoq
replace commonshares = cshprq if cshoq == .

gen marketeq = commonshares * prccq 

//* adrrq the common outstanding appears to be adjusted for the ADR ratio...

gen shareeq = seqq

replace shareeq = ceqq + pstkq if shareeq == .

replace shareeq = atq - ltq if shareeq == .


replace pstkq = 0 if pstkq == .
replace txditcq = 0 if txditcq == .

gen bookeq = shareeq + txditcq - pstkq


gen quarter = qofd(datadate)
encode tic, gen(tid)

//drop if quarter < yq(2003,1)

sort tid quarter
tsset tid quarter
tsfill

* Cohn and Sikes working paper say that gross repurchases are prstkcy - pstkq
* but prstkcy is cumulative over the year

keep quarter datacqtr datafqtr tid tic datadate marketeq bookeq shareeq atq curcdq curncdq currtrq adrrq prccq cshoq cshprq epsfxq epspiq dvpsxq cshfdq epsf12 pstkq prstkcy commonshares

mmerge quarter using "$apath/ADRBlue_quarter.dta", ukeep(ADRBlue OfficialRate) unmatched(master)

rename tic Ticker

mmerge Ticker quarter using "`temp'", unmatched(master)

gen comp_rate = 1 / currtrq

replace bookeq = bookeq / currtrq
replace atq = atq / currtrq

// Some data appears to be based on local, not ADRs..
replace marketeq = marketeq * ADRBlue if adrrq != .
replace marketeq = marketeq / currtrq if adrrq == .


gen peratio = prccq / epsf12

replace adrrq = 1 if adrrq == .

replace epsfxq = epsfxq / currtrq / adrrq
replace epspiq = epspiq / currtrq / adrrq
replace epsf12 = epsf12 / currtrq / adrrq

replace dvpsxq = dvpsxq / currtrq /adrrq

replace cshoq = cshoq * adrrq
replace cshprq = cshprq * adrrq
replace cshfdq = cshfdq * adrrq
replace commonshares = commonshares * adrrq


sort tid quarter

gen repurchases = (D.prstkcy - pstkq) / currtrq
replace repurchases = (prstkcy - pstkq) / currtrq if quarter(dofq(quarter)) == 1
replace repurchases = 0 if repurchases < 0 & repurchases != .

replace repurchases = repurchases / commonshares

format CommonOutstanding %9.2f
format quarter %tq

gen crsp_lev = (atq - bookeq + marketeq) / marketeq

order datadate datacqtr datafqtr quarter Ticker epspiq epsfxq EPSNew EPS epsf12 DivPerShare dvpsxq CommonOutstanding cshoq cshprq cshfdq BookCommon bookeq atq TotalAssets marketeq MV leverage crsp_lev


keep quarter Ticker marketeq crsp_lev epsfxq epspiq epsf12 dvpsxq repurchases commonshares adrrq peratio

sort Ticker quarter

save "$apath/ADR_CRSP.dta", replace

drop if Ticker == ""
drop if Ticker == "YPF"
drop if epsfxq == . | marketeq == . | commonshares == .
gen earn = epsfxq * commonshares

collapse (sum) earn marketeq, by(quarter)

gen peratio = marketeq / earn

tsset quarter

gen peratio2 = marketeq / (earn + L.earn + L2.earn + L3.earn)
