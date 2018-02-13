# Define MINLP implementations of Gas Models

export 
    MINLPGasModel, StandardMINLPForm
""
@compat abstract type AbstractMINLPForm <: AbstractGasFormulation end

""
@compat abstract type StandardMINLPForm <: AbstractMINLPForm end

const MINLPGasModel = GenericGasModel{StandardMINLPForm}

"default MINLP constructor"
MINLPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMINLPForm; kwargs...)

"Weymouth equation with discrete direction variables "
function constraint_weymouth{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, n::Int, pipe_idx, i_junction_idx, j_junction_idx, max_flow, w, pd_min, pd_max)
    pi = gm.var[:nw][n][:p][i_junction_idx] 
    pj = gm.var[:nw][n][:p][j_junction_idx] 
    yp = gm.var[:nw][n][:yp][pipe_idx] 
    yn = gm.var[:nw][n][:yn][pipe_idx] 
    f  = gm.var[:nw][n][:f][pipe_idx] 
        
    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*max_flow^2)
    
   if !haskey(gm.con[:nw][n], :weymouth1)
        gm.con[:nw][n][:weymouth1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:weymouth1][pipe_idx] = c1              
    gm.con[:nw][n][:weymouth2][pipe_idx] = c2
    gm.con[:nw][n][:weymouth3][pipe_idx] = c3              
    gm.con[:nw][n][:weymouth4][pipe_idx] = c4                               
end

"Weymouth equation with fixed direction variables"
function constraint_weymouth_fixed_direction{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, n::Int, pipe_idx, i_junction_idx, j_junction_idx, max_flow, w, pd_min, pd_max, yp, yn)
    pi = gm.var[:nw][n][:p][i_junction_idx] 
    pj = gm.var[:nw][n][:p][j_junction_idx] 
    f  = gm.var[:nw][n][:f][pipe_idx] 
           
    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*max_flow^2)
    
   if !haskey(gm.con[:nw][n], :weymouth_fixed_direction1)
        gm.con[:nw][n][:weymouth_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_fixed_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:weymouth_fixed_direction1][pipe_idx] = c1              
    gm.con[:nw][n][:weymouth_fixed_direction2][pipe_idx] = c2
    gm.con[:nw][n][:weymouth_fixed_direction3][pipe_idx] = c3              
    gm.con[:nw][n][:weymouth_fixed_direction4][pipe_idx] = c4                               
end

" Weymouth equation with discrete direction variables for MINLP "
function constraint_weymouth_ne{T <: AbstractMINLPForm}(gm::GenericGasModel{T},  n::Int, pipe_idx, i_junction_idx, j_junction_idx, w, max_flow, pd_min, pd_max)
    pi = gm.var[:nw][n][:p][i_junction_idx] 
    pj = gm.var[:nw][n][:p][j_junction_idx] 
    yp = gm.var[:nw][n][:yp_ne][pipe_idx] 
    zp = gm.var[:nw][n][:zp][pipe_idx] 
    yn = gm.var[:nw][n][:yn_ne][pipe_idx] 
    f  = gm.var[:nw][n][:f_ne][pipe_idx] 
          
    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*max_flow^2)
               
    if !haskey(gm.con[:nw][n], :weymouth_ne1)
        gm.con[:nw][n][:weymouth_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:weymouth_ne1][pipe_idx] = c1              
    gm.con[:nw][n][:weymouth_ne2][pipe_idx] = c2
    gm.con[:nw][n][:weymouth_ne3][pipe_idx] = c3              
    gm.con[:nw][n][:weymouth_ne4][pipe_idx] = c4                               
end

"Weymouth equation with fixed directions for MINLP"
function constraint_weymouth_ne_fixed_direction{T <: AbstractMINLPForm}(gm::GenericGasModel{T},  n::Int, pipe_idx, i_junction_idx, j_junction_idx, w, max_flow, pd_min, pd_max, yp, yn)
    pi = gm.var[:nw][n][:p][i_junction_idx] 
    pj = gm.var[:nw][n][:p][j_junction_idx] 
    zp = gm.var[:nw][n][:zp][pipe_idx] 
    f  = gm.var[:nw][n][:f_ne][pipe_idx] 
        
    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*max_flow^2)
               
    if !haskey(gm.con[:nw][n], :weymouth_ne_fixed_direction1)
        gm.con[:nw][n][:weymouth_ne_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_ne_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne_fixed_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:weymouth_ne_fixed_direction1][pipe_idx] = c1              
    gm.con[:nw][n][:weymouth_ne_fixed_direction2][pipe_idx] = c2
    gm.con[:nw][n][:weymouth_ne_fixed_direction3][pipe_idx] = c3              
    gm.con[:nw][n][:weymouth_ne_fixed_direction4][pipe_idx] = c4                               
end
