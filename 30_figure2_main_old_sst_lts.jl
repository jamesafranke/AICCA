using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

round_step(x, step) = round(x / step) * step

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
df = dropmissing(df, [:sst, :lts] )

dfc = @chain df begin  
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
temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.8, markercolor = :lightgray, 
    markerstrokewidth = 0.0, size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    scatter!( temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.85, 
    markercolor = colors[i], markerstrokewidth = 0)
end

for (i, class) in enumerate(colorclass2)
    temp = @subset dfc :plotclass.==class
    scatter!( temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.85, 
    markercolor = colors2[i], markerstrokewidth = 0)
end

temp = @rsubset dfc :plotclass .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
scatter!(temp.xbin, temp.ybin, markershape = :square, markersize =  marksize, markeralpha = 0.7, 
markercolor = :gray, markerstrokewidth = 0.00, markerstrokecolor=:gray )

xlims!(283, 305)
ylims!(4, 34)
png("./figures/heatmap_lts_sst.png")


dfc = @chain df begin 
    @subset :Label.!=0 
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    @transform :fracinbin=:maxcount./:total
    @subset :total.>20
end

scalef(x) = x.*13 #sqrt.(x.*100)/2.5
scatter( size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.fracinbin), 
    markeralpha = 0.9, markercolor=colors[i], markerstrokewidth=0)
end

for (i, class) in enumerate(colorclass2)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.fracinbin), 
    markeralpha = 0.9, markercolor=colors2[i], markerstrokewidth=0)
end

scatter!( [304,304,304,304], [33,31.5,30.4,29.5], markersize=[scalef(1), scalef(0.75), scalef(0.5), scalef(0.25)],
markershape=:circle, markeralpha=0.5, markercolor=:gray, markerstrokewidth=0)

xlims!(283, 305)
ylims!(4, 34)
png("./figures/heatmap_lts_sst_frac_in_bin.png")

scalef(x) = x ./ 300
scatter( size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.maxcount), 
    markeralpha = 0.9, markercolor=colors[i], markerstrokewidth=0)
end

for (i, class) in enumerate(colorclass2)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.maxcount), 
    markeralpha = 0.9, markercolor=colors2[i], markerstrokewidth=0)
end

scatter!( [304,304,304], [33,31.3,30], markersize=[scalef(3000), scalef(2000), scalef(1000)],
markershape=:circle, markeralpha=0.5, markercolor=:gray, markerstrokewidth=0)

xlims!(283, 305)
ylims!(4, 34)
png("./figures/heatmap_lts_sst_occurance.png")





dfc = @chain df begin  
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:Label)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label) :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( _, dft, on=[:xbin, :ybin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>20
end

temp = @chain df begin  
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:Label)[1]
end

dfc = leftjoin(dfc, temp, on=[:xbin, :ybin])
dfc = @by dfc [:plotclass, :Label] :total=sum(:counts)

Arrow.write( "./data/processed/histogram_plot_to_python.arrow", dfc )



dfc = @chain df begin  
    @subset :Label.!=0 
    @by [:lat, :lon, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @by [:lat, :lon] :maxclass=last(:Label)
end

Arrow.write( "./data/processed/geo_plot_no_zeros.arrow", dfc )



