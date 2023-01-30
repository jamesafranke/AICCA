###################################################################
### need to fix lat and lon in some era5 data 0-360 -> -180-180 ###
### and make date column for daily merge with classes           ###
### these files were created from the raw ncs in python         ###
###################################################################
using Arrow, CSV, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end


## lower tropospheric stability from ERA5 (700hpa potential temp - 1000hpa potential temp) ##
dfb = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_lts1.arrow") ) 
append!(dfb,  DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_lts2.arrow") ) )
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :lts
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.lts = convert.( Float16, dfb.lts )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/climate/era5_daily_lts.arrow", dfb)


## boundary layer height from ERA5 ##
dfb = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_blh.arrow") ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :blh
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.blh = convert.( Float16, dfb.blh )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/era5_daily_blh1.arrow", dfb)

## 925 hpa wind speed from ERA5 ##
dfb = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_u.arrow") ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :u
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.u = convert.( Float16, dfb.u )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/era5_daily_u.arrow", dfb)

dfb = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_v.arrow") ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :v
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.v = convert.( Float16, dfb.v )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/era5_daily_v.arrow", dfb)

dfb = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_w.arrow") ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :w
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.w = convert.( Float16, dfb.w )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/era5_daily_w.arrow", dfb)

## sea level pressure from  ERA5 ##
dfb = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_msl.arrow") ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :msl
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
dfb.msl = convert.( Float16, dfb.msl )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/era5_daily_msl.arrow", dfb)

## 925 hpa temp and sepecifc humidity from  ERA5 ##
dfs = DataFrame( Arrow.Table(  "./data/processed/climate/era5_daily_temp_925.arrow" ) )
dfs.lon = convert.(Float16, dfs.lon)
dfs.lat = convert.(Float16, dfs.lat)
dfs.t = convert.(Float16, dfs.t)
@transform! dfs :date=Date.(:time)
@select! dfs :date :lat :lon :t
@rtransform! dfs :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( joinpath(pwd(),"data/processed/climate/era5_daily_t.arrow"), dfs )


dfs = DataFrame( Arrow.Table( joinpath( pwd(), "data/processed/climate/raw/era5_daily_rh_925.arrow" ) ) )
dfs.lon = convert.(Float16, dfs.lon)
dfs.lat = convert.(Float16, dfs.lat)
dfs.q = convert.(Float16, dfs.q)
@transform! dfs :date=Date.(:time)
@select! dfs :date :lat :lon :q
@rtransform! dfs :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( joinpath(pwd(),"data/processed/climate/era5_daily_q.arrow"), dfs )

## era5 sst ##
dfs = DataFrame( Arrow.Table( "./data/processed/climate/raw/era5_daily_sst.arrow" ) )
dfs.lon = convert.(Float16, dfs.lon)
dfs.lat = convert.(Float16, dfs.lat)
dfs.sst = convert.(Float16, dfs.sst)
dropmissing!(dfs, :sst )
@rtransform! dfs :lon = :lon .> 180 ? :lon .- 360 : :lon
@transform! dfs :date=Date.(:time)
@select! dfs :date :lat :lon :sst
Arrow.write( "./data/processed/climate/era5_daily_sst.arrow", dfs )

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
fl = filter( contains("pr"), readdir( "./data/processed/climate/pr/" ) )
@showprogress for file in fl append!( df, DataFrame( Arrow.Table( "./data/processed/climate/$(file)" )  ) ) end
@transform! df :date=Date.(:time)
@select! df :date :lat :lon :pr
df.lat = convert.( Float16, df.lat )
df.lon = convert.( Float16, df.lon )
dropmissing!(df, :pr)
df.pr = convert.( Float32, df.pr )
Arrow.write(joinpath(pwd(),"data/processed/climate/imerg_daily_pr.arrow"), df)
df