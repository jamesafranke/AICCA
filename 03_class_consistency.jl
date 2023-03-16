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
    @by [:xbin, :ybin] :maxclass=last(:Label)
end

df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
@transform! df :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
df = dropmissing(df, [:xbin,:ybin])
leftjoin!(df, dfc, on =[:xbin, :ybin])
@select! df :Label :Timestamp :lat :lon :maxclass :xbin :ybin

dft = DataFrame( Arrow.Table( "./data/processed/test_class_confidence.arrow" ) )
dft = dropmissing(dft, :timestamp)
@transform! dft :lat=floor.(:lat).+0.5 :lon=floor.(:lon).+0.5 :Timestamp=:timestamp
leftjoin!(dft, df, on=[:Timestamp, :lat, :lon, :Label])

colorclass = [ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35]
colors = cgrad(:vik, 10, categorical = true, rev = true)
colorclass2 = [ 2, 8, 19]
colors2 = cgrad(:Cassatt2, 6, categorical = true, rev=true)

marksize = 2.7
plot( size=(500,500), grid = false, leg=false, dpi=900)
for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors[i], markerstrokewidth=0)
end
for (i, class) in enumerate(colorclass2)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors2[i], markerstrokewidth=0)
end

temp = @rsubset dfc :maxclass .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
scatter!(temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=:gray, markerstrokewidth=0)


scalef(x) = x .* 1
    
for (i, class) in enumerate(colorclass)
    temp = @subset dft :Label.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp[!,"d$(class)"]), markeralpha=0.7, markercolor=colors[i], markerstrokewidth=0)
end
for (i, class) in enumerate(colorclass2)
    temp = @subset dft :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp["d$(class)"]), markeralpha=0.7, markercolor=colors2[i], markerstrokewidth=0)
end

xlims!(283, 305)
ylims!(4, 34)


class = 10
temp[!,"d$(class)"]


temp = @subset dft :Label.==35

temp.xbin


scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=10, markeralpha=0.7, markercolor=:black, markerstrokewidth=0)
