using Plots; gr(); Plots.theme(:default)
using Images, FileIO
if occursin("AICCA", pwd()) == false cd("AICCA") else end

leg = plot(load("/Users/jamesfranke/Documents/julia/AICCA/figures/sc_gif_legend.png"), showaxis=false, grid=false, xticks=:none, yticks=:none)

root = "/Users/jamesfranke/Documents/julia/AICCA/figures/animate/"
fl1  = filter( contains("sc"), readdir(root) )
fl2  = filter( contains("met"), readdir(root) )

l = @layout [ a{0.8h} b{0.8h}
              c{0.2h} d{0.2h} ]

anim = @animate for i in 1:42
    p1 = plot(load(joinpath(root, fl1[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    p2 = plot(load(joinpath(root, fl2[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    plot(p1, p2, leg, layout = l, size=(1200,600), dpi=200)
end
gif(anim, "./figures/sc_south_pacific.gif", fps = 1)




#@gif for i ∈ 1:n circleplot(x, y, i, line_z = 1:n, cbar = false, framestyle = :zerolines) end