using Arrow, CSV, DataFrames, DataFramesMeta, Dates, ProgressMeter
using Plots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = CSV.read( "./data/raw/ibtracs.ALL.list.v04r00.csv", DataFrame)
@select! df :SEASON :NUMBER :BASIN :SUBBASIN :NAME :ISO_TIME :NATURE :LAT :LON :WMO_WIND :WMO_PRES :WMO_AGENCY :TRACK_TYPE :USA_SSHS :LANDFALL :TOKYO_GRADE :TOKYO_WIND :TOKYO_PRES :USA_WIND :USA_PRES
@subset! df :SEASON.>1999
Arrow.write("./data/processed/ibtracs_2000-2022.arrow" , df )


df = DataFrame( Arrow.Table( "./data/processed/ibtracs_2000-2022.arrow" ) )










print(names(df))

df.SEASON  = convert.( Float32, df.SEASON )