using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

## Load in the class data and merge with some daily climate vars for analysis ##
df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
df = get_subtrop(df)
@transform! df :date=Date.(:Timestamp)
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )

clim = ["era5_daily_lts.arrow", "era5_daily_blh.arrow", "era5_daily_w.arrow", "era5_daily_u.arrow", "era5_daily_v.arrow", "era5_daily_swh.arrow",
"era5_daily_t.arrow", "era5_daily_q.arrow", "era5_daily_sst.arrow","era5_daily_msl.arrow", "imerg_daily_pr.arrow", "avhrr_daily_aot.arrow", "era5_daily_eis.arrow"]

@showprogress for file in clim
    dft = DataFrame( Arrow.Table( "./data/processed/climate/$file" ) )
    dft = get_subtrop( dft )
    leftjoin!( df, dft, on = [:date, :lat, :lon] )
end 
Arrow.write(  "./data/processed/subtropics_with_climate.arrow" , df )







df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
@transform! df :date=Date.(:Timestamp)
dft = DataFrame( Arrow.Table( "./data/processed/climate/era5_daily_eis.arrow" ) )
dft.lon = convert.( Float16, dft.lon )
dft.lat = convert.( Float16, dft.lat ) 
leftjoin!( df, dft, on = [:date, :lat, :lon] )

Arrow.write(  "./data/processed/subtropics_with_climate.arrow" , df )
