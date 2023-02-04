using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )

top = @chain df begin
    @by :Label :size=size(:lat)[1]
    @orderby :size
    last(14)
    _.Label
end

temp = @rsubset df :Label in top

