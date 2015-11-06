set more off

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

do ${csd_dir}/DataCleaningScripts/GDP_Inflation_Cleaning.do

do ${csd_dir}/DataCleaningScripts/Additional_ADRs.do

do ${csd_dir}/DataCleaningScripts/Ambito.do

do ${csd_dir}/DataCleaningScripts/Cleaning_Bond_Level.do

do ${csd_dir}/DataCleaningScripts/TC_clean.do

do ${csd_dir}/DataCleaningScripts/Other_Equities.do

do ${csd_dir}/DataCleaningScripts/CRSP_ADR_Clean.do

do ${csd_dir}/DataCleaningScripts/Clean_TGNO4.do

do ${csd_dir}/CDSMaker.do

do ${csd_dir}/DataCleaningScripts/BB_Stale_EventCount.do

do ${csd_dir}/StaticTable.do



