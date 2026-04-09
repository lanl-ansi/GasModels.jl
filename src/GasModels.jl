module GasModels
    import InfrastructureModels
    const _IM = InfrastructureModels

    import InfrastructureModels: optimize_model!, @im_fields, ismultinetwork, nw_id_default

    import JSON
    import JuMP
    import Printf
    import Statistics

    using Dates, Logging, LoggingExtras
    using Dierckx
    using PolyhedralRelaxations
    
    global _LOGGER

    function __init__()
        logger_config!("info")
        return
    end

    function silence!()
        logger_config!("error")
    end

    function _meta_formatter(l::Logging.LogLevel, _module, ::Any, id, file, line)
        color = Logging.default_logcolor(l)
        prefix = "$(_module) | $l]:"
        if Logging.Info <= l < Logging.Warn
            return color, prefix, ""
        end
        suffix = string("@ $(_module) ", Base.contractuser(file), ":$line")
        return color, prefix, suffix
    end

    function logger_config!(level::Logging.LogLevel)
        global _LOGGER =
            Logging.ConsoleLogger(stdout, level; meta_formatter = _meta_formatter)
        return
    end

    function logger_config!(level::String)
        if level == "error"
            logger_config!(Logging.Error)
        elseif level == "warn"
            logger_config!(Logging.Warn)
        elseif level == "info"
            logger_config!(Logging.Info)
        else
            @assert level == "debug"
            logger_config!(Logging.Debug)
        end
        return
    end

    macro _warn(msg)
        logger = GlobalRef(@__MODULE__, :_LOGGER)
        return quote
            Logging.with_logger($logger) do
                @warn $(esc(msg))
            end
        end
    end

    macro _info(msg)
        logger = GlobalRef(@__MODULE__, :_LOGGER)
        return quote
            Logging.with_logger($logger) do
                @info $(esc(msg))
            end
        end
    end

    macro _debug(msg)
        logger = GlobalRef(@__MODULE__, :_LOGGER)
        return quote
            Logging.with_logger($logger) do
                @debug $(esc(msg))
            end
        end
    end

    macro _error(msg)
        logger = GlobalRef(@__MODULE__, :_LOGGER)
        return quote
            Logging.with_logger($logger) do
                @error $(esc(msg))
            end
            error($(esc(msg)))
        end
    end

    const _gm_global_keys = Set(["gas_specific_gravity", "specific_heat_capacity_ratio",
        "temperature", "sound_speed", "compressibility_factor", "R",
        "base_pressure", "base_length", "base_flow", "base_time",
        "base_flux", "base_density", "base_diameter", "base_volume", "base_mass",
        "units", "per_unit", "english_units", "si_units",
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
    include("io/multinetwork.jl") 
    include("io/solution_hints.jl")
    include("io/separated_data.jl")

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
    include("prob/ogf_comp_power_unconstrained.jl")
    include("prob/ogf_comp_power_proxy.jl")
    include("prob/ogf_comp_power_and_pipe_proxy.jl")
    include("prob/transient_ogf.jl")
    include("prob/transient_ogf_archived_storage.jl")


    include("io/diagnostics.jl")

    include("core/export.jl")
end
