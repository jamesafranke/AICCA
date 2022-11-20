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

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :circle, markersize = temp.fracinbin * 12, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 0.05, markerstrokecolor=:gray )

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

xlims!(5, 32.25)
ylims!(0, 2000)
png("./figures/heatmap_day_percentage.png")


temp = @subset dfc :plotclass.==0
scatter(temp.ltsbin, temp.blhbin, markershape = :circle, markersize = 0.5, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.00, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=800)

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :circle, markersize = temp.maxcount./500, markeralpha = 0.8, markercolor = :gray, 
    markerstrokewidth = 0.05, markerstrokecolor=:gray )

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :circle,
        markersize = temp.maxcount./500, markeralpha = 0.7, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=:black)
    end
end

xlims!(5, 32.25)
ylims!(0, 2000)
png("./figures/heatmap_day_occurance.png")



#############################
### for one location only ###
#############################

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:roma, 10, categorical = true)

function plot_loc(lat, lon)
    marksize = 4.1
    temp = @subset dfc :plotclass.==0
    scatter(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = :lightgray, 
        markerstrokewidth = 0, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=900)

    for (i, class) in enumerate(colorclass)
        temp = @subset dfc :plotclass.==class
        if size(temp)[1] > 0
            scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
            markersize = marksize, markeralpha = 0.3, markercolor = colors[i], 
            markerstrokewidth = 0, markerstrokecolor=:black)
        end
    end

    temp = @rsubset dfc :plotclass in otherclass
    scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = :gray, 
        markerstrokewidth = 0, markerstrokecolor= :gray )

    dft = @chain df begin  
        @subset :lat.==lat :lon.==lon
        dropmissing( [:lts, :blh] )
        @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
        @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
        @orderby :counts rev=true
        @aside dft = @subset _ :Label.!=0 
        @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
        @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
        leftjoin( dft, on=[:ltsbin, :blhbin] )
        @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    end

    temp = @rsubset dft :plotclass in otherclass
    scatter!(temp.ltsbin, temp.blhbin, markershape = :circle, 
        markersize = temp.maxcount.*5, markeralpha = 0.5, markercolor = :gray, 
        markerstrokewidth = 0.0, markerstrokecolor=:gray )

    marksize = 4
    for (i, class) in enumerate(colorclass)
        temp = @subset dft :plotclass.==class
        if size(temp)[1] > 0
            scatter!( temp.ltsbin, temp.blhbin, markershape = :circle,
            markersize = temp.maxcount.*5, markeralpha = 0.7, markercolor = colors[i], 
            markerstrokewidth = 0.0, markerstrokecolor=:black)
        end
    end

    xlims!(5, 32.25)
    ylims!(0, 2000)
    png("./figures/heatmap_day_$(lat)_$(lon).png")
end

#NP
plot_loc(29.5,-130.5)
#SP
plot_loc(-18.5, -80.5)
#SPW
plot_loc(-18.5, -100.5)
#SA
plot_loc(-29.5,7.5)


#############################
### check precip          ###
#############################

df.pr
dfp = @subset df :pr.>1
dfc = @chain dfp begin  
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
    @subset :total.>10
end

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
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
png("./figures/heatmap_day_pr.png")

#############################
### check aerosols        ###
#############################

dfp = @subset df :aot.<0.1
dfc = @chain dfp begin  
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
    @subset :total.>10
end

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
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
png("./figures/heatmap_day_lowaot.png")


########################################
### check other driver dimesions t q ###
########################################

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
    @subset :total.>10
end

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:roma, 10, categorical = true)

marksize = 3.7
temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(400,600), grid = false, leg=false, dpi=900)

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
png("./figures/heatmap_day_t_q.png")


##########################################
### check other driver dimesions w sst ###
##########################################

dfc = @chain df begin  
    dropmissing( [:w, :sst] )
    @transform :xbin=round.(:sst, digits=0) :ybin=round.(:w./3, digits=4)*3
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:xbin, :ybin] :nonzeroclass=last(:Label)  :totalnozero=sum(:counts)
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:xbin, :ybin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @transform :fracinbin=:maxcount./:totalnozero
    @subset :total.>10
end

colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:roma, 10, categorical = true)

marksize = 3.7
temp = @subset dfc :plotclass.==0
scatter(temp.xbin, temp.ybin, markershape = :square, markersize = marksize, markeralpha = 0.5, markercolor = :lightgray, 
    markerstrokewidth = 0.5, markerstrokecolor=:lightgray, size=(400,600), grid = false, leg=false, dpi=900)

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
png("./figures/heatmap_day_w_sst.png")



#### DAILY ##########Arrow.write(joinpath(pwd(),"data/processed/subtropic_sc_label_hourly_clim.arrow"), df)

df = DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_hourly_clim.arrow")) )

dfc = @chain df begin  
    dropmissing( [:ltsh, :blhh] )
    @transform :ltsbin=round.(:ltsh.*2, digits=0)./2 :blhbin=round.(:blhh./3, digits=-1)*3
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
png("./figures/heatmap_hourly.png")


function plot_loc_hour(lat, lon)
    marksize = 4.1
    temp = @subset dfc :plotclass.==0
    scatter(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = :lightgray, 
        markerstrokewidth = 0, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=900)

    for (i, class) in enumerate(colorclass)
        temp = @subset dfc :plotclass.==class
        if size(temp)[1] > 0
            scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
            markersize = marksize, markeralpha = 0.3, markercolor = colors[i], 
            markerstrokewidth = 0, markerstrokecolor=:black)
        end
    end

    temp = @rsubset dfc :plotclass in otherclass
    scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = :gray, 
        markerstrokewidth = 0, markerstrokecolor= :gray )

    dft = @chain df begin  
        @subset :lat.==lat :lon.==lon
        dropmissing( [:ltsh, :blhh] )
        @transform :ltsbin=round.(:ltsh.*2, digits=0)./2 :blhbin=round.(:blhh.*4, digits=-2) ./4
        @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
        @orderby :counts rev=true
        @aside dft = @subset _ :Label.!=0 
        @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
        @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
        leftjoin( dft, on=[:ltsbin, :blhbin] )
        @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    end

    temp = @rsubset dft :plotclass in otherclass
    scatter!(temp.ltsbin, temp.blhbin, markershape = :circle, 
        markersize = temp.maxcount.*5, markeralpha = 0.5, markercolor = :gray, 
        markerstrokewidth = 0.0, markerstrokecolor=:gray )

    marksize = 4
    for (i, class) in enumerate(colorclass)
        temp = @subset dft :plotclass.==class
        if size(temp)[1] > 0
            scatter!( temp.ltsbin, temp.blhbin, markershape = :circle,
            markersize = temp.maxcount.*5, markeralpha = 0.7, markercolor = colors[i], 
            markerstrokewidth = 0.0, markerstrokecolor=:black)
        end
    end

    xlims!(5, 32.25)
    ylims!(0, 2000)
    png("./figures/heatmap_hour_$(lat)_$(lon).png")
end

plot_loc_hour(29.5,-130.5)
#SP
plot_loc_hour(-18.5, -80.5)
#SPW
plot_loc_hour(-18.5, -100.5)
#SA
plot_loc_hour(-29.5,7.5)



### indivudial class plots

df = DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_hourly_clim.arrow")) )

dfc = @chain df begin  
    dropmissing( [:ltsh, :blhh] )
    @transform :ltsbin=round.(:ltsh.*2, digits=0)./2 :blhbin=round.(:blhh./3, digits=-1)*3
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
colors = cgrad(:roma, 10, categorical = true)

for (i, class) in enumerate(colorclass)
    marksize = 4.1
    temp = @subset dfc :plotclass.==0
    scatter(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = :lightgray, 
        markerstrokewidth = 0, markerstrokecolor=:lightgray, size=(500,600), grid = false, leg=false, dpi=900)

    temp = @rsubset dfc :plotclass.==class
    scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = marksize, markeralpha = 0.3, markercolor = colors[i], 
        markerstrokewidth = 0, markerstrokecolor=colors[i])

    dft = @chain df begin  
        dropmissing( [:ltsh, :blhh] )
        @subset :Label.==class
        @transform :ltsbin=round.(:ltsh.*2, digits=0)./2 :blhbin=round.(:blhh./3, digits=-1)*3
        @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
        @orderby :counts rev=true
        @by [:ltsbin, :blhbin] :maxcount=last(:counts)
    end

    scatter!( dft.ltsbin, dft.blhbin, markershape = :circle, markersize = dft.maxcount./500, 
    markeralpha = 0.7, markercolor = colors[i],  markerstrokewidth = 0, markerstrokecolor=:black)

    xlims!(5, 32.25)
    ylims!(0, 2000)
    title!("class_$class")
    png("./figures/heatmap_day_occurance_$(class).png")
end


dfc = @chain df begin  
    dropmissing( [:ltsh, :blhh] )
    @transform :ltsbin=round.(:ltsh.*2, digits=0)./2 :blhbin=round.(:blhh./3, digits=-1)*3
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

dft = @chain df begin  
    dropmissing( [:ltsh, :blhh] )
    @subset :Label.==class
    @transform :ltsbin=round.(:ltsh.*2, digits=0)./2 :blhbin=round.(:blhh./3, digits=-1)*3
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

for class in colorclass
    total = size(@subset df :Label.==class)[1]
    temp = @subset dfc :plotclass.==class
    inregion = sum(temp.maxcount)
    print( class,"___", inregion/total * 100)
end

class = 27
total = size(@subset df :Label.==class)[1]
temp = @subset dfc :plotclass.==class
inregion = sum(temp.maxcount)
print( class,"___", inregion/total * 100)
