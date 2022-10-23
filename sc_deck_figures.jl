using Plots, StatsPlots, UnicodePlots; plotlyjs(); theme(:dark) 
using DataFrames, DataFramesMeta, Query, CSV, Dates
using Statistics, StatsBase
using DataFramesMeta: @orderby, @subset

root = "AICCA/data/processed/sc_counts/"
fl = filter(!contains(".DS"), readdir(root) )
df = DataFrame()
for i in fl append!( df, @transform!( CSV.read( joinpath(root, i), DataFrame ), region = split(i, "_")[3]) ) end

dfsp = @subset(df, :region == "spacific")


@df dft scatter(:lon, :lat, group = :idn)


using AWS, AWSS3

p = S3Path("s3://noaa-himawari8/")#, config=global_aws_config())
readdir(p)





