
"Build a gas solution"
function build_solution{T}(gm::GenericGasModel{T}, status, solve_time; objective = NaN, solution_builder = get_solution)
    if status != :Error
        objective = getobjectivevalue(gm.model)
        status = solver_status_dict(Symbol(typeof(gm.model.solver).name.module), status)
    end

    sol = init_solution(gm)
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
                "connection_count" => length(nw_data["connection"])
            )
        end
    else
        solution_builder(gm, sol)
        data["junction_count"] = length(gm.data["junction"])
        data["connection_count"] = length(gm.data["connection"])
    end
          
    solution = Dict{String,Any}(
        "solver" => string(typeof(gm.model.solver)), 
        "status" => status, 
        "objective" => objective, 
        "objective_lb" => guard_getobjbound(gm.model),
        "solve_time" => solve_time,
        "solution" => sol,
        "machine" => Dict(
            "cpu" => Sys.cpu_info()[1].model,
            "memory" => string(Sys.total_memory()/2^30, " Gb")
            ),
        "data" => data
        )

    gm.solution = solution

    return solution
end

""
function init_solution(gm::GenericGasModel)
    data_keys = ["per_unit", "baseP", "baseQ", "multinetwork"]
    return Dict{String,Any}(key => gm.data[key] for key in data_keys)
end

" Get all the solution values "
function get_solution{T}(gm::GenericGasModel{T},sol::Dict{String,Any})
    add_junction_pressure_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    add_compressor_ratio_setpoint(sol, gm) 
end

" Get the pressure solutions "
function add_junction_pressure_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "junction", "p", :p; scale = (x,item) -> sqrt(getvalue(x)))
end

" Get the pressure squared solutions "
function add_junction_pressure_sqr_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "junction", "psqr", :p)
end

" Get the load flux solutions "
function add_load_flux_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "consumer", "fl", :fl; default_value = (item) -> 0)
end

" Get the production flux set point " 
function add_production_flux_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "producer", "fg", :fg; default_value = (item) -> 0)
end

" Get the load volume solutions "
function add_load_volume_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "consumer", "ql", :fl; scale = (x,item) -> getvalue(x) / gm.data["standard_density"], default_value = (item) -> 0)
end

" Get the production flux set point " 
function add_production_volume_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "producer", "qg", :fg; scale = (x,item) -> getvalue(x) / gm.data["standard_density"], default_value = (item) -> 0)
end

" Get the direction set points"
function add_direction_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "connection", "yp", :yp)
    add_setpoint(sol, gm, "connection", "yn", :yn)    
end

" Get the valve solutions "
function add_valve_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "connection", "valve", :v)
end

" Add the flow solutions "
function add_connection_flow_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "connection", "f", :f)  
end

" Add the compressor solutions "
function add_compressor_ratio_setpoint{T}(sol, gm::GenericGasModel{T}; default_value = (item) -> 1)
    add_setpoint(sol, gm, "connection", "ratio", :p; scale = (x,item) -> (item["type"] == "compressor" || item["type"] == "control_valve") ? sqrt(getvalue(x[2])) / sqrt(getvalue(x[1])) : 1.0, extract_var = (var,idx,item) -> [var[item["f_junction"]],var[item["t_junction"]]]   )
end

function add_setpoint{T}(sol, gm::GenericGasModel{T}, dict_name, param_name, variable_symbol; index_name = nothing, default_value = (item) -> NaN, scale = (x,item) -> getvalue(x), extract_var = (var,idx,item) -> var[idx])
    sol_dict = get(sol, dict_name, Dict{String,Any}())
      
    if gm.data["multinetwork"]
        data_dict = gm.data["nw"]["$(gm.cnw)"][dict_name]
    else
        data_dict = gm.data[dict_name]
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

solver_status_lookup = Dict{Any, Dict{Symbol, Symbol}}(
    :Ipopt => Dict(:Optimal => :LocalOptimal, :Infeasible => :LocalInfeasible),
    :ConicNonlinearBridge => Dict(:Optimal => :LocalOptimal, :Infeasible => :LocalInfeasible),
    # note that AmplNLWriter.AmplNLSolver is the solver type of bonmin
    :AmplNLWriter => Dict(:Optimal => :LocalOptimal, :Infeasible => :LocalInfeasible)
)

# translates solver status codes to our status codes
function solver_status_dict(solver_type, status)
    for (st, solver_stat_dict) in solver_status_lookup
        if solver_type == st
            if status in keys(solver_stat_dict)
                return solver_stat_dict[status]
            else
                return status
            end
        end
    end
    return status
end

function guard_getobjbound(model)
    try
        getobjbound(model)
    catch
        -Inf
    end
end



