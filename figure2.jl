using Plots; gr(); Plots.theme(:default)
using CSV, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end
root = pwd()

# load in class data for the tropics merged with climate vars
df = CSV.read( joinpath(root, "data/processed/all_subtropic_label_w_sst_aot.csv"), dateformat="yyyy-mm-ddTHH:MM:SS.s", DataFrame )





# get the sub-daily transisions
dft = @chain df begin
    @select :Timestamp :lat :lon :Label
    @transform :day=Date.(:Timestamp)
    @by [:lat, :lon, :day] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :hour_diff=Dates.value.(:Timestamp[end]-:Timestamp[1])./3_600_000
    @subset :day_num.>1
    @subset :class.!=43 
    @subset :nextclass.!=43 
    @rsubset :class.!=0 || :nextclass.!=0
end


# plot some class transisons 
temp = @subset dft :class .== 33 
histogram( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500) )
temp = @subset dft :class .== 32 
histogram!( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500), alpha = 0.5 )



n = 100
ts = range(0, stop = 8π, length = n)
Plots.plot(ts .* cos.(ts), (0.1ts).*sin.(ts), 1:n, w=1, zcolor=reverse(1:n),
    m = (20, 0.5, :blues, Plots.stroke(0)), leg=false, cbar=false, 
    gridstyle=:dash, gridalpha=0.5, tick_direction =:none, foreground_color_axis=:white
)


using Plots
plot(layout = @layout([a{0.1h}; b{0.3w} [c; d e]]), randn(100, 5), 
    t = [:line :histogram :scatter :steppre :bar], leg = false, border = :none)


