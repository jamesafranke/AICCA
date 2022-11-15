using Arrow, DataFrames, DataFramesMeta, Dates
using ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin)
    ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

## Load in the class data and merge with some climate vars for analysis ##
dft = DataFrame( Arrow.Table(joinpath( pwd(), "data/raw/all_AICCA_no_properties.arrow") ) )
df = get_subtrop(dft)

clim = ["era5_daily_lts_tropics.arrow", "era5_daily_blh_tropics.arrow", "era5_daily_ws_tropics.arrow",
"era5_daily_t_q.arrow", "era5_daily_sst.arrow", "aot_daily_tropics.arrow", "imerg_pr_daily.arrow"]

@showprogress for file in clim
    dft = DataFrame( Arrow.Table( joinpath( pwd(), "data/processed/", file ) ) )
    dft = get_subtrop( dft )
    leftjoin!( df, dft, on = [:date, :lat, :lon] )
end 


Arrow.write(joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim_all.arrow"), df)
