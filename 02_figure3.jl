using Plots; gr(); Plots.theme(:default) #plotlyjs()
using CSV, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

# load in class data for the tropics merged with climate vars
df = CSV.read( joinpath(pwd(), "data/processed/all_subtropic_label_with_climate.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@subset! df :Label.!=43 
dfb = @subset df :lat.>10  :lat.<40 :lon.>-160 :lon.<-95  #north pacific
dfp = @subset df :lat.>-40 :lat.<7  :lon.>-115 :lon.<-70  #south pacific
dfa = @subset df :lat.>-35 :lat.<6  :lon.>-30  :lon.<20   #south alantic
dfi = @subset df :lat.>-35 :lat.<0  :lon.>55   :lon.<120  #indian
regions = zip( ["NP","SP","SA","IN"],[dfb, dfp, dfa, dfi] )


### test subsidence or stability or sst ####
for (region, dftemp) in regions
    case = "stable boundary layer"
    dfc = @chain dftemp begin  
        @subset :lts .>16.4 #:blh.<830  #:w.>0.03
        dropmissing( :aot1 )
        @transform :aotbin=round.(:aot1, digits=1) 
        @aside replace!(_.aotbin, -0.0=>0.0)
        @by [:aotbin, :Label] :counts=size(:lat)[1]
        @aside dft = @by _ :aotbin :total_per_bin=sum(:counts)
        leftjoin( dft, on=:aotbin )
        @transform :classshare=:counts./:total_per_bin
    end

    scatter(dfc.aotbin, dfc.classshare *100, group = dfc.Label, size=(400,400), leg=false, dpi=800)
    xlims!(-0.21,1.01)
    ylims!(0, 60)
    xlabel!("aerosol optical depth")
    ylabel!("class share [%]")
    title!("$(region) $(case)")
    png("./figures/$(region)_$(case).png")
end

@transform! dfb :hour=Hour.(:Timestamp)
mean( dfb.hour )

histogram( dfa.lts, size=(500,500), dpi=800 )
xlims!(13, 16)

histogram( dfa.w, size=(500,500), dpi=300 )
xlims!(13, 16)

histogram( dfa.blh, size=(500,500), dpi=800 )
xlims!(13, 16)

median(dfa.lts)
median(dfb.lts)
median(dfp.lts)
median(dfi.lts)
