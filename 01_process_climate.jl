###################################################################
### need to fix lat and lon in some era5 data 0-360 -> -180-180 ###
### and make date column for daily merge with classes           ###
### these files were created from the raw ncs in python         ###
###################################################################
using Arrow, CSV, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end
include("00_helper.jl")

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
dfb = DataFrame( Arrow.Table( "./data/processed/era5_daily_blh.arrow") ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :blh
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/climate/era5_daily_blh.arrow", dfb)

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
dfb = DataFrame( Arrow.Table( "./data/processed/era5_daily_msl.arrow") ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :msl
dfb.lon = convert.( Float16, dfb.lon )
dfb.lat = convert.( Float16, dfb.lat )
@rtransform! dfb :lon = :lon .> 180 ? :lon .- 360 : :lon
Arrow.write( "./data/processed/climate/era5_daily_msl.arrow", dfb)

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


### IMERG PR ###
df = DataFrame()
fl = filter( contains("pr"), readdir( "./data/processed/climate/pr/" ) )
@showprogress for file in fl append!( df, DataFrame( Arrow.Table( "./data/processed/climate/pr/$(file)" )  ) ) end
@transform! df :date=Date.(:time)
@select! df :date :lat :lon :pr
df.lat = convert.( Float16, df.lat )
df.lon = convert.( Float16, df.lon )
dropmissing!(df, :pr)
df.pr = convert.( Float32, df.pr )
Arrow.write("./data/processed/climate/imerg_daily_pr.arrow", df)


## AOT from AHVRR satellite ##
df = DataFrame()
fl = filter( contains("aot"), readdir( "./data/processed/climate/aot/" ) )
@showprogress for file in fl append!( df, DataFrame( Arrow.Table( "./data/processed/climate/aot/$(file)" )  ) ) end
@transform! df :date=Date.(:time)
@select! df :date :lat :lon :aot
df.lat = convert.( Float16, df.lat )
df.lon = convert.( Float16, df.lon )
dropmissing!(df, :aot)
df.aot = convert.( Float32, df.aot )
Arrow.write("./data/processed/climate/avhrr_daily_aot.arrow", df)


## wave height from era5 ##
df = DataFrame()
fl = filter( contains("swh"), readdir( "./data/processed/climate/swh/" ) )
@showprogress for file in fl append!( df, DataFrame( Arrow.Table( "./data/processed/climate/swh/$(file)" )  ) ) end
@transform! df :date=Date.(:time)
@select! df :date :lat :lon :swh
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
dropmissing!(df, :swh)
unique!(df)
Arrow.write("./data/processed/climate/era5_daily_swh.arrow", df)


### EIS estimated inversion strenght ###
df1 = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_t_1000.arrow" ) )
@select! df1 :time :lat :lon :t
rename!( df1, :t=>:t1000 )
df7 = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_t_700.arrow" ) )
rename!( df7, :t=>:t700 )
@transform! df1 :t700=df7.t700
df1.lon = convert.( Float16, df1.lon )
df1.lat = convert.( Float16, df1.lat )

@rtransform! df1 :lon = :lon .> 180 ? :lon .- 360 : :lon
df1 = get_subtrop( df1 )
dropmissing!(df1)

@transform! df1 :eis=EIS.(:t1000, :t700) :date=Date.(:time)
@select! df1 :date :lat :lon :eis
 
Arrow.write("./data/processed/climate/era5_daily_eis.arrow", df1)