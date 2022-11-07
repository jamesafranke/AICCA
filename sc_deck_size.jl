using DataFrames, DataFramesMeta, CSV, Dates
using Statistics, StatsBase
using ImageMorphology, ImageSegmentation
using ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end
root = pwd()

################################ Cloud classes #################################
dfc = DataFrame(type_ = "high", idn = 1, Label = [1,2,3,4,5,6,7,8,9,10,11,12,17])
append!(dfc, DataFrame( type_ = "mclosed", idn = 1, Label = [13,14,15,16] ) )  #How high are these when they occur in the subtropics???
append!(dfc, DataFrame( type_ = "sparse", idn = 1, Label = [19,22,23,20,27,29,36,37,38,39,40,41] ) )
append!(dfc, DataFrame( type_ = "open",   idn = 1, Label = [0,18,25,26,30,32,34,42] ) )
append!(dfc, DataFrame( type_ = "closed", idn = 0, Label = [21,24,28,31,33,35]  ) )

################################ process years to get sc deck size #################################
function process_year(year, startlat, endlat, startlon, endlon, region)
    df = CSV.read( joinpath(root,"data/processed/subtrop/$(year)_subtropic.csv"), dateformat = "yyyy-mm-dd HH:MM:SS", DataFrame )
    @subset! df :lat .> startlat :lat .< endlat :lon .> startlon :lon .< endlon
    df.lat = floor.(df.lat);  df.lon = floor.(df.lon)
    df = orderby(df, :Timestamp)
    leftjoin!(df, dfc, on = :Label)

    ################## make daily raster for single basin ##########################
    dfo = DataFrame()
    dates = Date(year,1,1):Day(1):Date(year,12,31)
    @showprogress for date in dates
        dft = @subset df Dates.Date.(:Timestamp) .== date
        ndim = endlat - startlat
        m = ones( ndim, ndim ); m[:,:] .= -1

        for (i, lon) in enumerate(startlon:1:endlon)
            for (j, lat) in enumerate(startlat:1:endlat)
                temp = @subset dft, :lat .== lat, :lon .== lon
                try m[j,i] = temp.idn[1] catch e end
            end
        end

        ########################## fill missing values ##############################
        for y_shift in [-1,1]      
            for x_shift in [-1,1]
                temp = circshift( m, (y_shift, x_shift) )
                temp[1,:] .= -1 ; temp[end,:] .= -1  # dont allow rollover from other edge of domain
                temp[:,1] .= -1 ; temp[:,end] .= -1  # dont allow rollover from other edge of domain 
                m[m.<0] .= temp[m.<0]
            end 
        end
        replace!(m, -1 => 1)

        ##################### Watershed segmentation ################################
        bw    = Gray.(m) .< 0.5
        feat  = feature_transform( bw )
        dist  = distance_transform( feat )
        marks = label_components( dist .< 1)
        segs  = watershed( dist, marks )
        lab   = labels_map( segs ) .* bw
        count = counts( lab )

        append!( dfo, DataFrame( members = count[2:end], date = date ) )
    end
    CSV.write(joinpath(root,"/data/processed/sc_counts_no_mid/$(year)_subtropic_$(region)_counts.csv"), dfo)
end 

for year in 2003:2021 process_year( year, -45, 0, -115, -70, "spacific" ) end
for year in 2003:2021 process_year( year, 0, 45, -140, -95, "n_pacific" ) end
for year in 2003:2021 process_year( year, -40, 5, -27, 18, "africa" ) end
for year in 2003:2021 process_year( year, -45, 0, 75, 120, "indian" ) end