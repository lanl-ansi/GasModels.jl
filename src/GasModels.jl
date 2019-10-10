module GasModels
    import InfrastructureModels

    import JSON
    import JuMP
    import Memento

    # Create our module level logger (this will get precompiled)
    const _LOGGER = Memento.getlogger(@__MODULE__)

    # Register the module level logger at runtime so that folks can access the logger via `getlogger(GasModels)`
    # NOTE: If this line is not included then the precompiled `GasModels.LOGGER` won't be registered at runtime.
    __init__() = Memento.register(_LOGGER)

    "Suppresses information and warning messages output by GasModels, for fine grained control use the Memento package"
    function silence()
        Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.  Use the Memento package for more fine-grained control of logging.")
        Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
        Memento.setlevel!(Memento.getlogger(GasModels), "error")
    end

    import MathOptInterface
    const MOI = MathOptInterface
    const MOIU = MathOptInterface.Utilities

    include("io/json.jl")
    include("io/common.jl")
    include("io/grail.jl")
    include("io/matlab.jl")

    include("core/base.jl")
    include("core/types.jl")
    include("core/data.jl")
    include("core/variable.jl")
    include("core/constraint.jl")
    include("core/constraint_template.jl")
    include("core/constraint_mi.jl")
    include("core/constraint_template_mi.jl")
    include("core/objective.jl")
    include("core/solution.jl")

    include("form/mip.jl")
    include("form/lp.jl")
    include("form/nlp.jl")
    include("form/minlp.jl")
    include("form/misocp.jl")

    include("prob/gf.jl")
    include("prob/ne.jl")
    include("prob/ls.jl")
    include("prob/nels.jl")
    include("prob/ogf.jl")

    include("io/diagnostics.jl")

    include("core/export.jl")
end
