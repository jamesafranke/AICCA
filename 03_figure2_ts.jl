using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( joinpath(pwd(),"./data/processed/subtropic_sc_label_hourly_clim.arrow")) )

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:roma, 10, categorical = true)


dfc = @subset df :lat.==29.5 :lon.==-130.5
@subset! dfc :date.>Date(2005,1,1) :date.<Date(2006,6,1)
scatter(size=(800,500), grid = false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :Label.==class
    scatter!( temp.date, temp.lts, markershape = :circle,
    markersize = 5, markeralpha = 0.8, markercolor = colors[i], 
    markerstrokewidth = 0, markerstrokecolor=:black)
end

ylims!(5, 30)
png("./figures/sa_ts.png")


dfc = @subset df :lat.==-29.5 :lon.==7.5
@subset! dfc :date.>Date(2017,06,1) :date.<Date(2019,1,1)
scatter(size=(800,500), grid=false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :Label.==class
    scatter!( temp.date, temp.lts, markershape = :circle,
    markersize = 5, markeralpha = 0.8, markercolor = colors[i], 
    markerstrokewidth = 0, markerstrokecolor=:black)
end

ylims!(5, 30)
png("./figures/sa_ts.png")


dfc = @subset df :lat.==-18.5 :lon.==-80.5
@subset! dfc :date.>Date(2017,06,1) :date.<Date(2019,1,1)
scatter(size=(800,500), grid = false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :Label.==class
    scatter!( temp.date, temp.lts, markershape = :circle,
    markersize = 5, markeralpha = 0.8, markercolor = colors[i], 
    markerstrokewidth = 0, markerstrokecolor=:black)
end

ylims!(5, 30)
png("./figures/sp_ts.png")