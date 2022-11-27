using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
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
append!(df, Arrow.Table( "./data/processed/cmip6_bl/zmla_CESM2_1pctCO2_r1i1p1f1.nc4.arrow") )
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
df = get_subtrop(df)
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5

dft = DataFrame()
fl = filter( contains("ta_day"), readdir("./data/processed/cmip6_bl/") )
for file in fl
    append!( dft, Arrow.Table( "./data/processed/cmip6_bl/$file" ) ) 
end
@rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
dft = get_subtrop(dft)
dft.lat = floor.(dft.lat) .+ 0.5
dft.lon = floor.(dft.lon) .+ 0.5

innerjoin!( df, dft, on = [:year, :month, :day, :lat, :lon] )
rename!(df, :zmla=>:blh)
Arrow.write(joinpath(pwd(),"data/processed/CESM2.arrow"), df)


dft = @chain df begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :counts=size(:lat)[1]
end