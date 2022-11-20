###################################################################
### need to fix lat and lon in some era5 data 0-360 -> -180-180 ###
### and make date column for daily merge with classes           ###
### these files were created from the raw ncs in python         ###
###################################################################
using Arrow, CSV, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

## hourly boundary layer height or lts from ERA5 ##
dfA =  DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim_all.arrow")) )
@transform! dfA :year=Year.(:date)

df = DataFrame()
@showprogress for year in 2000:2021
    dfi = DataFrame( Arrow.Table( joinpath( pwd(),"data/processed/blh/era5_$(year)_hourly_blh.arrow" ) ) )
    @transform! dfi :date=Date.(:time) :hour=Hour.(:time)
    @select! dfi :date :hour :lat :lon :blh
    rename!(dfi, :blh => :blhh)
    for col in eachcol(dfi) replace!( col, NaN => missing ) end
    dropmissing!(dfi)

    dfl = DataFrame( Arrow.Table( joinpath( pwd(),"data/processed/lts/era5_$(year)_hourly_lts.arrow" ) ) )
    @transform! dfl :date=Date.(:time) :hour=Hour.(:time)
    @select! dfl :date :hour :lat :lon :lts
    rename!(dfl, :lts => :ltsh)
    for col in eachcol(dfl) replace!( col, NaN => missing ) end
    dropmissing!(dfl)

    dftemp = @subset dfA :year .== Year(year)
    leftjoin!(dftemp, dfi, on = [:date, :hour, :lat, :lon] ) 
    leftjoin!(dftemp, dfl, on = [:date, :hour, :lat, :lon] ) 
    append!(df, dftemp )

    dftemp = nothing
    dfi = nothing
    dfl = nothing
end

select!(df, Not([:year]))
Arrow.write(joinpath(pwd(),"data/processed/subtropic_sc_label_hourly_clim.arrow"), df)



## lower tropospheric stability from ERA5 (700hpa potential temp - 1000hpa potential temp) ##
dfl = CSV.read( joinpath(pwd(),"data/processed/era5_daily_lts.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfl :date=Date.(:time)
@select! dfl :date :lat :lon :lts
dfl.lon = convert.( Float16, dfl.lon )
dfl.lat = convert.( Float16, dfl.lat )
dfl.lts =convert.( Float16, dfl.lts )
@rtransform! dfl :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write(joinpath(pwd(),"data/processed/era5_daily_lts_tropics.arrow"), dfl)

## boundary layer height from ERA5 ##
dfb = CSV.read( joinpath(pwd(),"data/processed/era5_daily_blh.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :blh
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.blh = convert.( Float16, dfb.blh )
dftemp = @subset dfb :lon.>180
dftemp.lon .-= 360
@subset! dfb :lon.<180
append!( dfb, dftemp )
dftemp = nothing
Arrow.write(joinpath(pwd(),"data/processed/era5_daily_blh_tropics.arrow"), dfb)

## 925 hpa wind speed from ERA5 ##
dfb = CSV.read( joinpath(pwd(),"data/processed/era5_ws.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :u :v
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.u = convert.( Float16, dfb.u )
dfb.v = convert.( Float16, dfb.v )
dftemp = @subset dfb :lon.>180
dftemp.lon .-= 360
@subset! dfb :lon.<180
append!( dfb, dftemp )
dftemp = nothing
Arrow.write(joinpath(pwd(),"data/processed/era5_daily_ws_tropics.arrow"), dfb)

## 925 hpa temp and sepecifc humidity from  ERA5 ##
dfs = DataFrame( Arrow.Table( joinpath( pwd(), "data/processed/era5_daily_temp_rh_925.arrow" ) ) )
dfs.lon = convert.(Float16, dfs.lon)
dfs.lat = convert.(Float16, dfs.lat)
dfs.t = convert.(Float16, dfs.t)
dfs.q = convert.(Float16, dfs.q)
@transform! dfs :date=Date.(:time)
@select! dfs :date :lat :lon :t :q
dftemp = @subset dfs :lon.>180
dftemp.lon .-= 360
@subset! dfs :lon.<180
append!( dfs, dftemp )
dftemp = nothing
Arrow.write( joinpath(pwd(),"data/processed/era5_daily_t_q.arrow"), dfs )

## era5 sst ##
dfs = DataFrame( Arrow.Table( joinpath( pwd(), "data/processed/era5_daily_sst.arrow" ) ) )
dfs.lon = convert.(Float16, dfs.lon)
dfs.lat = convert.(Float16, dfs.lat)
dfs.sst = Array(dfs.sst)
dfs.time = Array(dfs.time)
dropmissing!(dfs, :sst )
dfs.sst = convert.(Float16, dfs.sst)
dftemp = @subset dfs :lon.>180
dftemp.lon .-= 360
@subset! dfs :lon.<180
append!( dfs, dftemp )
@transform! dfs :date=Date.(:time)
@select! dfs :date :lat :lon :sst
Arrow.write( joinpath(pwd(),"data/processed/era5_daily_sst3.arrow"), dfs )

## AOT from AHVRR satellite ##
df1 = CSV.read( joinpath( pwd(),    "data/processed/2002_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
append!(df1, CSV.read( joinpath(pwd(), "data/processed/2009_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) )
append!(df1, CSV.read( joinpath(pwd(), "data/processed/2010_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) )
append!(df1, CSV.read( joinpath(pwd(), "data/processed/2021_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) )
df1.lat = convert.( Float16, df1.lat )
df1.lon = convert.( Float16, df1.lon )
df1.aot1 = convert.( Float16, df1.aot1 )

@transform! df1 :date=Date.(:time)
@select! df1 :date :lat :lon :aot1
df1 = @by df1 [:date, :lat, :lon] :aot =mean(:aot1)
Arrow.write(joinpath(pwd(),"data/processed/aot_daily.arrow"), df1)

### IMERG PR ###
df = DataFrame()
fl = filter( !contains(".DS"), readdir( joinpath(pwd(), "data/processed/pr/") ) )
for file in fl append!( df, DataFrame( Arrow.Table( joinpath( pwd(),"data/processed/pr/", file ) ) ) ) end
@transform! df :date=Date.(:time)
@select! df :date :lat :lon :pr
df.lat = convert.( Float16, df.lat )
df.lon = convert.( Float16, df.lon )
dropmissing!(df, :pr)
df.pr = convert.( Float32, df.pr )
Arrow.write(joinpath(pwd(),"data/processed/imerg_pr_daily.arrow"), df)
