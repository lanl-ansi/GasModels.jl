# Definitions for running a pipe expansion problem to maximize load

export run_nels
export run_nels_directed

" entry point into running the gas flow expansion planning with load shedding "
function run_nels(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_nels; solution_builder = get_nels_solution, kwargs...)
end

" entry point into running the gas flow expansion planning with load shedding and a directed pipe model "
function run_nels_directed(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_nels_directed; solution_builder = get_nels_solution, kwargs...)
end

" construct the gas flow expansion problem to maximize load "
function post_nels(gm::GenericGasModel)
    variable_flow(gm)
    variable_pressure_sqr(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    variable_flow_ne(gm)

    # expansion cost objective
    objective_max_load(gm)

    for i in ids(gm, :junction)
        constraint_mass_flow_balance_ne_ls(gm, i)
    end

    for i in ids(gm,:pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_weymouth(gm,i)
    end

    for i in ids(gm,:resistor)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_weymouth(gm,i)
    end

    for i in ids(gm,:ne_pipe)
        constraint_pipe_pressure_ne(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_pipe_mass_flow_ne(gm,i)
        constraint_weymouth_ne(gm, i)
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

    for i in ids(gm, :control_valve)
        constraint_on_off_control_valve_mass_flow(gm, i)
        constraint_on_off_control_valve_pressure(gm, i)
    end

    exclusive = Dict()
    for (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]
        i = min(pipe["f_junction"],pipe["t_junction"])
        j = max(pipe["f_junction"],pipe["t_junction"])

        if haskey(exclusive, i) == false
            exclusive[i] = Dict()
        end

        if haskey(exclusive[i], j) == false
            constraint_exclusive_new_pipes(gm, i, j)
            exclusive[i][j] = true
        end
    end
end

" construct the gas flow expansion problem to maximize load where some of the pipes are directed"
function post_nels_directed(gm::GenericGasModel)
    variable_flow_directed(gm)
    variable_pressure_sqr(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    variable_flow_ne_directed(gm)

    # expansion cost objective
    objective_max_load(gm)

    for i in ids(gm, :junction)
        constraint_mass_flow_balance_ne_ls(gm, i)
    end

    for i in ids(gm,:undirected_pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_weymouth(gm,i)
    end

    for i in ids(gm,:undirected_resistor)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_weymouth(gm,i)
    end

    for i in ids(gm,:directed_pipe)
        constraint_pipe_pressure_directed(gm, i)
        constraint_pipe_flow_directed(gm, i)
        constraint_weymouth_directed(gm, i)
    end

    for i in ids(gm,:directed_resistor)
        constraint_pipe_pressure_directed(gm, i)
        constraint_pipe_flow_directed(gm, i)
        constraint_weymouth_directed(gm, i)
    end

    for i in ids(gm,:undirected_ne_pipe)
        constraint_pipe_pressure_ne(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_pipe_mass_flow_ne(gm,i)
        constraint_weymouth_ne(gm, i)
    end

    for i in ids(gm,:directed_ne_pipe)
        constraint_pressure_drop_ne_directed(gm, i)
        constraint_pipe_flow_ne_directed(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_weymouth_ne_directed(gm, i)
    end

    for i in ids(gm, :undirected_short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :directed_short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_flow_directed(gm, i)
    end

    for i in ids(gm,:undirected_compressor)
        constraint_compressor_ratios(gm, i)
        constraint_compressor_mass_flow(gm, i)
    end

    for i in ids(gm,:directed_compressor)
        constraint_compressor_mass_flow_directed(gm, i)
        constraint_compressor_ratios_directed(gm, i)
    end

    for i in ids(gm, :undirected_ne_compressor)
        constraint_compressor_ratios_ne(gm, i)
        constraint_compressor_ne(gm, i)
        constraint_compressor_mass_flow_ne(gm, i)
    end

    for i in ids(gm, :directed_ne_compressor)
        constraint_compressor_ne(gm, i)
        constraint_compressor_mass_flow_ne_directed(gm, i)
        constraint_compressor_ratios_ne_directed(gm, i)
    end

    for i in ids(gm, :undirected_valve)
        constraint_on_off_valve_mass_flow(gm, i)
        constraint_on_off_valve_pressure(gm, i)
    end

    for i in ids(gm, :directed_valve)
        constraint_on_off_valve_mass_flow_directed(gm, i)
        constraint_on_off_valve_pressure(gm, i)
    end

    for i in ids(gm, :undirected_control_valve)
        constraint_on_off_control_valve_mass_flow(gm, i)
        constraint_on_off_control_valve_pressure(gm, i)
    end

    for i in ids(gm, :directed_control_valve)
        constraint_on_off_control_valve_mass_flow_directed(gm, i)
        constraint_on_off_control_valve_pressure_directed(gm, i)
    end

    exclusive = Dict()
    for (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]
        i = min(pipe["f_junction"],pipe["t_junction"])
        j = max(pipe["f_junction"],pipe["t_junction"])

        if haskey(exclusive, i) == false
            exclusive[i] = Dict()
        end

        if haskey(exclusive[i], j) == false
            constraint_exclusive_new_pipes(gm, i, j)
            exclusive[i][j] = true
        end
    end
end

# Get all the solution values
function get_nels_solution(gm::GenericGasModel, sol::Dict{String,Any})
    add_junction_pressure_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    add_connection_ne(sol, gm)
    add_direction_setpoint(sol, gm)
    add_direction_ne_setpoint(sol, gm)
    add_load_volume_setpoint(sol, gm)
    add_load_mass_flow_setpoint(sol, gm)
    add_production_volume_setpoint(sol, gm)
    add_production_mass_flow_setpoint(sol, gm)
    add_compressor_ratio_setpoint(sol, gm)
    add_connection_flow_ne_setpoint(sol, gm)
    add_compressor_ratio_ne_setpoint(sol, gm)
end
