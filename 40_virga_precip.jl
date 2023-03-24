using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
df = get_subtrop(df)
df = @select df :Label :platform :date :hour :lat :lon :Cloud_Multi_Layer_Fraction
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
rename!(df, :Cloud_Multi_Layer_Fraction => :mlf)

df1 = @by df :Label :mean_frac=mean(:mlf)
df1 = @orderby df1 :mean_frac

# get the sub-daily transisions
dft = @chain df begin
    @select :date :hour :lat :lon :Label
    @orderby :date :hour
    @by [:lat, :lon, :date] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :hour_diff=Hour.(last(:hour)-first(:hour))
    @subset :day_num.>1
    @subset :class .== 7
    #@rsubset :class.!=0 || :nextclass.!=0
end

df2 = @by dft :nextclass :counts=size(:class)[1]
df2 = @orderby df2 :counts
last(df2, 20)

temp = @subset dft :nextclass.==25

scatter(temp.lon, temp.lat, leg = false)



df = DataFrame( Arrow.Table( joinpath(pwd(),"./data/processed/subtropic_sc_label_daily_clim.arrow")) )

dft = @chain df begin
    @select! :Label :date :hour :lat :lon :pr
    @orderby :date :hour
    @by [:lat, :lon, :date] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :mean_pr=mean(allowmissing(:pr))
    @subset :day_num.>1
    @subset :class.==7 :nextclass.==30
    dropmissing()
    #@rsubset :class.!=0 || :nextclass.!=0
end


median(dft.mean_pr)
median(dft.mean_pr)
median(dft.mean_pr)

dft = @chain df begin
    @select! :Label :date :hour :lat :lon :pr
    @orderby :date :hour
    @by [:lat, :lon, :date] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :mean_pr=mean(allowmissing(:pr))
    @subset :day_num.>1
    @subset :class.!=7 :nextclass.==21
    #@rsubset :class.!=0 || :nextclass.!=0
    dropmissing()
end

median(dft.mean_pr)
median(dft.mean_pr)

dft = @subset df :Label.==25
dropmissing!(dft)
631249

dft = @subset dft :pr.>0.001

2.7 / 0.07

density(y, leg = false)
density!(x)

using StatsPlots