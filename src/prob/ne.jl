# Definitions for running a pipe expansion problem

export run_ne

" entry point into running the gas flow feasability problem "
function run_ne(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_ne; solution_builder = get_ne_solution, kwargs...) 
end

" construct the gas flow feasbility problem "
function post_ne(gm::GenericGasModel)
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_flux_ne(gm)  
    variable_connection_direction(gm) 
    variable_connection_direction_ne(gm)     
    
    variable_valve_operation(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    # expansion cost objective
    objective_min_ne_cost(gm)

    for (i,junction) in gm.ref[:junction]
        constraint_junction_flow_balance_ne(gm, i) 
        if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0
            constraint_source_flow_ne(gm, i) 
        end
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
            constraint_sink_flow_ne(gm, i)
        end              
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree_all"] == 2
           constraint_conserve_flow_ne(gm, i)
        end            
    end

    for (i,connection) in gm.ref[:connection]
        constraint_flow_direction_choice(gm, i) 
        constraint_parallel_flow_ne(gm, i)  
    end
    
    for (i,connection) in gm.ref[:ne_connection]
        constraint_flow_direction_choice_ne(gm, i) 
        constraint_parallel_flow_ne(gm, i)  
    end

    for i in [collect(keys(gm.ref[:pipe])); collect(keys(gm.ref[:resistor]))]
        constraint_on_off_pressure_drop(gm, i) 
        constraint_on_off_pipe_flow_direction(gm, i) 
        constraint_weymouth(gm, i)
    end

    for (i, pipe) in gm.ref[:ne_pipe]
        constraint_on_off_pressure_drop_ne(gm, i) 
        constraint_on_off_pipe_flow_direction_ne(gm, i) 
        constraint_on_off_pipe_flow_ne(gm, i) 
        constraint_weymouth_ne(gm, i) 
    end
    
    for (i, pipe) in gm.ref[:short_pipe]
        constraint_short_pipe_pressure_drop(gm, i)
        constraint_on_off_short_pipe_flow_direction(gm, i)      
    end
    
    # We assume that we already have a short pipe connecting two nodes 
    # and we just want to add a compressor to it.  Use constraint 
    # constraint_on_off_compressor_flow_expansion to disallow flow
    # if the compressor is not built 
    for (i, compressor) in gm.ref[:compressor]
        constraint_on_off_compressor_flow_direction(gm, i) 
        constraint_on_off_compressor_ratios(gm, i)         
    end
    for (i,compressor) in gm.ref[:ne_compressor]
        constraint_on_off_compressor_flow_direction_ne(gm, i) 
        constraint_on_off_compressor_ratios_ne(gm, i) 
    end  
         
    for (i, valve) in gm.ref[:valve]    
        constraint_on_off_valve_flow_direction(gm, i)
        constraint_on_off_valve_pressure_drop(gm, i)  
    end
    
    for (i, valve) in gm.ref[:control_valve]    
        constraint_on_off_control_valve_flow_direction(gm, i)
        constraint_on_off_control_valve_pressure_drop(gm, i)  
    end
    
    exclusive = Dict()
    for (idx, pipe) in gm.ref[:ne_pipe]
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

" on/off constraints on flow across pipes for expansion variables "
function constraint_on_off_pipe_flow_ne{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
      
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    zp = gm.var[:zp][pipe_idx] 
    f  = gm.var[:f_ne][pipe_idx] 
    
    max_flow = gm.ref[:max_flow]
    pd_max = pipe["pd_max"]  
    pd_min = pipe["pd_min"]  
    w = pipe["resistance"]
          
    c1 = @constraint(gm.model, f <= zp*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))
    c2 = @constraint(gm.model, f >= -zp*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))            
    if !haskey(gm.constraint, :on_off_pipe_flow_ne1)
        gm.constraint[:on_off_pipe_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pipe_flow_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pipe_flow_ne1][pipe_idx] = c1              
    gm.constraint[:on_off_pipe_flow_ne2][pipe_idx] = c2              
end

" on/off constraints on flow across compressors for expansion variables "
function constraint_on_off_compressor_flow_ne{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:ne_connection][c_idx]
            
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    zc = gm.var[:zc][c_idx] 
    f = gm.var[:f][c_idx] 
    
    max_flow = gm.ref[:max_flow]
          
    c1 = @constraint(gm.model, -max_flow*zc <= f)
    c2 = @constraint(gm.model, f <= max_flow*zc)            
    if !haskey(gm.constraint, :on_off_compressor_flow_ne1)
        gm.constraint[:on_off_compressor_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_flow_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_flow_ne1][c_idx] = c1              
    gm.constraint[:on_off_compressor_flow_ne2][c_idx] = c2              
end

" This function ensures at most one pipe in parallel is selected "
function constraint_exclusive_new_pipes{T}(gm::GenericGasModel{T}, i, j)  
    parallel = collect(filter( connection -> in(connection, collect(keys(gm.ref[:ne_pipe]))), gm.ref[:all_parallel_connections][(i,j)] ))
    zp = gm.var[:zp]             
    c = @constraint(gm.model, sum(zp[i] for i in parallel) <= 1)
    if !haskey(gm.constraint, :exclusive_new_pipes)
        gm.constraint[:exclusive_new_pipes] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:exclusive_new_pipes][(i,j)] = c              
end

" Weymouth equation with discrete direction variables for MINLP "
function constraint_weymouth_ne{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
            
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp_ne][pipe_idx] 
    zp = gm.var[:zp][pipe_idx] 
    yn = gm.var[:yn_ne][pipe_idx] 
    f  = gm.var[:f_ne][pipe_idx] 
        
    max_flow = gm.ref[:max_flow]
    w = pipe["resistance"]
          
    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*max_flow^2)
               
    if !haskey(gm.constraint, :weymouth_ne1)
        gm.constraint[:weymouth_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth_ne3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:weymouth_ne1][pipe_idx] = c1              
    gm.constraint[:weymouth_ne2][pipe_idx] = c2
    gm.constraint[:weymouth_ne3][pipe_idx] = c3              
    gm.constraint[:weymouth_ne4][pipe_idx] = c4                               
end

"Weymouth equation with fixed directions for MINLP"
function constraint_weymouth_ne_fixed_direction{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
            
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = pipe["yp"]
    zp = gm.var[:zp][pipe_idx] 
    yn = pipe["yn"]
    f  = gm.var[:f_ne][pipe_idx] 
        
    max_flow = gm.ref[:max_flow]
    w = pipe["resistance"]
          
    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*max_flow^2)
               
    if !haskey(gm.constraint, :weymouth_ne_fixed_direction1)
        gm.constraint[:weymouth_ne_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth_ne_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne_fixed_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:weymouth_ne_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:weymouth_ne_fixed_direction2][pipe_idx] = c2
    gm.constraint[:weymouth_ne_fixed_direction3][pipe_idx] = c3              
    gm.constraint[:weymouth_ne_fixed_direction4][pipe_idx] = c4                               
end

"Weymouth equation with discrete direction variables for MINLP"
function constraint_weymouth_ne{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx] 
      
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp_ne][pipe_idx] 
    yn = gm.var[:yn_ne][pipe_idx] 
    zp = gm.var[:zp][pipe_idx]        
    l  = gm.var[:l_ne][pipe_idx] 
    f  = gm.var[:f_ne][pipe_idx] 
    
    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]     
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, zp*pipe["resistance"]*l >= f^2) 

    if !haskey(gm.constraint, :weymouth_ne1)
        gm.constraint[:weymouth_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth_ne3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne4] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.constraint[:weymouth_ne1][pipe_idx] = c1              
    gm.constraint[:weymouth_ne2][pipe_idx] = c2
    gm.constraint[:weymouth_ne3][pipe_idx] = c3              
    gm.constraint[:weymouth_ne4][pipe_idx] = c4                              
    gm.constraint[:weymouth_ne5][pipe_idx] = c5                                    
end

"Weymouth equation with fixed direction"
function constraint_weymouth_ne_fixed_direction{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
      
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = pipe["yp"]
    yn = pipe["yn"]
    zp = gm.var[:zp][pipe_idx]        
    l  = gm.var[:l_ne][pipe_idx] 
    f  = gm.var[:f_ne][pipe_idx] 
    
    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]     
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, zp*pipe["resistance"]*l >= f^2) 

    if !haskey(gm.constraint, :weymouth_ne_fixed_direction1)
        gm.constraint[:weymouth_ne_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth_ne_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne_fixed_direction4] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_ne_fixed_direction5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.constraint[:weymouth_ne_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:weymouth_ne_fixed_direction2][pipe_idx] = c2
    gm.constraint[:weymouth_ne_fixed_direction3][pipe_idx] = c3              
    gm.constraint[:weymouth_ne_fixed_direction4][pipe_idx] = c4                              
    gm.constraint[:weymouth_ne_fixed_direction5][pipe_idx] = c5                                    
end

# Special function for whether or not a connection is added
function add_connection_ne{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "ne_connection", "built", :zp; default_value = (item) -> 1)
end

# Get the direction solutions
function add_direction_ne_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "ne_connection", "yp", :yp_ne)
    add_setpoint(sol, gm, "ne_connection", "yn", :yn_ne)    
end

#compressor rations have on off for direction and expansion
function constraint_new_compressor_ratios_ne{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:ne_connection][c_idx]
      
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
      
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  

    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp][c_idx] 
    yn = gm.var[:yn][c_idx] 
    zc = gm.var[:zc][c_idx] 
            
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
      
    if !haskey(gm.constraint, :new_compressor_ratios_ne1)
        gm.constraint[:new_compressor_ratios_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:new_compressor_ratios_ne2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:new_compressor_ratios_ne3] = Dict{Int,ConstraintRef}()
        gm.constraint[:new_compressor_ratios_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:new_compressor_ratios_ne1][c_idx] = c1              
    gm.constraint[:new_compressor_ratios_ne2][c_idx] = c2
    gm.constraint[:new_compressor_ratios_ne3][c_idx] = c3              
    gm.constraint[:new_compressor_ratios_ne4][c_idx] = c4                               
end

# Get all the solution values
function get_ne_solution{T}(gm::GenericGasModel{T})
    sol = Dict{AbstractString,Any}()
    add_junction_pressure_sqr_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    add_connection_ne(sol, gm)
    add_direction_setpoint(sol, gm)
    add_direction_ne_setpoint(sol, gm)
    return sol
end
