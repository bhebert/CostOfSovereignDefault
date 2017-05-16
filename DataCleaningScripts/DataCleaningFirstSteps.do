set more off

* Runs code associated with preparing datasets for analysis
* Assumes the data cleaning scripts have been run


do ${csd_dir}/SetupPaths.do

do ${csd_dir}/DataCleaningScripts/Datastream_clean_v2.do

do ${csd_dir}/DataCleaningScripts/ImportDSexchange.do

do ${csd_dir}/DataCleaningScripts/T_NT.do

do ${csd_dir}/DataCleaningScripts/CleaningAdditionalVars.do

do ${csd_dir}/DataCleaningScripts/import_cds.do

do ${csd_dir}/DataCleaningScripts/GSW_Clean.do

do ${csd_dir}/DataCleaningScripts/Cleaning_Bolsar.do

do ${csd_dir}/DataCleaningScripts/CleaningBB_Step1.do

do ${csd_dir}/DataCleaningScripts/CleaningBB_Step2.do

do ${csd_dir}/DataCleaningScripts/CleaningBB_Step3.do

do ${csd_dir}/DataCleaningScripts/CleaningBB_Step4.do
