module GasModels
    import InfrastructureModels
    const _IM = InfrastructureModels

    import InfrastructureModels: optimize_model!, @im_fields, ismultinetwork, nw_id_default

    import JSON
    import JuMP
    import Printf
    import Statistics

    using Dates
    import Logging
    using Dierckx
    using PolyhedralRelaxations
    
    const _LOGGER = Ref{Logging.ConsoleLogger}()

    function __init__()
        logger_config!("info")
        return
    end

    """
        silence()

    Silence logging within GasModels and InfrastructureModels.

    This is equivalent to calling `logger_config!("error")`.
    """
    function silence()
        logger_config!("error")
        _IM.logger_config!("error")
        return
    end

    function _meta_formatter(level::Logging.LogLevel, _module, args...)
        return Logging.default_logcolor(level), "$(_module) | $level]:", ""
    end

    function logger_config!(level::Logging.LogLevel)
        _LOGGER[] =
            Logging.ConsoleLogger(stdout, level; meta_formatter = _meta_formatter)
        return
    end

    """
        logger_config!(level::String)

    Set the logging level within GasModels. `level` just be one of `"error"`,
    `"warn"`, `"info"`, or `"debug"`.
    """
    function logger_config!(level::String)
        return getfield(Logging, level |> titlecase |> Symbol) |> logger_config!
    end

    function _log_if_level(f, level, logger = _LOGGER[])
        if level >= Logging.min_enabled_level(logger)
            Logging.with_logger(f, logger)
        end
        return
    end

    macro _error(msg)
        return quote
            GasModels._log_if_level(() -> @error($msg), Logging.Error)
            error($msg)
        end |> esc
    end

    macro _warn(msg)
        return :(GasModels._log_if_level(() -> @warn($msg), Logging.Warn)) |> esc
    end

    macro _debug(msg)
        return :(GasModels._log_if_level(() -> @debug($msg), Logging.Debug)) |> esc
    end

    macro _info(msg)
        return :(GasModels._log_if_level(() -> @info($msg), Logging.Info)) |> esc
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
    include("io/contingency.jl")

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
