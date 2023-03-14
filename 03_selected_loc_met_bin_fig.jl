using Plots, StatsPlots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

df = DataFrame( Arrow.Table( "./data/processed/oct_animation_hourly_lts_sst.arrow" ) )
@transform! df :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
@select! df :time :latitude :longitude :xbin :ybin 
df = @subset df :xbin.!=-0.0 :ybin.!=-0.0
met = DataFrame( Arrow.Table( "./data/processed/to_python_subtrop_met_bins.arrow" ) )
leftjoin!(df, met, on =[:xbin,:ybin])

@subset! df Date.(:time).==Date("2020-10-26") :latitude.<0 :latitude.>-7 :longitude.<-92 :longitude.>-108

dfc = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )

dfc = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
dfc = dropmissing(dfc, [:sst, :lts] )

dfc = @chain dfc begin  
    @subset :Label.!=0
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label) :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( _, dft, on=[:xbin, :ybin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>20
end

colorclass = [ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35]
colors = cgrad(:vik, 10, categorical = true, rev = true)
colorclass2 = [ 2, 8, 19]
colors2 = cgrad(:Cassatt2, 6, categorical = true, rev=true)

marksize = 2.7
plot( size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors[i], markerstrokewidth=0)
end

for (i, class) in enumerate(colorclass2)
    temp = @subset dfc :plotclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors2[i], markerstrokewidth=0)
end

temp = @rsubset dfc :plotclass .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
scatter!(temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=:gray, markerstrokewidth=0)

for (i, class) in enumerate(colorclass)
    temp = @subset df :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=marksize, markeralpha=0.7, markercolor=colors[i], markerstrokewidth=0)
end

for (i, class) in enumerate(colorclass2)
    temp = @subset df :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=marksize, markeralpha=0.7, markercolor=colors2[i], markerstrokewidth=0)
end

temp = @rsubset df :maxclass .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
scatter!(temp.xbin, temp.ybin, markershape=:circle, markersize=marksize, markeralpha=0.7, markercolor=:gray, markerstrokewidth=0)

xlims!(283, 305)
ylims!(4, 34)

