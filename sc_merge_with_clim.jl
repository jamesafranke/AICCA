using CSV, DataFrames, DataFramesMeta, Dates 
if occursin("AICCA", pwd()) == false cd("AICCA") else end
root = pwd()

# Load in the class data (from only the tropics) and merge with # merge class data with sst, subsidence, and aerosol optical
path = joinpath(root,"data/processed/subtrop/")
fl = filter( !contains(".DS"), readdir(patht) )
df = DataFrame()
for i in fl append!( df, CSV.read( joinpath(path, i), dateformat="yyyy-mm-dd HH:MM:SS", DataFrame ) ) end
df.lat = floor.(df.lat) .+ 0.5;  df.lon = floor.(df.lon) .+0.5
@select! df :Timestamp :lat :lon :Label 
df = @orderby df :Timestamp
@transform! df :year=Year.(:Timestamp) :month=Month.(:Timestamp)

## Monthly vertical velocity from ERA5
dfw = CSV.read( joinpath(root,"data/processed/era5_700hpa_vertical_velocity_1deg.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
@transform! dfw :year=Year.(:time) :month=Month.(:time)
@select! dfw :year :month :lat :lon :w
dftemp = @subset dfw :lon .> 180
dftemp.lon .-= 360
@subset! dfw :lon .< 180
append!( dfw, dftemp )

## Monthly sst from NOAA NCEP Reanaluysis
dfs = CSV.read( joinpath(root,"data/processed/noaa_ncep_sst.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@transform! dfs :year=Year.(:time) :month=Month.(:time) 
@select! dfs :year :month :lat :lon :sst
dftemp = @subset dfs :lon .> 180
dftemp.lon .-= 360
@subset! dfs :lon .< 180
append!( dfs, dftemp )

## Monthly AOT from AHVRR satellite
dfa = CSV.read( joinpath(root,"data/processed/avhrr_aot_month.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@transform! dfa :year=Year.(:time) :month=Month.(:time)
@select! dfa :year :month :lat :lon :aot1
unique!(dfa)

leftjoin!( df, dfw, on = [:year, :month, :lat, :lon] )
leftjoin!( df, dfs, on = [:year, :month, :lat, :lon] )
leftjoin!( df, dfa, on = [:year, :month, :lat, :lon] )

@select! df :Timestamp :lat :lon :Label :w :sst :aot1 
CSV.write( joinpath(root,"data/processed/all_subtropic_label_w_sst_aot.csv"), df, index = false)

