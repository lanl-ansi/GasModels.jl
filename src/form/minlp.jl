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

#Weymouth equation with discrete direction variables
function constraint_weymouth{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = getindex(gm.model, :p_gas)[i_junction_idx]
    pj = getindex(gm.model, :p_gas)[j_junction_idx]
    yp = getindex(gm.model, :yp)[pipe_idx]
    yn = getindex(gm.model, :yn)[pipe_idx]
    f  = getindex(gm.model, :f)[pipe_idx]
        
    max_flow = gm.ref[:max_flow]
    w = pipe["resistance"]

    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*max_flow^2)
    
    return Set([c1, c2, c3, c4])
  
end

#Weymouth equation with fixed direction variables
function constraint_weymouth_fixed_direction{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe_idx)
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.ref[:junction][i_junction_idx]  
    j = gm.ref[:junction][j_junction_idx]  
        
    pi = getindex(gm.model, :p_gas)[i_junction_idx]
    pj = getindex(gm.model, :p_gas)[j_junction_idx]
    yp = pipe["yp"]
    yn = pipe["yn"]
    f  = getindex(gm.model, :f)[pipe_idx]
        
    max_flow = gm.ref[:max_flow]
    w = pipe["resistance"]

    c1 = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*max_flow^2)
    c2 = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*max_flow^2)
    c3 = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*max_flow^2)
    c4 = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*max_flow^2)
    
    return Set([c1, c2, c3, c4])
  
end



