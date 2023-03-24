using Arrow, CSV, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

## hourly boundary layer height or lts from ERA5 ##
dfA =  DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim_all.arrow")) )
@transform! dfA :year=Year.(:date)

df = DataFrame()
@showprogress for year in 2000:2021
    dfi = DataFrame( Arrow.Table( joinpath( pwd(),"data/processed/blh/era5_$(year)_hourly_blh.arrow" ) ) )
    @transform! dfi :date=Date.(:time) :hour=Hour.(:time)
    @select! dfi :date :hour :lat :lon :blh
    rename!(dfi, :blh => :blhh)
    for col in eachcol(dfi) replace!( col, NaN => missing ) end
    dropmissing!(dfi)

    dfl = DataFrame( Arrow.Table( joinpath( pwd(),"data/processed/lts/era5_$(year)_hourly_lts.arrow" ) ) )
    @transform! dfl :date=Date.(:time) :hour=Hour.(:time)
    @select! dfl :date :hour :lat :lon :lts
    rename!(dfl, :lts => :ltsh)
    for col in eachcol(dfl) replace!( col, NaN => missing ) end
    dropmissing!(dfl)

    dftemp = @subset dfA :year .== Year(year)
    leftjoin!(dftemp, dfi, on = [:date, :hour, :lat, :lon] ) 
    leftjoin!(dftemp, dfl, on = [:date, :hour, :lat, :lon] ) 
    append!(df, dftemp )

    dftemp = nothing
    dfi = nothing
    dfl = nothing
end

select!(df, Not([:year]))
Arrow.write(joinpath(pwd(),"data/processed/subtropic_sc_label_hourly_clim.arrow"), df)