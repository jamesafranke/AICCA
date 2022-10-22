using Plots, StatsPlots, UnicodePlots; plotlyjs(); theme(:dark) 
using DataFrames, DataFramesMeta, Query, CSV, Dates
using Statistics, StatsBase
using Images
using DataFramesMeta: @orderby
using ProgressMeter



@select!(dft, :lat, :lon, :lowtype, :idn )
@df dft scatter(:lon, :lat, group = :idn)



UnicodePlots.heatmap(lab, colormap=:inferno, height=40, width=45, border=:none, colorbar_border=:none, zlabel="cluster")
