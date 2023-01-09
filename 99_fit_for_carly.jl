using Optim, CSV, DataFrames, Plots; gr(); Plots.theme(:default)
df = CSV.read( "./data/afterR9.csv", DataFrame ) 
scatter(df.x, df.y, markersize = 2)

@. model(x, p) = p[1] + p[2] * exp( -p[3] * (x-p[4]) ) + p[5]*(x-p[4]) 

sqerror(p) = sum((ydata .- model(xdata, p)).^2)
p0 = [ 1, .8, .2, 0.04, 0 ] 

########  BREAKPOINT ################
err = []
for i in 1:9
    xdata = df.x[i:end]
    ydata = df.y[i:end]
    res = optimize(sqerror, p0)
    append!(err, Optim.minimum(res))
end 
breakpoint = argmin(err)
#####################################

xdata = df.x[breakpoint:end]
ydata = df.y[breakpoint:end]

res = optimize(sqerror, p0)
yhat = model( xdata, Optim.minimizer(res) )
plot!( xdata, yhat, linestyle=:dash  )

final_p3 = 1/Optim.minimizer(res)[3]
