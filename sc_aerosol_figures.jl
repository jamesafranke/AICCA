using Plots; gr(); theme(:juno) 
using CSV, DataFrames, DataFramesMeta, Dates 
using Statistics
#using Base.Threads; nthreads()

# Load in the class data
root = "data/processed/subtrop/"
fl = filter( !contains(".DS"), readdir(root) )
df = DataFrame()
for i in fl append!( df, CSV.read( joinpath(root, i), dateformat="yyyy-mm-dd HH:MM:SS", DataFrame ) ) end
df.lat = floor.(df.lat);  df.lon = floor.(df.lon)
@select! df :Timestamp :lat :lon :Label 
df = @orderby df :Timestamp
CSV.write("data/processed/all_subtropic_label_only.csv", df, index = false)


# merge with sst and subsidence data
df = CSV.read( "data/processed/all_subtropic_label_only.csv", dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) #df.Timestamp = tryparse.(DateTime, df.Timestamp)
df.lat .+= 0.5; df.lon .+= 0.5
@transform! df :year=Year.(:Timestamp) :month=Month.(:Timestamp)

dfw = CSV.read( "data/processed/era5_700hpa_vertical_velocity_1deg.csv", dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame ) 
dfs = CSV.read( "data/processed/noaa_ncep_sst.csv", dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
dfa = CSV.read( "data/processed/avhrr_aot_month.csv", dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@transform! dfw :year=Year.(:time) :month=Month.(:time)
@select!    dfw :year :month :lat :lon :w
@transform! dfs :year=Year.(:time) :month=Month.(:time)
@select!    dfs :year :month :lat :lon :sst
@transform! dfa :year=Year.(:time) :month=Month.(:time)
@select!    dfa :year :month :lat :lon :aot1
leftjoin!( df, dfw, on = [:year, :month, :lat, :lon] )
leftjoin!( df, dfs, on = [:year, :month, :lat, :lon] )
leftjoin!( df, dfa, on = [:year, :month, :lat, :lon] )
@select! df :Timestamp :lat :lon :Label :w :sst :aot1 
CSV.write("data/processed/all_subtropic_label_w_sst_aot.csv", df, index = false)

# load in merged data
df = CSV.read( "data/processed/all_subtropic_label_w_sst_aot.csv", dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
first(df)

# get the sub-daily transisions
dft = @chain df begin
    @select :Timestamp :lat :lon :Label
    @transform :day=Date.(:Timestamp)
    @by [:lat, :lon, :day] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :hour_diff=Dates.value.(:Timestamp[end]-:Timestamp[1])./3_600_000
    @subset :day_num.>1 :nextclass.!=43 
    @rsubset :class.!=0 || :nextclass.!=0
end;
size(dft)


# plot some class transisons
temp = @subset dft :class .== 33 
histogram( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500) )
temp = @subset dft :class .== 32 
histogram!( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500), alpha = 0.5 )









