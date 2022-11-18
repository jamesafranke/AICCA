using Statistics, MLJ, MLJLinearModels, Distributions
using Arrow, DataFrames, DataFramesMeta, Dates 
using Plots; gr(); Plots.theme(:default) #plotlyjs()
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim_all.arrow")) )

dfc = @chain df begin 
    @rsubset :Label in [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
    @rtransform :sc = :Label in [32, 33, 30, 35] ? 1 : 0 
    #@rtransform :sc = :Label in [35] ? 1 : :Label in [30,32,33] ? 2 : 0
    dropmissing( [:lts, :blh, :sst, :t, :q, :sc] )
    @select :lts :blh :sst :t :q :sc
end

dfc.lts = convert.( Float32, dfc.lts )
dfc.blh = convert.( Float32, dfc.blh )
#dfc.w = convert.( Float32, dfc.w )
dfc.sst = convert.( Float32, dfc.sst )
dfc.t = convert.( Float32, dfc.t )
dfc.q = convert.( Float32, dfc.q )

y, X = unpack(dfc, ==(:sc);
    :sc  => Multiclass, 
    :lts => Continuous, 
    :blh => Continuous,
    :q   => Continuous, 
    :t   => Continuous,
    #:w  => Continuous, 
    :sst => Continuous,
    )

minmax(x) = (x .- minimum(x)) ./ (maximum(x) - minimum(x))
transform!( X, [:lts, :blh, :q, :t, :sst] .=> (x -> minmax(x) ) .=> [:lts, :blh, :q, :t, :sst] )
train, test = partition( eachindex(y), 0.5, shuffle=true )

temp = first(X, 100)
scatter(temp.lts, temp.blh, markershape = :square, markersize = 5, markeralpha = 0.5, markercolor = :red, 
markerstrokewidth = 0.5, markerstrokecolor=:red, size=(500,600), grid = false, leg=false, dpi=900)

SVC = @load SVC pkg=LIBSVM
mod = EnsembleModel( model=SVC(gamma=0.7), n=1000, bagging_fraction=0.001 )
mach = machine( mod, X, y )
fit!( mach, verbosity = 2 )

yhat = predict(mach, X[test,:])
misclassification_rate(yhat, y[test] )


MultinomialClassifier = @load MultinomialClassifier pkg=MLJLinearModels
mod = MultinomialClassifier(lambda=0.5, gamma=0.7)
mach = machine(mod, X, y)
fit!(mach, rows = train, verbosity = 2)

@showprogress fit!(mach, rows = train, verbosity = 0)

yhat = predict(mach, X[test,:])


misclassification_rate(yhat, y[test] )
log_loss(yhat, y[test]) |> mean



λ = 0.5
mod = LogisticRegression(λ)
mach = machine(mod, X, y)
fit!(mach, rows = train, verbosity = 2)
yhat = predict(mach, X[test,:])

pred = DataFrame( lts=X[test,1], blh=X[test,2], class=y[test], openp=yhat0 = broadcast(pdf, yhat, 0), closedp=broadcast(pdf, yhat, 1))
temp = @subset pred :class .==0
temp = first(temp, 1000)
scatter(temp.lts, temp.blh, markershape = :square, markersize = 5, markeralpha = 0.5, markercolor = :red, 
markerstrokewidth = 0.5, markerstrokecolor=:red, size=(500,600), grid = false, leg=false, dpi=900)

temp = @subset pred :closedp .>0.5
temp = first(temp, 1000)
scatter!(temp.lts, temp.blh, markershape = :square, markersize = 5, markeralpha = 0.5, markercolor = :blue, 
markerstrokewidth = 0.5, markerstrokecolor=:blue, size=(500,600), grid = false, leg=false, dpi=900)


