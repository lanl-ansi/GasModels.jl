"Build a gas solution"
function build_solution(gm::AbstractGasModel, solve_time; solution_builder=solution_gf!)
    sol = _init_solution(gm)
    data = Dict{String,Any}("name" => haskey(gm.data, "name") ? gm.data["name"] : "none")

    if gm.data["multinetwork"]
        sol_nws = sol["nw"] = Dict{String,Any}()
        data_nws = data["nw"] = Dict{String,Any}()

        for (n,nw_data) in gm.data["nw"]
            sol_nw = sol_nws[n] = Dict{String,Any}()
            gm.cnw = parse(Int, n)
            solution_builder(gm, sol_nw)
            data_nws[n] = Dict(
                "name" => nw_data["name"],
                "junction_count" => length(nw_data["junction"]),
                "pipe_count" => haskey(nw_data, "pipe") ? length(nw_data["pipe"]) : 0,
                "short_pipe_count" => haskey(nw_data, "short_pipe") ? length(nw_data["short_pipe"]) : 0,
                "compressor_count" => haskey(nw_data, "compressor") ? length(nw_data["compressor"]) : 0,
                "valve_count" => haskey(nw_data, "valve") ? length(nw_data["valve"]) : 0,
                "control_valve_count" => haskey(nw_data, "control_valve") ? length(nw_data["control_valve"]) : 0,
                "resistor_count" => haskey(nw_data, "resistor") ? length(nw_data["resistor"]) : 0
            )
        end
    else
        solution_builder(gm, sol)
        data["junction_count"] = length(gm.data["junction"])
        data["pipe_count"] = haskey(gm.data, "pipe") ? length(gm.data["pipe"]) : 0
        data["compressor_count"] = haskey(gm.data, "compressor") ? length(gm.data["compressor"]) : 0
        data["valve_count"] = haskey(gm.data, "valve") ? length(gm.data["valve"]) : 0
        data["control_valve_count"] = haskey(gm.data, "control_valve") ? length(gm.data["control_valve"]) : 0
        data["resistor_count"] = haskey(gm.data, "resistor") ? length(gm.data["resistor"]) : 0
        data["short_pipe_count"] = haskey(gm.data, "short_pipe") ? length(gm.data["short_pipe"]) : 0
    end

    solution = Dict{String,Any}(
        "optimizer" => string(typeof(gm.model.moi_backend.optimizer)),
        "termination_status" => JuMP.termination_status(gm.model),
        "primal_status" => JuMP.primal_status(gm.model),
        "dual_status" => JuMP.dual_status(gm.model),
        "objective" => _guard_objective_value(gm.model),
        "objective_lb" => _guard_objective_bound(gm.model),
        "objective_gap" => abs((_guard_objective_value(gm.model) - _guard_objective_bound(gm.model)) / _guard_objective_value(gm.model)) * 100,
        "solve_time" => solve_time,
        "solution" => sol,
        "machine" => Dict(
            "cpu" => Sys.cpu_info()[1].model,
            "memory" => string(Sys.total_memory()/2^30, " Gb")
            ),
        "data" => data
        )

    return solution
end


""
function _init_solution(gm::AbstractGasModel)
    data_keys = ["per_unit", "baseP", "baseQ", "multinetwork"]
    return Dict{String,Any}(key => gm.data[key] for key in data_keys)
end


"Get all the solution values"
function solution_gf!(gm::AbstractGasModel,sol::Dict{String,Any})
    add_junction_pressure_setpoint!(sol, gm)
    add_connection_flow_setpoint!(sol, gm)
    add_compressor_ratio_setpoint!(sol, gm)
end


"Get the pressure solutions"
function add_junction_pressure_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "junction", "p", :p; scale = (x,item) -> sqrt(JuMP.value(x)))
end


"Get the pressure squared solutions"
function add_junction_pressure_sqr_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "junction", "psqr", :p)
end


"Get the load mass flow solutions"
function add_load_mass_flow_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "consumer", "fl", :fl; default_value = (item) -> 0)
end


"Get the production mass flow set point"
function add_production_mass_flow_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "producer", "fg", :fg; default_value = (item) -> 0)
end


"Get the load volume solutions"
function add_load_volume_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "consumer", "ql", :fl; scale = (x,item) -> JuMP.value(x) / gm.data["standard_density"], default_value = (item) -> 0)
end


"Get the production volume set point"
function add_production_volume_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "producer", "qg", :fg; scale = (x,item) -> JuMP.value(x) / gm.data["standard_density"], default_value = (item) -> 0)
end


"Get the direction set points"
function add_direction_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "pipe", "y", :y_pipe)
    add_setpoint!(sol, gm, "compressor", "y", :y_compressor)
    add_setpoint!(sol, gm, "valve", "y", :y_valve)
    add_setpoint!(sol, gm, "control_valve", "y", :y_control_valve)
    add_setpoint!(sol, gm, "resistor", "y", :y_resistor)
    add_setpoint!(sol, gm, "short_pipe", "y", :y_short_pipe)
end


"Get the valve solutions"
function add_valve_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "valve", "v", :v_valve)
    add_setpoint!(sol, gm, "control_valve", "v", :v_control_valve)
end


"Add the flow solutions"
function add_connection_flow_setpoint!(sol, gm::AbstractGasModel)
    add_setpoint!(sol, gm, "pipe", "f", :f_pipe)
    add_setpoint!(sol, gm, "compressor", "f", :f_compressor)
    add_setpoint!(sol, gm, "control_valve", "f", :f_control_valve)
    add_setpoint!(sol, gm, "valve", "f", :f_valve)
    add_setpoint!(sol, gm, "resistor", "f", :f_resistor)
    add_setpoint!(sol, gm, "short_pipe", "f", :f_short_pipe)
end


"Add the compressor solutions"
function add_compressor_ratio_setpoint!(sol, gm::AbstractGasModel; default_value = (item) -> 1)
    add_setpoint!(sol, gm, "compressor", "ratio", :p; scale = (x,item) -> sqrt(JuMP.value(x[2])) / sqrt(JuMP.value(x[1])), extract_var = (var,idx,item) -> [var[item["f_junction"]],var[item["t_junction"]]]   )
    add_setpoint!(sol, gm, "control_valve", "ratio", :p; scale = (x,item) -> sqrt(JuMP.value(x[2])) / sqrt(JuMP.value(x[1])), extract_var = (var,idx,item) -> [var[item["f_junction"]],var[item["t_junction"]]]   )
end


""
function add_setpoint!(sol, gm::AbstractGasModel, dict_name, param_name, variable_symbol; index_name = nothing, default_value = (item) -> NaN, scale = (x,item) -> JuMP.value(x), extract_var = (var,idx,item) -> var[idx])
    sol_dict = get(sol, dict_name, Dict{String,Any}())

    if gm.data["multinetwork"]
        data_dict = haskey(gm.data["nw"]["$(gm.cnw)"], dict_name) ? gm.data["nw"]["$(gm.cnw)"][dict_name] : Dict()
    else
        data_dict = haskey(gm.data, dict_name) ? gm.data[dict_name] : Dict()
    end

    if length(data_dict) > 0
        sol[dict_name] = sol_dict
    end

    for (i,item) in data_dict
        idx = parse(Int64,i)
        if index_name != nothing
            idx = Int(item[index_name])
        end
        sol_item = sol_dict[i] = get(sol_dict, i, Dict{String,Any}())
        sol_item[param_name] = default_value(item)
        try
            variable = extract_var(var(gm, variable_symbol), idx, item)
            sol_item[param_name] = scale(variable, item)
        catch e
        end
    end
end


""
function _guard_objective_value(model)
    obj_val = NaN

    try
        obj_val = JuMP.objective_value(model)
    catch
    end

    return obj_val
end


""
function _guard_objective_bound(model)
    obj_lb = -Inf

    try
        obj_lb = JuMP.objective_bound(model)
    catch
    end

    return obj_lb
end
