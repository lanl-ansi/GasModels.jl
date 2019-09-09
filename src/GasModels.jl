module GasModels

using JSON
using JuMP
using InfrastructureModels
using Compat
using Memento

# Create our module level logger (this will get precompiled)
const LOGGER = getlogger(@__MODULE__)

# Register the module level logger at runtime so that folks can access the logger via `getlogger(GasModels)`
# NOTE: If this line is not included then the precompiled `GasModels.LOGGER` won't be registered at runtime.
__init__() = Memento.register(LOGGER)

"Suppresses information and warning messages output by GasModels, for fine grained control use the Memento package"
function silence()
    info(LOGGER, "Suppressing information and warning messages for the rest of this session.  Use the Memento package for more fine-grained control of logging.")
    setlevel!(getlogger(InfrastructureModels), "error")
    setlevel!(getlogger(GasModels), "error")
end
import MathOptInterface
const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

include("io/json.jl")
include("io/common.jl")
include("io/grail.jl")
include("io/matlab.jl")

include("core/base.jl")
include("core/data.jl")
include("core/variable.jl")
include("core/constraint.jl")
include("core/constraint_template.jl")
include("core/objective.jl")
include("core/solution.jl")

include("form/mip.jl")
include("form/lp.jl")
include("form/nlp.jl")
include("form/mi/minlp.jl")
include("form/mi/misocp.jl")
include("form/mi/shared.jl")
include("form/mi/variable.jl")
include("form/mi/constraint.jl")
include("form/mi/constraint_template.jl")


include("prob/gf.jl")
include("prob/ne.jl")
include("prob/ls.jl")
include("prob/nels.jl")

include("io/diagnostics.jl")

end
