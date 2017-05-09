
* Runs code associated with preparing datasets for analysis
* Assumes the data cleaning scripts have been run


do ${csd_dir}/SetupPaths.do

do ${csd_dir}/GlobalFactors.do

do ${csd_dir}/BlueRateMaker_v2.do

*** why is this here?
do ${csd_dir}/DataCleaningScripts/ADRVolume.do

* candidate for removal
**do ${csd_dir}/Seasonal/Seasonal.do

* candidate for removal
* do ${csd_dir}/DataCleaningScripts/RER_GDP_Maker.do

do ${csd_dir}/ADR_CRSP.do

* candidate for removal
* do ${csd_dir}/ADR_Value.do

do ${csd_dir}/ADR_ValueNew.do

do ${csd_dir}/CDS_Other_Countries.do

do ${csd_dir}/ThirdAnalysis.do

* candidate for removal
* do ${csd_dir}/LowFreqFactors.do

* do ${csd_dir}/Industrial_ProductionNew.do

//do ${csd_dir}/DivMaker4.do


