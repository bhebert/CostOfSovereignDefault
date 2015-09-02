

* Code to setup global path variables

global bbpath "$droppath/Cost of Sovereign Default/Bloomberg/Datasets"
global opath "$droppath/Cost of Sovereign Default/Notes"
global fpath "$droppath/Cost of Sovereign Default/Additional Data"
global dpath "$droppath/Cost of Sovereign Default/Datastream"
global mpath "$droppath/Cost of Sovereign Default/Markit/Datasets"
global cpath "$droppath/Cost of Sovereign Default/CDS Comparison"
global ffpath "$droppath/Cost of Sovereign Default/Argentina/Tradable/FF"
global tpath "$droppath/Cost of Sovereign Default/Argentina/Tradable"
global gdppath "$droppath/Cost of Sovereign Default/GDP Weighting"
global miscdata "$droppath/Cost of Sovereign Default/Misc Data"
global forpath "$droppath/Cost of Sovereign Default/Forecasts"
global fweo_path "$droppath/Cost of Sovereign Default/Forecasts/WEO"
global crsp_path "$droppath/Cost of Sovereign Default/CRSP"

global mainpath "$droppath/Cost of Sovereign Default"

* Setup path for results

local sysdate = subinstr(c(current_date)," ","",.)

if "$alt_rho" == "" | "$alt_rho" == "0" {
	global rpath "$droppath/Cost of Sovereign Default/Results/${whoami}_`sysdate'"
}
else {
	local ext = string($alt_rho)
	global rpath "$droppath/Cost of Sovereign Default/Results/${whoami}_`sysdate'_`ext'"
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
global all_factors SPX_ VIX_ EEMA_ IG5Yr_ HY5Yr_ oil_ soybean_
