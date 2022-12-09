using Plots; gr(); Plots.theme(:dark) #plotlyjs()
using Arrow, CSV, DataFrames, DataFramesMeta, Dates 
using Statistics, Random, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    temp = @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100
    append!( dfout, @transform temp :region="np" )
    temp = @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  
    append!( dfout, @transform temp :region="sp" )
    temp = @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20 
    append!( dfout, @transform temp :region="sa" )
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

df1 = @subset dfg :exp.=="piControl"
df2 = @subset dfg :exp.=="abrupt-4xCO2"
rename!(df2, :mean_cl=>:mean_cl2,  :mean_lst=>:mean_lst2, :exp=>:exp2)
leftjoin!(df1, df2, on=:model)

@transform! df1 :lts=:mean_lst2-:mean_lst :cl=:mean_cl2-:mean_cl
@transform! df1 :clp=:cl./:mean_cl *100
dfc = @select df1 :model :clp :cl

### reflectance ###
df = DataFrame( Arrow.Table( "./data/processed/cmip6_rsut_rsutcs.arrow" ) )
df = @subset df :lat.>-25 :lat.<25
#df = get_subtrop(df)
@transform! df :cr = :rsut-:rsutcs 
df = @by df [:model, :experiment] :mean_cr=mean(:cr)
df1 = @subset df :experiment.=="piControl"
df2 = @subset df :experiment.=="abrupt-4xCO2"
dfc = leftjoin(df1, df2, on=:model, makeunique=true)
@transform! dfc :cr=(:mean_cr.-:mean_cr_1)./:mean_cr * 100 


df = DataFrame( Arrow.Table( "./data/processed/cmip6_lts_cl.arrow" ) )
@select! df :year :month :day :lat :lon :cl :lts :model :exp :realz
dfg = @by df [:model, :exp] :total=size(:cl)[1]

df25 = @chain df begin
    @subset :lts .< 20
    @by [:model, :exp] :total25=size(:cl)[1]
end

df35 = @chain df begin
    @subset :lts .> 20
    @by [:model, :exp] :total35=size(:cl)[1]
end

leftjoin!(dfg, df25, on=[:model, :exp])
leftjoin!(dfg, df35, on=[:model, :exp])
@transform! dfg :per25=:total25./:total :per35=:total35./:total

df1 = @subset dfg :exp.=="piControl"
df2 = @subset dfg :exp.=="abrupt-4xCO2"
@transform! df1 :cf_adjust= ((:per35_1 - :per35) * 0.33) * 100

dfa = @select df1 :model :cf_adjust


dfe = CSV.read( "./data/processed/cmip6_gmt_pi_to_4x.csv", DataFrame ) 
#@by! dfe [:model, :experiment] mean(:tas)
df1 = @subset dfe :experiment.=="piControl"
df2 = @subset dfe :experiment.=="abrupt-4xCO2"
unique!(df2, [:model, :experiment])
leftjoin!(df1, df2, on=:model, makeunique=true)
@transform! df1 :eqs=(:tas_1 - :tas)/ 2
dfe = @select df1 :model :eqs
unique!(dfe, [:model])


df = leftjoin(dfc, dfa, on=:model)
leftjoin!(df, dfe, on=:model)
@transform! df :crp=:cr./:eqs :cfp=:cf_adjust./:eqs

@select! df :model :cr :cf_adjust :eqs
dropmissing!(df, [:cr, :eqs])

scatter( size=(400,400), grid = false, leg=false, dpi=900)
scatter!(df.cr*-1, df.eqs, marker_z=df.eqs, markershape = :circle, markersize = 5, markeralpha = 1,
markerstrokewidth = 1, markerstrokecolor=:black, color = cgrad(:Benedictus, rev=true))

scatter!(df.cf_adjust, df.eqs, markershape = :circle, markersize = 5, markeralpha = 0.0,
markerstrokewidth = 0, markerstrokecolor=:black, markercolor = :gray)

png("./figures/clouds_cmip6.png")