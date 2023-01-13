using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

for year in 2000:2021 ### load in class data and wind speed from era5 and calc transitions ####
    print("starting----------------------------", year)
    out = DataFrame()

    df = @chain DataFrame( Arrow.Table( "./data/raw/yearly/$(year).arrow" ) ) begin
        @select :Timestamp :lat :lon :Label
        @subset :lat.<40 :lat.>-40
        dropmissing()
        @transform :Timestamp=DateTime.(:Timestamp, "yyyy-mm-dd HH:MM:SS") 
        @transform :time_0=:Timestamp
        @transform :Timestamp=round.(:Timestamp, Hour(1))
        @transform :date = Date.(:Timestamp) end

    era = @chain DataFrame( Arrow.Table( "./data/raw/era5/era5_$(year)_daily_ws.arrow" ) ) begin
        @subset :lat.<40 :lat.>-40
        @rtransform :lon = :lon .> 180 ? :lon .- 360 : :lon 
        @transform :date = Date.(:time)
        @select :date :lat :lon :u :v
        rename( :lat=>:latr, :lon=>:lonr) end

    @showprogress for date in unique(era.date)
        erat = @subset era :date.<=date.+Day(2) :date.>=date
        dft = @subset df :date.==date
        future = @chain df begin
        @subset :date.<=date.+Day(2) :date.>=date
        @transform :latr = round.(Int, :lat) :lonr = round.(Int, :lon)
        @select :Timestamp :lat :lon :latr :lonr :Label
        rename( :Label=>:next_label, :lat=>:latf, :lon=>:lonf) end

        for i in 1:48
            dft = @chain dft begin
            @transform :latr = round_step.(:lat, 0.25) :lonr = round_step.(:lon, 0.25)
            @rtransform :latr = :latr .== -0.0 ? 0.0 : :latr :lonr = :lonr .== -0.0 ? 0.0 : :lonr
            innerjoin(erat, on = [:date, :latr, :lonr])
            @transform :lon=:lon.+:u.*3600.0./111319.488cos.(:lat) :lat=:lat.+:v.*3600.0./111319.488 :Timestamp=:Timestamp.+Hour(1)
            @select :time_0 :Timestamp :lat :lon :Label
            @transform :latr=round.(Int, :lat) :lonr=round.(Int,:lon) :date=Date.(:Timestamp) end

            temp = innerjoin(dft, future, on =[:Timestamp, :latr, :lonr] )
            if size(temp)[1] > 0 
                @transform! temp :hours=i
                append!(out, temp)
            end
        end
    end
    Arrow.write("./data/processed/transitions/$(year)_transitions_40NS.arrow", out)
end


df = DataFrame()
for year in 2000:2021
    append!( df, Arrow.Table( "./data/processed/transitions/$(year)_transitions_40NS.arrow"  ) )
end
Arrow.write( "./data/processed/transitions/all_transitions_40NS.arrow", df )