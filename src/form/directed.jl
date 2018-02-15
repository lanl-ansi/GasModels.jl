################
# Variables
################
  
" variables associated with direction of flow on the connections "
function variable_connection_direction{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int=gm.cnw)
end

" variables associated with direction of flow on the connections "
function variable_connection_direction_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int=gm.cnw)
end

################
# Constraints
################

function constraint_flow_direction_choice{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, i)
end

function constraint_flow_direction_choice_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, i)
end

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max; kwargs...)
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = kwargs[:yp]
    yn = kwargs[:yn]
            
    if !haskey(gm.con[:nw][n], :on_off_pressure_drop1)
        gm.con[:nw][n][:on_off_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pressure_drop2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pressure_drop1][k] = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)              
    gm.con[:nw][n][:on_off_pressure_drop2][k] = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)                          
end

" constraints on pressure drop across pipes when the direction is fixed "
function constraint_on_off_pressure_drop_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max; kwargs...)
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j]
    yp = kwargs[:yp]   
    yn = kwargs[:yn]   
                
    if !haskey(gm.con[:nw][n], :on_off_pressure_drop_ne1)
        gm.con[:nw][n][:on_off_pressure_drop_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pressure_drop_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pressure_drop_ne1][k] = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)             
    gm.con[:nw][n][:on_off_pressure_drop_ne2][k] = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)              
end

" constraints on flow across pipes where the directions are fixed "
function constraint_on_off_pipe_flow_direction{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w; kwargs...)
    kwargs = Dict(kwargs)
    f      = gm.var[:nw][n][:f][k]
    yp     = kwargs[:yp]   
    yn     = kwargs[:yn]   
        
    if !haskey(gm.con[:nw][n], :on_off_pipe_flow_direction1)
        gm.con[:nw][n][:on_off_pipe_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pipe_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pipe_flow_direction1][k] = @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f)
    gm.con[:nw][n][:on_off_pipe_flow_direction2][k] = @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))              
end

" constraints on flow across pipes when directions are fixed "
function constraint_on_off_pipe_flow_direction_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w; kwargs...)
    kwargs = Dict(kwargs)
    f  = gm.var[:nw][n][:f_ne][k] 
    yp = kwargs[:yp]
    yn = kwargs[:yn]
            
    if !haskey(gm.con[:nw][n], :on_off_pipe_flow_direction_ne1)
        gm.con[:nw][n][:on_off_pipe_flow_direction_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pipe_flow_direction_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pipe_flow_direction_ne1][k] = @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f)  
    gm.con[:nw][n][:on_off_pipe_flow_direction_ne2][k] = @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))      
end

" constraints on flow across compressors when directions are constants "
function constraint_on_off_compressor_flow_direction{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
    kwargs = Dict(kwargs)
    f = gm.var[:nw][n][:f][k]
    yp = kwargs[:yp]  
    yn = kwargs[:yn]  
    
    if !haskey(gm.con[:nw][n], :on_off_compressor_flow_direction1)
        gm.con[:nw][n][:on_off_compressor_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_flow_direction1][k] = @constraint(gm.model, -(1-yp)*mf <= f)              
    gm.con[:nw][n][:on_off_compressor_flow_direction2][k] = @constraint(gm.model, f <= (1-yn)*mf)              
end

" constraints on flow across compressors when the directions are constants "
function constraint_on_off_compressor_flow_direction_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
    kwargs = Dict(kwargs)
    f = gm.var[:nw][n][:f_ne][k] 
    yp = kwargs[:yp]  
    yn = kwargs[:yn]  

    if !haskey(gm.con[:nw][n], :on_off_compressor_flow_direction_ne1)
        gm.con[:nw][n][:on_off_compressor_flow_direction_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_flow_direction_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_flow_direction_ne1][k] = @constraint(gm.model, -(1-yp)*mf <= f)
    gm.con[:nw][n][:on_off_compressor_flow_direction_ne2][k] = @constraint(gm.model, f <= (1-yn)*mf) 
end

" on/off constraint for compressors when the flow direction is constant "
function constraint_on_off_compressor_ratios{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin; kwargs...)
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j]
    yp = kwargs[:yp]   
    yn = kwargs[:yn]   
 
    if !haskey(gm.con[:nw][n], :on_off_compressor_ratios1)
        gm.con[:nw][n][:on_off_compressor_ratios1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_compressor_ratios3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_ratios1][k] = @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j_pmax^2 - max_ratio^2*i_pmin^2))              
    gm.con[:nw][n][:on_off_compressor_ratios2][k] = @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(min_ratio^2*i_pmax^2 - j_pmin^2))
    gm.con[:nw][n][:on_off_compressor_ratios3][k] = @constraint(gm.model, pi - max_ratio^2*pj <= (1-yn)*(i_pmax^2 - max_ratio^2*j_pmin^2))              
    gm.con[:nw][n][:on_off_compressor_ratios4][k] = @constraint(gm.model, min_ratio^2*pj - pi <= (1-yn)*(min_ratio^2*j_pmax^2 - i_pmin^2))                             
end

" constraints on flow across short pipes when the directions are constants "
function constraint_on_off_short_pipe_flow_direction{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
    kwargs = Dict(kwargs)
    f = gm.var[:nw][n][:f][k]
    yp = kwargs[:yp]     
    yn = kwargs[:yn]     
    
    if !haskey(gm.con[:nw][n], :on_off_short_pipe_flow_direction1)
        gm.con[:nw][n][:on_off_short_pipe_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_short_pipe_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_short_pipe_flow_direction1][k] = @constraint(gm.model, -max_flow*(1-yp) <= f)              
    gm.con[:nw][n][:on_off_short_pipe_flow_direction2][k] = @constraint(gm.model, f <= max_flow*(1-yn))              
end

" constraints on flow across valves when directions are constants "
function constraint_on_off_valve_flow_direction{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
    kwargs = Dict(kwargs)
    f = gm.var[:nw][n][:f][k] 
    v = gm.var[:nw][n][:v][k]
    yp = kwargs[:yp]
    yn = kwargs[:yn]     
       
    if !haskey(gm.con[:nw][n], :on_off_valve_flow_direction1)
        gm.con[:nw][n][:on_off_valve_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_valve_flow_direction2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_valve_flow_direction1][k] = @constraint(gm.model, -mf*(1-yp) <= f <= mf*(1-yn))              
    gm.con[:nw][n][:on_off_valve_flow_direction2][k] = @constraint(gm.model, -mf*v <= f <= mf*v)              
end

" constraints on flow across control valves when directions are constants "
function constraint_on_off_control_valve_flow_direction{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
    kwargs = Dict(kwargs)
    f = gm.var[:nw][n][:f][k] 
    v = gm.var[:nw][n][:v][k]
    yp = kwargs[:yp]   
    yn = kwargs[:yn]   
  
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

" constraints on pressure drop across control valves when directions are constants "
function constraint_on_off_control_valve_pressure_drop{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax; kwargs...)
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    v = gm.var[:nw][n][:v][k]
    yp = kwargs[:yp]  
    yn = kwargs[:yn]  
        
    if !haskey(gm.con[:nw][n], :on_off_control_valve_pressure_drop1)
        gm.con[:nw][n][:on_off_control_valve_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_pressure_drop2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_control_valve_pressure_drop3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_pressure_drop4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_control_valve_pressure_drop1][k] = @constraint(gm.model,  pj - (max_ratio*pi) <= (2-yp-v)*j_pmax^2)              
    gm.con[:nw][n][:on_off_control_valve_pressure_drop2][k] = @constraint(gm.model,  (min_ratio*pi) - pj <= (2-yp-v)*(min_ratio*i_pmax^2) )
    gm.con[:nw][n][:on_off_control_valve_pressure_drop3][k] = @constraint(gm.model,  pi - (max_ratio*pj) <= (2-yn-v)*i_pmax^2)              
    gm.con[:nw][n][:on_off_control_valve_pressure_drop4][k] = @constraint(gm.model,  (min_ratio*pj) - pi <= (2-yn-v)*(min_ratio*j_pmax^2))                             
end

function constraint_source_flow{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches)
end

function constraint_source_flow_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
end

function constraint_sink_flow{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches)
end

function constraint_sink_flow_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
end

function constraint_conserve_flow{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, i, yp_first, yn_first, yp_last, yn_last)
end

function constraint_conserve_flow_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, idx, yp_first, yn_first, yp_last, yn_last)
end

function constraint_parallel_flow{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections)
end

function constraint_parallel_flow_ne{T <: AbstractDirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne)    
end
