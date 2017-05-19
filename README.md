# CostOfSovereignDefault
Stata and other code associated with "The Cost of Sovereign Default: Evidence from Argentina"

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


Matlab is also required. Tested with Stata 14.2 and Matlab R2016b on Mac and Windows 
machines.

STATA Global Setup Instructions:
You will need to setup several global variables to run the code. These variables are 
listed below, along with example values and comments indicating their meaning.

** The name of the person/computer running the results. 
global whoami BenHMacDesk

** The local directory with .do files and space for temporary files
global csd_dir /Users/bhebert/CostOfSovereignDefault

** Path to the Matlab application to run the default probability computation
global matlab /Applications/MATLAB_R2016b.app/bin/matlab

Editing SetupPaths.do:
You will need to edit several paths at the top of SetupPaths.do, and create a location for
the output (the "results" folder).

Running the code:
Run the "RunEverything.do" file

Comparing the results to the paper:
The "results" folder you created when editing SetupPaths.do will contain many output 
files. The word document "FigureTablesForPaper.docx" describes which files contain results 
used in the paper.