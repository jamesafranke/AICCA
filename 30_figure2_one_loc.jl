using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

dfc = DataFrame( Arrow.Table( "./data/processed/to_python_subtrop_met_bins_1000_eis.arrow" ) )
dfc = @subset dfc :total.>50
rename!(dfc, :xbin=>:t1000, :ybin=>:eis)
@select! dfc :t1000 :eis :plotclass
colorclass = [ 20, 36, 27, 40, 25, 23, 30, 24, 28, 35]
colors = cgrad(:vik, 10, categorical = true, rev = true) 
high = [1,2,3,4,5,6,7,8,9,11,12,17]

df = DataFrame( Arrow.Table( "./data/processed/AICCA_with_climate_no_dec_2021.arrow" ) )
df = @subset df :Label .∈ Ref([25,27,30,35])
#temp = @subset df :pr.<0.1

df = @subset df Date.(:Timestamp).==Date("2020-10-26")
Arrow.write( "./data/processed/AICCA_drizzle_proxy_2010_2013_transitions.arrow", df )


lat = -30
lon = -75
dfts = @subset df :lat.>=lat :lat.<=lat+1 :lon.>=lon :lon.<=lon+1
@transform! dfts :date=Date.(:Timestamp)
dftss = @subset dfts :date.>Date(2009,6,1) :date.<Date(2011,9,1)  :Label.∈Ref([25,27,30,35])

### figure 3 top ###
scatter(size=(400,300), grid = false, leg=false, dpi=800)
for (i, class) in enumerate(colorclass)
    temp = @subset dftss :Label.==class
    @df temp scatter!( :date, :eis, markershape = :circle, markersize = 5, markeralpha = 0.8, 
    markercolor = colors[i], markerstrokewidth = 0, markerstrokecolor=:black)
end
ylims!(-2,24)
png("./figures/fig3a.png")

scatter(size=(400,300), grid = false, leg=false, dpi=800)
for (i, class) in enumerate(colorclass)
    temp = @subset dftss :Label.==class
    @df temp scatter!( :date, :t1000, markershape = :circle, markersize = 5, markeralpha = 0.8, 
    markercolor = colors[i], markerstrokewidth = 0, markerstrokecolor=:black)
end
ylims!(282,294)
png("./figures/fig3b.png")




### get predicted class ###
@select! dftss :Timestamp :Label :t1000 :eis
@transform! dftss :eis=round_step.(:eis, 0.35) :t1000=round_step.(:t1000, 0.30) 
dftss = leftjoin(dftss, dfc, on=[:eis, :t1000])
@transform! dftss :expt=1

scatter(size=(400,300), grid = false, leg=false, dpi=800)
for (i, class) in enumerate(colorclass)
    temp = @subset dftss :plotclass.==class
    @df temp scatter!(:Timestamp, :expt, markershape=:vline, markersize = 10, markeralpha = 0.8, 
    markercolor = colors[i], markerstrokewidth = 1, markerstrokecolor=:black)
end
ylims!(0,2)
png("./figures/fig3_predicted.png")




dft = @chain df begin 
    @subset :Label.!=0 
    @by [:lat, :lon] :range_eis=maximum(:eis) - minimum(:eis)
    @orderby :range_eis rev=true
    #@by [:xbin, :ybin] :maxclass=last(:Label) 
end 



function plot_loc(lat, lon, class)
    marksize = 2.7
    plot( size=(500,500), grid = false, leg=false, dpi=900)

    ### background ###
    for (i, class) in enumerate(colorclass)
        temp = @subset dfc :plotclass.==class
        @df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors[i], markerstrokewidth=0)
    end
    temp = @rsubset dfc :plotclass .∈ Ref(high)
    @df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=:lightgray, markerstrokewidth=0)
    temp = @rsubset dfc :plotclass .∉ Ref(vcat(colorclass, high))
    @df temp scatter!( :xbin, :ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=:gray, markerstrokewidth=0)

    ### forground ###
    dft = @chain df begin 
        @subset :lat.>=lat :lat.<=lat+1 :lon.>=lon :lon.<=lon+1 :Label.==class
        @transform :xbin=round_step.(:t1000, 0.3) :ybin=round_step.(:eis, 0.35)
        @by [:xbin, :ybin] :counts=size(:Label)[1]
    end

    if class == 25 
        color = colors[5]
    elseif class == 27
        color = colors[3]
    elseif class == 30
        color =colors[7]
    elseif class == 35
        color = colors[10]
    end

    scalef(x) = x .* 1.5
    scatter!( dft.xbin, dft.ybin, markershape=:circle, markersize=scalef(dft.counts), markeralpha = 0.7, markercolor=color, markerstrokewidth=0)
    
    xlims!(278, 303)
    ylims!(-3, 26)
    #png("./figures/heatmap_lts_sst_$(lat)_$(lon)_$(class).png")
end


plot_loc(-19, -80, 35) #SP#SP
plot_loc(27, -130, 35)
plot_loc(-27, 6, 35) #SA

plot_loc(-26.75, -73.5, 35) 

plot_loc(33.0, -121.0 , 25) 


 


@df dfts scatter(:Timestamp, :eis)


dfts = @subset df :lat.==33.0 :lon.==-121.0 
marksize = 2.7
plot( size=(500,500), grid = false, leg=false, dpi=900)
for (i, class) in enumerate(colorclass)
    temp = @subset dfts :Label.==class
    @df temp scatter!( :Timestamp, :eis, markershape=:circle, markersize=marksize, markeralpha=1, markercolor=colors[i], markerstrokewidth=0)
end
ylims!(-3,26)


colorclass
temp = @subset dfts :Label.==36
colors
@df temp scatter!( :Timestamp, :eis, markershape=:square, markersize=marksize, markeralpha=1, markercolor=colors[1], markerstrokewidth=0)




#SPW
plot_loc(-16.5, -100.5)


lat = -19
lon = -80
class = 30
dft = @chain df begin 
    @subset :lat.>=lat :lat.<=lat+1 :lon.>=lon :lon.<=-lon+1 :Label.==class
    @transform :xbin=round_step.(:t1000, 0.3) :ybin=round_step.(:eis, 0.35)
    @by [:xbin, :ybin, :Label] :counts=size(:Label)[1]
end


dft = @subset df :lat.>=lat :lat.<=lat+1 :lon.>=lon :lon.<=-lon+1 :Label.==30

scalef(x) = x * 1
for (i, class) in enumerate(colorclass)
    temp = @subset dft :Label.==class
    @df temp scatter!( :xbin, :ybin, markershape=:circle, markersize=:counts, markeralpha = 0.7, markercolor=colors[i], markerstrokewidth=0)
end


df





#dfts = @subset df :lat.==29.5 :lon.==-130.5
lat = 29
lon = -130
dfts = @subset df :lat.>=lat :lat.<=lat+1 :lon.>=lon :lon.<=lon+1
@transform! dfts :date=Date.(:Timestamp)
@subset! dfts :date.>Date(2010,1,1) :date.<Date(2011,6,1)

scatter(size=(800,500), grid = false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfts :Label.==class
    @df temp scatter!( :date, :eis, markershape = :circle, markersize = 5, markeralpha = 0.8, 
    markercolor = colors[i], markerstrokewidth = 0, markerstrokecolor=:black)
end
ylims!(-3,23)

png("./figures/fig3.png")


#sftp 'jfrankeATuchicago.edu@www.cloudsat.cira.colostate.edu:Data/2B-GEOPROF.P1_R05/2012/15*' .



#numbers for liz

df = DataFrame( Arrow.Table( "./data/processed/AICCA_with_climate_no_dec_2021.arrow" ) )
#df = @subset df :Label .∈ Ref([25,27,30,35])
@subset df :Label.!=0

unique(df.Label)

temp = @by df :Label :num=size(:Label)[1]


temp = @orderby temp :num
temp = @subset temp :Label.!=0

@subset df :Label.∈Ref([ 20, 36, 27, 40, 25, 23, 30, 24, 28, 35])

30, 35, 40, 36, 26, 27, 39, 32, 37, 19, 29, 25, 33, 41

temp

bar(temp.Label, temp.num)