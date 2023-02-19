using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

for year in 2000:2000 ### load in class data and wind speed from era5 and calc transitions ####
    print("starting----------------------------", year)
    out = DataFrame()
    
    df = @chain DataFrame( Arrow.Table( "./data/raw/yearly/$(year).arrow" ) ) begin
        @select :Timestamp :lat :lon :Label
        @subset :lat.>-40 :lat.<5 :lon.>-130 :lon.<-70  #### CHANGE ME PER REGION ##### #:lat.<40 :lat.>-40
        dropmissing(_)
        @transform :Timestamp=round.(DateTime.(:Timestamp, "yyyy-mm-dd HH:MM:SS"), Hour(1))
        @transform :time_0=:Timestamp :date=Date.(:Timestamp)     end
    
    era = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_$(year)_daily_ws.arrow" ) ) begin
        @rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
        @transform :date=Date.(:time) #:week=Week.(:time)
        @select :date :lat :lon :u :v #:week
        rename( :lat=>:latr, :lon=>:lonr )   
        dropmissing()    end

    sst = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_$(year)_sst.arrow" ) ) begin
        @rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
        @transform :date=Date.(:time)
        @select :date :lat :lon :sst
        rename( :lat=>:latr, :lon=>:lonr )    end

    lts = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_$(year)_daily_lts.arrow" ) ) begin
        @rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
        @transform :date=Date.(:time)
        @select :date :lat :lon :lts
        rename( :lat=>:latr, :lon=>:lonr )    end

    pr = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/imerg_$(year)_daily_pr.arrow" ) ) begin
        @transform :date=Date.(:time) :latr=round_step.(:lat, 0.25) :lonr=round_step.(:lon, 0.25)
        @rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
        @by [:latr, :lonr, :date] :pr=mean(skipmissing(:pr))
        @select :lonr :latr :date :pr         end
    
    leftjoin!(era, dropmissing(sst), on = [:date, :latr, :lonr])
    leftjoin!(era, dropmissing(lts), on = [:date, :latr, :lonr])
    leftjoin!(era, pr,  on = [:date, :latr, :lonr])
    era.pr = coalesce.(era.pr, 0.0f0)
    dropmissing!(era)

    @showprogress for date in unique(era.date)
        erat = @subset era :date.<=date.+Day(2) :date.>=date
    
        future = @chain df begin
            @subset :date.<=date.+Day(2) :date.>=date
            @transform :latr=round.(Int, :lat) :lonr=round.(Int, :lon)
            @select :Timestamp :latr :lonr :Label
            rename( :Label=>:next_label )    end
        
        dft = @chain df begin
            @subset :date.==date
            @transform :latr=round_step.(:lat, 0.25) :lonr=round_step.(:lon, 0.25) # round to 0.25 to merge with ERA
            @rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
            innerjoin(_, erat, on = [:date, :latr, :lonr] )
            @transform :lon=:lon.+:u.*3600.0./111319.488cos.(:lat) :lat=:lat.+:v.*3600.0./111319.488 :Timestamp=:Timestamp.+Hour(1) 
            @transform :prt=0.0f0 :sstd=0.0f0 :ltsd=0.0f0
            @transform :prt=:prt.+:pr :sstp=:sst :ltsp=:lts 
            @select :time_0 :Timestamp :lat :lon :Label :prt :sstp :ltsp :sstd :ltsd
            @transform :latr=round.(Int, :lat) :lonr=round.(Int,:lon) :date=Date.(:Timestamp)      end  # round to integer to find potential close patch

        temp = innerjoin(dft, future, on =[:Timestamp, :latr, :lonr] )
        if size(temp)[1] > 0 
            @transform! temp :hours=1
            append!(out, temp)
        end

        for i in 2:36
            dft = @chain dft begin
                @transform :latr=round_step.(:lat, 0.25) :lonr=round_step.(:lon, 0.25) # round to 0.25 to merge with ERA
                @rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
                innerjoin(_, erat, on = [:date, :latr, :lonr] )
                @transform :lon=:lon.+:u.*3600.0./111319.488cos.(:lat) :lat=:lat.+:v.*3600.0./111319.488 :Timestamp=:Timestamp.+Hour(1) 
                @transform :prt=:prt.+:pr :sstd=:sstd.+(:sstp.-:sst) :ltsd=:ltsd.+(:ltsp.-:lts)
                @transform :sstp=:sst :ltsp=:lts
                @select :time_0 :Timestamp :lat :lon :Label :prt :sstd :ltsd :sstp :ltsp
                @transform :latr=round.(Int, :lat) :lonr=round.(Int,:lon) :date=Date.(:Timestamp)      end  # round to integer to find potential close patch
    
            temp = innerjoin(dft, future, on =[:Timestamp, :latr, :lonr] )
            if size(temp)[1] > 0 
                @transform! temp :hours=i
                append!(out, temp)
            end
        end
    end
    @select! out :time_0 :lat :lon :Label :next_label :hours :prt :sstd :ltsd :sstp :ltsp 
    rename!(out, :time_0=>:Timestamp )
    Arrow.write("./data/processed/transitions/$(year)_transitions_SP.arrow", out)
end

df = DataFrame()
for year in 2000:2022
    append!( df, Arrow.Table( "./data/processed/transitions/$(year)_transitions_SP.arrow"  ) )
end
Arrow.write( "./data/processed/transitions/all_transitions_SP.arrow", df )


df = DataFrame()
for year in 2000:2022 
    df = @chain DataFrame(Arrow.Table( "./data/processed/transitions/$(year)_transitions_SP.arrow" )) begin
        @transform :week=Week.(:Timestamp) :latr=round.(Int, :lat) :lonr=round.(Int,:lon)   end

    aot = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/avhrr_$(year)_daily_aot.arrow" ) ) begin
        @transform :week=Week.(:time) :latr=round.(Int, :lat) :lonr=round.(Int, :lat)
        @rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
        @by [:latr, :lonr, :week] :aot=mean(skipmissing(:aot)) end
    
    leftjoin!(df, aot, on = [:week, :latr, :lonr]  )
    append!( out, df ) 
end
Arrow.write( "./data/processed/transitions/all_transitions_SP.arrow", df )






df = DataFrame( Arrow.Table( "./data/processed/transitions/2000_transitions_SP.arrow" ) )

df = @chain DataFrame(Arrow.Table( "./data/processed/transitions/2000_transitions_SP.arrow" )) begin
@transform :week=Week.(:Timestamp) :latr=round.(Int, :lat) :lonr=round.(Int,:lon)   end

aot = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/avhrr_2001_daily_aot.arrow" ) ) begin
@transform :week=Week.(:time) :latr=round.(Int, :lat) :lonr=round.(Int, :lat)
@by [:latr, :lonr, :week] :aot=mean(:aot) end

leftjoin!(df, aot, on = [:week, :latr, :lonr]  )


aot








years = 2006
era = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_$(years)_daily_ws.arrow" ) ) begin
@rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
@transform :date=Date.(:time) #:week=Week.(:time)
@select :date :lat :lon :u :v #:week
rename( :lat=>:latr, :lon=>:lonr )    end

sst = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_$(years)_sst.arrow" ) ) begin
@rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
@transform :date=Date.(:time)
@select :date :lat :lon :sst
rename( :lat=>:latr, :lon=>:lonr )    end

lts = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_$(years)_daily_lts.arrow" ) ) begin
@rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
@transform :date=Date.(:time)
@select :date :lat :lon :lts
rename( :lat=>:latr, :lon=>:lonr )    end

pr = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/imerg_$(years)_daily_pr.arrow" ) ) begin
@transform :date=Date.(:time) :latr=round_step.(:lat, 0.25) :lonr=round_step.(:lon, 0.25)
@rtransform :latr=:latr.==-0.0 ? 0.0 : :latr  :lonr=:lonr.==-0.0 ? 0.0 : :lonr
@by [:latr, :lonr, :date] :pr=mean(skipmissing(:pr))
@select :lonr :latr :date :pr         end

leftjoin!(era, sst, on = [:date, :latr, :lonr])
leftjoin!(era, lts, on = [:date, :latr, :lonr])
leftjoin!(era, pr,  on = [:date, :latr, :lonr])
era.pr = coalesce.(era.pr, 0.0f0)
dropmissing!(era)



df = DataFrame(Arrow.Table( "./data/processed/transitions/2001_transitions_SP.arrow" ))



sst = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_2022_sst.arrow" ) ) begin
@rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
@transform :date=Date.(:time)
@select :date :lat :lon :sst
rename( :lat=>:latr, :lon=>:lonr )    
unique()   end


sst = @chain DataFrame( Arrow.Table( "./data/processed/climate/lagrangian/era5_2021_sst.arrow" ) ) begin
@rtransform :lon=:lon.>180 ? :lon.-360 : :lon 
@transform :date=Date.(:time)
@select :date :lat :lon :sst
rename( :lat=>:latr, :lon=>:lonr )    end