# Definitions for running a pipe expansion problem

export run_ne

" entry point into running the gas flow feasability problem "
function run_ne(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_ne; solution_builder = get_ne_solution, kwargs...) 
end

" construct the gas flow feasbility problem "
function post_ne(gm::GenericGasModel; kwargs...)
    kwargs = Dict(kwargs)
    obj_normalization = haskey(kwargs, :obj_normalization) ? kwargs[:obj_normalization] : 1.0
      
    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_flow_ne(gm)
    
    variable_valve_operation(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    # expansion cost objective
    objective_min_ne_cost(gm; normalization =  obj_normalization)

    for i in ids(gm, :junction)
        constraint_junction_mass_flow_ne(gm, i) 
    end

    for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] 
        constraint_pipe_flow_ne(gm, i)
    end

    for i in ids(gm,:ne_pipe) 
        constraint_new_pipe_flow_ne(gm, i)
    end
    
    for i in ids(gm, :short_pipe) 
        constraint_short_pipe_flow_ne(gm, i)
    end
    
    # We assume that we already have a short pipe connecting two nodes 
    # and we just want to add a compressor to it.  Use constraint 
    # constraint_on_off_compressor_flow_expansion to disallow flow
    # if the compressor is not built 
    for i in ids(gm, :compressor)
        constraint_compressor_flow_ne(gm, i)
    end
    
    for i in ids(gm, :ne_compressor)
        constraint_new_compressor_flow_ne(gm, i)
    end  
         
    for i in ids(gm, :valve)  
        constraint_valve_flow(gm, i)       
    end
    
    for i in ids(gm, :control_valve)
        constraint_control_valve_flow(gm, i)       
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
    
    zp = gm.var[:nw][gm.cnw][:zp]
    zc = gm.var[:nw][gm.cnw][:zc]
end

# Special function for whether or not a connection is added
function add_connection_ne(sol, gm::GenericGasModel)
    add_setpoint(sol, gm, "ne_connection", "built_zp", :zp; default_value = (item) -> NaN)
    add_setpoint(sol, gm, "ne_connection", "built_zc", :zc; default_value = (item) -> NaN)
end

# Get the direction solutions
function add_direction_ne_setpoint(sol, gm::GenericGasModel)
    add_setpoint(sol, gm, "ne_connection", "yp", :yp_ne)
    add_setpoint(sol, gm, "ne_connection", "yn", :yn_ne)
end

" Add the compressor solutions "
function add_compressor_ratio_ne_setpoint(sol, gm::GenericGasModel)
    add_setpoint(sol, gm, "ne_connection", "ratio", :p; scale = (x,item) -> (item["type"] == "compressor" || item["type"] == "control_valve") ? sqrt(getvalue(x[2])) / sqrt(getvalue(x[1])) : NaN, extract_var = (var,idx,item) -> [var[item["f_junction"]],var[item["t_junction"]]]   )
end

" Add the flow solutions to new lines"
function add_connection_flow_ne_setpoint(sol, gm::GenericGasModel)
    add_setpoint(sol, gm, "ne_connection", "f", :f_ne)
end

# Get all the solution values
function get_ne_solution(gm::GenericGasModel, sol::Dict{String,Any})
    add_junction_pressure_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    add_connection_flow_ne_setpoint(sol, gm)
    add_direction_setpoint(sol, gm)
    add_direction_ne_setpoint(sol, gm)
    add_compressor_ratio_setpoint(sol, gm)
    add_compressor_ratio_ne_setpoint(sol, gm)
    add_connection_ne(sol, gm)
end
