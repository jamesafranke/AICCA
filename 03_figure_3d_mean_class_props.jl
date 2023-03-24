using DataFrames, DataFramesMeta, CSV, Dates
using Statistics
using GLMakie; GLMakie.activate!()
#using Plots
if occursin("AICCA", pwd()) == false cd("AICCA") else end
meanm(x) = mean(skipmissing(x))

# load in mean propoerty data
fl = filter( !contains(".DS"), readdir( joinpath(pwd(), "data/processed/mean_props/") ) )
df = DataFrame()
for file in fl append!( df, CSV.read( joinpath(pwd(), "data/processed/mean_props/", file), DataFrame ) ) end
df = @by df :Label :ot=meanm(:ot) :tp=meanm(:tp) :er =meanm(:er) :wp=meanm(:wp) :cf=meanm(:cf)
@subset! df :Label.!=0 :Label.!=43
@subset! df :ot.<= 23 :ot.>=3.4 :tp.>680


GLMakie.closeall()
x = df.ot
y = df.er
z = abs.(df.tp.- 1000) / 33
box = Rect3(Point3f(-0.5,-0.5,-0.5), Vec3f(1,1,1))
cmap_alpha = resample_cmap(:ice, 100, alpha = 0.8 )
fig, ax, = meshscatter(x, y, z; marker=box, markersize = 1.8, color = vec(df.cf), 
    colormap = cmap_alpha, colorrange = (50,100),
    axis = (; type = Axis3, aspect=:data),
    figure = (; resolution =(2000,2000)),
    )
xlims!(2,25)
ylims!(8,33)
#zlims!(0,25)
#hidedecorations!(ax, grid=false)
#hidespines!(ax)
fig
