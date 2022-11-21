using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

## Load in the class data and merge with some climate vars for analysis ##
df = DataFrame( Arrow.Table( "./data/raw/all_AICCA_no_properties.arrow" ) )
@transform! df :year=Year.(:date)
df = get_subtrop(df)

df = DataFrame( Arrow.Table( "./data/raw/all_AICCA.arrow" ) )
df = @select df :Label :platform :date :hour :lat :lon :Cloud_Optical_Thickness_mean :Cloud_Top_Pressure_mean :Cloud_Fraction
df = get_subtrop(df)
df.lon = convert.( Float16, floor.(df.lon) .+ 0.5 )
df.lat = convert.( Float16, floor.(df.lat) .+ 0.5 )

clim = ["era5_daily_lts_tropics.arrow", "era5_daily_blh_tropics.arrow", "era5_daily_ws_tropics.arrow",
"era5_daily_t_q.arrow", "era5_daily_sst.arrow", "aot_daily.arrow", "imerg_pr_daily.arrow", "era5_w.arrow"]

@showprogress for file in clim
    dft = DataFrame( Arrow.Table( "./data/processed/$file" ) )
    dft = get_subtrop( dft )
    leftjoin!( df, dft, on = [:date, :lat, :lon] )
end 

Arrow.write(  "./data/processed/subtropic_sc_label_daily_with_frac.arrow" , df )

#######################################
#### Calculate ISCCP classes   ########
#######################################
df = DataFrame( Arrow.Table("./data/processed/subtropic_sc_label_daily_with_frac.arrow") )
rename!(df, :Cloud_Optical_Thickness_mean => :cop, :Cloud_Top_Pressure_mean => :ctp, :Cloud_Fraction => :cf)
df = @select df :Label :platform :date :hour :lat :lon :cop :ctp :lts :blh :w :sst :aot :pr
df = dropmissing(df, [:cop, :ctp])

dfo = DataFrame()
ci = @subset df :cop.>0   :cop.<2.6 :ctp.<440  :ctp.>50
@transform! ci  :isccp="ci"
append!(dfo, ci)
cs = @subset df :cop.>3.6 :cop.<23  :ctp.<440  :ctp.>50 
@transform! cs  :isccp="cs"
append!(dfo, cs)
dc = @subset df :cop.>23  :cop.<379 :ctp.<440  :ctp.>50
@transform! dc  :isccp="dc"
append!(dfo, dc)
ac = @subset df :cop.>0   :cop.<2.6 :ctp.<680  :ctp.>440
@transform! ac  :isccp="ac"
append!(dfo, ac)
as = @subset df :cop.>3.6 :cop.<23  :ctp.<680  :ctp.>440
@transform! as  :isccp="as"
append!(dfo, as)
ns = @subset df :cop.>23  :cop.<379 :ctp.<680  :ctp.>440
@transform! ns  :isccp="ns"
append!(dfo, ns)
c = @subset df  :cop.>0   :cop.<2.6 :ctp.<1000 :ctp.>680 
@transform! c   :isccp="c"
append!(dfo, c)
sc = @subset df :cop.>3.6 :cop.<23  :ctp.<1000 :ctp.>680 
@transform! sc  :isccp="sc"
append!(dfo, sc)
s = @subset df  :cop.>23  :cop.<379 :ctp.<1000 :ctp.>680 
@transform! s   :isccp="s"
append!(dfo, s)

Arrow.write(  "./data/processed/subtropic_with_clim_and_isccp.arrow" , dfo )