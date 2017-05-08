# CostOfSovereignDefault
Stata and other code associated with "The Cost of Sovereign Default: Evidence from Argentina"

WARNING: Code comments have not been updated. If they conflict with what is in the paper,
assume the paper is correct and the code comments are not.

Required Stata packages:

ivreg2
carryforward
matmap
ranktest
outreg2
mmerge
rmfiles
sxpose


note that these packages can be installed using (for example)
"ssc install ivreg2"


STATA Global Setup Instructions:
You will need to setup several global variables to run the code. These variables are 
listed below, along with example values and comments indicating their meaning.

** The name of the person/computer running the results. 
global whoami BenHMacDesk

** The local directory with .do files and space for temporary files
global csd_dir /Users/bhebert/CostOfSovereignDefault

** Path to the Matlab application to run the default probability computation
global matlab /Applications/MATLAB_R2016b.app/bin/matlab

