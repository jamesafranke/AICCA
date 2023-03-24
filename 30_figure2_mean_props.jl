using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
using Plots, StatsPlots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step
sm(x) = skipmissing(x)

keys = [:cloud_fraction, :optical_thickness, :top_pressure, :effective_radius, :water_path, :emissivity]
cmaps = [:Greys_9, :Greens_9, :Reds_9, :Purples_9, :Blues_9, :Oranges_9]
clims = [(30,90),(5,12),(500,900),(10,30),(50,400),(0.8,0.975)]

dfc = @chain DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) ) begin  
    dropmissing( [:sst, :lts] )
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin] :num=size(:emissivity)[1] :optical_thickness=mean(sm(:optical_thickness)) :top_pressure=mean(sm(:top_pressure)) :effective_radius=mean(sm(:effective_radius)) :cloud_fraction=mean(sm(:cloud_fraction)) :water_path=mean(sm(:water_path)) :emissivity=mean(sm(:emissivity)) 
    @subset :num.>20
end

dfcc = @chain DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) ) begin  
    @subset :Label.!=0
    dropmissing( [:sst, :lts] )
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin] :num=size(:emissivity)[1] :optical_thickness=mean(sm(:optical_thickness)) :top_pressure=mean(sm(:top_pressure)) :effective_radius=mean(sm(:effective_radius)) :cloud_fraction=mean(sm(:cloud_fraction)) :water_path=mean(sm(:water_path)) :emissivity=mean(sm(:emissivity)) 
    @subset :num.>20
end

for i in 1:6
    @df dfcc scatter(:xbin, :ybin, marker_z=cols(keys[i]), color=cmaps[i], markershape=:square, markersize=2.7, markeralpha=0.8, 
    markerstrokewidth=0.0, colorbar_title=String(keys[i]), legend=false, colorbar=true, clim=(clims[i]), size=(560,500), dpi=900, grid=false)
    xlims!(283, 305)
    ylims!(4, 34)
    png("./figures/heatmap_without_clear_sky_$(String(keys[i])).png")

    @df dfc scatter(:xbin, :ybin, marker_z=cols(keys[i]), color=cmaps[i], markershape=:square, markersize=2.7, markeralpha=0.8, 
    markerstrokewidth=0.0, colorbar_title=String(keys[i]), legend=false, colorbar=true, clim=(clims[i]), size=(560,500), dpi=900, grid=false)
    xlims!(283, 305)
    ylims!(4, 34)
    png("./figures/heatmap_with_clear_sky_$(String(keys[i])).png")
end 


