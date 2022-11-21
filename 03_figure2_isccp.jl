using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table("./data/processed/subtropic_with_clim_and_isccp.arrow" ))

colorclass = ["ci","cs","dc","ac","as","ns","c","sc","s"]
colors = cgrad(:roma, 9, categorical = true)

dfc = @chain df begin 
    dropmissing( [:blh, :lts] ) 
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin, :isccp] :counts=size(:lat)[1]
    @orderby :counts
    @by [:ltsbin, :blhbin] :maxclass=last(:isccp) :maxcount=last(:counts) :total=sum(:counts)
    @subset :total.>100
end

marksize = 3.7
scatter(markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :square,  markersize = marksize, markeralpha = 0.9, 
        markercolor = colors[i], markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

xlims!(5, 32.25)
ylims!(0, 2000)
png("./figures/heatmap_day_isccp.png")




dfs = dropmissing(df, [:w, :sst] )

dfc = @chain dfs begin  
    @transform :xbin=round.(:sst./2, digits=1)*2 :ybin=round.(:w./2, digits=2)*2
    @aside replace!(_.ybin, -0.0 => 0.0)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    @subset :total.>100
end

marksize = 3.7
scatter(markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    if size(temp)[1] > 0
        scatter!( temp.xbin, temp.ybin, markershape = :square,  markersize = marksize, markeralpha = 0.9, 
        markercolor = colors[i], markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

#xlims!(284, 304)
#ylims!(-1.2, 0.6)
png("./figures/heatmap_day_isccp_w_s.png")



