# Definitions for running a pipe expansion problem to maximize load

"entry point into running the gas flow expansion planning with load shedding"
function run_nels(file, model_type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, build_nels; ref_extensions=[ref_add_ne!], solution_processors=[sol_psqr_to_p!, sol_compressor_p_to_r!, sol_regulator_p_to_r!, sol_ne_compressor_p_to_r!], kwargs...)
end


"entry point into running the gas flow expansion planning with load shedding and a directed pipe model"
function run_nels_directed(file, model_type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, build_nels_directed; ref_extensions=[ref_add_ne!], solution_processors=[sol_psqr_to_p!, sol_compressor_p_to_r!, sol_regulator_p_to_r!, sol_ne_compressor_p_to_r!], kwargs...)
end


"construct the gas flow expansion problem to maximize load"
function build_nels(gm::AbstractGasModel)
    variable_flow(gm)
    variable_pressure_sqr(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    variable_flow_ne(gm)

    # expansion cost objective
    objective_max_load(gm)

    for i in ids(gm, :junction)
        constraint_mass_flow_balance_ne(gm, i)
    end

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

    for i in ids(gm,:ne_pipe)
        constraint_pipe_pressure_ne(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_pipe_mass_flow_ne(gm,i)
        constraint_pipe_weymouth_ne(gm, i)
    end

    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm,:compressor)
        constraint_compressor_ratios(gm, i)
        constraint_compressor_mass_flow(gm, i)
    end

    for i in ids(gm, :ne_compressor)
        constraint_compressor_ratios_ne(gm, i)
        constraint_compressor_ne(gm, i)
        constraint_compressor_mass_flow_ne(gm, i)
    end

    for i in ids(gm, :valve)
        constraint_on_off_valve_mass_flow(gm, i)
        constraint_on_off_valve_pressure(gm, i)
    end

    for i in ids(gm, :regulator)
        constraint_on_off_regulator_mass_flow(gm, i)
        constraint_on_off_regulator_pressure(gm, i)
    end

    exclusive = Dict()
    for (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]
        i = min(pipe["fr_junction"],pipe["to_junction"])
        j = max(pipe["fr_junction"],pipe["to_junction"])

        if haskey(exclusive, i) == false
            exclusive[i] = Dict()
        end

        if haskey(exclusive[i], j) == false
            constraint_exclusive_new_pipes(gm, i, j)
            exclusive[i][j] = true
        end
    end
end


"construct the gas flow expansion problem to maximize load where some of the pipes are directed"
function build_nels_directed(gm::AbstractGasModel)
    variable_flow_directed(gm)
    variable_pressure_sqr(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    variable_flow_ne_directed(gm)

    # expansion cost objective
    objective_max_load(gm)

    for i in ids(gm, :junction)
        constraint_mass_flow_balance_ne(gm, i)
    end

    for i in ids(gm,:undirected_pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_pipe_weymouth(gm,i)
    end

    for i in ids(gm,:undirected_resistor)
        constraint_resistor_pressure(gm, i)
        constraint_resistor_mass_flow(gm,i)
        constraint_resistor_weymouth(gm,i)
    end

    for i in ids(gm,:directed_pipe)
        constraint_pipe_pressure_directed(gm, i)
        constraint_pipe_mass_flow_directed(gm, i)
        constraint_pipe_weymouth_directed(gm, i)
    end

    for i in ids(gm,:directed_resistor)
        constraint_resistor_pressure_directed(gm, i)
        constraint_resistor_mass_flow_directed(gm, i)
        constraint_resistor_weymouth_directed(gm, i)
    end

    for i in ids(gm,:undirected_ne_pipe)
        constraint_pipe_pressure_ne(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_pipe_mass_flow_ne(gm,i)
        constraint_pipe_weymouth_ne(gm, i)
    end

    for i in ids(gm,:directed_ne_pipe)
        constraint_pipe_pressure_ne_directed(gm, i)
        constraint_pipe_mass_flow_ne_directed(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_pipe_weymouth_ne_directed(gm, i)
    end

    for i in ids(gm, :undirected_short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :directed_short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow_directed(gm, i)
    end

    for i in ids(gm,:default_compressor)
        constraint_compressor_ratios(gm, i)
        constraint_compressor_mass_flow(gm, i)
    end

    for i in ids(gm,:unidirectional_compressor)
        constraint_compressor_mass_flow_directed(gm, i)
        constraint_compressor_ratios_directed(gm, i)
    end

    for i in ids(gm, :default_ne_compressor)
        constraint_compressor_ratios_ne(gm, i)
        constraint_compressor_ne(gm, i)
        constraint_compressor_mass_flow_ne(gm, i)
    end

    for i in ids(gm, :unidirectional_ne_compressor)
        constraint_compressor_ne(gm, i)
        constraint_compressor_mass_flow_ne_directed(gm, i)
        constraint_compressor_ratios_ne_directed(gm, i)
    end

    for i in ids(gm, :valve)
        constraint_on_off_valve_mass_flow(gm, i)
        constraint_on_off_valve_pressure(gm, i)
    end

    for i in ids(gm, :undirected_regulator)
        constraint_on_off_regulator_mass_flow(gm, i)
        constraint_on_off_regulator_pressure(gm, i)
    end

    for i in ids(gm, :directed_regulator)
        constraint_on_off_regulator_mass_flow_directed(gm, i)
        constraint_on_off_regulator_pressure_directed(gm, i)
    end

    exclusive = Dict()
    for (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]
        i = min(pipe["fr_junction"],pipe["to_junction"])
        j = max(pipe["fr_junction"],pipe["to_junction"])

        if haskey(exclusive, i) == false
            exclusive[i] = Dict()
        end

        if haskey(exclusive[i], j) == false
            constraint_exclusive_new_pipes(gm, i, j)
            exclusive[i][j] = true
        end
    end
end
