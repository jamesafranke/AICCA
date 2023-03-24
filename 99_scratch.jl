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



for row in eachrow(dft)
    #temp_era = @subset era :date.==row.date
    lat = row.lat
    lon = row.lon
    time = row.Timestamp

    for i in 1:48
        ws = @chain era begin
            @transform :euclid = sqrt.( (:lat.-lat).^2 + (:lon.-lon).^2 )
            @orderby :euclid
            first(1) 
        end
        
        lon = lon .+ ws.u .* 3600.0./111319.488cos.(lat)
        lat = lat .+ ws.v .* 3600.0./111319.488
        time = time .+ Hour(1)

        temp2 = @subset df :Timestamp.==time
        if size(temp2)[1] > 0
            @transform! temp2 :euclid = sqrt.( (:lat.-temp.lat).^2 + (:lon.-temp.lon).^2 )
            @subset! temp2 :euclid.<0.7
            if size(temp2)[1] > 0
                append!(out, temp2.Label)
                break 
            end
        end
    end
end 


using AWSS3, AWSCore

aws = AWSCore.aws_config( region="us-east-2")

bucket = "noaa-isd-lite-raw-data"
path = "isd-lite-history.snappy.parquet"
obj = s3_get(aws, bucket, path)

bytes = AWSS3.read(S3Path("s3://muh-bucket/path/data.csv"))
df = CSV.read(bytes, DataFrame)


metafile_bucket = "hardik-mswep-test"
metafile = "mswep_gridpoint_gp.feather"
bucket_name <- "weather-data-mswep-3hourly"
meta_df = s3read_using(FUN = read_feather, bucket = metafile_bucket, object = metafile)



pa = []; for i in 4:6
    p = @df dfc scatter(:xbin, :ybin, marker_z=cols(keys[i]), color=cmaps[i], markershape=:square, markersize=2.7, markeralpha=0.8, 
    markerstrokewidth=0.0, colorbar_title=String(keys[i]), legend=false, colorbar=true, clim=(clims[i]))
    push!(pa, p)
end 


l = @layout [ a{0.33w} b{0.33w} c{0.33w} ]
plot(pa..., layout=l, size=(1000,250), dpi=900, grid=false)
xlims!(283, 305)
ylims!(4, 34)
png("./figures/heatmap_without_clear_sky_2.png")



using HDF5, DataFrames, DataFramesMeta, Arrow, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

fl = filter( !contains(".DS"), readdir("./data/processed/halfhour/" ) )

df = DataFrame()
@showprogress for file in fl
    hd   = read( h5open("./data/processed/halfhour/$(file)", "r"), "Grid")
    temp = @chain DataFrame(lat=vec(ones(3600)'.*hd["lat"]), lon=vec(hd["lon"]'.*ones(1800)), pr=vec(hd["precipitationCal"])) begin
    @subset :pr.>=0 :lat.>-40 :lat.<5 :lon.>-130 :lon.<-70
    @transform :time=DateTime.(replace(collect(eachsplit(file, "."))[5][1:14], "-S"=>"T"), "yyyymmddTHHMM")  end
    append!(df, temp)
end

@transform! df :date=Date.(:time) :hour=(Hour.(:time))
df = @by df [:lat, :lon, :date, :hour] :pr=sum(:pr)

Arrow.write( "./data/processed/oct_hour_pr.arrow", df )




#### Download precip data ####
year = 2020
month = 10
for day in 23:31
    dt = DateTime.("$(year)-$(month)-$(day)", )
    for hour in 15:22
        file1 = "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGHH.06/$(year)/$(date.dayofyear:03)/3B-HHR.MS.MRG.3IMERG.$(year)$(month:02)$(day:02)-S$(hour:02)0000-E$(hour:02)2959.$(hour*60:04).V06B.HDF5"
        file2 = "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGHH.06/$(year)/$(date.dayofyear:03)/3B-HHR.MS.MRG.3IMERG.$(year)$(month:02)$(day:02)-S$(hour:02)3000-E$(hour:02)5959.$(hour*60+30:04).V06B.HDF5"
        download("wget --user=xx --password=xx $(file1) -P ./data/raw/imerg/halfhour/")
        download("wget --user=xx --password=xx $(file2) -P ./data/raw/imerg/halfhour/")
    end
end
