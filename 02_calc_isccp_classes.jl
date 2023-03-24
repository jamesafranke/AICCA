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