using Arrow, CSV, DataFrames, DataFramesMeta, Dates, ProgressMeter
using Plots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = CSV.read( "./data/raw/ibtracs.ALL.list.v04r00.csv", DataFrame)#, header=2, limit=1)
@select! df :SEASON :NUMBER :BASIN :SUBBASIN :NAME :ISO_TIME :NATURE :LAT :LON :WMO_WIND :WMO_PRES :WMO_AGENCY :TRACK_TYPE :USA_SSHS :LANDFALL :TOKYO_GRADE :TOKYO_WIND :TOKYO_PRES :USA_WIND :USA_PRES
@subset! df :SEASON.>1999
df.ISO_TIME = DateTime.(df.ISO_TIME, "yyyy-mm-dd HH:MM:SS") 
Arrow.write("./data/processed/ibtracs_2000-2022.arrow" , df )

dfi = DataFrame( Arrow.Table( "./data/processed/isccp_all.arrow" ) )

df = DataFrame( Arrow.Table( "./data/processed/ibtracs_2000-2022.arrow" ) )

dfc = DataFrame( Arrow.Table( "./data/raw/monthly/AICCA_2001_1.arrow" ) )
maximum(dfc.lat)

@df df scatter(:LON, :LAT, markercolor=:SEASON, markersize=1, markeralpha=0.5, markerstrokewidth=0.0, leg=false)

df.LAT = round_step.(df.LAT, 1.0)
df.LON = round_step.(df.LON, 1.0)





print(names(df))

df.SEASON  = convert.( Float32, df.SEASON )