# Definitions for running a pipe expansion problem

"entry point into running the gas flow feasability problem"
function run_ne(file, model_type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, post_ne; solution_builder = solution_ne!, ref_extensions=[ref_add_ne!], kwargs...)
end


"construct the gas flow feasbility problem"
function post_ne(gm::AbstractGasModel; kwargs...)
    kwargs = Dict(kwargs)
    obj_normalization = haskey(kwargs, :obj_normalization) ? kwargs[:obj_normalization] : 1.0

    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_flow_ne(gm)
    variable_valve_operation(gm)
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)

    # expansion cost objective
    objective_min_ne_cost(gm; normalization =  obj_normalization)

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
        constraint_pipe_weymouth_ne(gm, i)
        constraint_pipe_mass_flow_ne(gm,i)
    end

    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_mass_flow(gm, i)
        constraint_compressor_ratios(gm, i)
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


"Special function for whether or not a connection is added"
function add_connection_ne(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "ne_pipe", "built", :zp; default_value = (item) -> NaN)
    add_setpoint!(sol, gm, "ne_compressor", "built", :zc; default_value = (item) -> NaN)
end


"Get the direction solutions"
function add_direction_ne_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "ne_pipe", "y", :y_ne_pipe)
    add_setpoint!(sol, gm, "ne_compressor", "y", :y_ne_compressor)
end


"Add the compressor solutions"
function add_compressor_ratio_ne_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "ne_compressor", "ratio", :p; scale = (x,item) -> sqrt(JuMP.value(x[2])) / sqrt(JuMP.value(x[1])), extract_var = (var,idx,item) -> [var[item["fr_junction"]],var[item["to_junction"]]]   )
end


"Add the flow solutions to new lines"
function add_connection_flow_ne_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "ne_pipe", "f", :f_ne_pipe)
    add_setpoint!(sol, gm, "ne_compressor", "f", :f_ne_compressor)
end


"Get all the solution values"
function solution_ne!(gm::AbstractGasModel, sol::Dict{String,Any})
    add_junction_pressure_setpoint!(sol, gm)
    add_connection_flow_setpoint!(sol, gm)
    add_connection_flow_ne_setpoint!(sol, gm)
    add_direction_setpoint!(sol, gm)
    add_direction_ne_setpoint!(sol, gm)
    add_compressor_ratio_setpoint!(sol, gm)
    add_compressor_ratio_ne_setpoint!(sol, gm)
    add_connection_ne(sol, gm)
end
