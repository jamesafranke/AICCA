using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim_all.arrow")) )

dfc = @chain df begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)  :totalnozero=sum(:counts)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>100
end

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
#colors = cgrad(:Hiroshige, 10, categorical = true)  #rev=true)
colors = cgrad(:roma, 10, categorical = true)

marksize = 3.7
temp = @subset dfc :plotclass.==0
scatter(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
        markersize = marksize, markeralpha = 0.9, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 1, markerstrokecolor= :gray )

xlims!(5, 32.25)
ylims!(0, 2000)
png("./figures/heatmap_day.png")


temp = @subset dfc :plotclass.==0
scatter(temp.ltsbin, temp.blhbin, markershape = :circle, markersize = 0.5, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.00, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        temp1 = @subset temp :fracinbin.>0.33
        scatter!( temp1.ltsbin, temp1.blhbin, markershape = :circle,
        markersize = temp1.fracinbin * 12, markeralpha = 0.8, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
        temp2 = @subset temp :fracinbin.<0.33
        scatter!( temp2.ltsbin, temp2.blhbin, markershape = :circle,
        markersize = temp2.fracinbin * 12, markeralpha = 0.8, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :circle, markersize = temp.fracinbin * 12, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 0.05, markerstrokecolor=:gray )

xlims!(5, 32.25)
ylims!(0, 2000)
png("./figures/heatmap_day_percentage.png")


temp = @subset dfc :plotclass.==0
scatter(temp.ltsbin, temp.blhbin, markershape = :circle, markersize = 0.5, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.00, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :circle,
        markersize = temp.total ./ 4000, markeralpha = 0.8, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :circle, markersize = temp.fracinbin * 10, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 0.05, markerstrokecolor=:gray )

xlims!(5, 32.25)
ylims!(0, 2000)
png("./figures/heatmap_day_occurance.png")






#############################
### for one location only ###
#############################

dfc = @chain df begin  
    @subset :lat.==-35 :lon.<-127.5
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @subset :total.>10
end

colorclass = [25, 6, 27, 8, 40, 30, 32, 33, 36, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:Manet, 10, categorical = true);
colors = cgrad(:roma, 10, categorical = true);

marksize = 3

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
        markersize = marksize, markeralpha = 1, markercolor = colors[i], 
        markerstrokewidth = 0.05, markerstrokecolor=:lightgray)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 1, markercolor = :gray, 
    markerstrokewidth = 0.05, markerstrokecolor=:gray )

xlims!(5.25, 36.25)
ylims!(0, 2010)
png("./figures/heatmap_day_one_loc.png")




#########################################
### heatmaps of the indivdual classes ###
#########################################

dfc = @chain df begin  
    @subset :Label.!=0
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @transform :count_norm=:counts/ 4453
end


for (i, class) in enumerate(colorclass)
    temp = @subset dfc :Label.==class
    if size(temp)[1] > 0
        scatter( temp.ltsbin, temp.blhbin, markershape = :square,
        markersize = marksize, markeralpha = temp.count_norm, markercolor = colors[i], 
        markerstrokewidth = 0.00,  size=(500,550), grid = false, leg=false, dpi=800)
        xlims!(5.25, 36.25)
        ylims!(0, 2010)
        png("./figures/heatmap_$(class).png")
    end
end






temp = @subset dfc :Label.==35
temp = @orderby temp :ltsbin
temp = unstack(temp, :blhbin, :ltsbin, :counts)
temp = @orderby temp :blhbin
temp = Matrix(temp)
contour(temp, levels =[1000,2000,3000])

temp = @subset dfc :Label.==30
temp = @orderby temp :ltsbin
temp = unstack(temp, :blhbin, :ltsbin, :counts)
temp = @orderby temp :blhbin
temp = Matrix(temp)
contour!(temp, levels =[1000,2000,3000],cmap=:viridis)

temp = @subset dfc :Label.==32
temp = @orderby temp :ltsbin
temp = unstack(temp, :blhbin, :ltsbin, :counts)
temp = @orderby temp :blhbin
temp = Matrix(temp)
contour!(temp, levels =[1000,2000,3000],cmap=:viridis)