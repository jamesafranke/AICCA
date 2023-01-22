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
df = @chain DataFrame( Arrow.Table( "./data/processed/transitions/all_transitions_40NS.arrow" ) ) begin
    @subset :lat.>-39 :lat.<3  :lon.>-120 :lon.<-70 
    @orderby :time_0 
    @by [:time_0, :lat, :lon] :date=first(:date) :time=first(Hour.(:Timestamp)) :class1=first(:Label) :class2=first(:next_label) :delta1=first(:hours) :latf=first(:latf) :lonf=first(:lonf)
end

df2 = @chain df begin
    @transform :date=Date.(:time_0) :time=Hour.(:time_0)
    @select :date :time :class2 :latf :lonf  
    rename(:latf=>:lat, :lonf=>:lon, :class1=>:class2a, :class2=>:class3, :delta1=>:delta2)
    @select :lat :lon :date :time :class2a :class3 :delta2
end

df2 = leftjoin(df, df2, on=[:lat, :lon, :date, :time] )


@transform! df :ID=:Row

dropmissing!(df2)



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