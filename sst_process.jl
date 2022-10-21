using Plots, StatsPlots, UnicodePlots; plotlyjs(); theme(:dark) 
using DataFrames, DataFramesMeta, Query, CSV, Dates
using Statistics
using DataFramesMeta: @orderby
using NetCDF

### SST data: NOAA NCEP EMC CMB GLOBAL Reyn_SmithOIv2
sst = ncread("AICCA/data/raw/noaa_ncep_sst.nc","sst")
heatmap( permutedims(sst[:,:,1], [2,1]), c=:balance, )

