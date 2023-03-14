using Plots, StatsPlots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
using Images, FileIO
if occursin("AICCA", pwd()) == false cd("AICCA") else end

x = load("./data/cam1.png")

i, j = 325, 1
temp = convert.(Float32,Gray.(x[i:i+325,j:j+325]))
temp[150:end,290:end] .= 1
temp[190:end,260:end] .= 1
temp[270:325,170:200] .= 1
temp[1:100,1:180] .= 1
temp[1:150,1:120] .= 1
heatmap(temp, size=(400,400),showaxis=false, grid=false, xticks=:none, yticks=:none, colorbar=:none)







plot(temp, showaxis=false, grid=false, xticks=:none, yticks=:none)
rotgrid(grd,θ) = [cos(θ) -sin(θ); sin(θ) cos(θ)] * grd

rgrd = rotgrid.(temp, pi/4)

heatmap(rgrd)

grd = creatgrid(2,0.05)