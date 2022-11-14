using Arrow, CSV, DataFrames, DataFramesMeta, Dates 
if occursin("AICCA", pwd()) == false cd("AICCA") else end

## lower tropospheric stability from ERA5 (700hpa potential temp - 1000hpa potential temp) ##
dfl = CSV.read( joinpath(pwd(),"data/processed/era5_daily_lts.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfl :date=Date.(:time)
@select! dfl :date :lat :lon :lts
dfl.lon = convert.( Float16, dfl.lon )
dfl.lat = convert.( Float16, dfl.lat )
dfl.lts =convert.( Float16, dfl.lts )
dftemp = @subset dfl :lon.>180
dftemp.lon .-= 360
@subset! dfl :lon.<180
append!( dfl, dftemp )
dftemp = nothing
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


## AOT from AHVRR satellite ##
df1 = CSV.read( joinpath(pwd(),"data/processed/2002_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
append!(df1, CSV.read( joinpath(pwd(),"data/processed/2009_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ))
append!(df1, CSV.read( joinpath(pwd(),"data/processed/2010_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ))
append!(df1, CSV.read( joinpath(pwd(),"data/processed/2021_avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ))
df1.lat = convert.( Float16, df1.lat )
df1.lon = convert.( Float16, df1.lon )
df1.aot1 = convert.( Float16, df1.aot1 )
@transform! df1 :date=Date.(:time)
@select! df1 :date :lat :lon :aot1
Arrow.write(joinpath(pwd(),"data/processed/aot_daily_arrow"), df1)


