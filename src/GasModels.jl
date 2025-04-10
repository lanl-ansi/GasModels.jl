module GasModels
    import InfrastructureModels
    const _IM = InfrastructureModels

    import InfrastructureModels: optimize_model!, @im_fields, ismultinetwork, nw_id_default

    import JSON
    import JuMP
    import Memento
    import Printf
    import Statistics

    using Dates
    using Dierckx
    using PolyhedralRelaxations



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

    "alows the user to set the logging level without the need to add Memento"
    function logger_config!(level)
        Memento.config!(Memento.getlogger("GasModels"), level)
    end

    const _gm_global_keys = Set(["gas_specific_gravity", "specific_heat_capacity_ratio",
        "temperature", "sound_speed", "compressibility_factor", "R",
        "base_pressure", "base_length", "base_flow", "base_time",
        "base_flux", "base_density", "base_diameter", "base_volume", "base_mass",
        "units", "is_per_unit", "is_english_units", "is_si_units",
        "num_time_points", "time_step", "num_physical_time_points", "gas_molar_mass",
        "economic_weighting"])

    const acceleration_gravity = 9.81
    const gm_it_name = "gm"
    const gm_it_sym = Symbol(gm_it_name)

    include("io/json.jl")
    include("io/common.jl")
    include("io/gaslib.jl")
    include("io/matgas.jl")
    include("io/transient.jl")

    include("core/base.jl")
    include("core/types.jl")
    include("core/unit_converters.jl")
    include("core/data.jl")
    include("core/variable.jl")
    include("core/transient_variable.jl")
    include("core/transient_expression.jl")
    include("core/constraint_transient.jl")
    include("core/constraint_template_transient.jl")
    include("core/constraint.jl")
    include("core/constraint_template.jl")
    include("core/constraint_mi.jl")
    include("core/constraint_template_mi.jl")
    include("core/objective.jl")
    include("core/solution.jl")
    include("core/ref.jl")
    include("core/storage_archived.jl")


    include("form/lrdwp.jl")
    include("form/lrwp.jl")
    include("form/wp.jl")
    include("form/dwp.jl")
    include("form/crdwp.jl")
    include("form/cwp.jl")


    include("prob/gf.jl")
    include("prob/ne.jl")
    include("prob/ls.jl")
    include("prob/nels.jl")
    include("prob/ogf.jl")
    include("prob/ogf_comp_power_proxy.jl")
    include("prob/ogf_comp_power_and_pipe_proxy.jl")
    include("prob/transient_ogf.jl")
    include("prob/transient_ogf_archived_storage.jl")


    include("io/diagnostics.jl")

    include("core/export.jl")
end
