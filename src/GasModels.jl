isdefined(Base, :__precompile__) && __precompile__()

module GasModels

using JSON
using MathProgBase
using JuMP

include("io/json.jl")
include("io/common.jl")

include("core/base.jl")
include("core/variable.jl")
include("core/constraint.jl")
include("core/relaxation_scheme.jl")
include("core/objective.jl")
include("core/solution.jl")

include("form/minlp.jl")
include("form/misocp.jl")

include("prob/gf.jl")
include("prob/expansion.jl")

end