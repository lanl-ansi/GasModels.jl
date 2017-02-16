
# Build a gas solution
function build_solution{T}(gm::GenericGasModel{T}, status, solve_time; objective = NaN, solution_builder = get_solution)
    if status != :Error
        objective = getobjectivevalue(gm.model)
        status = solver_status_dict(typeof(gm.model.solver), status)
    end

    solution = Dict{AbstractString,Any}(
        "solver" => string(typeof(gm.model.solver)), 
        "status" => status, 
        "objective" => objective, 
        "objective_lb" => guard_getobjbound(gm.model),
        "solve_time" => solve_time,
        "solution" => solution_builder(gm),
        "machine" => Dict(
            "cpu" => Sys.cpu_info()[1].model,
            "memory" => string(Sys.total_memory()/2^30, " Gb")
            ),
        "data" => Dict(
            "junction_count" => length(gm.data["junction"]),
            "connection_count" => length(gm.data["connection"])
            )
        )

    gm.solution = solution

    return solution
end

# Get all the solution values
function get_solution{T}(gm::GenericGasModel{T})
    sol = Dict{AbstractString,Any}()
    add_junction_pressure_sqr_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    return sol
end

# Get the pressure squared solutions
function add_junction_pressure_sqr_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "junction", "index", "p_sqr", :p_gas)
end

# Get the pressure squared solutions
function add_load_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "junction", "index", "ql", :ql_gas)
end

# Get the direction solutions
function add_direction_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "connection", "index", "yp", :yp)
    add_setpoint(sol, gm, "connection", "index", "yn", :yn)    
end

# Get the valve solutions
function add_valve_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "connection", "index", "valve", :valve)
end

# Add the flow solutions
function add_connection_flow_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "connection", "index", "f", :f)  
end


function add_setpoint{T}(sol, gm::GenericGasModel{T}, dict_name, index_name, param_name, variable_symbol; default_value = (item) -> NaN, scale = (x,item) -> x, extract_var = (var,idx,item) -> var[idx])
    sol_dict = nothing
    if !haskey(sol, dict_name)
        sol_dict = Dict{Int,Any}()
        sol[dict_name] = sol_dict
    else
        sol_dict = sol[dict_name]
    end

    for item in gm.data[dict_name]
        idx = Int(item[index_name])

        sol_item = nothing
        if !haskey(sol_dict, idx)
            sol_item = Dict{AbstractString,Any}()
            sol_dict[idx] = sol_item
        else
            sol_item = sol_dict[idx]
        end
        sol_item[param_name] = default_value(item)

        try
            var = extract_var(getvariable(gm.model, variable_symbol), idx, item)
            sol_item[param_name] = scale(getvalue(var), item)
        catch
        end
    end
end



# TODO figure out how to do this properly, stronger types?
#importall MathProgBase.SolverInterface
solver_status_lookup = Dict{Any, Dict{Symbol, Symbol}}()

if (Pkg.installed("Ipopt") != nothing)
    using Ipopt
    solver_status_lookup[Ipopt.IpoptSolver] = Dict(:Optimal => :LocalOptimal, :Infeasible => :LocalInfeasible)
end

if (Pkg.installed("ConicNonlinearBridge") != nothing)
    using ConicNonlinearBridge
    solver_status_lookup[ConicNonlinearBridge.ConicNLPWrapper] = Dict(:Optimal => :LocalOptimal, :Infeasible => :LocalInfeasible)
end

if (Pkg.installed("AmplNLWriter") != nothing && Pkg.installed("CoinOptServices") != nothing)
    # note that AmplNLWriter.AmplNLSolver is the solver type of bonmin
    using AmplNLWriter
    using CoinOptServices
    solver_status_lookup[AmplNLWriter.AmplNLSolver] = Dict(:Optimal => :LocalOptimal, :Infeasible => :LocalInfeasible)
end

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



