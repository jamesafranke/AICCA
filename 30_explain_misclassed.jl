using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
using Plots, StatsPlots; gr(); Plots.theme(:default)
include("00_helper.jl")

### get dominant bins ###
dfc = @chain DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) ) begin  
    @subset :Label.!=0
    dropmissing( [:sst, :lts] )
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
end
Arrow.write( "./data/processed/to_python_subtrop_met_bins.arrow", dfc )

df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
@transform! df :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
df = dropmissing(df, [:xbin,:ybin])
df = leftjoin(df,dfc, on =[:xbin, :ybin])

dropmissing!(df, :pr)
temp1 = @subset df :maxclass.==35
temp2 = @subset df :maxclass.!=35
histogram(temp1.Label, bins=1:42)
histogram!(temp2.Label, bins=1:42)

temp1 = @by temp1 :Label :med_pr=mean(:pr)
temp2 = @by temp2 :Label :med_pr=mean(:pr)

scatter(temp1.Label, temp1.med_pr)
scatter!(temp2.Label, temp2.med_pr)
xlims!(0,43)

@select! df :Label :Timestamp :lat :lon :pr :aot :sst :lts :maxclass
Arrow.write( "./data/processed/to_python_subtrop_with_maxclass.arrow", df )


dropmissing!(df, :aot)
temp1 = @subset df :maxclass.==35
temp2 = @subset df :maxclass.!=35
histogram(temp1.Label, bins=0:42)
histogram!(temp2.Label, bins=1:42)

temp1 = @by temp1 :Label :med_pr=median(:aot)
temp2 = @by temp2 :Label :med_pr=median(:aot)





@select! df :Label :Timestamp :lat :lon :aot 
df = @orderby df :Timestamp
transform!(groupby(df, [:lat, :lon]), :aot => Impute.locf => :aot)

df


ffill(v) = v[accumulate(max, [i*!ismissing(v[i]) for i in 1:length(v)], init=1)
transform!(groupby(df, [:lat, :lon]), :aot=ffill(:aot))