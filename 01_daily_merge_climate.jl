using CSV, DataFrames, DataFramesMeta, Dates 
if occursin("AICCA", pwd()) == false cd("AICCA") else end

## Load in the class data (from only the tropics) and merge with # merge class data with sst, lst, subsidence, and aerosol optical ##
path = joinpath(pwd(),"data/processed/subtropic/")
fl = filter( !contains(".DS"), readdir(path) )
df = DataFrame()
for i in fl append!( df, CSV.read( joinpath(path, i), dateformat="yyyy-mm-dd HH:MM:SS", DataFrame ) ) end
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5
@select! df :Timestamp :lat :lon :Label :platform
@transform! df :date=Date.(:Timestamp)

## lower tropospheric stability from ERA5 (700hpa potential temp - 1000hpa potential temp) ##
dfl = CSV.read( joinpath(pwd(),"data/processed/era5_daily_lts.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfl :date=Date.(:time)
@select! dfl :date :lat :lon :lts
dftemp = @subset dfl :lon.>180
dftemp.lon .-= 360
@subset! dfl :lon.<180
append!( dfl, dftemp )
dftemp = nothing
leftjoin!( df, dfl, on = [:date, :lat, :lon] ) 
dfl = nothing

## boundary layer height from ERA5 ##
dfb = CSV.read( joinpath(pwd(),"data/processed/era5_daily_blh.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfb :date=Date.(:time)
@select! dfb :date :lat :lon :blh
dftemp = @subset dfb :lon.>180
dftemp.lon .-= 360
@subset! dfb :lon.<180
append!( dfb, dftemp )
dftemp = nothing
leftjoin!( df, dfb, on = [:date, :lat, :lon] ) 
dfl = nothing

## AOT from AHVRR satellite ##
#dfa = CSV.read( joinpath(pwd(),"data/processed/avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
#@transform! dfa :date=Date.(:time)
#@select! dfa :date :lat :lon :aot1
#leftjoin!( df, dfa, on = [:year, :day, :lat, :lon] )
#dfa = nothing

## write dataframe with lable, sst, aot, and w to csv ##
@select! df :Timestamp :lat :lon :Label :platform :lts :blh :aot1 
df = @orderby df :Timestamp
CSV.write( joinpath(pwd(),"data/processed/all_subtropic_label_climate_day.csv" ), df, index = false)

