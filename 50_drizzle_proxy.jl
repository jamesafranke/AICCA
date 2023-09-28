using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step


df = @chain DataFrame( Arrow.Table( "./data/processed/AICCA_with_climate_no_dec_2021.arrow" ) ) begin
    @select :Timestamp :Label :lat :lon :platform :water_path :pr :cloud_fraction
    @transform :year=year.(:Timestamp) :doy=dayofyear.(:Timestamp)
    dropmissing( _, :water_path)
    @subset :year.∈ Ref([2010,2011,2012,2013]) #:platform.=="AQUA"
    @transform :lat=round_step.(:lat, 0.5) :lon=round_step.(:lon, 0.5)
    @rtransform :lat=:lat.==-0.0 ? 0.0 : :lat  :lon=:lon.==-0.0 ? 0.0 : :lon
end

out = DataFrame()
for year_ in 2010:2013
    for a in ["AQUA","TERRA"]
        nd = @chain DataFrame( Arrow.Table( "./data/processed/modis_nd/$(year_)_modis_nd_$a.arrow" ) ) begin
            dropmissing(_)
            @transform :platform=a :year=year_ :doy=parse.( Int16, :doy )  end
        append!(out, nd)
    end
end

df = leftjoin(df, out, on=[:lat, :lon, :year, :doy, :platform])

df = dropmissing(df)
Arrow.write( "./data/processed/AICCA_drizzle_proxy_2010_2013.arrow", df )

df = DataFrame( Arrow.Table( "./data/processed/AICCA_drizzle_proxy_2010_2013.arrow" ) )
temp = 0.37.*(df.water_path./df.Nd_all).^1.75
df = @transform df :mdp=temp

df = @subset df :cloud_fraction.>50


scatter(size=(500,500), grid=false, leg=false, dpi=900)
@df df scatter!(:pr, :mdp, alpha=0.5)
ylims!(-0.1,2)
xlims!(-0.1,2)

xlabel!("IMERG [mm/day]")
ylabel!("MOIDS drizzle proxy [mm/day]")




# join drizzle proxy with transitions
mdp = DataFrame( Arrow.Table( "./data/processed/AICCA_drizzle_proxy_2010_2013.arrow" ) )
temp = 0.37.*(mdp.water_path./mdp.Nd_all).^1.75
mdp = @transform mdp :mdp=temp
@transform! mdp :Timestamp=round.(:Timestamp, Hour(1))
mdp = @select mdp :Timestamp :lat :lon :mdp

df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_SP_pr24.arrow" ) )
@transform! df :year=year.(:Timestamp)
df = @subset df :year.∈ Ref([2010,2011,2012,2013]) 
df = dropmissing(df, [:next_label])
@transform! df :lat=round_step.(:lat, 0.5) :lon=round_step.(:lon, 0.5) :lat_0=round_step.(:lat_0, 0.5) :lon_0=round_step.(:lon_0, 0.5)
@rtransform! df :lat=:lat.==-0.0 ? 0.0 : :lat :lon=:lon.==-0.0 ? 0.0 : :lon :lat_0=:lat_0.==-0.0 ? 0.0 : :lat_0  :lon_0=:lon_0.==-0.0 ? 0.0 : :lon_0
rename!(df, :Timestamp=>:Timestamp_0)
@transform! df :Timestamp=:Timestamp_0.+Hour.(:hours)

df = leftjoin(df, mdp, on=[:Timestamp, :lat, :lon])

rename!(mdp, :lat=>:lat_0, :lon=>:lon_0, :Timestamp=>:Timestamp_0, :mdp=>:mdp_0 )
df = leftjoin(df, mdp, on=[:Timestamp_0, :lat_0, :lon_0])



Arrow.write( "./data/processed/AICCA_drizzle_proxy_2010_2013_transitions.arrow", df )

df = DataFrame( Arrow.Table("./data/processed/AICCA_drizzle_proxy_2010_2013_transitions.arrow"))
temp = @subset df :Label.==30
temp = @subset temp :tstep.<6
temp = @transform temp :dlat = :lat-:lat_0
temp1 = @subset temp :next_label.==:Label
temp2 = @subset temp :next_label.!=:Label
temp2 = @subset temp2 :next_label.∉Ref([35,31,33])
temp2 = @subset temp2 :next_label.>11
temp3 = @subset temp :next_label.==35

median(skipmissing(temp1.mdp))
median(skipmissing(temp1.mdp_0))

median(skipmissing(temp2.mdp))
median(skipmissing(temp2.mdp_0))

median(skipmissing(temp3.mdp))
median(skipmissing(temp3.mdp_0))


mean(temp1.dlat)

mean(temp2.dlat)
mean(temp3.dlat)

mean(temp1.lat_0)
mean(temp2.lat_0)
mean(temp3.lat_0)

mean(temp1.lat)
mean(temp2.lat)
mean(temp3.lat)


mdp = DataFrame( Arrow.Table( "./data/processed/AICCA_drizzle_proxy_2010_2013.arrow" ) )
temp = 0.37.*(mdp.water_path./mdp.Nd_all).^1.75
mdp = @transform mdp :mdp=temp

temp = @subset mdp :Label.==30
median(skipmissing(temp.mdp))

temp = @subset df :Label.==35
median(skipmissing(temp.mdp))


# test drizzle proxy #
df = DataFrame( Arrow.Table( "./data/processed/AICCA_drizzle_proxy_2010_2013.arrow" ) )
temp = 0.37.*(df.water_path./df.Nd_all).^1.75
df = @transform df :mdp=temp

df = @subset df :year.==2011
df = @transform df :hour = hour.(:Timestamp)

df1 = DataFrame( Arrow.Table( "./data/processed/2011_26days_imerg_30min.arrow" ) )
df1 = @by df1 [:day, :hour, :lat, :lon] :pr=mean(:pr)
rename!(df1, :day=>:doy, :pr=>:imerg_hour)


df = leftjoin(df, df1, on =[:lat, :lon, :doy, :hour])


scatter(size=(500,500), grid=false, leg=false, dpi=900)
@df df scatter!(:imerg_hour, :mdp./12, alpha=0.5)
ylims!(-0.5,10)
xlims!(-0.5,10)

xlabel!("IMERG [mm/hour]")
ylabel!("MOIDS drizzle proxy [mm/hour]")




