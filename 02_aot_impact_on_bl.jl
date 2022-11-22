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

dfc = @chain df begin
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :mean_aot=mean(:aot1) :total=size(:aot1)[1]
    @subset :total.>10
    @orderby :ltsbin
    unstack( :blhbin, :ltsbin, :mean_aot)
    @orderby :blhbin 
    select( Not(:blhbin) )
    Array()
end

xlims!(0, 31)
ylims!(0, 35)
contourf(dfc, size=(600,600), grid = false, dpi=900, label = "mean aot")
png("./figures/heatmap_aot.png")


dfc = @chain df begin
    @subset :aot1.> median(:aot1)
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :counts=size(:aot1)[1]
    @subset :counts.>10
    @orderby :ltsbin
    unstack( :blhbin, :ltsbin, :counts)
    @orderby :blhbin 
    select( Not(:blhbin) )
    Array()
end

contourf(dfc, size=(600,600), grid = false, dpi=900, color = :viridis)

xlims!(0, 31)
ylims!(0, 35)
png("./figures/heatmap_aot_high.png")