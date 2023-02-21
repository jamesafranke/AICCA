using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
df = dropmissing(df, [:sst, :lts] )

dfc = @chain df begin  
    @subset :Label.!=0
    @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label) :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( _, dft, on=[:xbin, :ybin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>20
end

colorclass = [ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35]
colors = cgrad(:vik, 10, categorical = true, rev = true)
colorclass2 = [ 2, 8, 19]
colors2 = cgrad(:Cassatt2, 6, categorical = true, rev=true)

function plot_loc(lat, lon)
    marksize = 2.7
    #l = @layout [a b]
    plot( size=(500,500), grid = false, leg=false, dpi=900)

    for (i, class) in enumerate(colorclass)
        temp = @subset dfc :plotclass.==class
        scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors[i], markerstrokewidth=0)
    end

    for (i, class) in enumerate(colorclass2)
        temp = @subset dfc :plotclass.==class
        scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors2[i], markerstrokewidth=0)
    end

    temp = @rsubset dfc :plotclass .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
    scatter!(temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=:gray, markerstrokewidth=0)

    dft = @chain df begin 
        @subset :Label.!=0 :lat.==lat :lon.==lon
        @transform :xbin=round_step.(:sst, 0.25) :ybin=round_step.(:lts, 0.36)
        @by [:xbin, :ybin, :Label] :counts=size(:Label)[1]
        @orderby :counts
        @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts)
    end

    scalef(x) = x .* 3
    
    for (i, class) in enumerate(colorclass)
        temp = @subset dft :maxclass.==class
        scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.maxcount), markeralpha = 0.7, markercolor=colors[i], markerstrokewidth=0)
    end
    
    for (i, class) in enumerate(colorclass2)
        temp = @subset dft :maxclass.==class
        scatter!( temp.xbin, temp.ybin, markershape=:circle, markersize=scalef(temp.maxcount), markeralpha = 0.7, markercolor=colors2[i], markerstrokewidth=0)
    end
    
    xlims!(283, 305)
    ylims!(4, 34)
    #png("./figures/heatmap_lts_sst_$(lat)_$(lon).png")
end


#NP
plot_loc(29.5,-130.5)
#SP
plot_loc(-18.5, -80.5)
#SPW
plot_loc(-18.5, -100.5)
#SA
plot_loc(-29.5,7.5)


plot_loc(29.5,-135.5)



plot_loc(-29.5,-5.5)





for (i, class) in enumerate(colorclass)
    temp = @subset dft :maxclass.==class
    scatter!( temp.date, temp.lts, markershape = :circle, markersize = 5, markeralpha = 0.8, markercolor = colors[i], markerstrokewidth = 0, markerstrokecolor=:black)
end


@subset df :lat.==29.5 :lon.==-130.5

plot_loc(29.5,-135.5)

plot_loc(-29.5,-5.5)