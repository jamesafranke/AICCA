using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
using Plots; gr(); Plots.theme(:default)
if occursin("AICCA", pwd()) == false cd("AICCA") else end

function get_subtrop(dfin) ### subtropical regions with large sc decks ###
    dfout = DataFrame()
    append!( dfout, @subset dfin :lat.>7   :lat.<39 :lon.>-165 :lon.<-100 ) # north pacific
    append!( dfout, @subset dfin :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70  ) # south pacific
    append!( dfout, @subset dfin :lat.>-35 :lat.<0  :lon.>-25  :lon.<20   ) # south alantic
    return dfout
end

# string together transitions 
df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_SP.arrow" ) )
df = @orderby df :time_0 
df = @by df [:time_0, :lat, :lon] :class1=first(:Label) :delta1=first(:hours) :id=first(:id) :id2=first(:next_id)

df2 = @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time2, :lat=>:lat2, :lon=>:lon2, :id=>:id2, :class1=>:class2, :delta1=>:delta2, :id2=>:id3)
dfout = leftjoin(df, df2, on =:id2)
replace!(dfout.id3, missing=>-999)

df2 = @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time3, :lat=>:lat3, :lon=>:lon3, :id=>:id3, :class1=>:class3, :delta1=>:delta3, :id2=>:id4)
dfout = leftjoin(dfout, df2, on=:id3)
replace!(dfout.id4, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time4, :lat=>:lat4, :lon=>:lon4, :id=>:id4, :class1=>:class4, :delta1=>:delta4, :id2=>:id5)
dfout = leftjoin(dfout, df2, on=:id4)
replace!(dfout.id5, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time5, :lat=>:lat5, :lon=>:lon5, :id=>:id5, :class1=>:class5, :delta1=>:delta5, :id2=>:id6)
dfout = leftjoin(dfout, df2, on=:id5)
replace!(dfout.id6, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time6, :lat=>:lat6, :lon=>:lon6, :id=>:id6, :class1=>:class6, :delta1=>:delta6, :id2=>:id7)
dfout = leftjoin(dfout, df2, on=:id6)
replace!(dfout.id7, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time7, :lat=>:lat7, :lon=>:lon7, :id=>:id7, :class1=>:class7, :delta1=>:delta7, :id2=>:id8)
dfout = leftjoin(dfout, df2, on=:id7)
replace!(dfout.id8, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time8, :lat=>:lat8, :lon=>:lon8, :id=>:id8, :class1=>:class8, :delta1=>:delta8, :id2=>:id9)
dfout = leftjoin(dfout, df2, on=:id8)
replace!(dfout.id9, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time9, :lat=>:lat9, :lon=>:lon9, :id=>:id9, :class1=>:class9, :delta1=>:delta9, :id2=>:id10)
dfout = leftjoin(dfout, df2, on=:id9)
replace!(dfout.id10, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id
rename!(df2, :time_0=>:time10, :lat=>:lat10, :lon=>:lon10, :id=>:id10, :class1=>:class10, :delta1=>:delt10)
dfout = leftjoin(dfout, df2, on=:id10)

@subset! dfout :class1.==35
chained = unique(dfout.id10)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id9)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id8)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id7)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id6)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id5)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id4)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id3)
@subset! dfout :id .∉ Ref(chained)
chained = unique(dfout.id2)
@subset! dfout :id .∉ Ref(chained)

temp = @select dfout :class1 :class2 :class3 :class4 :class5 :class6 :class7 :class8 :class9 :class10

CSV.write("data/processed/35_chained10_transitions_SP.csv", temp)



dfout





