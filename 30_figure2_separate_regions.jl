using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

round_step(x, step) = round(x / step) * step

df = DataFrame( Arrow.Table( "./data/processed/AICCA_with_climate_no_dec_2021.arrow" ) )
@select! df :Label :lat :lon :eis :t1000 :cloud_fraction
df = dropmissing(df, [:eis, :t1000] )

dft = @subset df :lat.>0 

dft = @subset df :lon.>-40 

dft = @subset df :lon.<-40
dft = @subset dft :lat.<0

dfc = @chain dft begin  
    @transform :xbin=round_step.(:t1000, 0.3) :ybin=round_step.(:eis, 0.35)
    @aside replace!(_.ybin, -0.0 => 0.0)
    @by [:xbin, :ybin, :Label] :counts=size(:Label)[1]
    @orderby :counts
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label) :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( _, dft, on=[:xbin, :ybin] )
    @rtransform :plotclass=:nonzeroclass
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>50
end

colorclass = [ 20, 36, 27, 40, 25, 23, 30, 24, 28, 35]
colors = cgrad(:vik, 10, categorical = true, rev = true) 
high = [1,2,3,4,5,6,7,8,9,11,12,17]

marksize = 2.7
scatter(size=(500,500), grid=false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    @df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.95, markercolor=colors[i], markerstrokewidth=0)
end

temp = @rsubset dfc :plotclass .∈ Ref(high)
@df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.5, markercolor=:lightgray, markerstrokewidth=0)

temp = @rsubset dfc :plotclass .∉ Ref(vcat(colorclass, high))
@df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.5, markercolor=:gray, markerstrokewidth=0)

xlims!(278, 303)
ylims!(-3, 26)
png("./figures/heatmap_eis_t1000_SP.png")


