using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
using Plots, StatsPlots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

dfc = @chain DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) ) begin  
    #@subset :Label.!=0
    dropmissing( [:sst, :lts] )
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin] :num=size(:optical_thickness)[1] :optical_thickness=mean(skipmissing(:optical_thickness)) :top_pressure=mean(skipmissing(:top_pressure)) :effective_radius=mean(skipmissing(:effective_radius)) :cloud_fraction=mean(skipmissing(:cloud_fraction)) :water_path=mean(skipmissing(:water_path)) :emissivity=mean(skipmissing(:emissivity)) 
    @subset :num.>20
end

keys=[:cloud_fraction, :optical_thickness, :top_pressure, :effective_radius, :water_path, :emissivity]
cmaps = [:Greys_9, :Greens_9, :Reds_9, :Purples_9, :Blues_9, :Oranges_9]
clims = [(30,90),(5,12),(500,900),(10,30),(50,400),(0.8,0.975)]

pa = []
for i in 1:6
    p = @df dfc scatter(:xbin, :ybin, marker_z=cols(keys[i]), color=cmaps[i], markershape=:square, markersize=2.7, markeralpha=0.8, 
    markerstrokewidth=0.0, colorbar_title=String(keys[i]), legend=false, colorbar=true, clim=(clims[i]))
    push!(pa, p)
end 

l = @layout [ a{0.33w, 0.5h} b{0.33w, 0.5h} c{0.33w, 0.5h}
              d{0.33w, 0.5h} e{0.33w, 0.5h} f{0.33w, 0.5h} ]

Plots.gr_cbar_width[] = 0.02
plot(pa..., layout=l, size=(1000,500), dpi=900, grid=false)
xlims!()
png("./figures/heatmap_with_clear_sky.png")








