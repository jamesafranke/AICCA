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