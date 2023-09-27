using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

df = DataFrame( Arrow.Table( "./data/processed/AICCA_with_climate_no_dec_2021.arrow" ) )
@select! df :Label :lat :lon :eis :t1000 :cloud_fraction :lwp

nd = DataFrame( Arrow.Table( "./data/processed/2010_modis_nd_aqua.arrow" ) )
@transform! nd :platform="AQUA" :year=2010

df = dropmissing(df, [:eis, :t1000, :lwp] )



@transform! df :mdp=0.37*(:lwp/:nd)^1.75