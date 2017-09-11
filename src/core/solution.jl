
"Build a gas solution"
function build_solution{T}(gm::GenericGasModel{T}, status, solve_time; objective = NaN, solution_builder = get_solution)
    if status != :Error
        objective = getobjectivevalue(gm.model)
        status = solver_status_dict(Symbol(typeof(gm.model.solver).name.module), status)
    end

    sol = solution_builder(gm)
    
    solution = Dict{AbstractString,Any}(
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
        "data" => Dict(
            "junction_count" => length(gm.ref[:junction]),
            "connection_count" => length(gm.ref[:connection])
            )
        )

    gm.solution = solution

    return solution
end

""
function init_solution(gm::GenericGasModel)
    return Dict{String,Any}()
end

" Get all the solution values "
function get_solution{T}(gm::GenericGasModel{T})
    sol = init_solution(gm)
    add_junction_pressure_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    return sol
end

" Get the pressure squared solutions "
function add_junction_pressure_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "junction", "p", :p; scale = (x,item) -> sqrt(x))
end

" Get the pressure squared solutions "
function add_load_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "junction", "ql", :ql; default_value = (item) -> 0)
end

" Get the production set point " 
function add_production_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "junction", "qg", :qg; default_value = (item) -> 0)
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


function add_setpoint{T}(sol, gm::GenericGasModel{T}, dict_name, param_name, variable_symbol; index_name = nothing, default_value = (item) -> NaN, scale = (x,item) -> x, extract_var = (var,idx,item) -> var[idx])
    sol_dict = get(sol, dict_name, Dict{String,Any}())
    if length(gm.data[dict_name]) > 0
        sol[dict_name] = sol_dict
    end
    
    for (i,item) in gm.data[dict_name]
        idx = parse(Int64,i)        
        if index_name != nothing
            idx = Int(item[index_name])
        end
        sol_item = sol_dict[i] = get(sol_dict, i, Dict{String,Any}())
        sol_item[param_name] = default_value(item)
        try
            var = extract_var(gm.var[variable_symbol], idx, item)
            sol_item[param_name] = scale(getvalue(var), item)
        catch
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



