using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

## Load in the class data and merge with some climate vars for analysis ##
df = DataFrame( Arrow.Table( "./data/raw/all_AICCA_no_properties.arrow" ) )
@transform! df :year=Year.(:date)
df = get_subtrop(df)

## or load in the class data with some propos and merge with some climate vars for analysis ##
df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
@select! df :Label :date :hour :lat :lon :Cloud_Optical_Thickness_mean :Cloud_Top_Pressure_mean :Cloud_Fraction
df = get_subtrop(df)
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )

clim = ["era5_daily_lts_tropics.arrow", "era5_daily_blh_tropics.arrow", "era5_daily_ws_tropics.arrow",
"era5_daily_t_q.arrow", "era5_daily_sst.arrow", "aot_daily.arrow", "imerg_pr_daily.arrow", "era5_w.arrow"]

@showprogress for file in clim
    dft = DataFrame( Arrow.Table( "./data/processed/$file" ) )
    dft = get_subtrop( dft )
    leftjoin!( df, dft, on = [:date, :lat, :lon] )
end 

Arrow.write(  "./data/processed/subtropic_sc_w_ctp_and_frac_daily_clim.arrow" , df )
