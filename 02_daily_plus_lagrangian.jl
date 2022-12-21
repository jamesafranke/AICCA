using Plots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end



year = 2003
df = DataFrame( Arrow.Table( "./data/raw/yearly/$(year).arrow" ) )
@select! df :Timestamp :lat :lon :Label
df.Timestamp = DateTime.(df.Timestamp, "yyyy-mm-dd HH:MM:SS")
@transform! df :date = Date.(:Timestamp) :hour=Hour.(:Timestamp)

for col in eachcol(df) replace!( col, NaN => missing ) end
@transform! df @byrow :Timestamp=:Timestamp[1:19]

dfe = DataFrame( Arrow.Table( "./data/raw/era5/era5_$(year)_daily_blh.arrow" ) )
dropmissing!(dfe)









# get the sub-daily transisions
dft = @chain df begin
    @select :date :hour :lat :lon :Label :blhh :ltsh
    @orderby :date :hour
    @by [:lat, :lon, :date] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :hour_diff=Hour.(last(:hour)-first(:hour)) :blh1=first(:blhh) :blh2=last(:blhh) :lts1=first(:ltsh) :lts2=last(:ltsh)
    @subset :day_num.>1
    @subset :class .== 35
    #@rsubset :class.!=0 || :nextclass.!=0
end


