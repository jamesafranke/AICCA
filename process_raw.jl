using DataFrames, DataFramesMeta, CSV, Dates
using ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end


########################################  process data to subtropic only ################################################# 
for year in 2018:2021
    df = DataFrame()
    fl = filter( !contains(".DS"), readdir( joinpath(pwd(), "data/raw/$year/") ) )
    @showprogress for file in fl
        temp = CSV.read( joinpath(pwd(), "data/raw/$year/", file), DataFrame ) #dateformat="yyyy-mm-ddTHH:MM:SS.s",
        @subset! temp :lat.>-40 :lat.<40
        append!( df, temp )
    end
    for col in eachcol(df) replace!( col, NaN => missing ) end
    @transform! df @byrow :Timestamp=:Timestamp[1:19]
    CSV.write( joinpath(pwd(),"data/processed/subtropic/$(year)_40NS.csv"), df )
    df = nothing
end


########################################  process data to mean class properties ############################################ 
medm(x)  = median(   skipmissing(x) )
meanm(x) = mean(     skipmissing(x) )
m75(x)   = quantile( skipmissing(x), 0.25 )
m25(x)   = quantile( skipmissing(x), 0.75 )

for year in 2011:2021
    df = DataFrame()
    fl = filter( !contains(".DS"), readdir( joinpath(pwd(), "data/raw/$year/") ) )
    @showprogress for j in fl
        temp = CSV.read( joinpath(pwd(), "data/raw/$year/", j), DataFrame )
        @select! temp :Label :Cloud_Optical_Thickness_mean :Cloud_Top_Pressure_mean :Cloud_Effective_Radius_mean :Cloud_Water_Path_mean :Cloud_Fraction
        append!( df, temp )
    end
    for col in eachcol(df) replace!( col, NaN => missing ) end
    df = @by( df, :Label, 
    :ot=meanm(:Cloud_Optical_Thickness_mean), :tp=meanm(:Cloud_Top_Pressure_mean), 
    :er=meanm(:Cloud_Effective_Radius_mean),  :wp=meanm(:Cloud_Water_Path_mean),  :cf=meanm(:Cloud_Fraction), 
    :otm=medm(:Cloud_Optical_Thickness_mean), :tpm=medm(:Cloud_Top_Pressure_mean), 
    :erm=medm(:Cloud_Effective_Radius_mean),  :wpm=medm(:Cloud_Water_Path_mean),  :cfm=medm(:Cloud_Fraction), 
    :ot25=m25(:Cloud_Optical_Thickness_mean), :tp25=m25(:Cloud_Top_Pressure_mean), 
    :er25=m25(:Cloud_Effective_Radius_mean),  :wp25=m25(:Cloud_Water_Path_mean),  :cf25=m25(:Cloud_Fraction),  
    :ot75=m75(:Cloud_Optical_Thickness_mean), :tp75=m75(:Cloud_Top_Pressure_mean), 
    :er75=m75(:Cloud_Effective_Radius_mean),  :wp75=m75(:Cloud_Water_Path_mean),  :cf75=m75(:Cloud_Fraction) )
    CSV.write( joinpath(root,"data/processed/med_iqr_props/$(year)_class_mean_props.csv"), df)
    df = nothing
end
