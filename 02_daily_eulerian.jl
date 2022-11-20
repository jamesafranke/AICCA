using Plots; gr(); Plots.theme(:default)
using Arrow, DataFrames, DataFramesMeta, Dates 
using Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

# load in class data for the tropics merged with climate vars
df = DataFrame( Arrow.Table("./data/processed/subtropic_sc_w_ctp_and_frac_daily_clim.arrow"))
rename!(df, :Cloud_Optical_Thickness_mean => :cop, :Cloud_Top_Pressure_mean => :ctp, :Cloud_Fraction => :cf)


# get the sub-daily transisions
dft = @chain df begin
    @select :date :hour :lat :lon :Label
    @orderby [:date, :hour]
    @by [:lat, :lon, :date] :class=first(:Label) :nextclass=last(:Label) :day_num=size(:Label)[1] :hour_diff=last(:hour)-last(:hour)
    @subset :day_num.>1
    #@rsubset :class.!=0 || :nextclass.!=0
end


ci = @subset df :cop.>0   :cop>2.6 :ctp.>440  :ctp.<50
@transform! ci  :isccp="ci"
cs = @subset df :cop.>3.6 :cop>23  :ctp.>440  :ctp.<50 
@transform! cs  :isccp="cs"
dc = @subset df :cop.>23  :cop>379 :ctp.>440  :ctp.<50
@transform! dc  :isccp="dc"
ac = @subset df :cop.>0   :cop>2.6 :ctp.>680  :ctp.<440
@transform! ac  :isccp="ac"
as = @subset df :cop.>3.6 :cop>23  :ctp.>680  :ctp.<440
@transform! as  :isccp="as"
ns = @subset df :cop.>23  :cop>379 :ctp.>680  :ctp.<440
@transform! ns  :isccp="ns"
c = @subset df  :cop.>0    :cop>2.6 :ctp.>1000 :ctp.<680 
@transform! c   :isccp="c"
sc = @subset df :cop.>3.6 :cop>23  :ctp.>1000 :ctp.<680 
@transform! sc  :isccp="sc"
s = @subset df  :cop.>23   :cop>379 :ctp.>1000 :ctp.<680 
@transform! s   :isccp="s"
df = vcat( (ci,cs,dc,ac,as,ns,c,sc,s) )


# plot some class transisons 
temp = @subset dft :class .== 33 
histogram( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500) )
temp = @subset dft :class .== 32 
histogram!( temp.nextclass, xticks = 0:1:42, leg = false, size = (900,500), alpha = 0.5 )



