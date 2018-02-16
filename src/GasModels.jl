isdefined(Base, :__precompile__) && __precompile__()

module GasModels

using JSON
using MathProgBase
using JuMP
using Compat

include("io/json.jl")
include("io/common.jl")

include("core/base.jl")
include("core/data.jl")
include("core/variable.jl")
include("core/constraint.jl")
include("core/constraint_template.jl")
include("core/objective.jl")
include("core/solution.jl")

include("form/minlp.jl")
include("form/misocp.jl")
include("form/directed.jl")
include("form/undirected.jl")
include("form/shared.jl")

include("prob/gf.jl")
include("prob/ne.jl")
include("prob/ls.jl")
include("prob/nels.jl")

end