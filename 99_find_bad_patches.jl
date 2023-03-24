using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
temp = @subset df :lat.>40 :lat.<60 :lon.>56 :lon.<125 

temp = @rsubset df Date.(:Timestamp) ∉ Date(2021,12,10):Day(1):Date(2021,12,31)

df = @select temp :lat :lon :Label
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )
@rtransform! df :lon = :lon.==180.5 ? :lon=-179.5 : :lon
df = @by df [:lat, :lon, :Label] :counts=size(:Label)[1]
Arrow.write( "./data/processed/counts_lat_lon.arrow" , df )


temp = @subset df :lat.>33 :lat.<45 :lon.>-107 :lon.<-82


unique(temp.platform)

@transform! temp :day=Date.(:Timestamp)


print(unique(temp.day))

print(names(temp))

Date(2021,12,10):Day(1):Date(2021,12,31)