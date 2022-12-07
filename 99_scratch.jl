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


temp = @subset df :model.=="UKESM1-0-LL" :exp.=="piControl"


mods = unique(df.model)





using MLJ, MLJLinearModels
using ScikitLearn
@sk_import linear_model: LinearRegression
model = LinearRegression(fit_intercept=true)


temp = @subset df :model.=="BCC-CSM2-MR" :exp.=="piControl"
@select! temp :cl :lts

y, X = unpack(temp, ==(:cl);
    :cl  => Continuous, 
    :lts => Continuous, 
    )


minmax(x) = (x .- minimum(x)) ./ (maximum(x) - minimum(x))
transform!( X, :lts .=> (x -> minmax(x) ) .=> :lts )


reg = @load LinearRegressor pkg = "MLJLinearModels"
model_reg = reg()
mach = machine(model_reg, X, y)
fit!(mach)



train, test = partition( eachindex(y), 0.5, shuffle=true )

















### load in class data for the sub tropics merged with climate vars ###
df = DataFrame( Arrow.Table("./data/processed/subtropic_sc_label_daily_clim.arrow") )

dfc = @chain df begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @aside dft = @subset _ :Label.!=0 
    @aside dft = @by dft [:ltsbin, :blhbin] :nonzeroclass=last(:Label)  :totalnozero=sum(:counts)
    @by [:ltsbin, :blhbin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
    leftjoin( dft, on=[:ltsbin, :blhbin] )
    @rtransform :plotclass = :maxcount/:total>0.33 ? :maxclass : :nonzeroclass 
end

@select! dfc :ltsbin :blhbin :plotclass :maxcount
df = nothing

unique!(df, [:year, :month, :day, :lat, :lon])
df = DataFrame( Arrow.Table( "./data/processed/cmip6_bl/zmla_CESM2_piControl_r1i1p1f1_.nc4.arrow") )
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
df = get_subtrop(df)
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5
unique!(df)
unique!(df, [:year, :month, :day, :lat, :lon])

df = df[shuffle(1:size(df)[1])[1:10_000_000],:]

dft = DataFrame()
fl = filter( contains("ta_day_CESM2_piControl"), readdir("./data/processed/cmip6_bl/") )
for file in fl append!( dft, Arrow.Table( "./data/processed/cmip6_bl/$file" ) ) end
@rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
dft = get_subtrop(dft)
dft.lat = floor.(dft.lat) .+ 0.5
dft.lon = floor.(dft.lon) .+ 0.5
dropmissing!(dft)
unique!(dft, [:year, :month, :day, :lat, :lon])


leftjoin!( df, dft, on = [:year, :month, :day, :lat, :lon] )
rename!(df, :zmla=>:blh)
dropmissing!(df)
Arrow.write("./data/processed/CESM2_piControl.arrow", df)


df = DataFrame( Arrow.Table(  "./data/processed/cmip6_bl/zmla_CESM2_1pctCO2_r1i1p1f1.nc4.arrow") )
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
df = get_subtrop(df)
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5
unique!(df)
unique!(df, [:year, :month, :day, :lat, :lon])

df = df[shuffle(1:size(df)[1])[1:10_000_000],:]

dft = DataFrame()
fl = filter( contains("ta_day_CESM2_1pct"), readdir("./data/processed/cmip6_bl/") )
for file in fl append!( dft, Arrow.Table( "./data/processed/cmip6_bl/$file" ) ) end
@rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
dft = get_subtrop(dft)
dft.lat = floor.(dft.lat) .+ 0.5
dft.lon = floor.(dft.lon) .+ 0.5
dropmissing!(dft)
unique!(dft, [:year, :month, :day, :lat, :lon])

leftjoin!( df, dft, on = [:year, :month, :day, :lat, :lon] )
rename!(df, :zmla=>:blh)
dropmissing!(df)
Arrow.write("./data/processed/CESM2_1pct.arrow", df)


df1 = DataFrame( Arrow.Table( "./data/processed/CESM2_piControl.arrow" ) )
df2 = DataFrame( Arrow.Table( "./data/processed/CESM2_1pct.arrow" ) )

df1 = @chain df1 begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :counts_pi=size(:lat)[1]
end

df2 = @chain df2 begin  
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :counts_1pct=size(:lat)[1]
end

leftjoin!(dfc, df1, on=[:ltsbin, :blhbin])
leftjoin!(dfc, df2, on=[:ltsbin, :blhbin])

temp = @subset dfc :plotclass.==35
dropmissing!(temp)
sum( temp.counts_pi )
sum( temp.counts_1pct )


temp = @chain dfc begin
    @by [:ltsbin, :blhbin] :counts=sum(:maxcount)
    @subset :counts.>10
    @orderby :ltsbin
    unstack( :blhbin, :ltsbin, :counts)
    @orderby :blhbin 
    select( Not(:blhbin) )
    Array()
end

contourf(temp, size=(600,600), grid = false, dpi=900, color = :viridis)
xlims!(0, 60)
ylims!(0, 70)
png("./figures/heatmap_era5.png")



temp = @chain df2 begin
    dropmissing( [:lts, :blh] )
    @transform :ltsbin=round.(:lts.*2, digits=0)./2 :blhbin=round.(:blh./3, digits=-1)*3
    @by [:ltsbin, :blhbin] :counts=size(:lat)[1]
    @subset :counts.>10
    @orderby :ltsbin
    unstack( :blhbin, :ltsbin, :counts)
    @orderby :blhbin 
    select( Not(:blhbin) )
    Array()
end

contourf(temp, size=(600,600), grid = false, dpi=900, color = :viridis)
xlims!(0, 60)
ylims!(0, 70)
png("./figures/heatmap_cmip6_pi.png")





df = DataFrame( Arrow.Table( "./data/processed/cmip6_bl/zmla_HadGEM3-GC31-LL_piControl_r1i1p1f1.nc4.arrow") )
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
df = get_subtrop(df)
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5
unique!(df, [:year, :month, :day, :lat, :lon])

df = df[shuffle(1:size(df)[1])[1:10_000_000],:]

dft = DataFrame()
fl = filter( contains("ta_day_HadGEM3-GC31-LL_piControl"), readdir("./data/processed/cmip6_bl/") )
for file in fl append!( dft, Arrow.Table( "./data/processed/cmip6_bl/$file" ) ) end
@rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
dft = get_subtrop(dft)
dft.lat = floor.(dft.lat) .+ 0.5
dft.lon = floor.(dft.lon) .+ 0.5
dropmissing!(dft)
unique!(dft, [:year, :month, :day, :lat, :lon])

leftjoin!( df, dft, on = [:year, :month, :day, :lat, :lon] )
rename!(df, :zmla=>:blh)
dropmissing!(df)
Arrow.write("./data/processed/HadGEM3_piControl.arrow", df)


df = DataFrame( Arrow.Table(  "./data/processed/cmip6_bl/zmla_HadGEM3-GC31-LL_1pctCO2_r3i1p1f3.nc4.arrow") )
@rtransform! df :lon = :lon .> 180 ? :lon .- 360 : :lon
df = get_subtrop(df)
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5
unique!(df)
unique!(df, [:year, :month, :day, :lat, :lon])

df = df[shuffle(1:size(df)[1])[1:10_000_000],:]

dft = DataFrame()
fl = filter( contains("ta_day_HadGEM3-GC31-LL_1pct"), readdir("./data/processed/cmip6_bl/") )
for file in fl append!( dft, Arrow.Table( "./data/processed/cmip6_bl/$file" ) ) end
@rtransform! dft :lon = :lon .> 180 ? :lon .- 360 : :lon
dft = get_subtrop(dft)
dft.lat = floor.(dft.lat) .+ 0.5
dft.lon = floor.(dft.lon) .+ 0.5
dropmissing!(dft)
unique!(dft, [:year, :month, :day, :lat, :lon])

leftjoin!( df, dft, on = [:year, :month, :day, :lat, :lon] )
rename!(df, :zmla=>:blh)
dropmissing!(df)
Arrow.write("./data/processed/HadGEM3-GC31-LL_1pct.arrow", df)