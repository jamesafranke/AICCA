using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
using Statistics
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



temp = @chain df begin
    @orderby :time_0 
    @by [:time_0, :Label] :class=first(:next_label)
end



temp1 = @subset temp :Label.==35
histogram( temp1.class )

temp1 = @by temp1 :class :mean_time = mean(:hours)

mean?