using Plots, StatsPlots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
round_step(x, step) = round(x / step) * step

df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_SP.arrow" ) )
@transform! df :rr=:prt./ (Int.(:hours)*24) #messed up origional calc: counted daily total, hourly
met = DataFrame( Arrow.Table( "./data/processed/to_python_subtrop_met_bins.arrow" ) )
@transform! df :xbin=round_step.(:sstp, 0.25) :ybin=round_step.(:ltsp, 0.36)
leftjoin!(df, met, on =[:xbin,:ybin])

#temp =  @subset df Date.(:Timestamp).==Date("2020-10-23") :Label.==35 :maxclass.==35 
t = @subset df :prt.==0
t1 = @subset t :next_label.==35
t2 = @subset t :next_label.!=35
scatter([0],[size(t2)[1]./(size(t1)[1].+size(t2)[1])*100], leg=false, color=:black)

for i in 1:15
    t = @subset df :prt.<i :prt.>(i-1)
    t1 = @subset t :next_label.==35
    t2 = @subset t :next_label.!=35
    scatter!([i-0.5],[size(t2)[1]./(size(t1)[1].+size(t2)[1])*100], color=:black)
end 
#ylims!(0,100)
xlabel!("mean accumulated pr between samples")
ylabel!("transition probability [%]")




colorclass = [ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35]
colors = cgrad(:vik, 10, categorical = true, rev = true)
colorclass2 = [ 2, 8, 19]
colors2 = cgrad(:Cassatt2, 6, categorical = true, rev=true)

met = @subset met :maxcount.>10
marksize = 5
plot( size=(500,500), grid = false, leg=false, dpi=900)

for (i, class) in enumerate(colorclass)
    temp = @subset met :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors[i], markerstrokewidth=0)
end
for (i, class) in enumerate(colorclass2)
    temp = @subset met :maxclass.==class
    scatter!( temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=colors2[i], markerstrokewidth=0)
end
temp = @rsubset met :maxclass .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
scatter!(temp.xbin, temp.ybin, markershape=:square, markersize=marksize, markeralpha=0.3, markercolor=:gray, markerstrokewidth=0)

temp1 = @subset df Date.(:Timestamp).==Date("2020-10-23") :Label.==35 :maxclass.==30
#@subset! temp1 :prt.>0

for (i, class) in enumerate(colorclass)
    temp = @subset temp1 :next_label.==class
    scatter!( temp.sstp, temp.ltsp, markershape=:circle, markersize=5, markeralpha=0.9, markercolor=colors[i], markerstrokewidth=0)
end
for (i, class) in enumerate(colorclass2)
    temp = @subset temp1 :next_label.==class
    scatter!( temp.sstp, temp.ltsp, markershape=:circle, markersize=5, markeralpha=0.9, markercolor=colors2[i], markerstrokewidth=0)
end

temp = @rsubset temp1 :next_label .∉ Ref([ 40, 27, 25, 36, 26, 23, 34, 30, 28, 35, 2, 8, 19,0])
scatter!( temp.sstp, temp.ltsp, markershape=:circle, markersize=5, markeralpha=0.9, markercolor=:gray, markerstrokewidth=0)

for row in eachrow( temp1 )
    x1 = row.sstp+row.sstd
    x2 = row.sstp
    y1 = row.ltsp+row.ltsd
    y2 = row.ltsp
    plot!([x1,x2],[y1,y2], arrow=true, color=:black, linewidth=1, label="")
end

xlims!(286, 298)
ylims!(15, 30)

xlims!(286, 297)
ylims!(19, 34)

xlims!(283, 305)
ylims!(4, 34)
#png("./figures/heatmap_lts_sst_occurance.png")













temp = @subset df Date.(:Timestamp).==Date("2020-10-23") :Label.==35 :maxclass.==35
#@subset temp :prt.==0


histogram(temp.hours, bins = 27)


temp1 = @chain temp begin
    @subset :prt.==0
    @by :next_label :counts=size(:Label)[1]
    @transform :counts=:counts/maximum(:counts)
end
bar(temp1.next_label, temp1.counts, alpha=0.5, label="no pr")

temp1 = @chain temp begin
    @subset :prt.>1
    @by :next_label :counts=size(:Label)[1]
    @transform :counts=:counts/maximum(:counts)
end
bar!(temp1.next_label, temp1.counts, alpha=0.5, label="pr>10")
xlabel!("next class after 35")
ylabel!("relative rate")



