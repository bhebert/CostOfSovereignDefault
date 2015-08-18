
* Runs code associated with preparing datasets for analysis
* Assumes the data cleaning scripts have been run


do ${csd_dir}/SetupPaths.do

do ${csd_dir}/DataCleaningScripts/Commodity_Clean.do

do ${csd_dir}/DataCleaningScripts/Datastream_Quarterly_Clean.do

do ${csd_dir}/DataCleaningScripts/NDF_Clean.do

do ${csd_dir}/DataCleaningScripts/Clean_PUF.do

do ${csd_dir}/DataCleaningScripts/dolarblue_clean.do

do ${csd_dir}/DataCleaningScripts/CRSP_Bolsar_Blue.do

do ${csd_dir}/DataCleaningScripts/US_Inflation.do

do ${csd_dir}/DataCleaningScripts/BCS.do

do ${csd_dir}/DataCleaningScripts/RER_GDP_Maker.do


