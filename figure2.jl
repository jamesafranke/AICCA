using Plots; gr(); Plots.theme(:default)
using CSV, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

# load in class data for the tropics merged with climate vars
df = CSV.read( joinpath(pwd(), "data/processed/all_subtropic_label_w_sst_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )
@subset! df :Label.!=43 
dfb = @subset df :lat.>15  :lat.<40  :lon.>-155 :lon.<-100  #north pacific
dfp = @subset df :lat.>-40 :lat.<7   :lon.>-110 :lon.<-70   #south pacific
dfa = @subset df :lat.>-35 :lat.<6   :lon.>-30  :lon.<20    #south alantic
dfi = @subset df :lat.>-35 :lat.<0   :lon.>55   :lon.<120   #indian

histogram( dfi.w, size=(500,500), dpi = 300)
xlims!(0.01, 0.05)

### test subsidence ####
for (i, test) in enumerate([dfb, dfp, dfa, dfi])
    case = "strong_subsidence"
    dfc = @chain test begin  
        @subset :w.>0.03 #:w.<0.03
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
    title!(case)
    ylabel!("class share [%]")
    png("./figures/$(i)_$(case).png")
end

