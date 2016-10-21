# Define MISOCP implementations of Gas Models

export 
    MISOCPGasModel, StandardMISOCPForm

abstract AbstractMISOCPForm <: AbstractGasFormulation

type StandardMISOCPForm <: AbstractMISOCPForm end
typealias MISOCPGasModel GenericGasModel{StandardMISOCPForm}

# default MISOCP constructor
function MISOCPGasModel(data::Dict{AbstractString,Any}; kwargs...)
    return GenericGasModel(data, StandardMISOCPForm(); kwargs...)
end

# variables associated with the flux squared
function variable_flux_square{T <: AbstractMISOCPForm}(gm::GenericGasModel{T})
    max_flow = gm.data["max_flow"] 
    @variable(gm.model, 0 <= l[i in [gm.set.pipe_indexes; gm.set.resistor_indexes]] <= 1/gm.set.connections[i]["resistance"] * max_flow^2, start = getstart(gm.set.connections, i, "l_start", 0))  
    return l
end

# variables associated with the flux squared
function variable_flux_square_ne{T <: AbstractMISOCPForm}(gm::GenericGasModel{T})
    max_flow = gm.data["max_flow"] 
    @variable(gm.model, 0 <= l_ne[i in gm.set.new_pipe_indexes] <= 1/gm.set.new_connections[i]["resistance"] * max_flow^2, start = getstart(gm.set.new_connections, i, "l_start", 0))  
    return l_ne
end

#Weymouth equation with discrete direction variables
function constraint_weymouth{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe)
  
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    pi = getvariable(gm.model, :p_gas)[i_junction_idx]
    pj = getvariable(gm.model, :p_gas)[j_junction_idx]
    yp = getvariable(gm.model, :yp)[pipe_idx]
    yn = getvariable(gm.model, :yn)[pipe_idx]    
    l  = getvariable(gm.model, :l)[pipe_idx]
    f  = getvariable(gm.model, :f)[pipe_idx]
            
    pd_max = pipe["pd_max"] #i["pmax"]^2 - j["pmin"]^2;
    pd_min = pipe["pd_min"] # i["pmin"]^2 - j["pmax"]^2;    
    max_flow = gm.data["max_flow"]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, pipe["resistance"]*l >= f^2)
      
    return Set([c1, c2, c3, c4, c5])
end


