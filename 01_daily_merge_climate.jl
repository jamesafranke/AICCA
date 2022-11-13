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
@transform! df :year=Year.(:Timestamp) :day=Dayofyear.(:Timestamp)

## lower tropospheric stability from ERA5 (700hpa potential temp - 1000hpa potential temp) ##
dfl = CSV.read( joinpath(pwd(),"data/processed/era5_lts.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfl :year=Year.(:time) :day=Dayofyear.(:time)
@select! dfl :year :day :lat :lon :lts
dftemp = @subset dfl :lon.>180
dftemp.lon .-= 360
@subset! dfl :lon.<180
append!( dfl, dftemp )

## Monthly boundary layer height from ERA5 ##
dfb = CSV.read( joinpath(pwd(),"data/processed/era5_blh.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfb :year=Year.(:time) :day=Dayofyear.(:time)
@select! dfb :year :day :lat :lon :blh
dftemp = @subset dfb :lon.>180
dftemp.lon .-= 360
@subset! dfb :lon.<180
append!( dfb, dftemp )

## Monthly AOT from AHVRR satellite ##
#dfa = CSV.read( joinpath(pwd(),"data/processed/avhrr_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
#@transform! dfa :year=Year.(:time) :day=Dayofyear.(:time)
#@select! dfa :year :day :lat :lon :aot1

## join em all up by location, month, and year ##
leftjoin!( df, dfl, on = [:year, :day, :lat, :lon] )
leftjoin!( df, dfb, on = [:year, :day, :lat, :lon] )
#leftjoin!( df, dfa, on = [:year, :day, :lat, :lon] )

## write dataframe with lable, sst, aot, and w to csv ##
@select! df :Timestamp :lat :lon :Label :platform :lts :blh :aot1 
df = @orderby df :Timestamp
CSV.write( joinpath(pwd(),"data/processed/all_subtropic_label_climate_day.csv" ), df, index = false)

