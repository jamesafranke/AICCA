using Plots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

for year in 2000:2021 
    nothing
end

year = 2003
### load in class data and subset to only the subtropics and load in wind speed from era5 ####
df = DataFrame( Arrow.Table( "./data/raw/yearly/$(year).arrow" ) )
df.Timestamp = DateTime.(df.Timestamp, "yyyy-mm-dd HH:MM:SS")
df.Timestamp = round.(df.Timestamp, Hour(1))
df = @chain df begin
    @select :Timestamp :lat :lon :Label
    dropmissing()
    @transform :date = Date.(:Timestamp)
    @subset :lat.<40 :lat.>-40
end

era = @chain DataFrame( Arrow.Table( "./data/raw/era5/era5_$(year)_daily_ws.arrow" ) ) begin
    @subset :lat.<40 :lat.>-40
    @transform :date = Date.(:time)
    @rtransform :lon = :lon .> 180 ? :lon .- 360 : :lon
end

dates = unique(era.date)
for date in dates


### loop through to get all transions for a certain class ###
dft = @subset df :Label.==35
dft = first(dft, 10)
out = []

for row in eachrow(dft)
    #temp_era = @subset era :date.==row.date
    lat = row.lat
    lon = row.lon
    time = row.Timestamp

    for i in 1:48
        ws = @chain era begin
            @transform :euclid = sqrt.( (:lat.-lat).^2 + (:lon.-lon).^2 )
            @orderby :euclid
            first(1) 
        end
        
        lon = lon .+ ws.u .* 3600.0./111319.488cos.(lat)
        lat = lat .+ ws.v .* 3600.0./111319.488
        time = time .+ Hour(1)

        temp2 = @subset df :Timestamp.==time
        if size(temp2)[1] > 0
            @transform! temp2 :euclid = sqrt.( (:lat.-temp.lat).^2 + (:lon.-temp.lon).^2 )
            @subset! temp2 :euclid.<0.7
            if size(temp2)[1] > 0
                append!(out, temp2.Label)
                break 
            end
        end
    end
end 











for row in eachrow(dft)
    temp_era = @subset era :date.==temp.date

    for i in 1:48
        ws = @chain temp_era begin
            @transform :euclid = sqrt.( (:lat.-temp.lat).^2 + (:lon.-temp.lon).^2 )
            @orderby :euclid
            first(1) end
        
        @transform! temp :lat=:lat.+(ws.v.*3600.0./111319.488) :lon=:lon.+(ws.u.*3600.0./111319.488cos.(:lat)) :Timestamp=:Timestamp+Hour(1)

        temp2 = @subset df :Timestamp.==temp.Timestamp
        if size(temp2)[1] > 0
            @transform! temp2 :euclid = sqrt.( (:lat.-temp.lat).^2 + (:lon.-temp.lon).^2 )
            @subset! temp2 :euclid.<0.7
            if size(temp2)[1] > 0
                append!(out, temp2.Label)
                break 
            end
        end
    end
end 