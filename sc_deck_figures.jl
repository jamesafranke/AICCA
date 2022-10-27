using Plots; gr(); theme(:dark) #StatsPlots, UnicodePlots; 
using CSV, DataFrames, DataFramesMeta, Dates
using Statistics, StatsBase
using GLM

root = "AICCA/data/processed/sc_counts/"
fl = filter(!contains(".DS"), readdir(root) )
df = DataFrame()
for i in fl append!( df, @transform!( CSV.read( joinpath(root, i), dateformat="yyyy-mm-dd", DataFrame ), :region = split(i, "_")[3]) ) end

### perform daily aggregations ###
dfo = @chain df begin 
    groupby( [:region, :date] ) 
    @combine(:day_sum = sum(:members), :day_mean = mean(:members), :day_max = maximum(:members), 
    :day_med = median(:members), :day_num = size(:members)[1], :day_skew = skewness(:members))
    @transform(:month = Dates.month.(:date), :dayofyear = Dates.dayofyear.(:date) )
    @orderby(:date)
 end

 dfp = @subset(dfo, :region .== "spacific") 
dfo[!,:rate] = dfo.day_sum ./ dfo.day_num
scatter(dfp.date, dfp.rate, group = dfp.dayofyear)

dfp = @subset(dfo, :region .== "spacific") 
@transform!(dfp, :time = 1:size(dfp)[1])
@dropmissing!(dfp)

for month in 1:12
    temp = @subset(dfp, :month .== month ) 
    ols = lm( @formula(rate ~ time), temp )
    print(month)
    print(ols)
end

plot(dfo.day_skew)

ols = lm( @formula(day_skew ~ time), dfp )

Dates.month.(dfo.date)

dfg = groupby(df, [:region, :date] ) 




heatmap(lab, colormap=:inferno, height=40, width=45, border=:none, colorbar_border=:none, zlabel="cluster")
UnicodePlots.heatmap(lab, colormap=:inferno, height=40, width=45, border=:none, colorbar_border=:none, zlabel="cluster")


@df dft scatter(:lon, :lat, group = :idn)
