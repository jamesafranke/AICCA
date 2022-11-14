using DataFrames, DataFramesMeta, CSV, Dates, Arrow
using ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame()
fl = filter( !contains(".DS"), readdir( joinpath(pwd(), "data/raw/combined/") ) )
for file in fl append!( df, DataFrame( Arrow.Table( joinpath( pwd(),"data/raw/combined/",file ) ) ) ) end

@select! df :Label :Timestamp :lat :lon :platform :Cloud_Optical_Thickness_mean :Cloud_Phase_Infrared_liquid :Cloud_Phase_Infrared_ice :Cloud_Top_Pressure_mean :Cloud_Effective_Radius_mean :Cloud_Fraction :Cloud_Water_Path_mean :Cloud_Emissivity_mean :Cloud_Multi_Layer_Fraction
dropmissing!(df, [:Label, :lat, :lon] )
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
Arrow.write( joinpath(pwd(),"data/raw/all_AICCA.arrow"), df )



########################################  process data to mean class properties ############################################ 
medm(x)  = median(   skipmissing(x) )
meanm(x) = mean(     skipmissing(x) )
m75(x)   = quantile( skipmissing(x), 0.25 )
m25(x)   = quantile( skipmissing(x), 0.75 )

@transform! df :year=Year.(:Timestmp)
df = @by( df, [:Label, :year], 
:ot=meanm(:Cloud_Optical_Thickness_mean), :tp=meanm(:Cloud_Top_Pressure_mean), 
:er=meanm(:Cloud_Effective_Radius_mean),  :wp=meanm(:Cloud_Water_Path_mean),  :cf=meanm(:Cloud_Fraction), 
:otm=medm(:Cloud_Optical_Thickness_mean), :tpm=medm(:Cloud_Top_Pressure_mean), 
:erm=medm(:Cloud_Effective_Radius_mean),  :wpm=medm(:Cloud_Water_Path_mean),  :cfm=medm(:Cloud_Fraction), 
:ot25=m25(:Cloud_Optical_Thickness_mean), :tp25=m25(:Cloud_Top_Pressure_mean), 
:er25=m25(:Cloud_Effective_Radius_mean),  :wp25=m25(:Cloud_Water_Path_mean),  :cf25=m25(:Cloud_Fraction),  
:ot75=m75(:Cloud_Optical_Thickness_mean), :tp75=m75(:Cloud_Top_Pressure_mean), 
:er75=m75(:Cloud_Effective_Radius_mean),  :wp75=m75(:Cloud_Water_Path_mean),  :cf75=m75(:Cloud_Fraction) )
Arrow.write( joinpath(pwd(),"data/processed/mean_class_props.arrow"), df )
df = nothing

