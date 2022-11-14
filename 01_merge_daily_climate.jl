using Arrow, DataFrames, DataFramesMeta, Dates 
if occursin("AICCA", pwd()) == false cd("AICCA") else end

## Load in the class data  merge with some climate vars for analysis ##
df = DataFrame( Arrow.Table(joinpath(pwd(),"data/raw/all_AICCA.arrow")))
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
@select! df :Timestamp :lat :lon :Label
@transform! df :date=Date.(:Timestamp)
@subset! df :Label.!=43 

dft = DataFrame()
append!(dft, @subset df :lat.>7  :lat.<39 :lon.>-165 :lon.<-100)
append!(dft, @subset df :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70)
append!(dft, @subset df :lat.>-35 :lat.<0  :lon.>-25  :lon.<20 )
df = nothing

dfl = DataFrame(Arrow.Table(joinpath(pwd(),"data/processed/era5_daily_lts_tropics.arrow")))
leftjoin!( dft, dfl, on = [:date, :lat, :lon] )

dfb = DataFrame(Arrow.Table(joinpath(pwd(),"data/processed/era5_daily_blh_tropics.arrow")))
leftjoin!( dft, dfb, on = [:date, :lat, :lon] )

dfw = DataFrame(Arrow.Table(joinpath(pwd(),"data/processed/era5_daily_ws_tropics.arrow")))
leftjoin!( dft, dfw, on = [:date, :lat, :lon] )

dfp = DataFrame(Arrow.Table(joinpath(pwd(),"data/processed/imerg_daily_pr_tropics.arrow")))
leftjoin!( dft, dfp, on = [:date, :lat, :lon] )

dfa = DataFrame(Arrow.Table(joinpath(pwd(),"data/processed/aot_daily_tropics.arrow")))
@transform! dfa :date=Date.(:time)
leftjoin!( dft, dfa, on = [:date, :lat, :lon] )

@select! dft :Timestamp :lat :lon :Label :lts :blh :aot1 
dft = @orderby dft :Timestamp
Arrow.write(joinpath(pwd(),"data/processed/subtropic_sc_label_climate_day.arrow"), dft)