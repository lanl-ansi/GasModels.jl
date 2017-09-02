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

"variables associated with the flux squared"
function variable_flux_square{T <: AbstractMINLPForm}(gm::GenericGasModel{T}; bounded = true)
end

""
function variable_flux_square_ne{T <: AbstractMINLPForm}(gm::GenericGasModel{T}; bounded = true)
end

 "Weymouth equation with discrete direction variables "
function constraint_weymouth{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp][pipe_idx] 
    yn = gm.var[:yn][pipe_idx] 
    f  = gm.var[:f][pipe_idx] 
        
    max_flow = gm.ref[:max_flow]
    w = pipe["resistance"]

    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*max_flow^2)
    
   if !haskey(gm.constraint, :weymouth1)
        gm.constraint[:weymouth1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:weymouth1][pipe_idx] = c1              
    gm.constraint[:weymouth2][pipe_idx] = c2
    gm.constraint[:weymouth3][pipe_idx] = c3              
    gm.constraint[:weymouth4][pipe_idx] = c4                               
end

"Weymouth equation with fixed direction variables"
function constraint_weymouth_fixed_direction{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = pipe["yp"]
    yn = pipe["yn"]
    f  = gm.var[:f][pipe_idx] 
        
    max_flow = gm.ref[:max_flow]
    w = pipe["resistance"]

    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*max_flow^2)
    
   if !haskey(gm.constraint, :weymouth_fixed_direction1)
        gm.constraint[:weymouth_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_fixed_direction4] = Dict{Int,ConstraintRef}()          
    end    
    gm.constraint[:weymouth_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:weymouth_fixed_direction2][pipe_idx] = c2
    gm.constraint[:weymouth_fixed_direction3][pipe_idx] = c3              
    gm.constraint[:weymouth_fixed_direction4][pipe_idx] = c4                               
end



