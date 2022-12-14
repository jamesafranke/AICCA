using Plots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

# load in class data for the tropics merged with climate vars
df = DataFrame( Arrow.Table("./data/processed/subtropic_sc_label_hourly_clim.arrow"))
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



df1 = @subset dft :nextclass.==32
median(df1.lts1 .- df1.lts2)
median(df1.blh1 .- df1.blh2)

df1 = @subset dft :nextclass.==30
median(df1.lts1 .- df1.lts2)
median(df1.blh1 .- df1.blh2)

df1 = @subset dft :nextclass.==33
median(df1.lts1 .- df1.lts2)
median(df1.blh1 .- df1.blh2)

histogram(df1.lts1 .- df1.lts2)


histogram(df1.blh1 .- df1.blh2)

df1 = @subset dft :nextclass.==25
median(df1.lts1 .- df1.lts2)
median(df1.blh1 .- df1.blh2)



@orderby :date :hour
@by [:lat, :lon] :aot=ffill(:aot1)



# plot some class transisons 
temp = @subset dft :class .== 33 
histogram( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500) )
temp = @subset dft :class .== 32 
histogram!( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500), alpha = 0.5 )



@rtransform :sc=:Label in [21, 22, 23, 24, 28, 26, 28, 31, 32, 33, 34, 35] ? 1 : 0



@subset :Label .in sc
@subset :Label .∉ sc