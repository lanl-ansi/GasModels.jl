# Definitions for running a feasible gas flow

# Note that this particular formulation assumes the binary variable implementation of flow direction
# We would need to do some abstraction to support the absolute value formulation

export run_gf

# entry point into running the gas flow feasability problem
function run_gf(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gf; kwargs...) 
end

# construct the gas flow feasbility problem 
function post_gf{T}(gm::GenericGasModel{T})
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_connection_direction(gm)
    variable_flux_square(gm)
    variable_valve_operation(gm)

    for (i,junction) in gm.set.junctions
        constraint_junction_flow_balance(gm, junction)
      
        if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0 
            constraint_source_flow(gm, junction)
        end      
        
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
            constraint_sink_flow(gm, junction)
        end      
                
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree"] == 2
           constraint_conserve_flow(gm, junction)
        end
        
    end
    
    for (i,connection) in gm.set.connections
        constraint_flow_direction_choice(gm, connection)
        constraint_parallel_flow(gm,connection)
    end
    
    for i in [gm.set.pipe_indexes; gm.set.resistor_indexes]
        pipe = gm.set.connections[i]      
        constraint_on_off_pressure_drop(gm, pipe)
        constraint_on_off_pipe_flow_direction(gm,pipe)
        constraint_weymouth(gm,pipe)        
    end

    for i in gm.set.short_pipe_indexes
        pipe = gm.set.connections[i]
        constraint_short_pipe_pressure_drop(gm, pipe)
        constraint_on_off_short_pipe_flow_direction(gm,pipe)      
    end
        
    for i in gm.set.compressor_indexes
        compressor = gm.set.connections[i]        
        constraint_on_off_compressor_flow_direction(gm, compressor)
        constraint_on_off_compressor_ratios(gm, compressor)    
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
    
end

