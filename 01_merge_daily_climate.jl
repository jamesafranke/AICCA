using Arrow, DataFrames, DataFramesMeta, Dates, InlineStrings
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin)
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70 ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20 ) # south alantic
    return dfout
end

## Load in the class data  merge with some climate vars for analysis ##
dft = DataFrame( Arrow.Table(joinpath( pwd(), "data/raw/all_AICCA_no_properties.arrow") ) )
df = get_subtrop(dft)

dft = DataFrame( Arrow.Table( joinpath( pwd(), "data/processed/era5_daily_lts_tropics.arrow" ) ) )
dfl = get_subtrop(dft)
leftjoin!( df, dfl, on = [:date, :lat, :lon] )
dfl = nothing

dft = DataFrame( Arrow.Table( joinpath( pwd(), "data/processed/era5_daily_blh_tropics.arrow" ) ) )
dfb = get_subtrop(dft)
leftjoin!( df, dfb, on = [:date, :lat, :lon] )
dfb = nothing

dft = DataFrame( Arrow.Table( joinpath(pwd(), "data/processed/era5_daily_ws_tropics.arrow" ) ) )
dfw = get_subtrop(dft)
leftjoin!( df, dfw, on = [:date, :lat, :lon] )
dfw = nothing

dft = DataFrame( Arrow.Table( joinpath( pwd(), "data/processed/aot_daily_tropics.arrow" ) ) )
dfa = get_subtrop(dft)
leftjoin!( df, dfa, on = [:date, :lat, :lon] )
dfa = nothing

dft = DataFrame( Arrow.Table( joinpath(pwd(), "data/processed/imerg_daily_pr_tropics.arrow" ) ) )
dfp = get_subtrop(dft)
leftjoin!( df, dfp, on = [:date, :lat, :lon] )


Arrow.write(joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim.arrow"), df)







df.date = InlineString15.( Dates.format.(df.date, "yyyy-mm-dd") )
df.lat = InlineString7.(string.(df.lat))
df.lon = InlineString7.(string.(df.lon))


dfl.date = InlineString15.( Dates.format.(dfl.date, "yyyy-mm-dd") )
dfl.lat = InlineString7.( string.(dfl.lat) )
dfl.lon = InlineString7.( string.(dfl.lon) )