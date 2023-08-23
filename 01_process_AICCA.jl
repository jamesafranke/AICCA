using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

fl = filter( !contains(".DS"), readdir( "./data/raw/yearly/") )
df = DataFrame()
@showprogress for file in fl 
    temp = DataFrame( Arrow.Table("data/raw/yearly/$(file)" ) )
    @select! temp :Label :Timestamp :lat :lon :Cloud_Optical_Thickness_mean :Cloud_Top_Pressure_mean :Cloud_Effective_Radius_mean :Cloud_Fraction :Cloud_Emissivity_mean :Cloud_Multi_Layer_Fraction #:Cloud_Water_Path_mean
    dropmissing!(temp, [:Label, :lat, :lon] )
    @rtransform! temp :Timestamp=DateTime.(:Timestamp[1:19], "yyyy-mm-dd HH:MM:SS")
    append!( df, temp ) 
end

rename!(df, :Cloud_Optical_Thickness_mean=>:optical_thickness,  :Cloud_Top_Pressure_mean=>:top_pressure, 
:Cloud_Effective_Radius_mean=>:effective_radius, :Cloud_Fraction=>:cloud_fraction, 
:Cloud_Emissivity_mean=>:emissivity, :Cloud_Multi_Layer_Fraction=>:multi_layer) #:Cloud_Water_Path_mean=>:water_path, 
Arrow.write( joinpath(pwd(),"data/raw/all_AICCA.arrow"), df )














#:Cloud_Phase_Infrared_liquid :Cloud_Phase_Infrared_ice




df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
@select! df :Label :date :hour :lat :lon
Arrow.write( joinpath(pwd(),"data/raw/all_AICCA_no_properties.arrow"), df )



######################################################## 
######################################################## 
#### to get counts in lat and lon ####
df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
@select! df :lat :lon :Label :platform :Timestamp

### ISSUE with decemeber, 2021 on the AQUA platform ###
temp = @subset df Year.(:Timestamp).==Year(2021)
df = @subset df Year.(:Timestamp).!=Year(2021)
temp = @rsubset temp Date.(:Timestamp) ∉ Date(2021,12,10):Day(1):Date(2021,12,31) || :platform.!="AQUA"
append!(df, temp)


@select! df :lat :lon :Label
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
@rtransform! df :lon = :lon.==180.5 ? :lon=-179.5 : :lon
df = @by df [:lat, :lon, :Label] :counts=size(:Label)[1]
Arrow.write( "./data/processed/counts_lat_lon.arrow" , df )



########################################  process data to mean class properties ############################################ 
medm(x)  = median( skipmissing(x) )
meanm(x) = mean( skipmissing(x) )
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