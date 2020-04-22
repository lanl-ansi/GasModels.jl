# Definitions for running a minimum load shed model

"entry point into running the gas flow feasability problem"
function solve_ls(file, model_type, optimizer; kwargs...)
    return solve_model(file, model_type, optimizer, post_ls; kwargs...)
end


"construct the gas flow feasbility problem"
function post_ls(gm::AbstractGasModel)
    variable_flow(gm)
    variable_pressure_sqr(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)

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

    for i in ids(gm, :regulator)
        constraint_on_off_regulator_mass_flow(gm, i)
        constraint_on_off_regulator_pressure(gm, i)
    end
end
