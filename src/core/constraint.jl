######################################:ne_connection####################################################################
# The purpose of this file is to define commonly used and created constraints used in gas flow models
##########################################################################################################

# Constraints that don't need a template

" Constraint that states a flow direction must be chosen "
function constraint_flow_direction_choice{T}(gm::GenericGasModel{T}, n::Int, i)
    yp = gm.var[:nw][n][:yp][i] 
    yn = gm.var[:nw][n][:yn][i] 
              
    if !haskey(gm.con[:nw][n], :flow_direction_choice)
        gm.con[:nw][n][:flow_direction_choice] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:flow_direction_choice][i] = @constraint(gm.model, yp + yn == 1)              
end
constraint_flow_direction_choice(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice(gm, gm.cnw, i)

" Constraint that states a flow direction must be chosen for new edges "
function constraint_flow_direction_choice_ne{T}(gm::GenericGasModel{T}, n::Int, i)
    yp = gm.var[:nw][n][:yp_ne][i] 
    yn = gm.var[:nw][n][:yn_ne][i] 
              
    if !haskey(gm.con[:nw][n], :flow_direction_choice_ne)
        gm.con[:nw][n][:flow_direction_choice_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:flow_direction_choice_ne][i] = @constraint(gm.model, yp + yn == 1)               
end
constraint_flow_direction_choice_ne(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice_ne(gm, gm.cnw, i)

# Constraints with templates

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max; kwargs...)
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

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max; kwargs...)
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

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w; kwargs...)
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

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction_ne{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w; kwargs...)
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

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
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

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction_ne{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
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

" enforces pressure changes bounds that obey compression ratios "
function constraint_on_off_compressor_ratios{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin; kwargs...)
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
    gm.con[:nw][n][:on_off_compressor_ratios1][k] = @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j_pmax^2 - max_ratio^2*i_pmin^2))              
    gm.con[:nw][n][:on_off_compressor_ratios2][k] = @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(min_ratio^2*i_pmax^2 - j_pmin^2))
    gm.con[:nw][n][:on_off_compressor_ratios3][k] = @constraint(gm.model, pi - max_ratio^2*pj <= (1-yn)*(i_pmax^2 - max_ratio^2*j_pmin^2))              
    gm.con[:nw][n][:on_off_compressor_ratios4][k] = @constraint(gm.model, min_ratio^2*pj - pi <= (1-yn)*(min_ratio^2*j_pmax^2 - i_pmin^2))                             
end

" constraints on pressure drop across control valves "
function constraint_on_off_compressor_ratios_ne{T}(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, i_pmax)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp_ne][k] 
    yn = gm.var[:nw][n][:yn_ne][k]     
    zc = gm.var[:nw][n][:zc][k] 
            
    if !haskey(gm.con[:nw][n], :on_off_compressor_ratios_ne1)
        gm.con[:nw][n][:on_off_compressor_ratios_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_compressor_ratios_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_ratios_ne1][k] = @constraint(gm.model,  pj - (max_ratio*pi) <= (2-yp-zc)*j_pmax^2)              
    gm.con[:nw][n][:on_off_compressor_ratios_ne2][k] = @constraint(gm.model,  (min_ratio*pi) - pj <= (2-yp-zc)*(min_ratio*i_pmax^2) )
    gm.con[:nw][n][:on_off_compressor_ratios_ne3][k] = @constraint(gm.model,  pi - (max_ratio*pj) <= (2-yn-zc)*i_pmax^2)              
    gm.con[:nw][n][:on_off_compressor_ratios_ne4][k] = @constraint(gm.model,  (min_ratio*pj) - pi <= (2-yn-zc)*(min_ratio*j_pmax^2))                             
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

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, qgfirm, qlfirm)
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f] 

    if !haskey(gm.con[:nw][n], :junction_flow_balance)
        gm.con[:nw][n][:junction_flow_balance] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_flow_balance][i] = @constraint(gm.model, qgfirm - qlfirm == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) )              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ne{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, qgfirm, qlfirm)
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f] 
    f_ne = gm.var[:nw][n][:f_ne] 
                  
    if !haskey(gm.con[:nw][n], :junction_flow_balance_ne)
        gm.con[:nw][n][:junction_flow_balance_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_flow_balance_ne][i] = @constraint(gm.model, qgfirm - qlfirm == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne) )              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ls{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, ql_firm, qg_firm, qlmin, qlmax, qgmin, qgmax)
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f] 
    ql = 0
    qg = 0
    if qlmin != qlmax
        ql = gm.var[:nw][n][:ql][i] 
    end
    if qgmin != qgmax   
        qg = gm.var[:nw][n][:qg][i] 
    end
   
    if !haskey(gm.con[:nw][n], :junction_flow_balance_ls)
        gm.con[:nw][n][:junction_flow_balance_ls] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_flow_balance_ls][i] = @constraint(gm.model, qg_firm - ql_firm + qg - ql == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) )              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ne_ls{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, qlmin, qlmax, qgmin, qgmax, ql_firm, qg_firm)  
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f] 
    f_ne = gm.var[:nw][n][:f_ne] 
    
    ql = 0
    qg = 0
    if qlmin != qlmax
        ql = gm.var[:nw][n][:ql][i] 
    end
    if qgmin != qgmax
        qg = gm.var[:nw][n][:qg][i] 
    end
        
    if !haskey(gm.con[:nw][n], :junction_flow_balance_ne_ls)
        gm.con[:nw][n][:junction_flow_balance_ne_ls] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_flow_balance_ne_ls][i] = @constraint(gm.model, qg_firm - ql_firm + qg - ql == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne) )              
end

" constraints on flow across short pipes "
function constraint_on_off_short_pipe_flow_direction{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
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

" constraints on pressure drop across pipes "
function constraint_short_pipe_pressure_drop{T}(gm::GenericGasModel{T}, n::Int, k, i, j)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 

    if !haskey(gm.con[:nw][n], :short_pipe_pressure_drop)
        gm.con[:nw][n][:short_pipe_pressure_drop] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:short_pipe_pressure_drop][k] = @constraint(gm.model,  pi == pj)              
end

" constraints on flow across valves "
function constraint_on_off_valve_flow_direction{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
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

" constraints on pressure drop across valves "
function constraint_on_off_valve_pressure_drop{T}(gm::GenericGasModel{T}, n::Int, k, i, j, i_pmax, j_pmax)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 

    v = gm.var[:nw][n][:v][k] 

    if !haskey(gm.con[:nw][n], :on_off_valve_pressure_drop1)
        gm.con[:nw][n][:on_off_valve_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_valve_pressure_drop2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_valve_pressure_drop1][k] = @constraint(gm.model,  pj - ((1-v)*j_pmax^2) <= pi)              
    gm.con[:nw][n][:on_off_valve_pressure_drop2][k] = @constraint(gm.model,  pi <= pj + ((1-v)*i_pmax^2))              
end

" constraints on flow across control valves "
function constraint_on_off_control_valve_flow_direction{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...)
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

" constraints on pressure drop across control valves "
function constraint_on_off_control_valve_pressure_drop{T <: AbstractUndirectedGasFormulation}(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax; kwargs...)
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
    gm.con[:nw][n][:on_off_control_valve_pressure_drop1][k] = @constraint(gm.model,  pj - (max_ratio*pi) <= (2-yp-v)*j_pmax^2)              
    gm.con[:nw][n][:on_off_control_valve_pressure_drop2][k] = @constraint(gm.model,  (min_ratio*pi) - pj <= (2-yp-v)*(min_ratio*i_pmax^2) )
    gm.con[:nw][n][:on_off_control_valve_pressure_drop3][k] = @constraint(gm.model,  pi - (max_ratio*pj) <= (2-yn-v)*i_pmax^2)              
    gm.con[:nw][n][:on_off_control_valve_pressure_drop4][k] = @constraint(gm.model,  (min_ratio*pj) - pi <= (2-yn-v)*(min_ratio*j_pmax^2))                             
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

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches)
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
         
    if !haskey(gm.con[:nw][n], :source_flow)
        gm.con[:nw][n][:source_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:source_flow][i] = @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) >= 1)              
end

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
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
function constraint_sink_flow{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches)
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
          
    if !haskey(gm.con[:nw][n], :sink_flow)
        gm.con[:nw][n][:sink_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:sink_flow][i] = @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) >= 1)              
end

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne{T}(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
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
function constraint_conserve_flow{T}(gm::GenericGasModel{T}, n::Int, i, yp_first, yn_first, yp_last, yn_last)
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
function constraint_conserve_flow_ne{T}(gm::GenericGasModel{T}, n::Int, idx, yp_first, yn_first, yp_last, yn_last)
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
function constraint_parallel_flow{T}(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections)
    yp = gm.var[:nw][n][:yp] 
    yn = gm.var[:nw][n][:yn] 
    
    if !haskey(gm.con[:nw][n], :parallel_flow)
        gm.con[:nw][n][:parallel_flow] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:parallel_flow][k] = @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) == yp[k] * length(gm.ref[:nw][n][:parallel_connections][(i,j)]))              
end

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne{T}(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne)    
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

" on/off constraints on flow across pipes for expansion variables "
function constraint_on_off_pipe_flow_ne{T}(gm::GenericGasModel{T}, n::Int, k, w, mf, pd_min, pd_max)
    zp = gm.var[:nw][n][:zp][k] 
    f  = gm.var[:nw][n][:f_ne][k] 
          
    if !haskey(gm.con[:nw][n], :on_off_pipe_flow_ne1)
        gm.con[:nw][n][:on_off_pipe_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pipe_flow_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pipe_flow_ne1][k] = @constraint(gm.model, f <= zp*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))              
    gm.con[:nw][n][:on_off_pipe_flow_ne2][k] = @constraint(gm.model, f >= -zp*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))              
end

" on/off constraints on flow across compressors for expansion variables "
function constraint_on_off_compressor_flow_ne{T}(gm::GenericGasModel{T},  n::Int, k, mf)
    zc = gm.var[:nw][n][:zc][k] 
    f = gm.var[:nw][n][:f][k] 
    
    if !haskey(gm.con[:nw][n], :on_off_compressor_flow_ne1)
        gm.con[:nw][n][:on_off_compressor_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_flow_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_flow_ne1][k] = @constraint(gm.model, -mf*zc <= f)              
    gm.con[:nw][n][:on_off_compressor_flow_ne2][k] = @constraint(gm.model, f <= mf*zc)              
end

" This function ensures at most one pipe in parallel is selected "
function constraint_exclusive_new_pipes{T}(gm::GenericGasModel{T},  n::Int, i, j, parallel)  
    zp = gm.var[:nw][n][:zp]             
    if !haskey(gm.con[:nw][n], :exclusive_new_pipes)
        gm.con[:nw][n][:exclusive_new_pipes] = Dict{Any,ConstraintRef}()
    end    
    gm.con[:nw][n][:exclusive_new_pipes][(i,j)] = @constraint(gm.model, sum(zp[i] for i in parallel) <= 1)              
end

"compressor rations have on off for direction and expansion"
function constraint_new_compressor_ratios_ne{T}(gm::GenericGasModel{T},  n::Int, k, i, j, min_ratio, max_ratio, p_mini, p_maxi, p_minj, p_maxj)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    zc = gm.var[:nw][n][:zc][k] 
            
    if !haskey(gm.con[:nw][n], :new_compressor_ratios_ne1)
        gm.con[:nw][n][:new_compressor_ratios_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:new_compressor_ratios_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:new_compressor_ratios_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:new_compressor_ratios_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:new_compressor_ratios_ne1][c_idx] = @constraint(gm.model, pj - (max_ratio^2*pi) <= (2-yp-zc)*p_maxj^2)              
    gm.con[:nw][n][:new_compressor_ratios_ne2][c_idx] = @constraint(gm.model, (min_ratio^2*pi) - pj <= (2-yp-zc)*(min_ratio^2*p_maxi^2 - p_minj^2))
    gm.con[:nw][n][:new_compressor_ratios_ne3][c_idx] = @constraint(gm.model, pi - (max_ratio^2*pj) <= (2-yn-zc)*p_maxi^2)              
    gm.con[:nw][n][:new_compressor_ratios_ne4][c_idx] = @constraint(gm.model, (min_ratio^2*pj) - pi <= (2-yn-zc)*(min_ratio^2*p_maxj^2 - p_mini^2))                               
end