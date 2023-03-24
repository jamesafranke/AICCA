using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter, Statistics
if occursin("AICCA", pwd()) == false cd("AICCA") else end

round_step(x, step) = round(x / step) * step

df = DataFrame( Arrow.Table( "./data/processed/subtropics_with_climate.arrow" ) )
df = @subset df :Label.!=0 
dropmissing!( df, [:lts, :blh, :w, :u, :v , :t, :q, :sst, :msl] ) 

dropmissing!( df, [:lts, :blh, :w, :u, :v , :t, :q, :sst, :msl, :pr, :aot, :swh] )

@transform! df :sst=round_step.(:sst, 0.3) :w=round_step.(:w, 0.12) :t=round_step.(:t, 0.5) :q=round_step.(:q, 0.00025) :lts=round_step.(:lts, 0.5) :blh=round_step.(:blh, 35) :u=round_step.(:u, 1) :v=round_step.(:v, 1) :msl=round_step.(:msl, 100) :pr=round_step.(:pr, 5) :aot=round_step.(:aot, 0.07) :swh=round_step.(:swh, 0.1)

vars = [:lts, :blh, :w, :u, :v , :t, :q, :sst, :msl, :pr, :aot, :swh]
rounds = [0.5, 35, 0.12, 1,  1,  0.5, 0.00025, 0.3, 100, 5, 0.07, 0.1]
colorclass = [25, 6, 27, 8, 40, 36, 32, 33, 30, 35]

dfc = @chain df begin  
    @transform :xbin=:lts :ybin=:blh
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
end
for cc in colorclass
    total = size(@subset df :Label.==cc)[1]
    temp  = @subset dfc :maxclass.==cc
    inregion = sum(temp.maxcount)
    print( round(inregion/total * 100, digits = 2), "%", "\n") 
end


dfc = @chain df begin  
    @transform :xbin=:blh :ybin=:lts
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts rev=true
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
end
for cc in colorclass
    temp  = @subset dfc :maxclass.==cc
    inregion = sum(temp.maxcount)
    total = sum(temp.total)
    print( round(inregion/total * 100, digits = 2), "%", "\n") 
end




dfc = @chain df begin  
    @transform :xbin=:lts :ybin=:sst
    @by [:xbin, :ybin, :Label] :counts=size(:lat)[1]
    @orderby :counts
    @by [:xbin, :ybin] :maxclass=last(:Label) :maxcount=last(:counts) :total=sum(:counts)
end

temp  = @by dfc :maxclass :counts=size(:maxcount)[1]
@orderby temp -:counts


