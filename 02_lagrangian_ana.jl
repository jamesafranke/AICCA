using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
using Plots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_40NS.arrow" ) )

df

temp = @subset df :Label.==35

histogram(temp.next_label)