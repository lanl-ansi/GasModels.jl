# Definitions for running a pipe expansion problem to maximize load

export run_nels

" entry point into running the gas flow feasability problem "
function run_nels(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_nels; solution_builder = get_nels_solution, kwargs...) 
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
        constraint_junction_mass_flow_ne_ls(gm, i) 
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
    for i in ids(gm,:compressor)       
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
