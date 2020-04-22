# Definitions for running an optimal gas flow (ogf)

"entry point into running the ogf problem"
function solve_ogf(file, model_type, optimizer; kwargs...)
    return solve_model(file, model_type, optimizer, post_ogf; kwargs...)
end


""
function solve_soc_ogf(file, optimizer; kwargs...)
    return solve_ogf(file, MISOCPGasModel, optimizer; kwargs...)
end


""
function solve_minlp_ogf(file, optimizer; kwargs...)
    return solve_ogf(file, MINLPGasModel, optimizer; kwargs...)
end


"construct the ogf problem"
function post_ogf(gm::AbstractGasModel)
    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)
    variable_compressor_ratio_sqr(gm)

    objective_min_economic_costs(gm)

    for (i,junction) in ref(gm, :junction)
        constraint_mass_flow_balance(gm, i)
       if (junction["junction_type"] == 1)
           constraint_pressure(gm,i)
       end
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

    for i in ids(gm, :regulator)
        constraint_on_off_regulator_mass_flow(gm, i)
        constraint_on_off_regulator_pressure(gm, i)
    end
end
