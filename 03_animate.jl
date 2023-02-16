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
gif(anim, "./figures/sc_south_pacific.gif", fps = 1)








#@gif for i ∈ 1:n circleplot(x, y, i, line_z = 1:n, cbar = false, framestyle = :zerolines) end