

global GDP_models vecm consensus consensus03 consensus6m consensus036m

*Make the Dividend VAR indices
do "$csd_dir/DivMaker4.do"

*Creates NGF and the different indices of Forecasts from the Consensus Data
do "$csd_dir/Long_Term.do"

*Make the forecast index weights
do "$csd_dir/Forecast_RS.do"

*Run Regressions
do "$csd_dir/RigobonSack_v3.do"
