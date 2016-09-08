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
      
    for (i,junction) in gm.set.junctions
        constraint_junction_flow_balance(gm, junction)
      
        if junction["q_max"] > 0 && junction["q_min"] > 0 
            constraint_source_flow(gm, junction)
        end
        
        if junction["q_max"] < 0 && junction["q_min"] < 0 
            constraint_sink_flow(gm, junction)
        end      
           
        if junction["q_max"] == 0 && junction["q_min"] == 0 && junction["degree"] == 2
            constraint_conserve_flow{T}(gm, junction)
        end           
    end
    
    for (i,connection) in gm.set.connections
        constraint_flow_direction_choice(gm, connection)
        constraint_parallel_flow(gm,connection)
    end

    for i in gm.set.pipe_indexes || pm.set.resistor_indexes
        pipe = gm.set.connections[i]
      
        constraint_on_off_pressure_drop(gm, pipe)
        constraint_on_off_pipe_flow_direction(gm,pipe)        
        constraint_on_off_pipe_flow_expansion(gm, pipe)
        constraint_new_pipe_weymouth(gm,pipe)
    end
    
    for i in pm.set.short_pipe_indexes
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
      
        constraint_on_off_valve_flow_direction{T}(gm, valve)
        constraint_on_off_valve_pressure_drop{T}(gm, valve)  
    end
    
    for i in gm.set.control_valve_indexes    
        valve = gm.set.connections[i]
      
        constraint_on_off_control_valve_flow_direction{T}(gm, valve)
        constraint_on_off_control_valve_pressure_drop{T}(gm, valve)  
    end
    
    exclusive = Dict{}
    for idx in gm.set.new_pipes
        pipe = gm.set.connection_lookup[idx]
        i = min(pipe["f_junction"],pipe["t_junction"])
        j = max(pipe["f_junction"],pipe["t_junction"])
    
        if exclusive[(i,j) == nothing  
            constraint_exclusive_new_pipes(gm, i, j)         
            exclusive[(i,j)] = true
        end  
           
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

# This function ensures at most one pipe in parallel is selected
function constraint_exclusive_new_pipes{T}(gm::GenericGasModel{T}, i, j)
    c = @constraint(gm.model, sum{zp[connection["index"], connection in gm.set.parallel_connections[(i,j)] && contains(gm.new_pipes(connection["index"])) } <= 1)
    return Set([c])    
end


#Weymouth equation with discrete direction variables
function constraint_new_pipe_weymouth{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    if contains(gm.sets.new_pipes, pipe_idx)  
        return constraint_weymouth(gm, pipe)
    else
        i_junction_idx = pipe["f_junction"]
        j_junction_idx = pipe["t_junction"]
  
        i = gm.data.junctions[i_junction_idx]  
        j = gm.data.junctions[j_junction_idx]  
        
        pi = getvariable(gm.model, :p)[i_junction_idx]
        pj = getvariable(gm.model, :p)[j_junction_idx]
        yp = getvariable(gm.model, :yp)[pipe_idx]
        zp = getvariable(gm.model, :zp)[pipe_idx]
        yn = getvariable(gm.model, :yn)[pipe_idx]
        f  = getvariable(gm.model, :f)[pipe_idx]
    
        max_flow = gm.data["max_flow"]

        c1 = @constraint(gm.model, pipe["resistance"]*(pi - pj) >= f^2 - (2-yp-zp)*max_flow^2)
        c2 = @constraint(gm.model, pipe["resistance"]*(pi - pj) <= f^2 + (2-yp-zp)*max_flow^2)
        c3 = @constraint(gm.model, pipe["resistance"]*(pj - pi) >= f^2 - (2-yn-zp)*max_flow^2)
        c4 = @constraint(gm.model, pipe["resistance"]*(pj - pi) <= f^2 + (2-yn-zp)*max_flow^2)
        
        return Set([c1, c2, c3, c4])
    end  
end

