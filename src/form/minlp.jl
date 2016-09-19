# Define MINLP implementations of Gas Models

export 
    MINLPGasModel, StandardMINLPForm

abstract AbstractMINLPForm <: AbstractGasFormulation

type StandardMINLPForm <: AbstractMINLPForm end
typealias MINLPGasModel GenericGasModel{StandardMINLPForm}

# default MINLP constructor
function MINLPGasModel(data::Dict{AbstractString,Any}; kwargs...)
    return GenericGasModel(data, StandardMINLPForm(); kwargs...)
end


#Weymouth equation with discrete direction variables
function constraint_weymouth{T <: AbstractMINLPForm}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.data.junctions[i_junction_idx]  
    j = gm.data.junctions[j_junction_idx]  
        
    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]
    yp = getvariable(gm.model, :yp)[pipe_idx]
    yn = getvariable(gm.model, :yn)[pipe_idx]
    f  = getvariable(gm.model, :f)[pipe_idx]
    
    max_flow = gm.data["max_flow"]

    c1 = @constraint(gm.model, pipe["resistance"]*(pi - pj) >= f^2 - (1-yp)*max_flow^2)
    c2 = @constraint(gm.model, pipe["resistance"]*(pi - pj) <= f^2 + (1-yp)*max_flow^2)
    c3 = @constraint(gm.model, pipe["resistance"]*(pj - pi) >= f^2 - (1-yn)*max_flow^2)
    c4 = @constraint(gm.model, pipe["resistance"]*(pj - pi) <= f^2 + (1-yn)*max_flow^2)
        
    return Set([c1, c2, c3, c4])
  
end


