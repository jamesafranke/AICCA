using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics, Random
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table("./data/processed/subtropic_sc_label_daily_clim.arrow") )

dfc = @chain df begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)  :totalnozero=sum(:counts)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass = :maxcount/:total>0.33 ? :maxclass : :nonzeroclass 
end

@select! dfc :ltsbin :blhbin :plotclass
df = nothing


df = DataFrame( Arrow.Table( "./data/processed/cmip6_bl/zmla_CESM2_piControl_r1i1p1f1_.nc4.arrow") )
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
df = get_subtrop(df)
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5
unique!(df)
unique!(df, [:year, :month, :day, :lat, :lon])

df = df[shuffle(1:size(df)[1])[1:10_000_000],:]

dft = DataFrame()
fl = filter( contains("ta_day_CESM2_piControl"), readdir("./data/processed/cmip6_bl/") )
for file in fl append!( dft, Arrow.Table( "./data/processed/cmip6_bl/$file" ) ) end
@rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
dft = get_subtrop(dft)
dft.lat = floor.(dft.lat) .+ 0.5
dft.lon = floor.(dft.lon) .+ 0.5
dropmissing!(dft)
unique!(dft, [:year, :month, :day, :lat, :lon])


leftjoin!( df, dft, on = [:year, :month, :day, :lat, :lon] )
rename!(df, :zmla=>:blh)
dropmissing!(df)
Arrow.write("./data/processed/CESM2_piControl.arrow", df)


df = DataFrame( Arrow.Table(  "./data/processed/cmip6_bl/zmla_CESM2_1pctCO2_r1i1p1f1.nc4.arrow") )
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
df = get_subtrop(df)
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5
unique!(df)
unique!(df, [:year, :month, :day, :lat, :lon])

df = df[shuffle(1:size(df)[1])[1:10_000_000],:]

dft = DataFrame()
fl = filter( contains("ta_day_CESM2_1pct"), readdir("./data/processed/cmip6_bl/") )
for file in fl append!( dft, Arrow.Table( "./data/processed/cmip6_bl/$file" ) ) end
@rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
dft = get_subtrop(dft)
dft.lat = floor.(dft.lat) .+ 0.5
dft.lon = floor.(dft.lon) .+ 0.5
dropmissing!(dft)
unique!(dft, [:year, :month, :day, :lat, :lon])

leftjoin!( df, dft, on = [:year, :month, :day, :lat, :lon] )
rename!(df, :zmla=>:blh)
dropmissing!(df)
Arrow.write("./data/processed/CESM2_1pct.arrow", df)


df1 = DataFrame( Arrow.Table( "./data/processed/CESM2_piControl.arrow" ) )
df2 = DataFrame( Arrow.Table( "./data/processed/CESM2_1pct.arrow" ) )


df1 = @chain df1 begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :counts_pi=size(:lat)[1]
end

df2 = @chain df2 begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :counts_1pct=size(:lat)[1]
end

leftjoin!(dfc, df1, [:ltsbin :blhbin])
leftjoin!(dfc, df2, [:ltsbin :blhbin])

temp = @subset dfc :plotclass.==35
sum(temp.counts_pi)
sum(temp.counts_1pct)



dfc = @chain df begin
    @by [:ltsbin, :blhbin] :counts=size(:aot1)[1]
    @subset :counts.>10
    @orderby :ltsbin
    unstack( :blhbin, :ltsbin, :counts)
    @orderby :blhbin 
    select( Not(:blhbin) )
    Array()
end

contourf(dfc, size=(600,600), grid = false, dpi=900, color = :viridis)
xlims!(0, 31)
ylims!(0, 35)
png("./figures/heatmap_aot_high.png")