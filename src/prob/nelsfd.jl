# Definitions for running a pipe expansion problem to maximize load when the directions of
# of the pipes is fixed.

export run_nelsfd

# entry point into running the gas flow feasability problem
function run_nelsfd(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_nelsfd; solution_builder = get_ne_solution, kwargs...) 
end

# construct the gas flow expansion problem to maximize load
function post_nelsfd{T}(gm::GenericGasModel{T})
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_flux_ne(gm)  
    variable_flux_square(gm) 
    variable_flux_square_ne(gm)         
    variable_valve_operation(gm)
    variable_load(gm)
    variable_production(gm)
    
    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    # expansion cost objective
    objective_max_load(gm)

    for (i,junction) in gm.set.junctions
        constraint_junction_flow_balance_ne_ls(gm, junction) 
    end

    for i in [gm.set.pipe_indexes; gm.set.resistor_indexes]
        pipe = gm.set.connections[i]      
        constraint_on_off_pressure_drop_fixed_direction(gm, pipe) 
        constraint_on_off_pipe_flow_direction_fixed_direction(gm,pipe) 
        constraint_weymouth_fixed_direction(gm,pipe)
    end

    for i in gm.set.new_pipe_indexes
        pipe = gm.set.new_connections[i]      
        constraint_on_off_pressure_drop_ne_fixed_direction(gm, pipe) 
        constraint_on_off_pipe_flow_direction_ne_fixed_direction(gm,pipe) 
        constraint_on_off_pipe_flow_ne(gm, pipe) 
        constraint_weymouth_ne_fixed_direction(gm,pipe) 
    end
    
    for i in gm.set.short_pipe_indexes
        pipe = gm.set.connections[i]      
        constraint_short_pipe_pressure_drop(gm, pipe)
        constraint_on_off_short_pipe_flow_direction_fixed_direction(gm,pipe)      
    end
    
    # We assume that we already have a short pipe connecting two nodes 
    # and we just want to add a compressor to it.  Use constraint 
    # constraint_on_off_compressor_flow_expansion to disallow flow
    # if the compressor is not built 
    for i in gm.set.compressor_indexes
        compressor = gm.set.connections[i]        
        constraint_on_off_compressor_flow_direction_fixed_direction(gm, compressor) 
        constraint_on_off_compressor_ratios_fixed_direction(gm, compressor)         
    end
    for i in gm.set.new_compressor_indexes
        compressor = gm.set.new_connections[i]        
        constraint_on_off_compressor_flow_direction_ne_fixed_direction(gm, compressor) 
        constraint_on_off_compressor_ratios_ne_fixed_direction(gm, compressor) 
    end  
          
    for i in gm.set.valve_indexes    
        valve = gm.set.connections[i]      
        constraint_on_off_valve_flow_direction_fixed_direction(gm, valve)
        constraint_on_off_valve_pressure_drop(gm, valve)  
    end
    
    for i in gm.set.control_valve_indexes    
        valve = gm.set.connections[i]      
        constraint_on_off_control_valve_flow_direction_fixed_direction(gm, valve)
        constraint_on_off_control_valve_pressure_drop_fixed_direction(gm, valve)  
    end
    
    exclusive = Dict()
    for idx in gm.set.new_pipe_indexes
        pipe = gm.set.new_connections[idx]
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


