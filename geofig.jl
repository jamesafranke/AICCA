using GeoMakie, CairoMakie
CairoMakie.activate!()
using CSV, DataFrames, DataFramesMeta, Dates 
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = CSV.read( joinpath(pwd(), "data/processed/all_subtropic_label_with_climate.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@subset! df :Label.!=43 
dfp = DataFrame()
append!(dfp,  @subset df :lat.>7  :lat.<39 :lon.>-165 :lon.<-100)
append!(dfp, @subset df :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70)
append!(dfp, @subset df :lat.>-35 :lat.<0  :lon.>-25  :lon.<20 )
df = nothing
dropmissing!(dfp, [:lts, :blh] )
#@transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4

dfc = @chain dfp begin  
    @by [:lat, :lon, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:lat, :lon] :nonzeroclass=last(:Label)
    @by [:lat, :lon] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:lat, :lon] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @subset :total.>50
end

colorclass = [25, 6, 27, 8, 40, 30, 32, 33, 36, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:Hiroshige, 10, categorical=true)

fig = Figure(resolution=(3000,1500), grid = false)
ga = GeoAxis( fig[1, 1]; dest = "+proj=eqc", coastlines=true, xgridvisible=false, ygridvisible=flase)
s = 12
temp = @subset dfc :plotclass.==0
scatter!(ga,temp.lon, temp.lat; color=:lightgray, markersize=s, marker=:rect, strokewidth=0)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    scatter!(ga,temp.lon, temp.lat; color=colors[i], markersize=s, marker=:rect, strokewidth=0)
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(ga,temp.lon, temp.lat; color=:gray, markersize=s, marker=:rect, strokewidth=0, grid=false)

save("./figures/figure2_map.png", fig, px_per_unit = 2) 