using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

round_step(x, step) = round(x / step) * step

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( "./data/raw/AICCA_with_climate1.arrow" ) )
df2 = DataFrame( Arrow.Table( "./data/raw/AICCA_with_climate2.arrow" ) )
append!(df,df2)
df = @rsubset df Year.(:Timestamp).!=Year(2021) || Month.(:Timestamp).!=Month(12) || :platform.!="AQUA" #Date.(:Timestamp) ∉ Date(2021,12,10):Day(1):Date(2021,12,31)
Arrow.write( "./data/processed/AICCA_with_climate_no_dec_2021.arrow", df )
##################

df = DataFrame( Arrow.Table( "./data/processed/AICCA_with_climate_no_dec_2021.arrow" ) )
@select! df :Label :lat :lon :eis :t1000 :cloud_fraction
df = dropmissing(df, [:eis, :t1000] )

df = @subset df :Label.!=0

8166479 / 19263919 

13041513 / 16623106

temp = @subset df :Label .> 11

@rsubset df :Label .∈ Ref([20, 36, 27, 40, 25, 23, 30, 24, 28, 35])

unique(temp.Label)

dfc = @chain df begin  
    @transform :xbin=round_step.(:t1000, 0.3) :ybin=round_step.(:eis, 0.35)
    @aside replace!(_.ybin, -0.0 => 0.0)
    @by [:xbin, :ybin, :Label] :counts=size(:Label)[1]
    @orderby :counts
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label) :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( _, dft, on=[:xbin, :ybin] )
    #@rtransform :plotclass= :maxcount/:total>0.5 ? :maxclass : :nonzeroclass 
    @rtransform :plotclass=:nonzeroclass
    @transform :fracinbin=:maxcount./:totalnozero
    #@subset :total.>50
end
Arrow.write( "./data/processed/to_python_subtrop_met_bins_1000_eis.arrow", dfc )

### to find most plotting classes for colorlcass list ###
temp = @by dfc :plotclass :num=size(:nonzeroclass)[1]
temp = @orderby temp :num
### low clouds, ordered by optical thickness
temp = @by df :Label :opt=mean(skipmissing(:cloud_fraction))
temp = @rsubset temp :Label .∈ Ref(colorclass)
temp = @orderby temp :opt
######

colorclass = [ 20, 36, 27, 40, 25, 23, 30, 24, 28, 35]
colors = cgrad(:vik, 10, categorical = true, rev = true) 
#colors = cgrad(:OKeeffe1, 10, categorical = true)
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
png("./figures/heatmap_eis_t1000.png")

dfc = @chain df begin 
    @subset :Label.!=0 
    @transform :xbin=round_step.(:t1000, 0.3) :ybin=round_step.(:eis, 0.35)
    @by [:xbin, :ybin, :Label] :counts=size(:Label)[1]
    @orderby :counts rev=true
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    @transform :fracinbin=:maxcount./:total
    @subset :total.>50
end

dfc = 1

scalef(x) = x.*13 #sqrt.(x.*100)/2.5
scatter( size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.fracinbin), 
    markeralpha = 0.9, markercolor=colors[i], markerstrokewidth=0)
end


scatter!( [301,301,301,301], [33,31.5,30.4,29.5].-8, markersize=[scalef(1), scalef(0.75), scalef(0.5), scalef(0.25)],
markershape=:circle, markeralpha=0.5, markercolor=:gray, markerstrokewidth=0)

xlims!(278, 303)
ylims!(-3, 26.5)
png("./figures/heatmap_eis_lts_frac_in_bin.png")

scalef(x) = x ./ 300
scatter( size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.maxcount), 
    markeralpha = 0.9, markercolor=colors[i], markerstrokewidth=0)
end

scatter!( [301,301,301], [33,31.3,30].-8, markersize=[scalef(3000), scalef(2000), scalef(1000)],
markershape=:circle, markeralpha=0.5, markercolor=:gray, markerstrokewidth=0)

xlims!(278, 303)
ylims!(-3, 26.5)
png("./figures/heatmap_eis_t1000_occurance.png")



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
    @select :Label :lat :lon
    dropmissing() 
    @subset :Label.!=0 
    @transform :lat=round_step.(:lat, 1) :lon=round_step.(:lon, 1)
    @by [:lat, :lon, :Label] :counts=size(:lat)[1]
    @orderby :counts
    @by [:lat, :lon] :maxclass=last(:Label)
end

Arrow.write( "./data/processed/geo_plot_no_zeros.arrow", dfc )



