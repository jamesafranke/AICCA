using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
using Plots, StatsPlots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

#### individual timesteps of pr ####

for year in 2000:2022 ### load in class data and wind speed from era5 and calc transitions ####
    print("starting----------------------------", year)
    out = DataFrame()
    
    df = @chain DataFrame( Arrow.Table( "./data/raw/yearly/$(year).arrow" ) ) begin
        @select :Timestamp :lat :lon :Label
        @subset :lat.>-40 :lat.<5 :lon.>-130 :lon.<-70  #### CHANGE ME PER REGION ##### #:lat.<40 :lat.>-40
        dropmissing(_)
        @rtransform :Timestamp=:Timestamp[1:19]
        @transform :Timestamp=round.(DateTime.(:Timestamp, "yyyy-mm-dd HH:MM:SS"), Hour(1))
        @transform :time_0=:Timestamp :date=Date.(:Timestamp) :lat_0=:lat :lon_0=:lon  end
    
    era = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_$(year)_daily_ws.arrow" ) ) begin
        @rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
        @transform :date=Date.(:time) #:week=Week.(:time)
        @select :date :lat :lon :u :v #:week
        rename( :lat=>:latr, :lon=>:lonr )   
        dropmissing(_)    end

    pr = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/imerg_$(year)_daily_pr.arrow" ) ) begin
        @transform :date=Date.(:time) :latr=round_step.(:lat, 0.25) :lonr=round_step.(:lon, 0.25) :pr=:pr./24
        @rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
        @by [:latr, :lonr, :date] :pr=mean(skipmissing(:pr))
        @select :lonr :latr :date :pr         end
    
    leftjoin!(era, pr,  on = [:date, :latr, :lonr])
    era.pr = coalesce.(era.pr, 0.0f0)
    dropmissing!(era)

    @showprogress for date in unique(era.date)
        erat = @subset era :date.<=date.+Day(2) :date.>=date
    
        future = @chain df begin
            @subset :date.<=date.+Day(2) :date.>=date
            @transform :latr=round.(Int, :lat) :lonr=round.(Int, :lon)
            @select :Timestamp :latr :lonr :Label
            rename( :Label=>:next_label )         end
        
        dft = @chain df begin
            @subset :date.==date
            @transform :latr=round_step.(:lat, 0.25) :lonr=round_step.(:lon, 0.25) # round to 0.25 to merge with ERA
            @rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
            innerjoin(_, erat, on = [:date, :latr, :lonr] )
            @transform :lon=:lon.+:u.*3600.0./111319.488cos.(:lat) :lat=:lat.+:v.*3600.0./111319.488 :Timestamp=:Timestamp.+Hour(1) 
            @transform :prt=0.0f0 
            @transform :prt=:pr :tstep=1
            @select :time_0 :lat_0 :lon_0 :Timestamp :lat :lon :Label :prt :tstep
            @transform :latr=round.(Int, :lat) :lonr=round.(Int,:lon) :date=Date.(:Timestamp)      end  # round to integer to find potential close patch

        temp = leftjoin(dft, future, on =[:Timestamp, :latr, :lonr] ) #innrjoin for the only transision case

        if size(temp)[1] > 0 
            @transform! temp :hours=1
            append!(out, temp)
        end

        for i in 2:24
            dft = @chain dft begin
                @transform :latr=round_step.(:lat, 0.25) :lonr=round_step.(:lon, 0.25) # round to 0.25 to merge with ERA
                @rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
                innerjoin(_, erat, on = [:date, :latr, :lonr] )
                @transform :lon=:lon.+:u.*3600.0./111319.488cos.(:lat) :lat=:lat.+:v.*3600.0./111319.488 :Timestamp=:Timestamp.+Hour(1) 
                @transform :prt=:pr :tstep=i
                @select :time_0 :lat_0 :lon_0 :Timestamp :lat :lon :Label :prt :tstep
                @transform :latr=round.(Int, :lat) :lonr=round.(Int,:lon) :date=Date.(:Timestamp)      end  # round to integer to find potential close patch

            temp = leftjoin(dft, future, on =[:Timestamp, :latr, :lonr] ) #innrjoin for the only transision case

            if size(temp)[1] > 0 
                @transform! temp :hours=i
                append!(out, temp)
            end
        end
    end
    @select! out :time_0 :lat_0 :lon_0 :lat :lon :Label :next_label :hours :prt :tstep
    rename!(out, :time_0=>:Timestamp )
    Arrow.write("./data/processed/transitions/$(year)_transitions_SP_pr24.arrow", out)
end

df = DataFrame()
for year in 2000:2022 append!( df, Arrow.Table( "./data/processed/transitions/$(year)_transitions_SP_pr24.arrow" ) ) end
Arrow.write( "./data/processed/transitions/all_transitions_SP_pr24.arrow", df )


df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_SP_pr24.arrow" ) )
df = @subset df :Label.>11
temp = dropmissing(df)
@select! temp :Timestamp :lat_0 :lon_0 :next_label
@select! df :Timestamp :lat_0 :lon_0 :lat :lon :Label :hours :prt :tstep 
df = leftjoin(df, temp, on =[:Timestamp,:lat_0,:lon_0])
dropmissing!(df)


Arrow.write( "./data/processed/transitions/all_transitions_SP_pr24_merge.arrow", df )
df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_SP_pr24_merge.arrow" ) )
temp = @by df [:Timestamp,:lat_0,:lon_0] :max_time=maximum(:tstep)
@select! temp :Timestamp :lat_0 :lon_0 :max_time
df = leftjoin(df, temp, on =[:Timestamp,:lat_0,:lon_0])


temp = @subset df :max_time .<6
temp2 = @subset df :max_time .>12
temp2 = @subset temp2 :max_time .<18

temp = @subset temp2 :Label.==:next_label
temp2 = @subset temp2 :Label.!=:next_label




temp = @subset df :tstep.==24

df1 = @subset temp :next_label.==27 
df2 = @subset temp :next_label.==35 

df1 = @by temp [:tstep] :meanpr=mean(:prt)
df2 = @by temp2 [:tstep] :meanpr=mean(:prt)


plot(df1.meanpr)
plot!(df2.meanpr)


df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_pr24_merge.arrow" ) )
df = @subset df :next_label.==30
df = @subset df :hours.>12
df = @subset df :hours.<6

temp = @subset df :Label.==:next_label
temp2 = @subset df :Label.!=:next_label

23533 / (117353 + 23533)

19862 / (127093 + 19862)

29360 / 71689