using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )

dfc = @chain df begin  
    dropmissing( [:sst, :lts] )
    @transform :xbin=round_step.(:sst, 0.26) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label) :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( _, dft, on=[:xbin, :ybin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>20
end

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]

colorclass = [ 2, 8, 19, 21, 23, 24, 25, 26, 27, 28, 30, 34,  35, 36, 40]

otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:nord, 15, categorical = true)  #rev=true)
colors = cgrad(:roma, 15, categorical = true)
colors = cgrad(:berlin, 15, categorical = true)
colors = cgrad(:Hiroshige, 15, categorical = true)
colors = cgrad(:Iridescent, 15, categorical = true)

marksize = 2.7
temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.95, 
        markercolor = colors[i], markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

xlims!(283, 305)
ylims!(4, 34)
png("./figures/heatmap_lts_sst.png")















temp = @rsubset dfc :plotclass in otherclass
#scatter!(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.8, markercolor = :gray, 
    #markerstrokewidth = 1, markerstrokecolor= :gray )
temp = @by dfc :plotclass :test=size(:plotclass)[1]
@orderby temp :test


