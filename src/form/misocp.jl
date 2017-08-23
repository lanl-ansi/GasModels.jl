# Define MISOCP implementations of Gas Models

export 
    MISOCPGasModel, StandardMISOCPForm

""
@compat abstract type AbstractMISOCPForm <: AbstractGasFormulation end

""
@compat abstract type StandardMISOCPForm <: AbstractMISOCPForm end

const MISOCPGasModel = GenericGasModel{StandardMISOCPForm}

"default MISOCP constructor"
MISOCPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMISOCPForm; kwargs...)

"variables associated with the flux squared"
function variable_flux_square{T <: AbstractMISOCPForm}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow] 
    gm.var[:l] = @variable(gm.model, 0 <= l[i in [collect(keys(gm.ref[:pipe])); collect(keys(gm.ref[:resistor])) ]] <= 1/gm.ref[:connection][i]["resistance"] * max_flow^2, start = getstart(gm.ref[:connection], i, "l_start", 0))  
    return gm.var[:l]
end

" variables associated with the flux squared "
function variable_flux_square_ne{T <: AbstractMISOCPForm}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow] 
    gm.var[:l_ne] = @variable(gm.model, 0 <= l_ne[i in keys(gm.ref[:ne_pipe])] <= 1/gm.ref[:ne_connection][i]["resistance"] * max_flow^2, start = getstart(gm.ref[:ne_connection], i, "l_start", 0))  
    return gm.var[:l_ne]
end

" Weymouth equation with discrete direction variables "
function constraint_weymouth{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe_idx)  
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp][pipe_idx] 
    yn = gm.var[:yn][pipe_idx]     
    l  = gm.var[:l][pipe_idx] 
    f  = gm.var[:f][pipe_idx]
            
    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]     
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, pipe["resistance"]*l >= f^2)
      
    return Set([c1, c2, c3, c4, c5])
end

#Weymouth equation with fixed direction
function constraint_weymouth_fixed_direction{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe_idx)  
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = pipe["yp"]
    yn = pipe["yn"]    
    l  = gm.var[:l][pipe_idx] 
    f  = gm.var[:f][pipe_idx] 
            
    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]     
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, pipe["resistance"]*l >= f^2)
      
    return Set([c1, c2, c3, c4, c5])
end


