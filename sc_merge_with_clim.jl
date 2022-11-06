using CSV, DataFrames, DataFramesMeta, Dates 
root = pwd()

# Load in the class data (from only the tropics)
path = joinpath(root,"data/processed/subtrop/")
fl = filter( !contains(".DS"), readdir(patht) )
df = DataFrame()
for i in fl append!( df, CSV.read( joinpath(path, i), dateformat="yyyy-mm-dd HH:MM:SS", DataFrame ) ) end
df.lat = floor.(df.lat);  df.lon = floor.(df.lon)
df.lat .+= 0.5; df.lon .+= 0.5
@select! df :Timestamp :lat :lon :Label 
df = @orderby df :Timestamp
CSV.write("data/processed/all_subtropic_label_only.csv", df, index = false)


# merge class data with sst, subsidence, and aerosol optical depth data
df = CSV.read( joinpath(root,"data/processed/all_subtropic_label_only.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) #df.Timestamp = tryparse.(DateTime, df.Timestamp)
@transform! df :year=Year.(:Timestamp) :month=Month.(:Timestamp)

dfw = CSV.read( joinpath(root,"data/processed/era5_700hpa_vertical_velocity_1deg.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
dfs = CSV.read( joinpath(root,"data/processed/noaa_ncep_sst.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
dfa = CSV.read( joinpath(root,"data/processed/avhrr_aot_month.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )

@transform! dfw :year=Year.(:time) :month=Month.(:time)
@select!    dfw :year :month :lat :lon :w

@transform! dfs :year=Year.(:time) :month=Month.(:time)
@select!    dfs :year :month :lat :lon :sst

@transform! dfa :year=Year.(:time) :month=Month.(:time)
@select!    dfa :year :month :lat :lon :aot1
unique!(dfa)

leftjoin!( df, dfw, on = [:year, :month, :lat, :lon] )
leftjoin!( df, dfs, on = [:year, :month, :lat, :lon] )
leftjoin!( df, dfa, on = [:year, :month, :lat, :lon] )
@select! df :Timestamp :lat :lon :Label :w :sst :aot1 

CSV.write( joinpath(root,"data/processed/all_subtropic_label_w_sst_aot.csv"), df, index = false)

