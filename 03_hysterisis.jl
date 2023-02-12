using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

round_step(x, step) = round(x / step) * step

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
df = dropmissing(df, [:sst, :lts] )

dft = DataFrame( Arrow.Table(  "./data/processed/transitions/all_transitions_SP.arrow", df ) )