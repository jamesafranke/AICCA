using Plots, StatsPlots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

