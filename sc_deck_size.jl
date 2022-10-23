using Plots, UnicodePlots; plotlyjs(); theme(:dark) 
using DataFrames, DataFramesMeta, Query, CSV, Dates
using DataFramesMeta: @orderby
using Statistics, StatsBase
using Images, ImageMorphology, ImageSegmentation
using ProgressMeter

################################ Cloud classes #################################
dfc = DataFrame(type_ = "high", idn = 1, Label = [1,2,3,4,5,6,7,8,9,10,11,12,17])
append!(dfc, DataFrame( type_ = "sparse", idn = 1, Label = [19,22,23,20,27,29,36,37,38,39,40,41] ) )
append!(dfc, DataFrame( type_ = "open", idn = 1, Label = [0,18,25,26,30,32,34,42] ) )
append!(dfc, DataFrame( type_ = "closed", idn = 0, Label = [21,24,28,31,33,35]  ) )
append!(dfc, DataFrame( type_ = "mclosed", idn = 0, Label = [13,14,15,16] ) ) #How high are these when they occur in the subtropics???

################################ process years to get sc deck size #################################
function process_year(year, startlat, endlat, startlon, endlon, region)
    df = CSV.read( "AICCA/data/processed/$(year)_subtropic.csv", dateformat="yyyy-mm-dd HH:MM:SS", DataFrame )
    df = df |> @filter(_.lat > startlat && _.lat < endlat && _.lon > startlon && _.lon < endlon) |> DataFrame
    df.lat = floor.(df.lat)
    df.lon = floor.(df.lon)
    df = @orderby(df, :Timestamp)
    df = leftjoin(df, dfc, on = :Label)

    ################## make daily raster for single basin ##########################
    dfo = DataFrame()
    dates = Date(year,1,1):Day(1):Date(year,12,31)
    @showprogress for date in dates
        dft = df |> @filter( Dates.Date(_.Timestamp) == date ) |> DataFrame
        ndim = endlat - startlat
        m = ones( ndim, ndim ); m[:,:] .= -1

        for (i, lon) in enumerate(startlon:1:endlon)
            for (j, lat) in enumerate(startlat:1:endlat)
                temp = dft |> @filter(_.lat == lat && _.lon == lon ) |> DataFrame
                try m[j,i] = temp.idn[1] catch e end
            end
        end

        ########################## fill missing values ##############################
        for y_shift in [-1,1]      
            for x_shift in [-1,1]
                temp = circshift( m, (y_shift, x_shift) )
                m[m.<0] .= temp[m.<0]
            end 
        end
        replace!(m, -1 => 1)

        ##################### Watershed segmentation ################################
        bw    = Gray.(m) .< 0.5
        feat  = ImageMorphology.FeatureTransform.feature_transform( bw )
        dist  = ImageMorphology.FeatureTransform.distance_transform( feat )
        marks = label_components( dist .< 1)
        segs  = watershed( dist, marks )
        lab   = labels_map( segs ) .* bw
        count = counts( lab )

        append!( dfo, DataFrame( members = count[2:end], date = date ) )
    end
    CSV.write("AICCA/data/processed/sc_counts/$(year)_subtropic_$(region)_counts.csv", dfo)
end 

for year in 2003:2021 process_year( year, -45, 0, -115, -70, "spacific" ) end

for year in 2003:2021 process_year( year, 0, 45, -140, -95, "n_pacific" ) end

for year in 2003:2021 process_year( year, -35, 5, -22, 18, "africa" ) end

for year in 2003:2021 process_year( year, -45, -5, 80, 120, "indian" ) end