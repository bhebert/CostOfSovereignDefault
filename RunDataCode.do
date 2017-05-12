
* Runs code associated with preparing datasets for analysis
* Assumes the data cleaning scripts have been run

do ${csd_dir}/SetupPaths.do

do ${csd_dir}/GlobalFactors.do

do ${csd_dir}/BlueRateMaker_v2.do


do ${csd_dir}/ADR_CRSP.do


do ${csd_dir}/ADR_ValueNew.do

do ${csd_dir}/CDS_Other_Countries.do

do ${csd_dir}/ThirdAnalysis.do



