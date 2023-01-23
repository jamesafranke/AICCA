using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
using Statistics
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
dfout = leftjoin(dfout, df2, on =:id3)
replace!(dfout.id4, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id :id2
rename!(df2, :time_0=>:time4, :lat=>:lat4, :lon=>:lon4, :id=>:id4, :class1=>:class4, :delta1=>:delta4, :id2=>:id5)
dfout = leftjoin(dfout, df2, on =:id4)
replace!(dfout.id5, missing=>-999)

df2 =  @select df :time_0 :lat :lon :class1 :delta1 :id
rename!(df2, :time_0=>:time5, :lat=>:lat5, :lon=>:lon5, :id=>:id5, :class1=>:class5, :delta1=>:delta5)
dfout = leftjoin(dfout, df2, on =:id5)


chained = unique(dfout.id5)
@rsubset! dfout :id .∉ 






df2 = @chain df begin
    @transform :date=Date.(:time_0) :time=Hour.(:time_0)
    @select :date :time :class2 :latf :lonf  
    rename(:latf=>:lat, :lonf=>:lon, :class1=>:class2a, :class2=>:class3, :delta1=>:delta2)
    @select :lat :lon :date :time :class2a :class3 :delta2
end

df2 = leftjoin(df, df2, on=[:lat, :lon, :date, :time] )


@transform! df :ID=:Row

dropmissing!(df2)

histogram(df.hours)


df = DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_40NS.arrow" ) )

dfs = get_subtrop(df)
temp = @chain dfs begin
    @orderby :time_0 
    @by [:time_0, :lat, :lon] :first=first(:Label) :next=first(:next_label) :hours=first(:hours)
end


temp1 = @subset temp :first.==35
histogram( temp1.next )

temp2 = @by temp1 :next :mean_time=mean(:hours)
scatter(temp2.next, temp2.mean_time)



@subset df :time_0 = Datetime

















df1 = @subset df :date.==Date("2021-12-30") :latr.==9 :lonr.==176

temp = @chain df begin
    @by [:time_0, :lat, :lon] :num=size(:Label)[1]
    @orderby :num
end


@subset temp :num.>1


81468670 - 81440628

24163