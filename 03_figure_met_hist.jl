using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function q2rh(q, t, press = 925)
    t = t.-273.15
    es =  6.112 .* exp.((17.67 .* t)./(t .+ 243.5))
    e  = q .* press ./ (0.378 .* q .+ 0.622)
    rh = e ./ es 
    #rh[rh .> 1] = 1
    #rh[rh .< 0] = 0
    return rh .* 100
end 

q2rh(0.001, 250)


df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
@transform! df :rh=q2rh(:q, :t)

top = @chain df begin
    @by :Label :size=size(:lat)[1]
    @orderby :size
    last(14)
    _.Label
end

temp = @rsubset df :Label in top
histogram(df.Label)

bins=5:0.25:33
temp = @rsubset df :Label.==35
stephist(temp.lts, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.lts, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.lts, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.lts, bins=bins, label="25")
xlabel!("lts")
ylabel!("counts")
png("./figures/hist_lts.png")

bins=283:0.25:305
temp = @rsubset df :Label.==35
stephist(temp.sst, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.sst, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.sst, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.sst, bins=bins, label="25")
xlabel!("sst")
ylabel!("counts")
png("./figures/hist_sst.png")

bins=-1:0.01:1
temp = @rsubset df :Label.==35
stephist(temp.w, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.w, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.w, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.w, bins=bins, label="25")
xlabel!("700hpa vertical velocity")
ylabel!("counts")
png("./figures/hist_w.png")

bins=272:0.25:302
temp = @rsubset df :Label.==35
stephist(temp.t, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.t, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.t, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.t, bins=bins, label="25")
xlabel!("925hpa T")
ylabel!("counts")
png("./figures/hist_T.png")

bins=-16:0.5:22
temp = @rsubset df :Label.==35
stephist(temp.u, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.u, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.u, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.u, bins=bins, label="25")
xlabel!("925 u wind")
ylabel!("counts")
png("./figures/hist_u.png")

bins=-16:0.5:22
temp = @rsubset df :Label.==35
stephist(temp.v, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.v, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.v, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.v, bins=bins, label="25")
xlabel!("925 v wind")
ylabel!("counts")
png("./figures/hist_v.png")

bins=0:0.0002:0.02
temp = @rsubset df :Label.==35
stephist(temp.q, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.q, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.q, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.q, bins=bins, label="25")
xlabel!("925 specific humidity")
ylabel!("counts")
png("./figures/hist_q.png")


bins=0:1:105
temp = @rsubset df :Label.==35
stephist(temp.rh, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.rh, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.rh, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.rh, bins=bins, label="25")
xlabel!("925 relative humidity")
ylabel!("counts")
png("./figures/hist_rh.png")


bins=0:20:2000
temp = @rsubset df :Label.==35
stephist(temp.blh, bins=bins, label="35", size=(600,500), grid = false, dpi=900)
temp = @rsubset df :Label.==30
stephist!(temp.blh, bins=bins, label="30")
temp = @rsubset df :Label.==27
stephist!(temp.blh, bins=bins, label="27")
temp = @rsubset df :Label.==25
stephist!(temp.blh, bins=bins, label="25")
xlabel!("boundary layer height (m)")
ylabel!("counts")
png("./figures/hist_blh.png")