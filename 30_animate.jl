using Plots; gr(); Plots.theme(:default)
using Images, FileIO
if occursin("AICCA", pwd()) == false cd("AICCA") else end

leg = plot(load("/Users/jamesfranke/Documents/julia/AICCA/figures/sc_gif_legend.png"), showaxis=false, grid=false, xticks=:none, yticks=:none)

root = "/Users/jamesfranke/Documents/julia/AICCA/figures/animate/"
fl1  = filter( contains("sc"), readdir(root) )
fl2  = filter( contains("met"), readdir(root) )
fl3  = filter( contains("pr"), readdir(root) )

l = @layout [ a{0.8h} b{0.8h} c{0.8h}
              d{0.2h} e{0.2h} f{0.2h} ]

anim = @animate for i in 1:42
    p1 = plot(load(joinpath(root, fl1[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    p2 = plot(load(joinpath(root, fl2[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    p3 = plot(load(joinpath(root, fl3[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    plot(p1, p2, p3, leg, layout = l, size=(1800,600), dpi=150)
end
gif(anim, "./figures/sc_south_pacific.gif", fps = 1)


root = "/Users/jamesfranke/Documents/julia/AICCA/figures/animate/"
fl1  = filter( contains("sc"), readdir(root) )
fl2  = filter( contains("met"), readdir(root) )
fl3  = filter( contains("pr"), readdir(root) )

l = @layout [ a{0.8h}
              b{0.2h} ]

anim = @animate for i in 1:42
    p1 = plot(load(joinpath(root, fl1[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    plot(p1, leg, layout = l, size=(600,600), dpi=250)
end
gif(anim, "./figures/sc_south_pacific_just_obs.gif", fps = 1)

root = "/Users/jamesfranke/Documents/julia/AICCA/figures/animate/"
fl1  = filter( contains("met"), readdir(root) )
fl2  = filter( contains("pr"), readdir(root) )
fl3  = filter( contains("sst"), readdir(root) )
fl4  = filter( contains("lts"), readdir(root) )

l = @layout [ a{0.5h} b{0.5h}
              c{0.5h} d{0.5h} ]

anim = @animate for i in 1:31
    p1 = plot(load(joinpath(root, fl1[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    p2 = plot(load(joinpath(root, fl2[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    p3 = plot(load(joinpath(root, fl3[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    p4 = plot(load(joinpath(root, fl4[i])), showaxis=false, grid=false, xticks=:none, yticks=:none)
    plot(p1, p2, p3, p4, layout = l, size=(1000,800), dpi=200)
end
gif(anim, "./figures/sc_south_pacific_met.gif", fps = 1)



root = "/Users/jamesfranke/Documents/julia/AICCA/figures/animate/"
fl1  = filter( contains("_t_"), readdir(root) )

anim = @animate for i in 1:31
    plot(load(joinpath(root, fl1[i])), showaxis=false, grid=false, xticks=:none, yticks=:none, size=(1000,800), dpi=200)
end
gif(anim, "./figures/sc_south_pacific_700_t.gif", fps = 1)



#@gif for i ∈ 1:n circleplot(x, y, i, line_z = 1:n, cbar = false, framestyle = :zerolines) end






root = "/Users/jamesfranke/Documents/julia/AICCA/figures/o3/"
fl  = filter( contains(".png"), readdir(root) )

anim = @animate for i in 1:150
    plot(load(joinpath(root, fl[i])), showaxis=false, grid=false, xticks=:none, yticks=:none, size=(600,520), dpi=200)
end
gif(anim, "./figures/o3_austral_winter.gif", fps = 2)



root = "/Users/jamesfranke/Documents/julia/AICCA/figures/pv/"
fl  = filter( contains(".png"), readdir(root) )

anim = @animate for i in 1:358
    plot(load(joinpath(root, fl[i])), showaxis=false, grid=false, xticks=:none, yticks=:none, size=(600,520), dpi=200)
end
gif(anim, "./figures/pv_2021.gif", fps = 2)

root = "/Users/jamesfranke/Documents/julia/AICCA/figures/t/"
fl  = filter( contains(".png"), readdir(root) )

anim = @animate for i in 1:365
    plot(load(joinpath(root, fl[i])), showaxis=false, grid=false, xticks=:none, yticks=:none, size=(600,520), dpi=200)
end
gif(anim, "./figures/t_2022.gif", fps = 2)

root = "/Users/jamesfranke/Documents/julia/AICCA/figures/pv_pol_aug_sep/"
fl  = filter( contains(".png"), readdir(root) )

anim = @animate for i in 1:61
    plot(load(joinpath(root, fl[i])), showaxis=false, grid=false, xticks=:none, yticks=:none, size=(600,520), dpi=200)
end
gif(anim, "./figures/pv_polar_aug_sept.gif", fps = 2)

root = "/Users/jamesfranke/Documents/julia/AICCA/figures/pv_pol_mar_jun/"
fl  = filter( contains(".png"), readdir(root) )

anim = @animate for i in 1:61
    plot(load(joinpath(root, fl[i])), showaxis=false, grid=false, xticks=:none, yticks=:none, size=(600,520), dpi=200)
end
gif(anim, "./figures/pv_polar_march_jun.gif", fps = 2)