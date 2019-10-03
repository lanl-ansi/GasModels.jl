# Definitions for running a compressor optimization


export run_c

" entry point into running the compressor optimization problem "
function run_c(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_c; kwargs...)
end

""
function run_soc_c(file, solver; kwargs...)
    return run_c(file, MISOCPGasModel, solver; kwargs...)
end

""
function run_minlp_c(file, solver; kwargs...)
    return run_c(file, MINLPGasModel, solver; kwargs...)
end

" construct the compressor optimization problem "
function post_c(gm::GenericGasModel)
    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_compression_ratio(gm)

    objective_min_compressor_energy(gm)

    for i in ids(gm, :junction)
        constraint_mass_flow_balance(gm, i)
    end

    for i in ids(gm, :pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_pipe_weymouth(gm,i)
    end

    for i in ids(gm, :resistor)
        constraint_resistor_pressure(gm, i)
        constraint_resistor_mass_flow(gm,i)
        constraint_resistor_weymouth(gm,i)
    end


    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_ratios(gm, i)
        constraint_compressor_mass_flow(gm, i)
        constraint_compressor_ratio_value(gm,i)
        constraint_compressor_energy(gm,i)
    end

    for i in ids(gm, :valve)
        constraint_on_off_valve_mass_flow(gm, i)
        constraint_on_off_valve_pressure(gm, i)
    end

    for i in ids(gm, :control_valve)
        constraint_on_off_control_valve_mass_flow(gm, i)
        constraint_on_off_control_valve_pressure(gm, i)
    end
end
