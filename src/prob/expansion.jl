# Definitions for running a pipe expansion problem

export run_expansion

# entry point into running the gas flow feasability problem
function run_expansion(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_expansion; kwargs...) 
end

# construct the gas flow feasbility problem 
function post_expansion{T}(gm::GenericGasModel{T})
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_connection_direction(gm)
    variable_flux_square(gm)
    variable_valve_operation(gm)

    # expansion variables
    variable_pipe_expansion(gm)
    variable_compressor_expansion(gm)

    # expansion cost objective
    objective_min_expansion_cost(gm)
      
    
    for (i,connection) in pm.set.connections
        constraint_flow_direction_choice(gm, connection)
    end

    for i in pm.set.pipe_indexes || pm.set.resistor_indexes
        pipe = pm.set.connections[i]
      
        constraint_on_off_pressure_drop(gm, pipe)
        constraint_on_off_pipe_flow_direction(gm,pipe)        
        constraint_on_off_pipe_flow_expansion
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


# on/off constraints on flow across pipes for expansion variables
function constraint_on_off_pipe_flow_expansion{T}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    zp = getvariable(gm.model, :zp)[pipe_idx]
    f = getvariable(gm.model, :f)[pipe_idx]
  
    c = @constraint(gm.model, -(1-zp)*min(gm.data["max_flow"], sqrt(pipe["resistance"]*max(pipe["pd_max"], abs(pipe["pd_min"])))) <= f <= (1-zp)*min(gm.data["max_flow"], sqrt(pipe["resistance"]*max(pipe["pd_max"], abs(pipe["pd_min"])))
    return Set([c])    
end


