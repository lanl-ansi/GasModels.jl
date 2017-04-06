# Definitions for running a pipe expansion problem to maximize load

export run_nels

# entry point into running the gas flow feasability problem
function run_nels(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_nels; solution_builder = get_ne_solution, kwargs...) 
end

# construct the gas flow expansion problem to maximize load
function post_nels{T}(gm::GenericGasModel{T})
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_flux_ne(gm)  
    variable_connection_direction(gm) 
    variable_connection_direction_ne(gm)     
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
        if max(junction["qgmin"],junction["qgfirm"]) > 0.0  && junction["qlmin"] == 0.0 && junction["qlmax"] == 0.0 && junction["qlfirm"] == 0.0 && junction["qgmin"] >= 0.0
            constraint_source_flow_ne(gm, junction) 
        end
        if junction["qgmax"] == 0.0 && junction["qgmin"] == 0.0 && junction["qgfirm"] == 0.0 && max(junction["qlmin"],junction["qlfirm"]) > 0.0 && junction["qlmin"] >= 0.0
            constraint_sink_flow_ne(gm, junction)
        end              
        if junction["qgmax"] == 0 && junction["qgmin"] == 0 && junction["qgfirm"] == 0 && junction["qlmax"] == 0 && junction["qlmin"] == 0 && junction["qlfirm"] == 0 && junction["degree_all"] == 2
           constraint_conserve_flow_ne(gm, junction)
        end            
    end

    for (i,connection) in gm.set.connections
        constraint_flow_direction_choice(gm, connection) 
        constraint_parallel_flow_ne(gm,connection)  
    end
    
    for (i,connection) in gm.set.new_connections
        constraint_flow_direction_choice_ne(gm, connection) 
        constraint_parallel_flow_ne(gm,connection)  
    end

    for i in [gm.set.pipe_indexes; gm.set.resistor_indexes]
        pipe = gm.set.connections[i]      
        constraint_on_off_pressure_drop(gm, pipe) 
        constraint_on_off_pipe_flow_direction(gm,pipe) 
        constraint_weymouth(gm,pipe)
    end

    for i in gm.set.new_pipe_indexes
        pipe = gm.set.new_connections[i]      
        constraint_on_off_pressure_drop_ne(gm, pipe) 
        constraint_on_off_pipe_flow_direction_ne(gm,pipe) 
        constraint_on_off_pipe_flow_ne(gm, pipe) 
        constraint_weymouth_ne(gm,pipe) 
    end
    
    for i in gm.set.short_pipe_indexes
        pipe = gm.set.connections[i]      
        constraint_short_pipe_pressure_drop(gm, pipe)
        constraint_on_off_short_pipe_flow_direction(gm,pipe)      
    end
    
    # We assume that we already have a short pipe connecting two nodes 
    # and we just want to add a compressor to it.  Use constraint 
    # constraint_on_off_compressor_flow_expansion to disallow flow
    # if the compressor is not built 
    for i in gm.set.compressor_indexes
        compressor = gm.set.connections[i]        
        constraint_on_off_compressor_flow_direction(gm, compressor) 
        constraint_on_off_compressor_ratios(gm, compressor)         
    end
    for i in gm.set.new_compressor_indexes
        compressor = gm.set.new_connections[i]        
        constraint_on_off_compressor_flow_direction_ne(gm, compressor) 
        constraint_on_off_compressor_ratios_ne(gm, compressor) 
    end  
      
    
    for i in gm.set.valve_indexes    
        valve = gm.set.connections[i]      
        constraint_on_off_valve_flow_direction(gm, valve)
        constraint_on_off_valve_pressure_drop(gm, valve)  
    end
    
    for i in gm.set.control_valve_indexes    
        valve = gm.set.connections[i]      
        constraint_on_off_control_valve_flow_direction(gm, valve)
        constraint_on_off_control_valve_pressure_drop(gm, valve)  
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


