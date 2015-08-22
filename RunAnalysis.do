
* Setup paths-- in case it hasn't been done yet.
do ${csd_dir}/SetupPaths.do

global GDP_models gdp_var ip_var gdp_dols ip_dols consensus consensus03 consensus6m consensus036m consensusIP consensusIP03 consensusIP6m consensusIP036m gdp_tracking ip_tracking
// vecm 
*global GDP_models vecm 

* Build the data for VAR/tracking/consensus
do "$csd_dir/DivMakerNew.do"

*Make the Dividend VAR indices
do "$csd_dir/VarRunner.do"

*Creates NGF and the different indices of Forecasts from the Consensus Data
do "$csd_dir/Long_Term.do"

*Make the forecast index weights
do "$csd_dir/Forecast_RS.do"

*Make the Industrial Production weights
*do "$csd_dir/Industrial_Production.do"

* Build the tracking portfolios
do "$csd_dir/TrackingPortfolio.do"

*Run Regressions
do "$csd_dir/RigobonSack_v3.do"
