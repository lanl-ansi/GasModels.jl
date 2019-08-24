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
function run_nl_gf(file, solver; kwargs...)
    return run_gf(file, MINLPGasModel, solver; kwargs...)
end

" construct the gas flow feasbility problem "
function post_gf(gm::GenericGasModel)
    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_valve_operation(gm)

    for i in ids(gm, :junction)
        constraint_set_junction_mass_flow(gm, i)
    end

    for i in [collect(ids(gm, :pipe)); collect(ids(gm, :resistor))]
        constraint_set_pipe_flow(gm, i)
    end

    for i in ids(gm, :short_pipe)
        constraint_set_short_pipe_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_set_compressor_flow(gm, i)
    end

    for i in ids(gm, :valve)
        constraint_set_valve_flow(gm, i)
    end

    for i in ids(gm, :control_valve)
        constraint_set_control_valve_flow(gm, i)
    end
end
