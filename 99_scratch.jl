using InlineStrings
df.date = InlineString15.( Dates.format.(df.date, "yyyy-mm-dd") )
df.lat = InlineString7.(string.(df.lat))
df.lon = InlineString7.(string.(df.lon))




X = randn(40, 2)
X = [[dfc.lts]; [dfc.blh]]
tX = MLJ.table()
ty = categorical(y);


y, X = unpack(dfc, ==(:sc); :sc => Multiclass, :lts => Continuous, :blh => Continuous)
first(dfc, 3) |> pretty

print(models(matching(X,y)))

iris = load_iris();

schema(iris)

y, X = unpack(iris, ==(:target); rng=123)


Tree = @load DecisionTreeClassifier pkg=DecisionTree

train, test = partition( eachindex(y), 0.8, shuffle=true )

#### Support vector classification ####
@load SVC pkg=LIBSVM
svc = machine( SVC(), X, y )
fit!( svc, rows = train )


yhat = predict(svc, X[test,:])

misclassification_rate(yhat, y[test,:])


X.lts = (X.lts .- minimum(X.lts)) ./ (maximum(X.lts) .- minimum(X.lts))
X.blh = (X.blh .- minimum(X.blh)) ./ (maximum(X.blh) .- minimum(X.blh))



######## KNNClassifier #######
KNNClassifier = @load KNNClassifier pkg=NearestNeighborModels
MultitargetKNNClassifier = @load MultitargetKNNClassifier pkg=NearestNeighborModels
knn = machine( KNNClassifier(K=11), X, y )
fit!( knn, rows = train, verbosity=2 )

ŷ = predict( knn, X[test,:] )


print(models(matching(X,y)))




BaggingClassifier = @load BaggingClassifier pkg=ScikitLearn
SVMClassifier = @load SVMClassifier pkg=ScikitLearn
clf = BaggingClassifier(base_estimator=SVMClassifier(), n_estimators=1000, max_samples=1000, random_state=0)
svc = machine( clf, X, y )
fit!( svc, rows = train, verbosity=2 )
