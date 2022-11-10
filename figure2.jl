using Plots; gr(); Plots.theme(:default)
using CSV, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

# load in class data for the tropics merged with climate vars
df = CSV.read( joinpath(pwd(), "data/processed/all_subtropic_label_w_sst_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@subset! df :Label.!=43 

### test subsidence ####
dfcs = @chain df begin  
    @subset :lat.<35 :lat.>-35 #:lon.<20 :lon.>-30
    @subset :w.>0.035 # :w.<0.035
    dropmissing( :aot1 )
    @transform :aotbin=round.(:aot1, digits=1) 
    @aside replace!(_.aotbin, -0.0=>0.0)
    @by [:aotbin, :Label] :counts=size(:lat)[1]
    @aside dft = @by _ :aotbin :total_per_bin=sum(:counts)
    leftjoin( dft, on=:aotbin )
    @transform :classshare=:counts./:total_per_bin
end

scatter(dfc.aotbin, dfc.classshare *100, group = dfc.Label, size=(500,500), leg=false, dpi = 300)
xlims!(-0.21,1.01)
ylims!(0, 40)
xlabel!("aerosol optical depth")
title!("weak subsidence")
ylabel!("class share [%]")
png("./figures/weak_subsidence.png")

scatter(dfcs.aotbin, dfcs.classshare *100, group = dfcs.Label, size=(500,500), leg=false, dpi = 300)
xlims!(-0.21,1.01)
ylims!(0, 40)
xlabel!("aerosol optical depth")
title!("strong subsidence")
ylabel!("class share [%]")
png("./figures/strong_subsidence.png")

temp = @subset dfc :aotbin .== 0.8
temp = @orderby temp :classshare
### test sst ####
dfc = @chain df begin  
    @subset :lat.<-5 :lat.>-35 :lon.<20 :lat.>-30
    @subset :sst.>23
    dropmissing( :aot1 )
    @transform :aotbin=round.(:aot1, digits=1) 
    @aside replace!(_.aotbin, -0.0=>0.0)
    @by [:aotbin, :Label] :counts=size(:lat)[1]
    @aside dft = @by _ :aotbin :total_per_bin=sum(:counts)
    leftjoin( dft, on=:aotbin )
    @transform :classshare=:counts./:total_per_bin
end

scatter(dfc.aotbin, dfc.classshare *100, group = dfc.Label, size=(500,500), leg=false, dpi = 300)
xlims!(-0.21,1.01)
ylims!(0, 60)
xlabel!("aerosol optical depth")
title!("low sst")
ylabel!("class share [%]")
png("./figures/low_sst.png")


scatter(dfc.aotbin, dfc.classshare *100, group = dfc.Label, size=(500,500), leg=false, dpi = 300)
xlims!(-0.21,1.01)
ylims!(0, 60)
xlabel!("aerosol optical depth")
title!("high sst")
ylabel!("class share [%]")
png("./figures/high_sst.png")



dfc = @subset df :lat.<0 :lat.>-35 :lon.<-70 :lat.>-115

histogram( dfc.w, size=(500,500), dpi = 300)
xlims!(0.03, 0.06)
xlabel!("sst")
png("./figures/vertical_velocity.png")

histogram( dfc.aot1, size=(500,500), dpi = 300)
xlims!(-0.2, 1)
xlabel!("aot")
png("./figures/aot.png")




temp = @subset df :lat.<0 :lat.>-35 :lon.<-70 :lat.>-115 :w.>0.035  
histogram( temp.aot1, size=(500,500), dpi = 300)
xlims!(-0.2, 1)
xlabel!("aot")
#@rtransform :w_abs = :w < 0.05 ? -1 : 1




###### 
dfc = @chain df begin  
    @subset :lat.<-5 :lat.>-35 :lon.<20 :lon.>-30
    @subset :sst.>23 :w.<0.035 :w.>0.0 
    dropmissing( :aot1 )
    @transform :aotbin=round.(:aot1, digits=1) 
    @aside replace!(_.aotbin, -0.0=>0.0)
    @by [:aotbin, :Label] :counts=size(:lat)[1]
    @aside dft = @by _ :aotbin :total_per_bin=sum(:counts)
    leftjoin( dft, on=:aotbin )
    @transform :classshare=:counts./:total_per_bin
end


scatter(dfc.aotbin, dfc.classshare *100, group = dfc.Label, size=(500,500), leg=false, dpi = 300)
xlims!(-0.21,1.01)
ylims!(0, 60)
xlabel!("aerosol optical depth")
title!("high sst strong subsidence")
ylabel!("class share [%]")
png("./figures/high_sst_strong_subsidence.png")

scatter(dfc.aotbin, dfc.classshare *100, group = dfc.Label, size=(500,500), leg=false, dpi = 300)
xlims!(-0.21,1.01)
ylims!(0, 60)
xlabel!("aerosol optical depth")
title!("low sst weak subsidence")
ylabel!("class share [%]")
png("./figures/low_sst_weak_subsidence.png")