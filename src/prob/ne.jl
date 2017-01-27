# Definitions for running a pipe expansion problem

export run_ne

# entry point into running the gas flow feasability problem
function run_ne(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_ne; solution_builder = get_ne_solution, kwargs...) 
end

# construct the gas flow feasbility problem 
function post_ne{T}(gm::GenericGasModel{T})
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_flux_ne(gm)  
    variable_connection_direction(gm) 
    variable_connection_direction_ne(gm)     
    variable_flux_square(gm) 
    variable_flux_square_ne(gm) 
    
    variable_valve_operation(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    # expansion cost objective
    objective_min_ne_cost(gm)

    for (i,junction) in gm.set.junctions
        constraint_junction_flow_balance_ne(gm, junction) 
        if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0
            constraint_source_flow_ne(gm, junction) 
        end
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
            constraint_sink_flow_ne(gm, junction)
        end              
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree_all"] == 2
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
        constraint_on_off_valve_flow_direction(gm, valve)
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


# on/off constraints on flow across pipes for expansion variables
function constraint_on_off_pipe_flow_ne{T}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    zp = getvariable(gm.model, :zp)[pipe_idx]
    f = getvariable(gm.model, :f_ne)[pipe_idx]
    
    max_flow = gm.data["max_flow"]
    pd_max = pipe["pd_max"]  
    pd_min = pipe["pd_min"]  
    w = pipe["resistance"]
          
    c1 = @constraint(gm.model, f <= zp*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))
    c2 = @constraint(gm.model, f >= -zp*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))            
    return Set([c1, c2])    
end


# on/off constraints on flow across compressors for expansion variables
function constraint_on_off_compressor_flow_ne{T}(gm::GenericGasModel{T}, compressor)
    c_idx = compressor["index"]
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    zc = getvariable(gm.model, :zc)[c_idx]
    f = getvariable(gm.model, :f)[c_idx]
    
    max_flow = gm.data["max_flow"]
          
    c1 = @constraint(gm.model, -max_flow*zc <= f)
    c2 = @constraint(gm.model, f <= max_flow*zc)            
    return Set([c1, c2])    
end


# This function ensures at most one pipe in parallel is selected
function constraint_exclusive_new_pipes{T}(gm::GenericGasModel{T}, i, j)  
    parallel = collect(filter( connection -> in(connection, gm.set.new_pipe_indexes), gm.set.all_parallel_connections[(i,j)] ))
    zp = getvariable(gm.model, :zp)            
    c = @constraint(gm.model, sum(zp[i] for i in parallel) <= 1)
    return Set([c])    
end

#Weymouth equation with discrete direction variables for MINLP
function constraint_weymouth_ne{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.set.junctions[i_junction_idx]  
    j = gm.set.junctions[j_junction_idx]  
        
    pi = getvariable(gm.model, :p_gas)[i_junction_idx]
    pj = getvariable(gm.model, :p_gas)[j_junction_idx]
    yp = getvariable(gm.model, :yp_ne)[pipe_idx]
    zp = getvariable(gm.model, :zp)[pipe_idx]
    yn = getvariable(gm.model, :yn_ne)[pipe_idx]
    f  = getvariable(gm.model, :f_ne)[pipe_idx]
        
    max_flow = gm.data["max_flow"]
    w = pipe["resistance"]
          
    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*max_flow^2)
               
    return Set([c1, c2, c3, c4])
end

#Weymouth equation with discrete direction variables for MINLP
function constraint_weymouth_ne{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.set.junctions[i_junction_idx]  
    j = gm.set.junctions[j_junction_idx]  
        
    pi = getvariable(gm.model, :p_gas)[i_junction_idx]
    pj = getvariable(gm.model, :p_gas)[j_junction_idx]
    yp = getvariable(gm.model, :yp_ne)[pipe_idx]
    yn = getvariable(gm.model, :yn_ne)[pipe_idx]
    zp = getvariable(gm.model, :zp)[pipe_idx]       
    l  = getvariable(gm.model, :l_ne)[pipe_idx]
    f  = getvariable(gm.model, :f_ne)[pipe_idx]
    
    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]     
    max_flow = gm.data["max_flow"]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, zp*pipe["resistance"]*l >= f^2) 
    return Set([c1, c2, c3, c4, c5])  
end

# Special function for whether or not a connection is added
function add_connection_ne{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "new_connection", "index", "built", :zp; default_value = (item) -> 1)
end

#compressor rations have on off for direction and expansion
function constraint_new_compressor_ratios_ne{T}(gm::GenericGasModel{T}, compressor)
    c_idx = compressor["index"]  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
      
    i = gm.set.junctions[i_junction_idx]  
    j = gm.set.junctions[j_junction_idx]  

    pi = getvariable(gm.model, :p_gas)[i_junction_idx]
    pj = getvariable(gm.model, :p_gas)[j_junction_idx]
    yp = getvariable(gm.model, :yp_ne)[c_idx]
    yn = getvariable(gm.model, :yn_ne)[c_idx]
    zc = getvariable(gm.model, :zc)[c_idx]
            
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    p_maxj = j["pmax"]
    p_maxi = i["pmax"]
    p_minj = j["pmin"]
    p_mini = i["pmin"]
                     
    c1 = @constraint(gm.model, pj - (max_ratio^2*pi) <= (2-yp-zc)*p_maxj^2)
    c2 = @constraint(gm.model, (min_ratio^2*pi) - pj <= (2-yp-zc)*(min_ratio^2*p_maxi^2 - p_minj^2))
    c3 = @constraint(gm.model, pi - (max_ratio^2*pj) <= (2-yn-zc)*p_maxi^2)
    c4 = @constraint(gm.model, (min_ratio^2*pj) - pi <= (2-yn-zc)*(min_ratio^2*p_maxj^2 - p_mini^2))
      
    return Set([c1, c2, c3, c4])  
end

# Get all the solution values
function get_ne_solution{T}(gm::GenericGasModel{T})
    sol = Dict{AbstractString,Any}()
    add_junction_pressure_sqr_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    add_connection_ne(sol, gm)
    return sol
end
