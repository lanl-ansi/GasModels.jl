module GasModels

using JSON
using MathProgBase
using JuMP
using InfrastructureModels
using Compat

if VERSION < v"0.7.0-"
    import Compat: @warn

end

include("io/json.jl")
include("io/common.jl")
include("io/grail.jl")

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

include("io/diagnostics.jl")

end