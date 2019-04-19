################
# Variables
################

" variables associated with direction of flow on the connections. yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction "
function variable_connection_direction(gm::GenericGasModel{T}, n::Int=gm.cnw) where T <: AbstractUndirectedGasFormulation
    gm.var[:nw][n][:yp] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:connection])], binary=true, base_name="$(n)_yp", lower_bound=0, upper_bound=1, start = getstart(gm.ref[:nw][n][:connection], l, "yp_start", 1.0))                  
    gm.var[:nw][n][:yn] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:connection])], binary=true, base_name="$(n)_yn", lower_bound=0, upper_bound=1, start = getstart(gm.ref[:nw][n][:connection], l, "yn_start", 0.0))                  
end

" variables associated with direction of flow on the connections "
function variable_connection_direction_ne(gm::GenericGasModel{T}, n::Int=gm.cnw) where T <: AbstractUndirectedGasFormulation
     gm.var[:nw][n][:yp_ne] = @variable(gm.model, [l in keys(sort(gm.ref[:nw][n][:ne_connection]))], binary=true, base_name="$(n)_yp_ne", lower_bound=0, upper_bound=1, start = getstart(gm.ref[:nw][n][:ne_connection], l, "yp_start", 1.0))                  
     gm.var[:nw][n][:yn_ne] = @variable(gm.model, [l in keys(sort(gm.ref[:nw][n][:ne_connection]))], binary=true, base_name="$(n)_yn_ne", lower_bound=0, upper_bound=1, start = getstart(gm.ref[:nw][n][:ne_connection], l, "yn_start", 0.0))                  
end

################
# Constraints
################

function constraint_flow_direction_choice(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp][i] 
    yn = gm.var[:nw][n][:yn][i] 
              
    if !haskey(gm.con[:nw][n], :flow_direction_choice)
        gm.con[:nw][n][:flow_direction_choice] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:flow_direction_choice][i] = @constraint(gm.model, yp + yn == 1)              
end

function constraint_flow_direction_choice_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp_ne][i] 
    yn = gm.var[:nw][n][:yn_ne][i] 
              
    if !haskey(gm.con[:nw][n], :flow_direction_choice_ne)
        gm.con[:nw][n][:flow_direction_choice_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:flow_direction_choice_ne][i] = @constraint(gm.model, yp + yn == 1)               
end

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
                
    if !haskey(gm.con[:nw][n], :on_off_pressure_drop1)
        gm.con[:nw][n][:on_off_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pressure_drop2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pressure_drop1][k] = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)              
    gm.con[:nw][n][:on_off_pressure_drop2][k] = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)           
end

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp_ne][k] 
    yn = gm.var[:nw][n][:yn_ne][k] 
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
          
    if !haskey(gm.con[:nw][n], :on_off_pressure_drop_ne1)
        gm.con[:nw][n][:on_off_pressure_drop_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pressure_drop_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pressure_drop_ne1][k] = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)  
    gm.con[:nw][n][:on_off_pressure_drop_ne2][k] = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)              
end

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    f  = gm.var[:nw][n][:f][k]  
           
    if !haskey(gm.con[:nw][n], :on_off_pipe_flow_direction1)
        gm.con[:nw][n][:on_off_pipe_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pipe_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pipe_flow_direction1][k] = @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f)    
    gm.con[:nw][n][:on_off_pipe_flow_direction2][k] = @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))   
end

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction_ne(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp_ne][k] 
    yn = gm.var[:nw][n][:yn_ne][k] 
    f  = gm.var[:nw][n][:f_ne][k]  
        
    if !haskey(gm.con[:nw][n], :on_off_pipe_flow_direction_ne1)
        gm.con[:nw][n][:on_off_pipe_flow_direction_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pipe_flow_direction_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pipe_flow_direction_ne1][k] = @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f)              
    gm.con[:nw][n][:on_off_pipe_flow_direction_ne2][k] = @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))              
end

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    f  = gm.var[:nw][n][:f][k] 
      
    if !haskey(gm.con[:nw][n], :on_off_compressor_flow_direction1)
        gm.con[:nw][n][:on_off_compressor_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_flow_direction1][k] = @constraint(gm.model, -(1-yp)*mf <= f) 
    gm.con[:nw][n][:on_off_compressor_flow_direction2][k] = @constraint(gm.model, f <= (1-yn)*mf) 
end

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction_ne(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp_ne][k] 
    yn = gm.var[:nw][n][:yn_ne][k] 
    f  = gm.var[:nw][n][:f_ne][k] 

    if !haskey(gm.con[:nw][n], :on_off_compressor_flow_direction_ne1)
        gm.con[:nw][n][:on_off_compressor_flow_direction_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_flow_direction_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_flow_direction_ne1][k] = @constraint(gm.model, -(1-yp)*mf <= f)  
    gm.con[:nw][n][:on_off_compressor_flow_direction_ne2][k] = @constraint(gm.model, f <= (1-yn)*mf)
end 

" enforces pressure changes bounds that obey compression ratios "
function constraint_on_off_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin; kwargs...) where T <: AbstractUndirectedGasFormulation
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
     
    if !haskey(gm.con[:nw][n], :on_off_compressor_ratios1)
        gm.con[:nw][n][:on_off_compressor_ratios1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_compressor_ratios3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios4] = Dict{Int,ConstraintRef}()          
    end 

    gm.con[:nw][n][:on_off_compressor_ratios1][k] = @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j_pmax^2))              
    gm.con[:nw][n][:on_off_compressor_ratios2][k] = @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(i_pmax^2))
    gm.con[:nw][n][:on_off_compressor_ratios3][k] = @constraint(gm.model, pi - pj <= (1-yn)*(i_pmax^2))                               
    gm.con[:nw][n][:on_off_compressor_ratios4][k] = @constraint(gm.model, pj - pi <= (1-yn)*(j_pmax^2))              
            
    # Old way... bi-directional constraints   
    #gm.con[:nw][n][:on_off_compressor_ratios1][k] = @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j_pmax^2 - max_ratio^2*i_pmin^2))              
    #gm.con[:nw][n][:on_off_compressor_ratios2][k] = @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(min_ratio^2*i_pmax^2 - j_pmin^2))
    #gm.con[:nw][n][:on_off_compressor_ratios3][k] = @constraint(gm.model, pi - max_ratio^2*pj <= (1-yn)*(i_pmax^2 - max_ratio^2*j_pmin^2))              
    #gm.con[:nw][n][:on_off_compressor_ratios4][k] = @constraint(gm.model, min_ratio^2*pj - pi <= (1-yn)*(min_ratio^2*j_pmax^2 - i_pmin^2))                             
end

" constraints on flow across short pipes "
function constraint_on_off_short_pipe_flow_direction(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    f = gm.var[:nw][n][:f][k]   
    
    if !haskey(gm.con[:nw][n], :on_off_short_pipe_flow_direction1)
        gm.con[:nw][n][:on_off_short_pipe_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_short_pipe_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_short_pipe_flow_direction1][k] = @constraint(gm.model, -mf*(1-yp) <= f)              
    gm.con[:nw][n][:on_off_short_pipe_flow_direction2][k] = @constraint(gm.model, f <= mf*(1-yn))              
end

" constraints on flow across valves "
function constraint_on_off_valve_flow_direction(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    f = gm.var[:nw][n][:f][k] 
    v = gm.var[:nw][n][:v][k] 
            
    if !haskey(gm.con[:nw][n], :on_off_valve_flow_direction1)
        gm.con[:nw][n][:on_off_valve_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_valve_flow_direction2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_valve_flow_direction3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_valve_flow_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_valve_flow_direction1][k] = @constraint(gm.model, -mf*(1-yp) <= f)              
    gm.con[:nw][n][:on_off_valve_flow_direction2][k] = @constraint(gm.model, f <= mf*(1-yn))
    gm.con[:nw][n][:on_off_valve_flow_direction3][k] = @constraint(gm.model, -mf*v <= f )              
    gm.con[:nw][n][:on_off_valve_flow_direction4][k] = @constraint(gm.model, f <= mf*v)                             
end

" constraints on flow across control valves "
function constraint_on_off_control_valve_flow_direction(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    f = gm.var[:nw][n][:f][k] 
    v = gm.var[:nw][n][:v][k] 

    if !haskey(gm.con[:nw][n], :on_off_control_valve_flow_direction1)
        gm.con[:nw][n][:on_off_control_valve_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_flow_direction2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_control_valve_flow_direction3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_flow_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_control_valve_flow_direction1][k] = @constraint(gm.model, -mf*(1-yp) <= f)              
    gm.con[:nw][n][:on_off_control_valve_flow_direction2][k] = @constraint(gm.model, f <= mf*(1-yn)) 
    gm.con[:nw][n][:on_off_control_valve_flow_direction3][k] = @constraint(gm.model, -mf*v <= f )              
    gm.con[:nw][n][:on_off_control_valve_flow_direction4][k] = @constraint(gm.model, f <= mf*v)                             
end

" constraints on pressure drop across control valves "
function constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax; kwargs...) where T <: AbstractUndirectedGasFormulation
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k]     
    v = gm.var[:nw][n][:v][k] 
        
    if !haskey(gm.con[:nw][n], :on_off_control_valve_pressure_drop1)
        gm.con[:nw][n][:on_off_control_valve_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_pressure_drop2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_control_valve_pressure_drop3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_pressure_drop4] = Dict{Int,ConstraintRef}()          
    end    

    gm.con[:nw][n][:on_off_control_valve_pressure_drop1][k] = @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-yp-v)*j_pmax^2)              
    gm.con[:nw][n][:on_off_control_valve_pressure_drop2][k] = @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-yp-v)*(i_pmax^2) )
    gm.con[:nw][n][:on_off_control_valve_pressure_drop3][k] = @constraint(gm.model,  pj - pi <= (2-yn-v)*j_pmax^2)              
    gm.con[:nw][n][:on_off_control_valve_pressure_drop4][k] = @constraint(gm.model,  pi - pj <= (2-yn-v)*(i_pmax^2))                             
            
    # Old way for bi-directional
    #gm.con[:nw][n][:on_off_control_valve_pressure_drop1][k] = @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-yp-v)*j_pmax^2)              
    #gm.con[:nw][n][:on_off_control_valve_pressure_drop2][k] = @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-yp-v)*(min_ratio^2*i_pmax^2) )
    #gm.con[:nw][n][:on_off_control_valve_pressure_drop3][k] = @constraint(gm.model,  pi - (max_ratio^2*pj) <= (2-yn-v)*i_pmax^2)              
    #gm.con[:nw][n][:on_off_control_valve_pressure_drop4][k] = @constraint(gm.model,  (min_ratio^2*pj) - pi <= (2-yn-v)*(min_ratio^2*j_pmax^2))                             
end

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
         
    if !haskey(gm.con[:nw][n], :source_flow)
        gm.con[:nw][n][:source_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:source_flow][i] = @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) >= 1)              
end

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
   
    yp_ne = gm.var[:nw][n][:yp_ne] 
    yn_ne = gm.var[:nw][n][:yn_ne] 
             
    if !haskey(gm.con[:nw][n], :source_flow_ne)
        gm.con[:nw][n][:source_flow_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:source_flow_ne][i] = @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) + sum(yp_ne[a] for a in f_branches_ne) + sum(yn_ne[a] for a in t_branches_ne) >= 1) 
end

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
          
    if !haskey(gm.con[:nw][n], :sink_flow)
        gm.con[:nw][n][:sink_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:sink_flow][i] = @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) >= 1)              
end

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
    yp_ne = gm.var[:nw][n][:yp_ne] 
    yn_ne = gm.var[:nw][n][:yn_ne] 
          
    if !haskey(gm.con[:nw][n], :sink_flow_ne)
        gm.con[:nw][n][:sink_flow_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:sink_flow_ne][i] = @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) + sum(yn_ne[a] for a in f_branches_ne) + sum(yp_ne[a] for a in t_branches_ne) >= 1)  
end

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::GenericGasModel{T}, n::Int, i, yp_first, yn_first, yp_last, yn_last) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
    
    if !haskey(gm.con[:nw][n], :conserve_flow1)
        gm.con[:nw][n][:conserve_flow1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:conserve_flow2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:conserve_flow3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:conserve_flow4] = Dict{Int,ConstraintRef}()          
    end
        
    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                gm.con[:nw][n][:conserve_flow1][i] = @constraint(gm.model, yn[i1]  == yp[i2])
                gm.con[:nw][n][:conserve_flow2][i] = @constraint(gm.model, yp[i1]  == yn[i2])              
                gm.con[:nw][n][:conserve_flow3][i] = @constraint(gm.model, yn[i1] + yn[i2] == 1)
                gm.con[:nw][n][:conserve_flow4][i] = @constraint(gm.model, yp[i1] + yp[i2] == 1)              
            end 
        end      
    end  
        
    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                gm.con[:nw][n][:conserve_flow1][i] = @constraint(gm.model, yn[i1] == yn[i2])
                gm.con[:nw][n][:conserve_flow2][i] = @constraint(gm.model, yp[i1] == yp[i2])
                gm.con[:nw][n][:conserve_flow3][i] = @constraint(gm.model, yn[i1] + yp[i2] == 1)
                gm.con[:nw][n][:conserve_flow4][i] = @constraint(gm.model, yp[i1] + yn[i2] == 1)              
            end 
        end      
    end  
              
    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                gm.con[:nw][n][:conserve_flow1][i] = @constraint(gm.model, yp[i1]  == yp[i2])
                gm.con[:nw][n][:conserve_flow2][i] = @constraint(gm.model, yn[i1]  == yn[i2]) 
                gm.con[:nw][n][:conserve_flow3][i] = @constraint(gm.model, yp[i1] + yn[i2] == 1)
                gm.con[:nw][n][:conserve_flow4][i] = @constraint(gm.model, yn[i1] + yp[i2] == 1)                
            end 
        end      
    end  
      
    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                gm.con[:nw][n][:conserve_flow1][i] = @constraint(gm.model, yp[i1] == yn[i2])
                gm.con[:nw][n][:conserve_flow2][i] = @constraint(gm.model, yn[i1] == yp[i2])      
                gm.con[:nw][n][:conserve_flow3][i] = @constraint(gm.model, yp[i1] + yp[i2] == 1)
                gm.con[:nw][n][:conserve_flow4][i] = @constraint(gm.model, yn[i1] + yn[i2] == 1)                
            end 
        end      
    end  
end

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow_ne(gm::GenericGasModel{T}, n::Int, idx, yp_first, yn_first, yp_last, yn_last) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
    yp_ne = gm.var[:nw][n][:yp_ne] 
    yn_ne = gm.var[:nw][n][:yn_ne] 

    if !haskey(gm.con[:nw][n], :conserve_flow_ne1)
        gm.con[:nw][n][:conserve_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:conserve_flow_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:conserve_flow_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:conserve_flow_ne4] = Dict{Int,ConstraintRef}()          
    end     
      
    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                yn1 = haskey(gm.ref[:nw][n][:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:nw][n][:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:nw][n][:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:nw][n][:connection],i2) ? yp[i2] : yp_ne[i2]    

                gm.con[:nw][n][:conserve_flow_ne1][idx] = @constraint(gm.model, yn1  == yp2)
                gm.con[:nw][n][:conserve_flow_ne2][idx] = @constraint(gm.model, yp1  == yn2)
                gm.con[:nw][n][:conserve_flow_ne3][idx] = @constraint(gm.model, yn1 + yn2 == 1)
                gm.con[:nw][n][:conserve_flow_ne4][idx] = @constraint(gm.model, yp1 + yp2 == 1)               
            end 
        end      
    end  
        
    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                yn1 = haskey(gm.ref[:nw][n][:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:nw][n][:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:nw][n][:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:nw][n][:connection],i2) ? yp[i2] : yp_ne[i2]    
               
                gm.con[:nw][n][:conserve_flow_ne1][idx] = @constraint(gm.model, yn1 == yn2)
                gm.con[:nw][n][:conserve_flow_ne2][idx] = @constraint(gm.model, yp1 == yp2)
                gm.con[:nw][n][:conserve_flow_ne3][idx] = @constraint(gm.model, yn1 + yp2 == 1)
                gm.con[:nw][n][:conserve_flow_ne4][idx] = @constraint(gm.model, yp1 + yn2 == 1)
            end 
        end      
    end  
              
    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                yn1 = haskey(gm.ref[:nw][n][:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:nw][n][:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:nw][n][:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:nw][n][:connection],i2) ? yp[i2] : yp_ne[i2]    
                
                gm.con[:nw][n][:conserve_flow_ne1][idx] = @constraint(gm.model, yp1 == yp2)
                gm.con[:nw][n][:conserve_flow_ne2][idx] = @constraint(gm.model, yn1 == yn2)
                gm.con[:nw][n][:conserve_flow_ne3][idx] = @constraint(gm.model, yp1 + yn2 == 1)
                gm.con[:nw][n][:conserve_flow_ne4][idx] = @constraint(gm.model, yn1 + yp2 == 1)
            end 
        end      
    end  
      
    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                yn1 = haskey(gm.ref[:nw][n][:connection],i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(gm.ref[:nw][n][:connection],i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(gm.ref[:nw][n][:connection],i1) ? yp[i1] : yp_ne[i1]  
                yp2 = haskey(gm.ref[:nw][n][:connection],i2) ? yp[i2] : yp_ne[i2]    
                
                gm.con[:nw][n][:conserve_flow_ne1][idx] = @constraint(gm.model, yp1 == yn2)
                gm.con[:nw][n][:conserve_flow_ne2][idx] = @constraint(gm.model, yn1 == yp2)
                gm.con[:nw][n][:conserve_flow_ne3][idx] = @constraint(gm.model, yp1 + yp2 == 1)
                gm.con[:nw][n][:conserve_flow_ne4][idx] = @constraint(gm.model, yn1 + yn2 == 1)
            end 
        end      
    end  
end

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
    
    if !haskey(gm.con[:nw][n], :parallel_flow)
        gm.con[:nw][n][:parallel_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:parallel_flow][k] = @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) == yp[k] * length(gm.ref[:nw][n][:parallel_connections][(i,j)]))              
end

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne) where T <: AbstractUndirectedGasFormulation
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
    yp_ne = gm.var[:nw][n][:yp_ne] 
    yn_ne = gm.var[:nw][n][:yn_ne] 
    yp_i = haskey(gm.ref[:nw][n][:connection], k) ? yp[k] : yp_ne[k]   
                                          
    if !haskey(gm.con[:nw][n], :parallel_flow_ne)
        gm.con[:nw][n][:parallel_flow_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:parallel_flow_ne][k] = @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) + sum(yp_ne[i] for i in f_connections_ne) + sum(yn_ne[i] for i in t_connections_ne) == yp_i * length(gm.ref[:nw][n][:all_parallel_connections][(i,j)]))              
end

