######################################:ne_connection####################################################################
# The purpose of this file is to define commonly used and created constraints used in gas flow models
##########################################################################################################

" Constraint that states a flow direction must be chosen "
function constraint_flow_direction_choice{T}(gm::GenericGasModel{T}, i)
    yp = gm.var[:yp][i] 
    yn = gm.var[:yn][i] 
              
    c = @constraint(gm.model, yp + yn == 1)

    if !haskey(gm.constraint, :flow_direction_choice)
        gm.constraint[:flow_direction_choice] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:flow_direction_choice][i] = c              
end

" Constraint that states a flow direction must be chosen for new edges "
function constraint_flow_direction_choice_ne{T}(gm::GenericGasModel{T}, i)
    yp = gm.var[:yp_ne][i] 
    yn = gm.var[:yn_ne][i] 
              
    c = @constraint(gm.model, yp + yn == 1)    
    if !haskey(gm.constraint, :flow_direction_choice_ne)
        gm.constraint[:flow_direction_choice_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:flow_direction_choice_ne][i] = c              
end

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = gm.var[:yp][pipe_idx] 
    yn = gm.var[:yn][pipe_idx] 
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    
    pd_min = pipe["pd_min"]
    pd_max = pipe["pd_max"]
      
    c1 = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)
    c2 = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)
    
    if !haskey(gm.constraint, :on_off_pressure_drop1)
        gm.constraint[:on_off_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pressure_drop2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pressure_drop1][pipe_idx] = c1              
    gm.constraint[:on_off_pressure_drop2][pipe_idx] = c2              
end

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_fixed_direction{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]
   
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = pipe["yp"]
    yn = pipe["yn"]
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    
    pd_min = pipe["pd_min"]
    pd_max = pipe["pd_max"]
      
    c1 = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)
    c2 = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)
    
    if !haskey(gm.constraint, :on_off_pressure_drop_fixed_direction1)
        gm.constraint[:on_off_pressure_drop_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pressure_drop_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pressure_drop_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:on_off_pressure_drop_fixed_direction2][pipe_idx] = c2              
end

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
    
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = gm.var[:yp_ne][pipe_idx] 
    yn = gm.var[:yn_ne][pipe_idx] 
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    
    pd_min = pipe["pd_min"]
    pd_max = pipe["pd_max"]
      
    c1 = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)
    c2 = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)
    
    if !haskey(gm.constraint, :on_off_pressure_drop_ne1)
        gm.constraint[:on_off_pressure_drop_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pressure_drop_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pressure_drop_ne1][pipe_idx] = c1              
    gm.constraint[:on_off_pressure_drop_ne2][pipe_idx] = c2              
end

" constraints on pressure drop across pipes when the direction is fixed "
function constraint_on_off_pressure_drop_ne_fixed_direction{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
  
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = pipe["yp"]
    yn = pipe["yn"]
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    
    pd_min = pipe["pd_min"]
    pd_max = pipe["pd_max"]
      
    c1 = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)
    c2 = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)
            
    if !haskey(gm.constraint, :on_off_pressure_drop_ne_fixed_direction1)
        gm.constraint[:on_off_pressure_drop_ne_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pressure_drop_ne_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pressure_drop_ne_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:on_off_pressure_drop_ne_fixed_direction2][pipe_idx] = c2              
end

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]
    
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = gm.var[:yp][pipe_idx] 
    yn = gm.var[:yn][pipe_idx] 
    f  = gm.var[:f][pipe_idx]  
    
    max_flow = gm.ref[:max_flow]
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    w = pipe["resistance"]  
    
    c1 = @constraint(gm.model, -(1-yp)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))) <= f)      
    c2 = @constraint(gm.model, f <= (1-yn)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))      

    if !haskey(gm.constraint, :on_off_pipe_flow_direction1)
        gm.constraint[:on_off_pipe_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pipe_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pipe_flow_direction1][pipe_idx] = c1              
    gm.constraint[:on_off_pipe_flow_direction2][pipe_idx] = c2              
end

" constraints on flow across pipes where the directions are fixed "
function constraint_on_off_pipe_flow_direction_fixed_direction{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]

    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = pipe["yp"]
    yn = pipe["yn"]
    f = gm.var[:f][pipe_idx] 
    
    max_flow = gm.ref[:max_flow]
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    w = pipe["resistance"]  
    
    c1 = @constraint(gm.model, -(1-yp)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))) <= f)      
    c2 = @constraint(gm.model, f <= (1-yn)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))      
    
    if !haskey(gm.constraint, :on_off_pipe_flow_direction_fixed_direction1)
        gm.constraint[:on_off_pipe_flow_direction_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pipe_flow_direction_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pipe_flow_direction_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:on_off_pipe_flow_direction_fixed_direction2][pipe_idx] = c2              
end

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction_ne{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
     
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = gm.var[:yp_ne][pipe_idx] 
    yn = gm.var[:yn_ne][pipe_idx] 
    f  = gm.var[:f_ne][pipe_idx]  
    
    max_flow = gm.ref[:max_flow]
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    w = pipe["resistance"]  
    
    c1 = @constraint(gm.model, -(1-yp)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))) <= f)      
    c2 = @constraint(gm.model, f <= (1-yn)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))      
    
    if !haskey(gm.constraint, :on_off_pipe_flow_direction_ne1)
        gm.constraint[:on_off_pipe_flow_direction_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pipe_flow_direction_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pipe_flow_direction_ne1][pipe_idx] = c1              
    gm.constraint[:on_off_pipe_flow_direction_ne2][pipe_idx] = c2              
end

" constraints on flow across pipes when directions are fixed "
function constraint_on_off_pipe_flow_direction_ne_fixed_direction{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:ne_connection][pipe_idx]
        
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = pipe["yp"]
    yn = pipe["yn"]
    f  = gm.var[:f_ne][pipe_idx] 
    
    max_flow = gm.ref[:max_flow]
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    w = pipe["resistance"]  
    
    c1 = @constraint(gm.model, -(1-yp)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))) <= f)      
    c2 = @constraint(gm.model, f <= (1-yn)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))      
    
    if !haskey(gm.constraint, :on_off_pipe_flow_direction_ne_fixed_direction1)
        gm.constraint[:on_off_pipe_flow_direction_ne_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_pipe_flow_direction_ne_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_pipe_flow_direction_ne_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:on_off_pipe_flow_direction_ne_fixed_direction2][pipe_idx] = c2              
end

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:connection][c_idx]
  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    yp = gm.var[:yp][c_idx] 
    yn = gm.var[:yn][c_idx] 
    f  = gm.var[:f][c_idx] 

    c1 = @constraint(gm.model, -(1-yp)*gm.ref[:max_flow] <= f)
    c2 = @constraint(gm.model, f <= (1-yn)*gm.ref[:max_flow])
      
    if !haskey(gm.constraint, :on_off_compressor_flow_direction1)
        gm.constraint[:on_off_compressor_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_flow_direction1][c_idx] = c1              
    gm.constraint[:on_off_compressor_flow_direction2][c_idx] = c2              
end 

" constraints on flow across compressors when directions are constants "
function constraint_on_off_compressor_flow_direction_fixed_direction{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:connection][c_idx]
  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    yp = compressor["yp"]
    yn = compressor["yn"]
    f = gm.var[:f][c_idx]

    c1 = @constraint(gm.model, -(1-yp)*gm.ref[:max_flow] <= f)
    c2 = @constraint(gm.model, f <= (1-yn)*gm.ref[:max_flow])
      
    if !haskey(gm.constraint, :on_off_compressor_flow_direction_fixed_direction1)
        gm.constraint[:on_off_compressor_flow_direction_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_flow_direction_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_flow_direction_fixed_direction1][c_idx] = c1              
    gm.constraint[:on_off_compressor_flow_direction_fixed_direction2][c_idx] = c2              
end

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction_ne{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:ne_connection][c_idx]  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    yp = gm.var[:yp_ne][c_idx] 
    yn = gm.var[:yn_ne][c_idx] 
    f  = gm.var[:f_ne][c_idx] 

    c1 = @constraint(gm.model, -(1-yp)*gm.ref[:max_flow] <= f)
    c2 = @constraint(gm.model, f <= (1-yn)*gm.ref[:max_flow])
      
    if !haskey(gm.constraint, :on_off_compressor_flow_direction_ne1)
        gm.constraint[:on_off_compressor_flow_direction_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_flow_direction_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_flow_direction_ne1][c_idx] = c1              
    gm.constraint[:on_off_compressor_flow_direction_ne2][c_idx] = c2              
end 

" constraints on flow across compressors when the directions are constants "
function constraint_on_off_compressor_flow_direction_ne_fixed_direction{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:ne_connection][c_idx]
      
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    yp = compressor["yp"]
    yn = compressor["yn"]
    f = gm.var[:f_ne][c_idx] 

    c1 = @constraint(gm.model, -(1-yp)*gm.ref[:max_flow] <= f)
    c2 = @constraint(gm.model, f <= (1-yn)*gm.ref[:max_flow])
      
    if !haskey(gm.constraint, :on_off_compressor_flow_direction_ne_fixed_direction1)
        gm.constraint[:on_off_compressor_flow_direction_ne_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_flow_direction_ne_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_flow_direction_ne_fixed_direction1][c_idx] = c1              
    gm.constraint[:on_off_compressor_flow_direction_ne_fixed_direction2][c_idx] = c2              
end 

" enforces pressure changes bounds that obey compression ratios "
function constraint_on_off_compressor_ratios{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:connection][c_idx]
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
      
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  

    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp][c_idx] 
    yn = gm.var[:yn][c_idx] 
    
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]

    c1 = @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j["pmax"]^2 - max_ratio^2*i["pmin"]^2))
    c2 = @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(min_ratio^2*i["pmax"]^2 - j["pmin"]^2))
    c3 = @constraint(gm.model, pi - max_ratio^2*pj <= (1-yn)*(i["pmax"]^2 - max_ratio^2*j["pmin"]^2))
    c4 = @constraint(gm.model, min_ratio^2*pj - pi <= (1-yn)*(min_ratio^2*j["pmax"]^2 - i["pmin"]^2))
          
    if !haskey(gm.constraint, :on_off_compressor_ratios1)
        gm.constraint[:on_off_compressor_ratios1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_ratios2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_compressor_ratios3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_ratios4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_ratios1][c_idx] = c1              
    gm.constraint[:on_off_compressor_ratios2][c_idx] = c2
    gm.constraint[:on_off_compressor_ratios3][c_idx] = c3              
    gm.constraint[:on_off_compressor_ratios4][c_idx] = c4                             
end

" constraints on pressure drop across control valves "
function constraint_on_off_compressor_ratios_ne{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:ne_connection][c_idx]  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp_ne][c_idx] 
    yn = gm.var[:yn_ne][c_idx]     
    zc = gm.var[:zc][c_idx] 
    
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    
    c1 = @constraint(gm.model,  pj - (max_ratio*pi) <= (2-yp-zc)*j["pmax"]^2)
    c2 = @constraint(gm.model,  (min_ratio*pi) - pj <= (2-yp-zc)*(min_ratio*i["pmax"]^2) )
    c3 = @constraint(gm.model,  pi - (max_ratio*pj) <= (2-yn-zc)*i["pmax"]^2)
    c4 = @constraint(gm.model,  (min_ratio*pj) - pi <= (2-yn-zc)*(min_ratio*j["pmax"]^2))
    
    if !haskey(gm.constraint, :on_off_compressor_ratios_ne1)
        gm.constraint[:on_off_compressor_ratios_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_ratios_ne2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_compressor_ratios_ne3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_ratios_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_ratios_ne1][c_idx] = c1              
    gm.constraint[:on_off_compressor_ratios_ne2][c_idx] = c2
    gm.constraint[:on_off_compressor_ratios_ne3][c_idx] = c3              
    gm.constraint[:on_off_compressor_ratios_ne4][c_idx] = c4                             
end

" on/off constraint for compressors when the flow direction is constant "
function constraint_on_off_compressor_ratios_fixed_direction{T}(gm::GenericGasModel{T}, c_idx)
    compressor = gm.ref[:connection][c_idx]
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
      
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  

    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = compressor["yp"]
    yn = compressor["yn"]
    
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]

    c1 = @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j["pmax"]^2 - max_ratio^2*i["pmin"]^2))
    c2 = @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(min_ratio^2*i["pmax"]^2 - j["pmin"]^2))
    c3 = @constraint(gm.model, pi - max_ratio^2*pj <= (1-yn)*(i["pmax"]^2 - max_ratio^2*j["pmin"]^2))
    c4 = @constraint(gm.model, min_ratio^2*pj - pi <= (1-yn)*(min_ratio^2*j["pmax"]^2 - i["pmin"]^2))
          
    if !haskey(gm.constraint, :on_off_compressor_ratios_fixed_direction1)
        gm.constraint[:on_off_compressor_ratios_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_ratios_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_compressor_ratios_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_compressor_ratios_fixed_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_compressor_ratios_fixed_direction1][c_idx] = c1              
    gm.constraint[:on_off_compressor_ratios_fixed_direction2][c_idx] = c2
    gm.constraint[:on_off_compressor_ratios_fixed_direction3][c_idx] = c3              
    gm.constraint[:on_off_compressor_ratios_fixed_direction4][c_idx] = c4                             
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance{T}(gm::GenericGasModel{T}, i)
    junction = gm.ref[:junction][i]  
    junction_branches = gm.ref[:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:connection])))
      
    p = gm.var[:p] 
    f = gm.var[:f] 

    c = @constraint(gm.model, junction["qgfirm"] - junction["qlfirm"] == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) )
                  
    if !haskey(gm.constraint, :junction_flow_balance)
        gm.constraint[:junction_flow_balance] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:junction_flow_balance][i] = c              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ne{T}(gm::GenericGasModel{T}, i)
    junction = gm.ref[:junction][i]  
    junction_branches = gm.ref[:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:connection])))

    f_branches_ne = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:ne_connection])))
    t_branches_ne = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:ne_connection])))
                  
    p = gm.var[:p] 
    f = gm.var[:f] 
    f_ne = gm.var[:f_ne] 
    c = @constraint(gm.model, junction["qgfirm"] - junction["qlfirm"] == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne) )
                  
    if !haskey(gm.constraint, :junction_flow_balance_ne)
        gm.constraint[:junction_flow_balance_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:junction_flow_balance_ne][i] = c              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ls{T}(gm::GenericGasModel{T}, i)
    junction = gm.ref[:junction][i]    
    junction_branches = gm.ref[:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:connection])))
      
    p = gm.var[:p] 
    f = gm.var[:f] 
    ql = 0
    qg = 0
    if junction["qlmin"] != junction["qlmax"]
        ql = gm.var[:ql][i] 
    end
    if junction["qgmin"] != junction["qgmax"]   
        qg = gm.var[:qg][i] 
    end
    ql_firm = junction["qlfirm"]
    qg_firm = junction["qgfirm"]

    c = @constraint(gm.model, qg_firm - ql_firm + qg - ql == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) )
                  
    if !haskey(gm.constraint, :junction_flow_balance_ls)
        gm.constraint[:junction_flow_balance_ls] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:junction_flow_balance_ls][i] = c              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ne_ls{T}(gm::GenericGasModel{T}, i)  
    junction = gm.ref[:junction][i]  
    junction_branches = gm.ref[:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:connection])))

    f_branches_ne = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:ne_connection])))
    t_branches_ne = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:ne_connection])))
                  
    p = gm.var[:p] 
    f = gm.var[:f] 
    f_ne = gm.var[:f_ne] 
    
    ql = 0
    qg = 0
    if junction["qlmin"] != junction["qlmax"]
        ql = gm.var[:ql][i] 
    end
    if junction["qgmin"] != junction["qgmax"]
        qg = gm.var[:qg][i] 
    end
    
    ql_firm = junction["qlfirm"]
    qg_firm = junction["qgfirm"]
        
    c = @constraint(gm.model, qg_firm - ql_firm + qg - ql == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne) )
                      
    if !haskey(gm.constraint, :junction_flow_balance_ne_ls)
        gm.constraint[:junction_flow_balance_ne_ls] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:junction_flow_balance_ne_ls][i] = c              
end

" constraints on flow across short pipes "
function constraint_on_off_short_pipe_flow_direction{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]    
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
      
    yp = gm.var[:yp][pipe_idx] 
    yn = gm.var[:yn][pipe_idx] 
    f = gm.var[:f][pipe_idx]   
    max_flow = gm.ref[:max_flow]
    
    c1 = @constraint(gm.model, -max_flow*(1-yp) <= f)
    c2 = @constraint(gm.model, f <= max_flow*(1-yn))
      
    if !haskey(gm.constraint, :on_off_short_pipe_flow_direction1)
        gm.constraint[:on_off_short_pipe_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_short_pipe_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_short_pipe_flow_direction1][pipe_idx] = c1              
    gm.constraint[:on_off_short_pipe_flow_direction2][pipe_idx] = c2              
end

" constraints on flow across short pipes when the directions are constants "
function constraint_on_off_short_pipe_flow_direction_fixed_direction{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]  
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
      
    yp = pipe["yp"]
    yn = pipe["yn"]
    f = gm.var[:f][pipe_idx]   
    max_flow = gm.ref[:max_flow]
    
    c1 = @constraint(gm.model, -max_flow*(1-yp) <= f)
    c2 = @constraint(gm.model, f <= max_flow*(1-yn))
      
    if !haskey(gm.constraint, :on_off_short_pipe_flow_direction_fixed_direction1)
        gm.constraint[:on_off_short_pipe_flow_direction_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_short_pipe_flow_direction_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_short_pipe_flow_direction_fixed_direction1][i] = c1              
    gm.constraint[:on_off_short_pipe_flow_direction_fixed_direction2][i] = c2              
end

" constraints on pressure drop across pipes "
function constraint_short_pipe_pressure_drop{T}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]  
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 

    c = @constraint(gm.model,  pi == pj)
    if !haskey(gm.constraint, :short_pipe_pressure_drop)
        gm.constraint[:short_pipe_pressure_drop] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:short_pipe_pressure_drop][pipe_idx] = c              
end

" constraints on flow across valves "
function constraint_on_off_valve_flow_direction{T}(gm::GenericGasModel{T}, valve_idx)
    valve = gm.ref[:connection][valve_idx]  
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]

    yp = gm.var[:yp][valve_idx] 
    yn = gm.var[:yn][valve_idx] 
    f = gm.var[:f][valve_idx] 
    v = gm.var[:v][valve_idx] 

    max_flow = gm.ref[:max_flow]
            
    c1 = @constraint(gm.model, -max_flow*(1-yp) <= f)
    c2 = @constraint(gm.model, f <= max_flow*(1-yn))     
    c3 = @constraint(gm.model, -max_flow*v <= f )
    c4 = @constraint(gm.model, f <= max_flow*v)
      
    if !haskey(gm.constraint, :on_off_valve_flow_direction1)
        gm.constraint[:on_off_valve_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_valve_flow_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_valve_flow_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_valve_flow_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_valve_flow_direction1][valve_idx] = c1              
    gm.constraint[:on_off_valve_flow_direction2][valve_idx] = c2
    gm.constraint[:on_off_valve_flow_direction3][valve_idx] = c3              
    gm.constraint[:on_off_valve_flow_direction4][valve_idx] = c4                             
end

" constraints on flow across valves when directions are constants "
function constraint_on_off_valve_flow_direction_fixed_direction{T}(gm::GenericGasModel{T}, valve_idx)
    valve = gm.ref[:connection][valve_idx]  
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]

    yp = valve["yp"]
    yn = valve["yn"]
    f = gm.var[:f][valve_idx] 
    v = gm.var[:v][valve_idx] 

    max_flow = gm.ref[:max_flow]
            
    c1 = @constraint(gm.model, -max_flow*(1-yp) <= f <= max_flow*(1-yn))
    c2 = @constraint(gm.model, -max_flow*v <= f <= max_flow*v)
      
    if !haskey(gm.constraint, :on_off_valve_flow_direction_fixed_direction1)
        gm.constraint[:on_off_valve_flow_direction_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_valve_flow_direction_fixed_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_valve_flow_direction_fixed_direction1][valve_idx] = c1              
    gm.constraint[:on_off_valve_flow_direction_fixed_direction2][valve_idx] = c2              
end

" constraints on pressure drop across valves "
function constraint_on_off_valve_pressure_drop{T}(gm::GenericGasModel{T}, valve_idx)
    valve = gm.ref[:connection][valve_idx]  
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 

    v = gm.var[:v][valve_idx] 

    c1 = @constraint(gm.model,  pj - ((1-v)*j["pmax"]^2) <= pi)
    c2 = @constraint(gm.model,  pi <= pj + ((1-v)*i["pmax"]^2))
    
    if !haskey(gm.constraint, :on_off_valve_pressure_drop1)
        gm.constraint[:on_off_valve_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_valve_pressure_drop2] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_valve_pressure_drop1][valve_idx] = c1              
    gm.constraint[:on_off_valve_pressure_drop2][valve_idx] = c2              
end

" constraints on flow across control valves "
function constraint_on_off_control_valve_flow_direction{T}(gm::GenericGasModel{T}, valve_idx)
    valve = gm.ref[:connection][valve_idx]  
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]

    yp = gm.var[:yp][valve_idx] 
    yn = gm.var[:yn][valve_idx] 
    f = gm.var[:f][valve_idx] 
    v = gm.var[:v][valve_idx] 
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, -max_flow*(1-yp) <= f)
    c2 = @constraint(gm.model, f <= max_flow*(1-yn))      
    c3 = @constraint(gm.model, -max_flow*v <= f )
    c4 = @constraint(gm.model, f <= max_flow*v)
          
    if !haskey(gm.constraint, :on_off_control_valve_flow_direction1)
        gm.constraint[:on_off_control_valve_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_flow_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_control_valve_flow_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_flow_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_control_valve_flow_direction1][valve_idx] = c1              
    gm.constraint[:on_off_control_valve_flow_direction2][valve_idx] = c2
    gm.constraint[:on_off_control_valve_flow_direction3][valve_idx] = c3              
    gm.constraint[:on_off_control_valve_flow_direction4][valve_idx] = c4                             
end

" constraints on flow across control valves when directions are constants "
function constraint_on_off_control_valve_flow_direction_fixed_direction{T}(gm::GenericGasModel{T}, valve_idx)
    valve = gm.ref[:connection][valve_idx]  
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]

    yp = valve["yp"]
    yn = valve["yn"]
    f = gm.var[:f][valve_idx] 
    v = gm.var[:v][valve_idx] 
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, -max_flow*(1-yp) <= f)
    c2 = @constraint(gm.model, f <= max_flow*(1-yn))      
    c3 = @constraint(gm.model, -max_flow*v <= f )
    c4 = @constraint(gm.model, f <= max_flow*v)
          
    if !haskey(gm.constraint, :on_off_control_valve_flow_direction_fixed_direction1)
        gm.constraint[:on_off_control_valve_flow_direction_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_flow_direction_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_control_valve_flow_direction_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_flow_direction_fixed_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_control_valve_flow_direction_fixed_direction1][valve_idx] = c1              
    gm.constraint[:on_off_control_valve_flow_direction_fixed_direction2][valve_idx] = c2
    gm.constraint[:on_off_control_valve_flow_direction_fixed_direction3][valve_idx] = c3              
    gm.constraint[:on_off_control_valve_flow_direction_fixed_direction4][valve_idx] = c4                             
end

" constraints on pressure drop across control valves "
function constraint_on_off_control_valve_pressure_drop{T}(gm::GenericGasModel{T}, valve_idx)
    valve = gm.ref[:connection][valve_idx]  
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp][valve_idx] 
    yn = gm.var[:yn][valve_idx]     
    v = gm.var[:v][valve_idx] 
    
    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]
    
    c1 = @constraint(gm.model,  pj - (max_ratio*pi) <= (2-yp-v)*j["pmax"]^2)
    c2 = @constraint(gm.model,  (min_ratio*pi) - pj <= (2-yp-v)*(min_ratio*i["pmax"]^2) )
    c3 = @constraint(gm.model,  pi - (max_ratio*pj) <= (2-yn-v)*i["pmax"]^2)
    c4 = @constraint(gm.model,  (min_ratio*pj) - pi <= (2-yn-v)*(min_ratio*j["pmax"]^2))
    
    if !haskey(gm.constraint, :on_off_control_valve_pressure_drop1)
        gm.constraint[:on_off_control_valve_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_pressure_drop2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_control_valve_pressure_drop3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_pressure_drop4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_control_valve_pressure_drop1][valve_idx] = c1              
    gm.constraint[:on_off_control_valve_pressure_drop2][valve_idx] = c2
    gm.constraint[:on_off_control_valve_pressure_drop3][valve_idx] = c3              
    gm.constraint[:on_off_control_valve_pressure_drop4][valve_idx] = c4                             
end

" constraints on pressure drop across control valves when directions are constants "
function constraint_on_off_control_valve_pressure_drop_fixed_direction{T}(gm::GenericGasModel{T}, valve_idx)
    valve = gm.ref[:connection][valve_idx]  
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = valve["yp"]
    yn = valve["yn"]    
    v = gm.var[:v][valve_idx]
    
    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]
    
    c1 = @constraint(gm.model,  pj - (max_ratio*pi) <= (2-yp-v)*j["pmax"]^2)
    c2 = @constraint(gm.model,  (min_ratio*pi) - pj <= (2-yp-v)*(min_ratio*i["pmax"]^2) )
    c3 = @constraint(gm.model,  pi - (max_ratio*pj) <= (2-yn-v)*i["pmax"]^2)
    c4 = @constraint(gm.model,  (min_ratio*pj) - pi <= (2-yn-v)*(min_ratio*j["pmax"]^2))
    
    if !haskey(gm.constraint, :on_off_control_valve_pressure_drop_fixed_direction1)
        gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction1][valve_idx] = c1              
    gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction2][valve_idx] = c2
    gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction3][valve_idx] = c3              
    gm.constraint[:on_off_control_valve_pressure_drop_fixed_direction4][valve_idx] = c4                             
end

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow{T}(gm::GenericGasModel{T}, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:connection]))) 

    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
         
    c = @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) >= 1)
    if !haskey(gm.constraint, :source_flow)
        gm.constraint[:source_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:source_flow][i] = c              
end

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne{T}(gm::GenericGasModel{T}, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:connection]))) 

    f_branches_ne = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:ne_connection])))
    t_branches_ne = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:ne_connection]))) 
            
    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
   
    yp_ne = gm.var[:yp_ne] 
    yn_ne = gm.var[:yn_ne] 
             
    c = @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) + sum(yp_ne[a] for a in f_branches_ne) + sum(yn_ne[a] for a in t_branches_ne) >= 1)
    if !haskey(gm.constraint, :source_flow_ne)
        gm.constraint[:source_flow_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:source_flow_ne][i] = c              
end

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow{T}(gm::GenericGasModel{T}, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:connection]))) 

    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
          
    c = @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) >= 1)
    if !haskey(gm.constraint, :sink_flow)
        gm.constraint[:sink_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:sink_flow][i] = c              
end

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne{T}(gm::GenericGasModel{T}, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:connection]))) 
    f_branches_ne = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:ne_connection])))
    t_branches_ne = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:ne_connection]))) 
      
    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
    yp_ne = gm.var[:yp_ne] 
    yn_ne = gm.var[:yn_ne] 
          
    c = @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) + sum(yn_ne[a] for a in f_branches_ne) + sum(yp_ne[a] for a in t_branches_ne) >= 1)
    if !haskey(gm.constraint, :sink_flow_ne)
        gm.constraint[:sink_flow_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:sink_flow_ne][i] = c              
end

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow{T}(gm::GenericGasModel{T}, idx)
    first = nothing
    last = nothing
    
    for i in gm.ref[:junction_connections][idx]
        connection = gm.ref[:connection][i]
        if connection["f_junction"] == idx
            other = connection["t_junction"]
        else
            other = connection["f_junction"]
        end
        
        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end
            last = other    
        end      
    end
    
    yp_first = filter(i -> gm.ref[:connection][i]["f_junction"] == first, gm.ref[:junction_connections][idx])
    yn_first = filter(i -> gm.ref[:connection][i]["t_junction"] == first, gm.ref[:junction_connections][idx])
    yp_last  = filter(i -> gm.ref[:connection][i]["t_junction"] == last,  gm.ref[:junction_connections][idx])
    yn_last  = filter(i -> gm.ref[:connection][i]["f_junction"] == last,  gm.ref[:junction_connections][idx])
          
    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
    
    c1 = nothing
    c2 = nothing
    c3 = nothing
    c4 = nothing           
    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                c1 = @constraint(gm.model, yn[i1]  == yp[i2])
                c2 = @constraint(gm.model, yp[i1]  == yn[i2])              
                c3 = @constraint(gm.model, yn[i1] + yn[i2] == 1)
                c4 = @constraint(gm.model, yp[i1] + yp[i2] == 1)              
            end 
        end      
    end  
      
  
   if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                c1 = @constraint(gm.model, yn[i1] == yn[i2])
                c2 = @constraint(gm.model, yp[i1] == yp[i2])
                c3 = @constraint(gm.model, yn[i1] + yp[i2] == 1)
                c4 = @constraint(gm.model, yp[i1] + yn[i2] == 1)              
            end 
        end      
    end  
              
    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                c1 = @constraint(gm.model, yp[i1]  == yp[i2])
                c2 = @constraint(gm.model, yn[i1]  == yn[i2]) 
                c3 = @constraint(gm.model, yp[i1] + yn[i2] == 1)
                c4 = @constraint(gm.model, yn[i1] + yp[i2] == 1)                
            end 
        end      
    end  
      
    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                c1 = @constraint(gm.model, yp[i1] == yn[i2])
                c2 = @constraint(gm.model, yn[i1] == yp[i2])      
                c3 = @constraint(gm.model, yp[i1] + yp[i2] == 1)
                c4 = @constraint(gm.model, yn[i1] + yn[i2] == 1)                
            end 
        end      
    end  

    if !haskey(gm.constraint, :conserve_flow1)
        gm.constraint[:conserve_flow1] = Dict{Int,ConstraintRef}()
        gm.constraint[:conserve_flow2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:conserve_flow3] = Dict{Int,ConstraintRef}()
        gm.constraint[:conserve_flow4] = Dict{Int,ConstraintRef}()          
    end
        
    gm.constraint[:conserve_flow1][idx] = c1              
    gm.constraint[:conserve_flow2][idx] = c2
    gm.constraint[:conserve_flow3][idx] = c3              
    gm.constraint[:conserve_flow4][idx] = c4                             
end


" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow_ne{T}(gm::GenericGasModel{T}, idx)
    first = nothing
    last = nothing
    
    for i in gm.ref[:junction_connections][idx] 
        connection = gm.ref[:connection][i]
        if connection["f_junction"] == idx
            other = connection["t_junction"]
        else
            other = connection["f_junction"]
        end
        
        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end          
            last = other    
        end      
    end
    
    for i in gm.ref[:junction_ne_connections][idx] 
        connection = gm.ref[:ne_connection][i]
        if connection["f_junction"] == idx
            other = connection["t_junction"]
        else
            other = connection["f_junction"]
        end
        
        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end          
            last = other    
        end      
    end
    
      
    yp_first = [filter(i -> gm.ref[:connection][i]["f_junction"] == first, gm.ref[:junction_connections][idx]); filter(i -> gm.ref[:ne_connection][i]["f_junction"] == first, gm.ref[:junction_ne_connections][idx])]
    yn_first = [filter(i -> gm.ref[:connection][i]["t_junction"] == first, gm.ref[:junction_connections][idx]); filter(i -> gm.ref[:ne_connection][i]["t_junction"] == first, gm.ref[:junction_ne_connections][idx])]
    yp_last  = [filter(i -> gm.ref[:connection][i]["t_junction"] == last,  gm.ref[:junction_connections][idx]); filter(i -> gm.ref[:ne_connection][i]["t_junction"] == last,  gm.ref[:junction_ne_connections][idx])]
    yn_last  = [filter(i -> gm.ref[:connection][i]["f_junction"] == last,  gm.ref[:junction_connections][idx]); filter(i -> gm.ref[:ne_connection][i]["f_junction"] == last,  gm.ref[:junction_ne_connections][idx])]

    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
    yp_ne = gm.var[:yp_ne] 
    yn_ne = gm.var[:yn_ne] 

    c1 = nothing
    c2 = nothing
    c3 = nothing
    c4 = nothing           
    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                yn1 = haskey(gm.ref[:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:connection],i2) ? yp[i2] : yp_ne[i2]    

                c1 = @constraint(gm.model, yn1  == yp2)
                c2 = @constraint(gm.model, yp1  == yn2)
                c3 = @constraint(gm.model, yn1 + yn2 == 1)
                c4 = @constraint(gm.model, yp1 + yp2 == 1)               
            end 
        end      
    end  
        
    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                yn1 = haskey(gm.ref[:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:connection],i2) ? yp[i2] : yp_ne[i2]    
               
                c1 = @constraint(gm.model, yn1 == yn2)
                c2 = @constraint(gm.model, yp1 == yp2)
                c3 = @constraint(gm.model, yn1 + yp2 == 1)
                c4 = @constraint(gm.model, yp1 + yn2 == 1)
            end 
        end      
    end  
              
    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                yn1 = haskey(gm.ref[:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:connection],i2) ? yp[i2] : yp_ne[i2]    
                
                c1 = @constraint(gm.model, yp1 == yp2)
                c2 = @constraint(gm.model, yn1 == yn2)
                c3 = @constraint(gm.model, yp1 + yn2 == 1)
                c4 = @constraint(gm.model, yn1 + yp2 == 1)
            end 
        end      
    end  
      
    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                yn1 = haskey(gm.ref[:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:connection],i2) ? yp[i2] : yp_ne[i2]    
                
                c1 = @constraint(gm.model, yp1 == yn2)
                c2 = @constraint(gm.model, yn1 == yp2)
                c3 = @constraint(gm.model, yp1 + yp2 == 1)
                c4 = @constraint(gm.model, yn1 + yn2 == 1)
            end 
        end      
    end  

    if !haskey(gm.constraint, :conserve_flow_ne1)
        gm.constraint[:conserve_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.constraint[:conserve_flow_ne2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:conserve_flow_ne3] = Dict{Int,ConstraintRef}()
        gm.constraint[:conserve_flow_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:conserve_flow_ne1][idx] = c1              
    gm.constraint[:conserve_flow_ne2][idx] = c2
    gm.constraint[:conserve_flow_ne3][idx] = c3              
    gm.constraint[:conserve_flow_ne4][idx] = c4                             
end

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow{T}(gm::GenericGasModel{T}, idx)
    connection = gm.ref[:connection][idx]
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])
    
    f_connections = filter(i -> gm.ref[:connection][i]["f_junction"] == connection["f_junction"], gm.ref[:parallel_connections][(i,j)])
    t_connections = filter(i -> gm.ref[:connection][i]["f_junction"] != connection["f_junction"], gm.ref[:parallel_connections][(i,j)])

    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
    
    if length(gm.ref[:parallel_connections][(i,j)]) <= 1
        return nothing
    end  
                                    
    c = @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) == yp[idx] * length(gm.ref[:parallel_connections][(i,j)]))
    if !haskey(gm.constraint, :parallel_flow)
        gm.constraint[:parallel_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:parallel_flow][idx] = c              
end

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne{T}(gm::GenericGasModel{T}, idx)    
    connection = haskey(gm.ref[:connection], idx) ? gm.ref[:connection][idx] : gm.ref[:ne_connection][idx] 
      
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])
             
    f_connections = filter(i -> gm.ref[:connection][i]["f_junction"] == connection["f_junction"], intersect(gm.ref[:all_parallel_connections][(i,j)], gm.ref[:parallel_connections][(i,j)]))
    t_connections = filter(i -> gm.ref[:connection][i]["f_junction"] != connection["f_junction"], intersect(gm.ref[:all_parallel_connections][(i,j)], gm.ref[:parallel_connections][(i,j)]))
    f_connections_ne = filter(i -> gm.ref[:ne_connection][i]["f_junction"] == connection["f_junction"], setdiff(gm.ref[:all_parallel_connections][(i,j)], gm.ref[:parallel_connections][(i,j)]))
    t_connections_ne = filter(i -> gm.ref[:ne_connection][i]["f_junction"] != connection["f_junction"], setdiff(gm.ref[:all_parallel_connections][(i,j)], gm.ref[:parallel_connections][(i,j)]))
        
    yp = gm.var[:yp] 
    yn = gm.var[:yn] 
    yp_ne = gm.var[:yp_ne] 
    yn_ne = gm.var[:yn_ne] 
    yp_i = haskey(gm.ref[:connection], idx) ? yp[idx] : yp_ne[idx]   
      
    if length(gm.ref[:all_parallel_connections][(i,j)]) <= 1
        return nothing
    end    
                                          
    c = @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) + sum(yp_ne[i] for i in f_connections_ne) + sum(yn_ne[i] for i in t_connections_ne) == yp_i * length(gm.ref[:all_parallel_connections][(i,j)]))
    if !haskey(gm.constraint, :parallel_flow_ne)
        gm.constraint[:parallel_flow_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.constraint[:parallel_flow_ne][idx] = c              
end

