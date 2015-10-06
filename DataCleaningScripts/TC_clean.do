tempfile temp1
import excel "$miscdata/RatingsDirect/Histories/RatingsHistory.xlsx", sheet("Sheet1") firstrow clear
keep Date TC
rename TC Rating
gen rating=23 if Rating=="AAA"
replace rating=22 if Rating=="AA+"
replace rating=21 if Rating=="AA"
replace rating=20 if Rating=="AA-"
replace rating=19 if Rating=="A+"
replace rating=18 if Rating=="A"
replace rating=17 if Rating=="A-"
replace rating=16 if Rating=="BBB+"
replace rating=15 if Rating=="BBB"
replace rating=14 if Rating=="BBB-"
replace rating=13 if Rating=="BB+"
replace rating=12 if Rating=="BB"
replace rating=11 if Rating=="BB-"
replace rating=10 if Rating=="B+"
replace rating=9 if Rating=="B"
replace rating=8 if Rating=="B-"
replace rating=7 if Rating=="CCC+"
replace rating=6 if Rating=="CCC"
replace rating=5 if Rating=="CCC-"
replace rating=4 if Rating=="CC+"
replace rating=3 if Rating=="CC"
replace rating=2 if Rating=="CC-"
replace rating=1 if Rating=="SD" | Rating=="D"
rename rating TC
drop Rating
rename Date date
tsset date

tsfill 
carryforward TC, replace
save "`temp1'", replace


import excel "$miscdata/RatingsDirect/Histories/AllFirms.xlsx", sheet("Sheet1") firstrow clear
replace CreditWatchOutlookDate=RatingDate if CreditWatchOutlookDate==""
gen date=date(CreditWatchOutlookDate,"DMY")
order date RatingD
format date %td
drop RatingDate
replace RatingType="ASLT" if RatingType=="Argentina National Scale LT"
replace RatingType="FCLT" if RatingType=="Foreign Currency LT"
replace RatingType="FCST" if RatingType=="Foreign Currency ST"
replace RatingType="LCLT" if RatingType=="Local Currency LT"
replace RatingType="LCST" if RatingType=="Local Currency ST"
gen rating=23 if Rating=="AAA"
replace rating=22 if Rating=="AA+"
replace rating=21 if Rating=="AA"
replace rating=20 if Rating=="AA-"
replace rating=19 if Rating=="A+"
replace rating=18 if Rating=="A"
replace rating=17 if Rating=="A-"
replace rating=16 if Rating=="BBB+"
replace rating=15 if Rating=="BBB"
replace rating=14 if Rating=="BBB-"
replace rating=13 if Rating=="BB+"
replace rating=12 if Rating=="BB"
replace rating=11 if Rating=="BB-"
replace rating=10 if Rating=="B+"
replace rating=9 if Rating=="B"
replace rating=8 if Rating=="B-"
replace rating=7 if Rating=="CCC+"
replace rating=6 if Rating=="CCC"
replace rating=5 if Rating=="CCC-"
replace rating=4 if Rating=="CC+"
replace rating=3 if Rating=="CC"
replace rating=2 if Rating=="CC-"
replace rating=1 if Rating=="SD" | Rating=="D"
label define ratings 23 "AAA" 22 "AA+" 21 "AA" 20 "AA-" 19 "A+" 18 "A" 17 "A-" 16 "BBB+" 15 "BBB" 14 "BBB-" 13 "BB+" 12 "BB" 11 "BB-" 10 "B+" 9 "B" 8 "B-" 7 "CCC+" 6 "CCC" 5 "CCC-" 4 "CC+" 3 "CC" 2 "CC-" 1 "Default" 
label values rating ratings
drop Rating
order date Firm rating
gen firmshort=Firm
replace firmshort="Aeropuertos Argentina" if Firm=="Aeropuertos Argentina 2000 S.A."
replace firmshort="Alto Palermo" if Firm=="Alto Palermo S.A."
replace firmshort="Arauco" if Firm=="Arauco Argentina S.A."
replace firmshort="CAPEX" if Firm=="CAPEX S.A."
replace firmshort="CLISA" if Firm=="CLISA-Compania Latinoamericana de Infraestructura & Servicios S.A."
replace firmshort="HPA" if Firm=="Hidroelectrica Piedra del Aguila S.A."
replace firmshort="IRSA Inv Rep" if Firm=="IRSA Inversiones y Representaciones S.A."
replace firmshort="Mastellone Hermanos" if Firm=="Mastellone Hermanos S.A"
replace firmshort="Metrogas" if Firm=="Metrogas"
replace firmshort="RAGHSA" if Firm=="RAGHSA S.A."
replace firmshort="Transener" if Firm=="Transener"
replace firmshort="TGS" if Firm=="Transportadora de Gas del Sur S.A. (TGS)"
replace firmshort="WPE" if Firm=="WPE International Cooperatief U.A."
replace firmshort="Argentina" if Firm=="Argentina"
replace firmshort="SAIC" if Firm=="Industrias Metalurgicas Pescarmona S.A.I.C.y.F."
replace firmshort="IRCP" if Firm=="IRSA Propiedades Comerciales"
keep date Firm firmshort RatingType rating

keep if yofd(date)>2010

*FIX THIS
reshape wide rating, i(date Firm firmshort) j(RatingType) string

renpfix rating
sort firmshort date
encode firmshort, gen (cid)

tsset cid date
tsfill
foreach x in Firm firmshort ASLT FCLT FCST LCLT LCST {
	bysort cid: carryforward `x', replace
	}
	mmerge date using "`temp1'"
label values TC ratings
	keep if yofd(date)>2010
order date cid firmshort
order Firm, last
order date cid FCLT LCLT TC
drop if firmshort=="Alto Palermo"
gen gov=0
replace gov=1 if firmshort=="Neuquen Province" |  firmshort=="Buenos Aires Province" | firmshort=="Cordoba Province" | firmshort=="Buenos Aires City" | firmshort=="Mendoza Province"  | firmshort=="Argentina" 
gen dataset=0
replace dataset=1 if firmshort=="Banco Hipotecario" | firmshort=="Banco Patagonia" | firmshort=="Banco de Galicia y Buenos Aires" | firmshort=="CAPEX" | firmshort=="IRCP" | firmshort=="IRSA Inv Rep" | firmshort=="Metrogas"  | firmshort=="Petrobras Argentina" | firmshort=="TGS" 
gen ticker=""
replace ticker="HPD" if firmshort=="Banco Hipotecario"
replace ticker="BPT" if firmshort=="Banco Patagonia"
replace ticker="GGA" if firmshort=="Banco de Galicia y Buenos Aires"
replace ticker="CPX" if firmshort=="CAPEX"
replace ticker="SAM" if firmshort=="IRCP"
replace ticker="IRSA" if firmshort=="IRSA Inv Rep"
replace ticker="MET" if firmshort=="Metrogas"
replace ticker="PER" if firmshort=="Petrobras Argentina"
replace ticker="TGS" if firmshort=="TGS"
keep if  date==td(15sep2013) & dataset==1
gen TCind=0
replace TCind=1 if LCLT>FCLT | FCLT>TC
keep TCind ticker 
save "$apath/TCind.dta"
