using Plots, StatsPlots; gr(); Plots.theme(:default)
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
    @by [:xbin, :ybin] :maxclass=last(:Label)    end

df = @chain DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) ) begin
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    dropmissing([:xbin,:ybin])
    leftjoin(_, dfc, on =[:xbin, :ybin])
    @select :Label :Timestamp :lat :lon :maxclass :xbin :ybin     end

### get test set with distance to cluster center ###
dft = @chain DataFrame( Arrow.Table( "./data/processed/test_class_confidence.arrow" ) ) begin
    dropmissing(:timestamp)
    @transform :lat=floor.(:lat).+0.5 :lon=floor.(:lon).+0.5 :Timestamp=:timestamp
    leftjoin(_, df, on=[:Timestamp, :lat, :lon, :Label])      end

colorclass = [ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35]
colors = cgrad(:vik, 10, categorical=true, rev=true)
colorclass2 = [ 2, 8, 19]
colors2 = cgrad(:Cassatt2, 6, categorical=true, rev=true)

marksize = 2.7
plot( size=(500,500), grid = false, leg=false, dpi=900 )
for (i, class) in enumerate(colorclass)
    @df (@subset dfc :maxclass.==class) scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors[i], markerstrokewidth=0)
end
for (i, class) in enumerate(colorclass2)
    @df (@subset dfc :maxclass.==class) scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors2[i], markerstrokewidth=0)
end

temp = @rsubset dfc :maxclass .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
@df temp scatter!(:xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=:gray, markerstrokewidth=0)

scalef(x) = 15 ./ (x .- minimum(x) .+ 1)
@df (@subset dft :Label.==26) scatter!( :xbin, :ybin, markershape=:circle, markersize=scalef(cols(:d26)), markeralpha=0.6, markercolor=colors[5], markerstrokewidth=0.2, strokecolor=:black )
xlims!(283, 305)
ylims!(4, 34)
png("./figures/heatmap_26_class_purity.png")



Symbol("d$i")

temp = @subset dft :Label.==30
minimum(temp.d30)

temp = @subset dft :Label.==30
@transform! temp :t35=:d30-:d35 :t40=:d30-:d40
t1 = @subset temp :maxclass.==40 
t2 = @subset temp :maxclass.==35
mean(t1.d35)
mean(t2.d35)

mean(t1.t40)
mean(t2.t40)

(mean(t1.t35)-mean(t2.t35))./mean(t1.t35)
(mean(t1.t40)-mean(t2.t40))./mean(t1.t40)

t3 = @subset temp :maxclass.==30
mean(t3.d30)

t3 = @subset temp :maxclass.!=30
mean(t3.d30)


for (i, class) in enumerate(colorclass)
    temp = @subset dft :Label.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp[!,"d$(class)"]), markeralpha=0.7, markercolor=colors[i], markerstrokewidth=0)
end
for (i, class) in enumerate(colorclass2)
    temp = @subset dft :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp[!,"d$(class)"]), markeralpha=0.7, markercolor=colors2[i], markerstrokewidth=0)
end

xlims!(283, 305)
ylims!(4, 34)