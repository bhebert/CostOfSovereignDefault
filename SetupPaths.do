
* Path to root of location with data files
* "$droppath" may not be defined for you
* Edit the entire path to wherever the data files are


*global csd_data "$droppath/Cost of Sovereign Default"
global csd_data "$droppath/Hebert_Schreger_AER/AER-Data"

* Path to root of location for results.
* Directory must exist.
global csd_results "$droppath/Cost of Sovereign Default/Results"


* Code to setup global path variables
* You should not need to edit below here

global bbpath "$csd_data/Bloomberg"
global opath "$csd_data/Notes"
global fpath "$csd_data/Additional Data"
global dpath "$csd_data/Datastream"
global mpath "$csd_data/Markit/Datasets"
global cpath "$csd_data/CDS Comparison"
global ffpath "$csd_data/Argentina/Tradable/FF"
global tpath "$csd_data/Argentina/Tradable"
global gdppath "$csd_data/GDP Weighting"
global miscdata "$csd_data/Misc Data"

global crsp_path "$csd_data/CRSP"
global local_path "$csd_data/Local Data"

global warrant_path "$csd_data/GDP Warrants"


global mainpath "$csd_data"

* Setup path for results

local sysdate = subinstr(c(current_date)," ","",.)

if "$alt_rho" == "" | "$alt_rho" == "0" {
	global rpath "$csd_results/${whoami}_`sysdate'"
}
else {
	local ext = string($alt_rho)
	global rpath "$csd_results/${whoami}_`sysdate'_`ext'"
}
capture confirm file "$rpath/nul"
if _rc { 
	!md "$rpath"
	!mkdir "$rpath"
}


* This is for locally generated files
global apath "$csd_dir/Datasets"

* change current directory
cd ${csd_dir}

* add this to the adopath

adopath + $csd_dir

* force loading of the business day calendar
bcal load basic


* a list of factor variables
* useful in multiple places.
global all_factors SPX_ VIX_ EEMA_ IG5Yr_ HY5Yr_ oil_
*soybean_
