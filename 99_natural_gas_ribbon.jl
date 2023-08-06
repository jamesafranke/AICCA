using Plots, StatsPlots; gr(); Plots.theme(:default) #plotlyjs()
using Arrow, DataFrames, DataFramesMeta, Dates, Statistics, CSV
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = CSV.read( "data/robert_natural_gas.csv", DataFrame )
@transform! df :zero=0
@transform! df :non_ele_total=:natural_gas_agricultural+:natural_gas_industrial+:natural_gas_residential+:natural_gas_transportation

plot( size=(600,300), grid = false, leg=:topleft, dpi=900, fg_legend=:transparent )
@df df plot!(:year, :zero, fillrange=:non_ele_total, fillalpha = 0.9, linecolor=:false, color=:black, label="Non-electrical uses") 
@df df plot!(:year, :non_ele_total, fillrange=:natural_gas_electrical+:non_ele_total, fillalpha = 0.9, linecolor=:false, color=:gold, label="Electricity generation") 

@df df plot!(:year, :natural_gas_residential, linecolor=:gray, label="Residential")
@df df plot!(:year, :natural_gas_industrial, linecolor=:gray, linestyle=:dot, label="Industrial")
@df df plot!(:year, :natural_gas_agricultural, linecolor=:gray, linestyle=:dashdot, label="Agricultural")
@df df plot!(:year, :natural_gas_transportation, linecolor=:gray, linestyle=:dash, label="Transportation")

ylabel!("W/capita",  yguidefont = font(10))
xlims!(1880,2022)

@df df plot!(twinx(),:year,:transmission_pipeline_mileage/1000, label=:false, ylims=(0,310), color=:steelblue)
@df df scatter!(twinx(),:year,:transmission_pipeline_mileage/1000, label=:false, markerstrokecolor=:steelblue, color=:steelblue, markersize=1.5, ylabel="Pipeline (1000 miles)",  yguidefont=font(10, :steelblue), ylims=(0,310))

png("./figures/robert_natural_gas.png")


plot( size=(600,300), grid = false, leg=:topleft, dpi=900, fg_legend=:transparent )
@df df plot!(:year, :zero, fillrange=:natural_gas_electrical+:non_ele_total, fillalpha = 0.6, linecolor=:false, color=1, label=:false) 

@df df plot!(:year, :natural_gas_residential, linecolor=1, label="Residential")
@df df plot!(:year, :natural_gas_industrial, linecolor=1, linestyle=:dot, label="Industrial")
@df df plot!(:year, :natural_gas_agricultural, linecolor=1, linestyle=:dashdot, label="Agricultural")
@df df plot!(:year, :natural_gas_transportation, linecolor=1, linestyle=:dash, label="Transportation")
@df df plot!(:year, :natural_gas_electrical, linecolor=1, linestyle=:dashdotdot, label="Electricity")

@df df plot!(:year, :manufactured_gas, linecolor=:black, label="Manufactured")

ylabel!("W/capita",  yguidefont = font(10))
xlims!(1880,2022)

temp = dropmissing(df, :transmission_pipeline_mileage)
@df temp plot!(twinx(),:year,:transmission_pipeline_mileage/1000, label=:false,  color=:salmon, ylabel="Pipeline (1000 miles)",  yguidefont=font(10, :salmon), ylims=(0,310))
#@df df scatter!(twinx(),:year,:transmission_pipeline_mileage/1000, label=:false, markerstrokecolor=:steelblue, color=:steelblue, markersize=1.5, ylabel="Pipeline (1000 miles)",  yguidefont=font(10, :steelblue), ylims=(0,310))

png("./figures/robert_natural_gas.png")

colors = cgrad(:vik, 10, categorical = true) 
plot( size=(600,300), grid = false, leg=:topleft, dpi=900, fg_legend=:transparent )
@df df plot!(:year, :natural_gas_agricultural+:natural_gas_transportation+:natural_gas_industrial+:natural_gas_residential, fillrange=:natural_gas_agricultural+:natural_gas_transportation+:natural_gas_industrial+:natural_gas_residential+:natural_gas_electrical, fillalpha = 0.6, linecolor=:false, color=colors[1], label="Electricity") 
@df df plot!(:year, :natural_gas_agricultural+:natural_gas_transportation+:natural_gas_industrial, fillrange=:natural_gas_agricultural+:natural_gas_transportation+:natural_gas_industrial+:natural_gas_residential, fillalpha = 0.6, linecolor=:false, color=colors[2], label="Residential") 
@df df plot!(:year, :natural_gas_agricultural+:natural_gas_transportation, fillrange=:natural_gas_agricultural+:natural_gas_transportation+:natural_gas_industrial, fillalpha = 0.6, linecolor=:false, color=colors[3], label="Industrial") 
@df df plot!(:year, :natural_gas_agricultural, fillrange=:natural_gas_agricultural+:natural_gas_transportation, fillalpha = 0.6, linecolor=:false, color=colors[4], label="Transportation") 
@df df plot!(:year, :zero, fillrange=:natural_gas_agricultural, fillalpha = 0.6, linecolor=:false, color=colors[5], label="Agricultural") 


@df df plot!(:year, :manufactured_gas, linecolor=:black, lw=2, label="Manufactured")

ylabel!("W/capita", yguidefont=font(10))
xlims!(1880,2022)
ylims!(-50,5000)

temp = dropmissing(df, :transmission_pipeline_mileage)
@df temp plot!(twinx(),:year,:transmission_pipeline_mileage/1000, label=:false, lw=2, color=:salmon, ylabel="Pipeline (1000 miles)",  yguidefont=font(10, :salmon), ylims=(0,310))
#@df df scatter!(twinx(),:year,:transmission_pipeline_mileage/1000, label=:false, markerstrokecolor=:steelblue, color=:steelblue, markersize=1.5, ylabel="Pipeline (1000 miles)",  yguidefont=font(10, :steelblue), ylims=(0,310))

png("./figures/robert_natural_gas.png")