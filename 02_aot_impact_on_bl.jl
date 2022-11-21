using Plots; gr(); Plots.theme(:default) #plotlyjs()
using CSV, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

aot = CSV.read( "./data/processed/monthly_climate/avhrr_aot_month.csv", DataFrame )
blh = CSV.read( "./data/processed/monthly_climate/era5_blh.csv", DataFrame )
lts = CSV.read( "./data/processed/monthly_climate/era5_lts.csv", DataFrame )
df = leftjoin(aot, blh, on = [:time,:lat,:lon])
leftjoin!(df, lts, on = [:time,:lat,:lon])

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

df = get_subtrop(df)
dropmissing!(df)

