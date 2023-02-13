using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

### get dominant bins ###
dfc = @chain DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) ) begin  
    @subset :Label.!=0
    dropmissing( [:sst, :lts] )
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
dft = DataFrame( Arrow.Table(  "./data/processed/transitions/all_transitions_SP.arrow") )
dft.lon = convert.( Float16, floor.(dft.lon) .+ 0.5 )
dft.lat = convert.( Float16, floor.(dft.lat) .+ 0.5 )
rename!(dft, :time_0=>:Timestamp)
@select! dft :Timestamp :lat :lon :id :next_label :next_id :hours 

df = leftjoin(df,dft, on=[:Timestamp, :lat, :lon])
@transform! df :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
@select! df :Label :id :next_id :xbin :ybin
dropmissing!(df)
df = leftjoin(df,dfc, on =[:xbin, :ybin])
df2 = copy(df)
@select! df :Label :id :maxclass
@select! df2 :Label :next_id :maxclass
rename!(df2, :next_id=>:id)
df = leftjoin(df, df2, on=:id, makeunique=true)
dropmissing!(df)



temp = @subset df :Label.==35 :maxclass_1.==30

temp = @subset df :Label.==30 :maxclass_1.==35

histogram(temp.Label_1, bins=1:42)