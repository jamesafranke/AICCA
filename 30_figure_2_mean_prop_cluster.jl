using CSV
using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

df = CSV.read( "./data/processed/test_ctp.csv", DataFrame )
@select! df :lab2 :eis :t1000 
df = dropmissing(df, [:eis, :t1000] )

dfc = @chain df begin  
    @transform :xbin=round_step.(:t1000, 0.3) :ybin=round_step.(:eis, 0.35)
    @aside replace!(_.ybin, -0.0 => 0.0)
    @by [:xbin, :ybin, :lab2] :counts=size(:lab2)[1]
    @orderby :counts
    #@aside dft = @subset _ :Label.!=0 
    #@aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:lab2) :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:lab2) :maxcount=last(:counts) :total=sum(:counts)
    #leftjoin( _, dft, on=[:xbin, :ybin] )
    #@rtransform :plotclass=:nonzeroclass
    #@transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>2
end

temp = @by dfc :maxclass :num=size(:maxclass)[1]
temp = @orderby temp :num

colorclass = [ 4, 7, 5, 13, 18, 28, 29, 8, 15, 14]
colors = cgrad(:vik, 10, categorical = true, rev = true) 

marksize = 2.7
scatter(size=(500,500), grid=false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    @df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.95, markercolor=colors[i], markerstrokewidth=0)
end

temp = @rsubset dfc :maxclass .∉ Ref(colorclass)
@df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.5, markercolor=:gray, markerstrokewidth=0)

xlims!(278, 303)
ylims!(-3, 26)
png("./figures/heatmap_eis_t1000_mean.png")


