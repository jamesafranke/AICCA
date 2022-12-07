using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics, Random, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    temp = @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100
    @transform! temp :region="np"
    append!( dfout, temp )
    temp = @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  
    @transform! temp :region="sp"
    append!( dfout, temp )
    temp = @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20 
    @transform! temp :region="sa"
    append!( dfout, temp )
    return dfout
end

df = DataFrame()
fl = filter( contains(".arrow"), readdir("./data/processed/cmip6_lts_cl/") )
@showprogress for file in fl 
    dft = DataFrame( Arrow.Table( "./data/processed/cmip6_lts_cl/$file" ) )
    splits = split(file, "_")
    @transform! dft :model=splits[1] :exp=splits[2] :realz=splits[3]
    @rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
    dft = get_subtrop(dft)
    dropmissing!(dft)
    append!( df, dft ) 
end

Arrow.write("./data/processed/cmip6_lts_cl.arrow", df)



df = DataFrame( Arrow.Table( "./data/processed/cmip6_lts_cl.arrow" ) )
@select! df :year :month :day :lat :lon :cl :lts :model :exp :realz
dfg = @by df [:model, :exp] :mean_cl=mean(:cl) :mean_lst=mean(:lts)  




df = get_subtrop(df)