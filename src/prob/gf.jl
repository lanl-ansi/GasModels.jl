# Definitions for running a feasible gas flow

"entry point into running the gas flow feasability problem"
function run_gf(file, model_type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, post_gf; kwargs...)
end


""
function run_soc_gf(file, optimizer; kwargs...)
    return run_gf(file, MISOCPGasModel, optimizer; kwargs...)
end


""
function run_minlp_gf(file, optimizer; kwargs...)
    return run_gf(file, MINLPGasModel, optimizer; kwargs...)
end


"construct the gas flow feasbility problem"
function post_gf(gm::AbstractGasModel)
    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)

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
