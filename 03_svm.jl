using Statistics, MLJ, ProgressMeter
using Arrow, DataFrames, DataFramesMeta, Dates 
using Plots; gr(); Plots.theme(:default) #plotlyjs()
if occursin("AICCA", pwd()) == false cd("AICCA") else end
SVC = @load SVC pkg=LIBSVM

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
train, test = partition( eachindex(y), 0.99, shuffle=true )

esvm = EnsembleModel( model=SVC(gamma=0.), n=1000, bagging_fraction=0.001 )
ensemble = machine( esvm, X, y )
fit!( ensemble, verbosity = 2 )

yhat = predict(ensemble, X[test,:])
misclassification_rate(yhat, y[test] )


