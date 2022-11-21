using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table("./data/processed/subtropic_with_clim_and_isccp.arrow" ))


colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:roma, 10, categorical = true)

dfc = @chain df begin 
    dropmissing( [:blh, :lts] ) 
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)  :totalnozero=sum(:counts)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>100
end

marksize = 3.7
temp = @subset dfc :plotclass.==0
scatter(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
        markersize = marksize, markeralpha = 0.9, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 1, markerstrokecolor= :gray )

xlims!(5, 32.25)
ylims!(0, 2000)
png("./figures/heatmap_day.png")
