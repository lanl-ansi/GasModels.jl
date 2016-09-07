# Definitions for running a feasible gas flow

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

    for (i,connection) in pm.set.connections
        constraint_flow_direction_choice(gm, connection)
    end

    for i in pm.set.pipe_indexes || pm.set.resistor_indexes
        pipe = pm.set.connections[i]
      
        constraint_on_off_pressure_drop(gm, pipe)
        constraint_on_off_pipe_flow_direction(gm,pipe)
    end

    for i in pm.set.short_pipe_indexes
        pipe = pm.set.connections[i]
      
        constraint_short_pipe_pressure_drop(gm, pipe)
        constraint_on_off_short_pipe_flow_direction(gm,pipe)      
    end
        
    for i in pm.set.compressor_indexes
        compressor = pm.set.connections[i]
        
        constraint_on_off_compressor_flow_direction(gm, compressor)
        constraint_on_off_compressor_ratios(gm, compressor)    
    end  

end

