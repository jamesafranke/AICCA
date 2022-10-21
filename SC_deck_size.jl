using Plots, StatsPlots; plotlyjs(); theme(:dark) #unicodeplots() 
using DataFrames, DataFramesMeta, Query, CSV, Dates
using Statistics, StatsBase, Random
using Images
using NetCDF
using Impute
using DataFramesMeta: @orderby

function get_random_color(seed)
    Random.seed!(seed); rand(RGB{N0f8});
end

#################### process data to subtropic only ########################
for i in 2005:2021
    root = "AICCA/data/raw/$i/"
    fl = readdir(root)
    df = DataFrame()
    for i in fl
        temp = CSV.read( joinpath(root, i), DataFrame ) |> @filter(_.lon > -145 && _.lon < 120) |> DataFrame
        append!( df, temp |> @filter(_.lat < 45 && _.lat > -45) |> DataFrame )
    end
    transform!( df, :Timestamp => ByRow( x -> x[1:19] ) => :Timestamp)
    CSV.write("AICCA/data/processed/$(i)_subtropic.csv", df)
end

################################ Cloud classes #################################
high    = [1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 17]
sparse  = [19, 22, 23, 20, 27, 29, 36, 37, 38, 39, 40, 41] 
open    = [0, 18, 25, 26, 30, 32, 34, 42]
closed  = [21, 24, 28, 31, 33, 35] 
mclosed = [13, 14, 15, 16]

year = 2003
dfi = CSV.read( "AICCA/data/processed/$(year)_subtropic.csv", dateformat="yyyy-mm-dd HH:MM:SS", DataFrame )
df = DataFrame()
for (i, id, group) in zip(["high","sparse","open","closed","mclosed"], [1,1,1,0,0], [high,sparse,open,closed,mclosed])
    append!( df, dfi |> @filter( _.Label in group ) |> @mutate( lowtype .= i, idn .= id ) |> DataFrame )
end

df = @orderby(df, :Timestamp)
df = df |> @filter(_.lat < 0 && _.lat > -45 && _.lon > -115 && _.lon < -70)  |> DataFrame
df.lat = floor.(df.lat) .+ 0.5
df.lon = floor.(df.lon) .+ 0.5

################## make daily raster for single basin ##########################
dft = df |> @filter( Dates.Date(_.Timestamp) == Date("2003-11-03") ) |> DataFrame
#@select!(dft, :lat, :lon, :lowtype, :idn )
@df dft scatter(:lon, :lat, group = :idn)

dates = Date(year,1,1):Day(1):Date(year,12,31)
#for day in dates
    #dft = df |> @filter( Dates.Date(_.Timestamp) ==date ) |> DataFrame
#end

m = Array{Union{Missing,Float64}}(missing, 45, 45)
#m = zero(rand(45,45))
lats = -45.5:1:-0.5
lons = -115.5:1:-70.5
for (i, lon) in enumerate(lons)
    for (j, lat) in enumerate(lats)
        temp = dft |> @filter(_.lat == lat && _.lon == lon )  |> DataFrame
        try m[j,i] = temp.idn[1]
        catch e
        end
    end
end

heatmap( m, c=:bone, clims=(0,1) )

########################## fill missing values ##############################
replace!(m, missing => -1)
m = convert.(Int, m)
for y_shift in [-1,1]      
    for x_shift in [-1,1]
        temp = circshift( m, (y_shift, x_shift) )
        m[m.<0] .= temp[m.<0]
    end 
end
replace!(m, -1 => 1)
heatmap( m, c=:bone, clims=(0,1) )

##################### Watershed segmentation ################################
bw = Gray.(m) .< 0.5
dist = distance_transform( feature_transform( bw ) )
markers = label_components( dist .< 1)
segments = watershed( dist, markers )
lab = labels_map( segments ) .* bw
heatmap( lab, c = :phase )
counts = countmap(lab)



### SST data: NOAA NCEP EMC CMB GLOBAL Reyn_SmithOIv2
sst = ncread("AICCA/data/raw/noaa_ncep_sst.nc","sst")

heatmap( permutedims(sst[:,:,1], [2,1]), c=:balance, )



test = replace(allowmissing(lab), 0=> missing)
test = lab
test[test.==0] .= -10
UnicodePlots.heatmap(test, colormap=:jet, height=40, width=45, border=:none, colorbar_border=:none)#, zlabel="cr")

############################################# OLD ##############################################
############################################# OLD ##############################################
############################################# OLD ##############################################
############################################# OLD ##############################################



img = load(download("http://docs.opencv.org/3.1.0/water_coins.jpg"))
bw = Gray.(img) .> 0.5
dist = 1 .- distance_transform( feature_transform( bw ) )
markers = label_components( dist .< -15 )
segments = watershed(dist, markers)

lab = labels_map( segments ) .* ( 1 .-bw )
heatmap( bw )

heatmap( map( i -> get_random_color( i ), labels_map( segments ) ) .* ( 1 .- bw ) )
counts = countmap(lab)


heatmap(dist)


using Impute: Interpolate, impute!
impute!(m, Interpolate(); dims=(1,2))

m = Impute.knn( m, threshold=0.1)

data = allowmissing(reshape(sin.(1:20), 5, 4)); data[[2, 3, 7, 9, 13, 19]] .= missing; 
Impute.knn(data; dims=:cols)

replace_missing!(v) = accumulate!( (n0,n1) -> ismissing(n1) ? n0 : n1, v, v, init=zero(eltype(v)))
replace_missing!(m)


#dft = unstack(dft, :lat, :lon, :lowtype)

lat = -10.5
lon = -80.5
temp = dft |> @filter( _.lat == lat && _.lon == lon )  |> DataFrame

dfn |> 
    @filter(Dates.Date(_.Timestamp) == Date("2003-02-01")) |>
    @vlplot(:scatter,
        x = :lat,
        y = :lon,
        #color = :platform,
        width = 600, height = 400,
        #config = { view = { stroke=:transparent,  background="#333" } }
    )


dfn.Timestamp = DateTime.(dfn.Timestamp, "yyyy-mm-dd HH:MM:SS")

df[!,:lowtype ] .= "none"
df[ df[:Label] in closed, :lowtype ] .= "closed"

df = @transform( df, lowtype = [x in closed ? "clossed" : missing for x in :Label] )

@transform!( df, lowtype = [x in closed ? "clossed" : missing for x in :Label] )
@transform!( df, lowtype = [x in open ? "open" : missing for x in :Label] )
@transform!( df, lowtype = [x in sparse ? "sparse" : missing for x in :Label] )

df = DataFrame(x = [1, 1, 2, 2], y = [1, 2, 101, 102]);
@transform!(df, x2 = 2 .* :x )\

df = CSV.read( "AICCA/data/processed/2003_subtropic.csv", DataFrame )
dfs = df |> @filter(:Label in sparse) |> @transform( :name = "sparse" )
@subset(df, :Label in sparse)

@chain df begin end

@chain df begin 
    @rsubset :Lable in sparse
    @transform!(:name .= "sparse")
end

#transform!( dfn, :Timestamp => ByRow( x -> x[1:19] ) => :Timestamp)
#dfn[!, :day] = dfn.Timestamp.Date.Day