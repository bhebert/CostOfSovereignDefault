
* Setup paths-- in case it hasn't been done yet.
do ${csd_dir}/SetupPaths.do

global GDP_models gdp_var ip_var gdp_dols ip_dols gdp_con1y gdp_con6m ip_con1y ip_con6m gdp_tracking ip_tracking

* Build the data for VAR/tracking/consensus
do "$csd_dir/DivMakerNew.do"

*Make the Dividend VAR indices
do "$csd_dir/VarRunner.do"

*Creates NGF and the different indices of Forecasts from the Consensus Data
do "$csd_dir/Long_Term.do"

*Make the forecast index weights
do "$csd_dir/Forecast_RSNew.do"

*Make the Industrial Production weights
*do "$csd_dir/Industrial_Production.do"

* Build the tracking portfolios
do "$csd_dir/TrackingPortfolio.do"

*Run Regressions
do "$csd_dir/RigobonSack_v3.do"
