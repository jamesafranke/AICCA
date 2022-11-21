using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table( "./data/processed/subtropic_sc_label_daily_with_frac.arrow"))
df = @subset df :Label .!= 43

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:roma, 10, categorical = true)

dfc = @chain df begin 
    dropmissing( [:blh, :lts] ) 
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


### t and q 
dfc = @chain df begin  
    dropmissing( [:t, :q] )
    @transform :xbin=round.(:t, digits=0) :ybin=round.(:q./3, digits=4)*3
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label)  :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:xbin, :ybin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>100
end

marksize = 3.7
temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(400,600), grid = false, leg=false, dpi=900, ytickfontrotation=0)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.xbin, temp.ybin, markershape = :square,
        markersize = marksize, markeralpha = 0.9, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 1, markerstrokecolor= :gray )

#xlims!(250, 280)
#ylims!(0, )
xlabel!("925 hpa temperature [k]")
ylabel!("925 hpa specific humidity [kg/kg]")
png("./figures/heatmap_day_t_q.png")


### w and sst 
dfs = dropmissing(df, [:w, :sst] )

dfc = @chain dfs begin  
    @transform :xbin=round.(:sst./2, digits=1)*2 :ybin=round.(:w./2, digits=2)*2
    @aside replace!(_.ybin, -0.0 => 0.0)
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label)  :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:xbin, :ybin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>100
end

marksize = 2.2
temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(500,500), grid = false, leg=false, dpi=900, ytickfontrotation=0)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.xbin, temp.ybin, markershape = :square,
        markersize = marksize, markeralpha = 0.9, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 1, markerstrokecolor= :gray )

#xlims!(250, 280)
#ylims!(0, )
xlabel!("sst [k]")
ylabel!("700 hpa vertical velocity [m/s]")
png("./figures/heatmap_day_sst_w.png")


temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :circle, markersize = 0.5, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.00, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=800)

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.xbin, temp.ybin, markershape = :circle, markersize = temp.fracinbin * 12, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 0.05, markerstrokecolor=:gray )

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        temp1 = @subset temp :fracinbin.>0.33
        scatter!( temp1.xbin, temp1.ybin, markershape = :circle,
        markersize = temp1.fracinbin * 18, markeralpha = 0.8, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
        temp2 = @subset temp :fracinbin.<0.33
        scatter!( temp2.xbin, temp2.ybin, markershape = :circle,
        markersize = temp2.fracinbin * 18, markeralpha = 0.8, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

png("./figures/heatmap_day_percentage_sst_w.png")


temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :circle, markersize = 0.5, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.00, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=800)

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.xbin, temp.ybin, markershape = :circle, markersize = temp.maxcount./500, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 0.05, markerstrokecolor=:gray )

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.xbin, temp.ybin, markershape = :circle,
        markersize = temp.maxcount./500, markeralpha = 0.7, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

png("./figures/heatmap_day_occurance_sst_w.png")



all = @chain dfs begin  
    @transform :xbin=round.(:sst./2, digits=1)*2 :ybin=round.(:w./2, digits=2)*2
    @aside replace!(_.ybin, -0.0 => 0.0)
    @by [:xbin, :ybin] :allcounts=size(:lat)[1]
end

for (i, class) in enumerate(colorclass)
    marksize = 4.1

    temp = @subset dfc :plotclass.==class
    scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=colors[i], size=(500,600), grid = false, leg=false, dpi=900)

    dft = @chain dfs begin  
        @subset :Label.==class
        @transform :xbin=round.(:sst./2, digits=1)*2 :ybin=round.(:w./2, digits=2)*2
        @aside replace!(_.ybin, -0.0 => 0.0)
        @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
        @subset :counts.>10
    end

    leftjoin!(dft, all, on=[:xbin, :ybin])
    @transform! dft :fracbin=:counts./:allcounts

    scatter!( dft.xbin, dft.ybin, markershape=:circle, markersize = dft.fracbin.*18, 
    markeralpha = 0.9, markercolor = colors[i],  markerstrokewidth = 0, markerstrokecolor=:black)

    xlims!(284, 304)
    ylims!(-1.2, 0.6)
    title!("class_$class")
    png("./figures/heatmap_day_percentage_$(class)_w_sst.png")
end



for (i, class) in enumerate(colorclass)
    marksize = 4.1

    temp = @subset dfc :plotclass.==class
    scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=colors[i], size=(500,600), grid = false, leg=false, dpi=900)

    dft = @chain dfs begin  
        @subset :Label.==class
        @transform :xbin=round.(:sst./2, digits=1)*2 :ybin=round.(:w./2, digits=2)*2
        @aside replace!(_.ybin, -0.0 => 0.0)
        @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
        @subset :counts.>10
    end

    scatter!( dft.xbin, dft.ybin, markershape=:circle, markersize = dft.counts./300, 
    markeralpha = 0.9, markercolor = colors[i],  markerstrokewidth = 0, markerstrokecolor=:black)

    xlims!(284, 304)
    ylims!(-1.2, 0.6)
    title!("class_$class")
    png("./figures/heatmap_day_occurances_$(class)_w_sst.png")
end










for class in colorclass
    total = size(@subset df :Label.==class)[1]
    temp = @rsubset dfc :plotclass.==class || :plotclass.==30 
    inregion = sum(temp.maxcount)
    print( class,"___", inregion/total * 100)
end


#class 25 --> 45% of occurrences are in dominant region
6 --> 10% 
27 -->17%
8 --> 41%
40 --> 32%
36 --> 2%
32 --> 0.03%
33 --> 0.03%
30 --> 96%
35 --> 49%
