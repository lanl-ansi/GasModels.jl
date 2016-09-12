# Define MISOCP implementations of Gas Models

export 
    MISOCPGasModel, StandardMISOCPForm

abstract AbstractMISCOPForm <: AbstractGasFormulation

type StandardMISOCPForm <: AbstractMISOCPForm end
typealias MISOCPGasModel GenericGasModel{StandardMISOCPForm}

# default MISOCP constructor
function MISOCPPowerModel(data::Dict{AbstractString,Any}; kwargs...)
    return GenericGasModel(data, StandardMISOCPForm(); kwargs...)
end


# variables associated with flux, the second order cone adds the relaxed variation of flux squared to get the second order cone constraint
function variable_flux{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}; bounded = true)
    if bounded
        max_flow = gm.data["max_flow"]
        @variable(gm.model, -max_flow <= f[i in gm.set.connection_indexes] <= max_flow, start = getstart(pm.set.connections, i, "f_start", 0))
        @variable(gm.model, 0 <= l[i in gm.set.connection_indexes] <= 1/gm.set.connection_lookup[i]["resistance"]*(max_flow)^2, start = getstart(pm.set.connections, i, "l_start", 0))  
    else
        @variable(gm.model, f[i in gm.set.connection_indexes], start = getstart(pm.set.connections, i, "f_start", 0))
        @variable(gm.model, 0 <= l[i in gm.set.connection_indexes], start = getstart(pm.set.connections, i, "l_start", 0))          
    end
    return f,l
end



#Weymouth equation with discrete direction variables
function constraint_weymouth{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    i = gm.data.junctions[i_junction_idx]  
    j = gm.data.junctions[j_junction_idx]  
        
    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]
    yp = getvariable(gm.model, :yp)[pipe_idx]
    yn = getvariable(gm.model, :yn)[pipe_idx]
    l  = getvariable(gm.model, :l)[pipe_idx]
    
    pd_max = i["p_max"]^2 - j["p_min"]^2;
    pd_min = i["p_min"]^2 - j["p_max"]^2;    
    max_flow = gm.data["max_flow"]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, pipe["resistance"]*l >= f^2)
            
    return Set([c1, c2, c3, c4, c5])
  
end


