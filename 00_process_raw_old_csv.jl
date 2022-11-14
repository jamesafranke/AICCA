using DataFrames, DataFramesMeta, CSV, Dates, Arrow
using ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

########################################  process data to arrow [depreciated] ################################################# 
for year in 2012:2021
    df = DataFrame()
    fl = filter( !contains(".DS"), readdir( joinpath(pwd(), "data/raw/$year/") ) )
    @showprogress for file in fl
        append!( df, CSV.read( joinpath(pwd(), "data/raw/$year/", file), DataFrame ) ) 
        try
            df.lat = allowmissing(df.lat)
            df.lon = allowmissing(df.lon)
        catch e
        end
    end
    for col in eachcol(df) replace!( col, NaN => missing ) end
    @transform! df @byrow :Timestamp=:Timestamp[1:19]
    Arrow.write( joinpath(pwd(),"data/raw/combined/$(year).arrow"), df )
end


########################################  process data to mean class properties [old] ############################################ 
medm(x)  = median(   skipmissing(x) )
meanm(x) = mean(     skipmissing(x) )
m75(x)   = quantile( skipmissing(x), 0.25 )
m25(x)   = quantile( skipmissing(x), 0.75 )

for year in 2000:2021
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
    CSV.write( joinpath(pwd(),"data/processed/mean_props/$(year)_class_mean_props.csv"), df)
    df = nothing
end
