using DataFrames, Query, CSV, Dates

#################### process data to subtropic only ########################
for i in 2003:2021
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