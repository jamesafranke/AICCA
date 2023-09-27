using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

df = @chain DataFrame( Arrow.Table( "./data/processed/AICCA_with_climate_no_dec_2021.arrow" ) ) begin
    @select :Timestamp :Label :lat :lon :platform :water_path :pr :cloud_fraction
    @transform :year=year.(:Timestamp) :doy=dayofyear.(:Timestamp)
    dropmissing( _, :water_path)
    @subset :year.==2010 :platform.=="AQUA"
    @transform :lat=round_step.(:lat, 0.5) :lon=round_step.(:lon, 0.5)
    @rtransform :lat=:lat.==-0.0 ? 0.0 : :lat  :lon=:lon.==-0.0 ? 0.0 : :lon
end

nd = @chain DataFrame( Arrow.Table( "./data/processed/2010_modis_nd_aqua.arrow" ) ) begin
    dropmissing(_)
    @transform :platform="AQUA" :year=2010 :doy=parse.( Int16, :doy )
end

df = leftjoin(df, nd, on=[:lat, :lon, :year, :doy, :platform])

df = dropmissing(df)
Arrow.write( "./data/processed/AICCA_drizzle_proxy_2010_aqua.arrow", df )

df = DataFrame( Arrow.Table( "./data/processed/AICCA_drizzle_proxy_2010_aqua.arrow" ) )

df = @transform df :mdp=0.37(:water_path/:Nd_all)^1.75

temp = 0.37.*(df.water_path./df.Nd_all).^1.75

df = @transform df :mdp=temp

df = @subset df :cloud_fraction.>50


scatter(size=(500,500), grid=false, leg=false, dpi=900)
@df df scatter!(:pr, :mdp, alpha=0.5)
ylims!(-0.1,2)
xlims!(-0.1,2)

xlabel!("IMERG [mm/day]")
ylabel!("MOIDS drizzle proxy [mm/day]")