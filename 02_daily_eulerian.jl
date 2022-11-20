using Plots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

# load in class data for the tropics merged with climate vars
df = DataFrame( Arrow.Table("./data/processed/subtropic_sc_w_ctp_and_frac_daily_clim.arrow"))
@subset! df :Label.!=43 

# get the sub-daily transisions
dft = @chain df begin
    @select :Timestamp :lat :lon :Label
    @transform :day=Date.(:Timestamp)
    @by [:lat, :lon, :day] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :hour_diff=Dates.value.(:Timestamp[end]-:Timestamp[1])./3_600_000
    @subset :day_num.>1
    @rsubset :class.!=0 || :nextclass.!=0
end






# plot some class transisons 
temp = @subset dft :class .== 33 
histogram( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500) )
temp = @subset dft :class .== 32 
histogram!( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500), alpha = 0.5 )



