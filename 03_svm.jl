using LIBSVM, Statistics
using Arrow, DataFrames, DataFramesMeta, Dates 
using Plots; gr(); Plots.theme(:default) #plotlyjs()
if occursin("AICCA", pwd()) == false cd("AICCA") else end

df = DataFrame( Arrow.Table( joinpath(pwd(),"data/processed/subtropic_sc_label_daily_clim_all.arrow")) )

dfc = @chain df begin 
    @rsubset :Label in [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]
    @rtransform :sc = :Label in [32, 33, 30, 35] ? 1 : 0
    #@rtransform :sc = :Label in [32, 33, 30, 35] ? 1 : :Label in [6,8] ? 2 : 0
    dropmissing( [:lts, :blh] )
    @select :lts :blh :Label :sc
end

dfc.lts = convert.(Float32, dfc.lts )
dfc.blh = convert.(Float32, dfc.blh )

X = Matrix(dfc[:, 1:2])'
y = dfc.sc # LIBSVM handles multi-class data automatically using a one-against-one strategy

# Split the dataset into training set and testing set
Xtrain = X[:, 1:2:end]
Xtest  = X[:, 2:2:end]
ytrain = y[1:2:end]
ytest  = y[2:2:end]

model = svmtrain(Xtrain, ytrain)

# Test model on the other half of the data
ŷ, decision_values = svmpredict( model, Xtest );
mean(ŷ .== ytest) * 100
