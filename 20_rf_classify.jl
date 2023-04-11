using Statistics, MLJ, MLJLinearModels, Distributions, Combinatorics
using Arrow, DataFrames, DataFramesMeta, Dates, ProgressMeter
if occursin("AICCA", pwd()) == false cd("AICCA") else end
include("00_helper.jl")

df = DataFrame()
fl = filter( !contains(".DS"), readdir( joinpath( pwd(), "data/processed/monthly_merged/") ) )
@showprogress for file in fl[begin:7:end] append!( df, DataFrame( Arrow.Table( joinpath("./data/processed/monthly_merged/", file ) ) ) )  end

all_vars = [:t1000,:t950,:t925,:t900,:t850,:t800,:t750,:t700,:r950,:r925,:r900,:r850,:r800,:r750,:r700,:d950,:d925,:d900,:d850,:d800,:d750,
        :d700,:z950,:z925,:z900,:z850,:z800,:z750,:z700,:pv950,:pv925,:pv900,:pv850,:pv800,:pv750,:pv700,:u950,:u925,:u900,:u850,:u800,
        :u750,:u700,:v950,:v925,:v900,:v850,:v800,:v750,:v700,:w950,:w925,:w900,:w850,:w800,:w750,:w700,:sst,:swh,:msl,:blh,:aot,:pr]

temp = DataFrame( Arrow.Table( joinpath("./data/processed/monthly_merged/", fl[1] ) ) )

var_combs = collect(combinations(all_vars,2))
class_combs = collect(combinations([25, 34, 37, 36, 29, 27, 19, 39, 28, 31, 33, 32, 40, 26, 30, 35],2))

df = DataFrame()
for vars in var_combs
        temp = select(temp, [:Label, vars[i], vars[j]])
        transform!(temp, vars .=> (x -> minmax(x) ) .=> vars)
        dropmissing!(temp)

        for k in class_combs
                temp1 = @rsubset temp :Label in k

                y, X = unpack( temp, ==(:Label); :Label => Multiclass )
                train, test = partition( eachindex(y), 0.8, shuffle=true )

                SVC = @load SVC pkg=LIBSVM
                mod = EnsembleModel( model=SVC(gamma=0.7), n=10, bagging_fraction=0.1 )
                mach = machine( mod, X, y )
                fit!( mach, verbosity = 2 )
                yhat = predict(mach, X[test,:])
                mcr = misclassification_rate(yhat, y[test] )
                
        end
end



