using Plots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end




df = DataFrame( Arrow.Table("./data/processed/subtropic_sc_label_hourly_clim.arrow") )
rename!(df, :Cloud_Optical_Thickness_mean => :cop, :Cloud_Top_Pressure_mean => :ctp, :Cloud_Fraction => :cf)





# get the sub-daily transisions
dft = @chain df begin
    @select :date :hour :lat :lon :Label :blhh :ltsh
    @orderby :date :hour
    @by [:lat, :lon, :date] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :hour_diff=Hour.(last(:hour)-first(:hour)) :blh1=first(:blhh) :blh2=last(:blhh) :lts1=first(:ltsh) :lts2=last(:ltsh)
    @subset :day_num.>1
    @subset :class .== 35
    #@rsubset :class.!=0 || :nextclass.!=0
end


