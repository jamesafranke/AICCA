using Plots, StatsPlots;gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, CSV, Statistics, StatsBase

fip = CSV.read( "./data/county_fips_lat_lon.csv", DataFrame)
rename!(fip, :full_state=>:State, :county_name=>:County)

df = DataFrame()
for i in 1:4
    temp = CSV.read( "./data/har$(i).csv", DataFrame )
    temp.Value = replace.(temp.Value, ","=>"")
    temp.Value = passmissing(parse).(Float64, temp.Value)
    @select! temp :Year :State :County :Value
    append!(df,  temp )
end

leftjoin!(df, fip, on =[:State, :County], matchmissing=:notequal )
@select! df :Year :Value :lat
dropmissing!(df)
@subset! df :Year.>1953
df = @by df :Year :latm=mean(:lat, weights(:Value))

plot(size=(500,500), grid = false, leg=false, dpi=900)
@df df plot!(:Year, :latm, line=(1,:black), marker=(:circle,3,:black,:white))
ylabel!("observed US corn weighted mean latitude ")
png("./figures/plot_for_thesis_talk.png")


xlims!(1953.5,2025)
ylims!(40.2,41.3)