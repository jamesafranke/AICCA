using Plots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end
using Images, FileIO

leg = load("/Users/jamesfranke/Documents/julia/AICCA/figures/sc_gif_legend.png")
root = "/Users/jamesfranke/Documents/julia/AICCA/figures/animate/"
fl = filter( contains(".png"), readdir(root) )

l = @layout [ a{0.8h}
              b{0.2h} ]

p2 = plot(leg, showaxis=false, grid=false, xticks=:none, yticks=:none)

anim = @animate for file in fl
    p1 = plot(load(joinpath(root, file)), showaxis=false, grid=false, xticks=:none, yticks=:none);
    plot(p1, p2, layout = l, size=(600,600), dpi=800 )
end
gif(anim, "./figures/sc_south_pacific_anim.gif", fps = 1)






















@gif for file in fl myplot(file) end















img_path = "/Users/jamesfranke/Documents/julia/AICCA/figures/animate/sc_2020-10-23 00_00_00_15.png"
img = load(img_path)
plot(img, size=(600,500), dpi=800, showaxis=false, grid=false, xticks=:none, yticks=:none, tranparent=true)#, margin=0

p1 = plot(img, showaxis=false, grid=false, xticks=:none, yticks=:none, tranparent=true)#, margin=0
p2 = plot(leg, showaxis=false, grid=false, xticks=:none, yticks=:none, tranparent=true)#, margin=0
plot(size=(600,600), dpi=800, p1, p2, layout = l)



@userplot CirclePlot
@recipe function f(cp::CirclePlot)
    x, y, i = cp.args
    n = length(x)
    inds = circshift(1:n, 1 - i)
    linewidth --> range(0, 10, length = n)
    seriesalpha --> range(0, 1, length = n)
    aspect_ratio --> 1
    label --> false
    x[inds], y[inds]
end

n = 150
t = range(0, 2π, length = n)
x = sin.(t)
y = cos.(t)

anim = @animate for i ∈ 1:n
    circleplot(x, y, i)
end
gif(anim, "anim_fps15.gif", fps = 15)



@gif for i ∈ 1:n circleplot(x, y, i, line_z = 1:n, cbar = false, framestyle = :zerolines) end