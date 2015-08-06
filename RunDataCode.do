
* Runs code associated with preparing datasets for analysis
* Assumes the data cleaning scripts have been run


do ${csd_dir}/SetupPaths.do

do ${csd_dir}/StaticTable.do

do ${csd_dir}/ADR_Value.do

do ${csd_dir}/BlueRateMaker.do

do ${csd_dir}/GlobalFactors.do

do ${csd_dir}/CDSMaker.do

do ${csd_dir}/ThirdAnalysis.do

