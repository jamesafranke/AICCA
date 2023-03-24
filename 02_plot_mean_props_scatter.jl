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


df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
@select! df :Label :Cloud_Emissivity_mean :Cloud_Fraction 
@transform! df :em=:Cloud_Emissivity_mean.*:Cloud_Fraction  
df = dropmissing(df)
df = @by df :Label :cot=mean( :em ) 
temp = @subset df :Label.==35
temp2 = @subset df :Label.==30
temp3 = @subset df :Label.==25
temp4 = @subset df :Label.==27

(temp.cot + temp2.cot) / 2 - (temp3.cot + temp4.cot) / 2


df = DataFrame( Arrow.Table( "./data/raw/yearly/2003.arrow" ) )

@select! df :Label  :Timestamp  :Cloud_Optical_Thickness_mean  :Cloud_Phase_Infrared_liquid :lat :lon :platform


