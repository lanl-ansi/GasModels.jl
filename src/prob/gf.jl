# Definitions for running a feasible gas flow

# Note that this particular formulation assumes the binary variable implementation of flow direction
# We would need to do some abstraction to support the absolute value formulation

export run_gf

" entry point into running the gas flow feasability problem "
function run_gf(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gf; kwargs...)
end

""
function run_soc_gf(file, solver; kwargs...)
    return run_gf(file, MISOCPGasModel, solver; kwargs...)
end

""
function run_minl_gf(file, solver; kwargs...)
    return run_gf(file, MINLPGasModel, solver; kwargs...)
end

" construct the gas flow feasbility problem "
function post_gf(gm::GenericGasModel)
    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_valve_operation(gm)

    for i in ids(gm, :junction)
        constraint_mass_flow_balance(gm, i)
    end

    for i in ids(gm, :pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_weymouth(gm,i)
    end

    for i in ids(gm, :resistor)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_weymouth(gm,i)
    end


    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_ratios(gm, i)
        constraint_compressor_mass_flow(gm, i)
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
