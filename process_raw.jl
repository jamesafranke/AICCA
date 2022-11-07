using DataFrames, DataFramesMeta, CSV, Dates
if occursin("AICCA", pwd()) == false cd("AICCA") else end
root = pwd()

#################### process data to subtropic only ########################
for i in 2003:2021
    root = "AICCA/data/raw/$i/"
    fl = readdir( joinpath(root, "data/raw/$i/") )
    df = DataFrame()
    for j in fl
        temp = CSV.read( joinpath(root, "data/raw/$i/", j), DataFrame )
        @subset! temp :lon>-145 :lon<120 :lat<45 :lat>-45
        append!( df, temp )
    end
    @transform! df @byrow :Timestamp=:Timestamp[1:19]
    CSV.write( joinpath(root,"data/processed/$(i)_subtropic.csv", df) )
end