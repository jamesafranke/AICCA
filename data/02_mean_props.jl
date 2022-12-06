using Plots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
df = @select df :Label :Cloud_Optical_Thickness_mean :Cloud_Top_Pressure_mean
dropmissing!(df)
df = @by df :Label :cot=mean(:Cloud_Optical_Thickness_mean) :ctp=mean(:Cloud_Top_Pressure_mean)
@subset! df :Label.!=0

scatter(size=(500,300), grid=false, leg=false, dpi=800)
hline!([440,680], linestyle=:dash, color="#4a86e8")
vline!([3.6,23], linestyle=:dash, color="#4a86e8")
scatter!( df.cot, df.ctp, markeralpha = 0.0, markerstrokewidth = 0, 
    series_annotations=text.(df.Label, :middle, 8, :helvectica),
    xticks = ([0,3.6,23], string.([0,3.6,23])),
    yticks = ([440,680,1000], string.([440,680,1000]))
    )

yflip!(true)
ylims!(200, 1000)
xlims!(0, 24.5)
png("./figures/mean_props.png")