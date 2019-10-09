# Definitions for running a minimum load shed model

"entry point into running the gas flow feasability problem"
function run_ls(file, model_type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, post_ls; solution_builder = solution_ls!, kwargs...)
end


"construct the gas flow feasbility problem"
function post_ls(gm::AbstractGasModel)
    variable_flow(gm)
    variable_pressure_sqr(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)

    objective_max_load(gm)

    for i in ids(gm,:pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_pipe_weymouth(gm,i)
    end

    for i in ids(gm,:resistor)
        constraint_resistor_pressure(gm, i)
        constraint_resistor_mass_flow(gm,i)
        constraint_resistor_weymouth(gm,i)
    end

    for i in ids(gm, :junction)
        constraint_mass_flow_balance(gm, i)
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


"Get all the load shedding solution values"
function solution_ls!(gm::AbstractGasModel,sol::Dict{String,Any})
    add_junction_pressure_setpoint!(sol, gm)
    add_connection_flow_setpoint!(sol, gm)
    add_direction_setpoint!(sol, gm)
    add_load_volume_setpoint!(sol, gm)
    add_load_mass_flow_setpoint!(sol, gm)
    add_production_volume_setpoint!(sol, gm)
    add_production_mass_flow_setpoint!(sol, gm)
    add_compressor_ratio_setpoint!(sol, gm)
end
