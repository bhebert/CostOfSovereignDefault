
* Runs code associated with preparing datasets for analysis
* Assumes the data cleaning scripts have been run


do ${csd_dir}/SetupPaths.do

do ${csd_dir}/DataCleaningScripts/Commodity_Clean.do

do ${csd_dir}/DataCleaningScripts/Datastream_Quarterly_Clean.do


