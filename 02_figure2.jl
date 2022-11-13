using Plots; gr(); Plots.theme(:default) #plotlyjs()
using CSV, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

# load in class data for the tropics merged with climate vars
df = CSV.read( joinpath(pwd(), "data/processed/all_subtropic_label_with_climate.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@subset! df :Label.!=43 
dfp = DataFrame()
append!(dfp,  @subset df :lat.>7  :lat.<39 :lon.>-165 :lon.<-100)
append!(dfp, @subset df :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70)
append!(dfp, @subset df :lat.>-35 :lat.<0  :lon.>-25  :lon.<20 )
df = nothing
dropmissing!(dfp, [:lts, :blh] )

dfc = @chain dfp begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @subset :total.>50
end

colorclass = [25, 6, 27, 8, 40, 30, 32, 33, 36, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:Hiroshige, 10, categorical = true)

temp = @subset dfc :plotclass.==0
scatter(temp.ltsbin, temp.blhbin, markershape = :square, markersize = 5, markeralpha = 1, markercolor = :lightgray, 
    markerstrokewidth = 0.75, markerstrokecolor=:lightgray, size=(500,550), grid = false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
        markersize = 5, markeralpha = 1, markercolor = colors[i], 
        markerstrokewidth = 0.75, markerstrokecolor=:lightgray)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = 5, markeralpha = 1, markercolor = :gray, 
    markerstrokewidth = 0.75, markerstrokecolor=:gray )

xlims!(10.25, 30)
ylims!(212.5, 1425-12.5)
png("./figures/heatmap.png")


temp = @subset dfp :Label.!=0
temp = @by temp [:lat, :lon] :counts=size(:lat)[1]
temp = @orderby temp :counts rev=true
temp = @subset temp :lat.<0

temp = @subset dfp :lat.==35.5 :lon.==-134.5

temp = @subset dfp :lat.==-33.5 :lon.==-93.5
dfc = @chain temp begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @subset :total.>50
end

colorclass = [25, 6, 27, 8, 40, 30, 32, 33, 36, 35]
otherclass = [1,2,3,4,5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,28,29,31,34,37,38,39,41,42]
colors = cgrad(:Hiroshige, 10, categorical = true)

temp = @subset dfc :plotclass.==0
scatter(temp.ltsbin, temp.blhbin, markershape = :square, markersize = 5, markeralpha = 1, markercolor = :lightgray, 
    markerstrokewidth = 0.75, markerstrokecolor=:lightgray, size=(500,550), grid = false, leg=false, dpi=800)

for (i, class) in enumerate(colorclass)
    temp = @subset dfc :plotclass.==class
    if size(temp)[1] > 0
        scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
        markersize = 5, markeralpha = 1, markercolor = colors[i], 
        markerstrokewidth = 0.75, markerstrokecolor=:lightgray)
    end
end

temp = @rsubset dfc :plotclass in otherclass
scatter!(temp.ltsbin, temp.blhbin, markershape = :square, markersize = 5, markeralpha = 1, markercolor = :gray, 
    markerstrokewidth = 0.75, markerstrokecolor=:gray )

xlims!(10.25, 30)
ylims!(212.5, 1425-12.5)
png("./figures/heatmap_SP_gridcell.png")







#old

dfb = @subset df :lat.>10  :lat.<40 :lon.>-160 :lon.<-95  #north pacific
dfp = @subset df :lat.>-40 :lat.<7  :lon.>-115 :lon.<-70  #south pacific
dfa = @subset df :lat.>-35 :lat.<6  :lon.>-30  :lon.<20   #south alantic
dfi = @subset df :lat.>-35 :lat.<-5 :lon.>55   :lon.<120  #indian
regions = zip( ["NP","SP","SA","IN"],[dfb, dfp, dfa, dfi] )

for (region, case) in regions
    dfc = @chain case begin  
        dropmissing( [:lts, :blh] )
        @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
        @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
        @orderby :counts rev=true
        @aside dft = @subset _ :Label.!=0 
        @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
        @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
        leftjoin( dft, on=[:ltsbin, :blhbin] )
        @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
        @subset :total.>100
    end

    temp = @subset dfc :plotclass.==0
    scatter(temp.ltsbin, temp.blhbin, markershape = :square,
    markersize = 5, markeralpha = 1, markercolor = :lightgray, 
    markerstrokewidth = 0.75, markerstrokecolor=:lightgray,
    size=(500,550), grid = false, leg=false, dpi=800)

    for (i, class) in enumerate(colorclass)
        temp = @subset dfc :plotclass.==class
        if size(temp)[1] > 0
            scatter!( temp.ltsbin, temp.blhbin, markershape = :square,
            markersize = 5, markeralpha = 1, markercolor = colors[i], 
            markerstrokewidth = 0.75, markerstrokecolor=:lightgray)
        end
    end

    temp = @rsubset dfc :plotclass in otherclass
    scatter!(temp.ltsbin, temp.blhbin, markershape = :square,
    markersize = 5, markeralpha = 1, markercolor = :gray, 
    markerstrokewidth = 0.75, markerstrokecolor=:gray )

    xlims!(10.25, 30)
    ylims!(212.5, 1425-12.5)
    png("./figures/$(region)_heatmap.png")
end


function get_pop() 
    #cumbersome way to get the most popular classes for plotting colors
    out = DataFrame()
    for (region, case) in regions
        dfc = @chain case begin  
            dropmissing( [:lts, :blh] )
            @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
            @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
            @orderby :counts rev=true
            @aside dft = @subset _ :Label.!=0 
            @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
            @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
            leftjoin( dft, on=[:ltsbin, :blhbin] )
            @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
            @subset :total.>100
        end
        append!(out, dfc)
    end

    out = @by out :plotclass :tempcount= size(:total)[1] 
    out = @orderby out :tempcount
    otherclass = first(out, 19).plotclass
    colorclass = last(out, 11).plotclass
    return otherclass, colorclass[colorclass.!=0]
end
otherclass, colorclass = get_pop()



dfc = @chain dfp begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh.*4, digits=-2) ./4
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass= :maxcount/:total>0.3 ? :maxclass : :nonzeroclass 
    @subset :total.>100
end

plotlyjs()
scatter(dfc.ltsbin, dfc.blhbin, group = dfc.plotclass,
size=(500,550), grid = false, leg=false, dpi=800)














df = CSV.read( "./carly_cloud/allDat-20221024.csv", DataFrame )
df2 = CSV.read( "./carly_cloud/all_ACCLIP.csv", DataFrame )
rename!(df2, :UTC_Seconds => :T_UTC)
df.T_UTC = round.( df.T_UTC, digits=0 )
df.T_UTC = convert.( Int64, df.T_UTC )
df2.T_UTC = convert.( Int64, df2.T_UTC )

leftjoin!(df, df2, on = [:YEAR,:MONTH,:DAY,:T_UTC])
CSV.write( "./carly_cloud/allDat_and_ACCLIP.csv" , df, index = false)
