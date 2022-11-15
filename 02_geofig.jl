using GeoMakie, CairoMakie
CairoMakie.activate!()
using Arrow, DataFrames, DataFramesMeta, Dates
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim_all.arrow")) )

dfc = @chain df begin  
    @by [:lat, :lon, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:lat, :lon] :nonzeroclass=last(:Label)
    @by [:lat, :lon] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:lat, :lon] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @subset :total.>50
end

#using CSV
#CSV.write("geo_plot_test.csv", dfc, index=false)

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:roma, 10, categorical = true)

fig = Figure(resolution=(3000,1500))
ga = GeoAxis( fig[1, 1], dest = "+proj=eqc +lon_0=-80", coastlines=true) #lonticks = -180:360:180, latticks =  -90:180:90,
s = 12
temp = @subset dfc :plotclass.==0
scatter!(ga,temp.lon, temp.lat; color=:lightgray, markersize=s, marker=:rect, strokewidth=0)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    scatter!(ga,temp.lon, temp.lat; color=colors[i], markersize=s, marker=:rect, strokewidth=0.5)
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(ga,temp.lon, temp.lat; color=:gray, markersize=s, marker=:rect, strokewidth=0 )
save("./figures/figure2_map_roma.png", fig, px_per_unit = 2) 


