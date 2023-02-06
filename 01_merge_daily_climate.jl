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
df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
df = get_subtrop(df)
@transform! df :date=Date.(:Timestamp)
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )

clim = ["era5_daily_lts.arrow", "era5_daily_blh.arrow", "era5_daily_w.arrow", "era5_daily_u.arrow", "era5_daily_v.arrow", "era5_daily_swh.arrow",
"era5_daily_t.arrow", "era5_daily_q.arrow", "era5_daily_sst.arrow","era5_daily_msl.arrow", "imerg_daily_pr.arrow", "avhrr_daily_aot.arrow"]

@showprogress for file in clim
    dft = DataFrame( Arrow.Table( "./data/processed/climate/$file" ) )
    dft = get_subtrop( dft )
    leftjoin!( df, dft, on = [:date, :lat, :lon] )
end 

Arrow.write(  "./data/processed/subtropics_with_climate.arrow" , df )





df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
@select! df :Label :Timestamp :lat :lon :platform :optical_thickness :top_pressure :effective_radius :cloud_fraction :water_path :emissivity :multi_layer_frac :date :lts :w :u :v :t :q :sst

df = @subset df :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70
@transform! df :hour = Hour.(:Timestamp)



df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
@select! df :lat :lon :Label
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
@rtransform! df :lon = :lon.==180.5 ? :lon=-179.5 : :lon
df = @by df [:lat, :lon, :Label] :counts=size(:Label)[1]
Arrow.write( "./data/processed/counts_lat_lon.arrow" , df )


df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
@select! df :lat :lon :Label
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
@rtransform! df :lon = :lon.==180.5 ? :lon=-179.5 : :lon
Arrow.write( "./data/processed/AICC_lat_lon.arrow" , df )