##########################################################################################################
# The purpose of this file is to define commonly used and created constraints used in gas flow models
##########################################################################################################


# Constraint that states a flow direction must be chosen
function constraint_flow_direction_choice{T}(gm::GenericGasModel{T}, connection)
    i = connection["index"]

    yp = getvariable(gm.model, :yp)[i]
    yn = getvariable(gm.model, :yn)[i]
              
    c = @constraint(gm.model, yp + yn == 1)
    return Set([c])
end

# constraints on pressure drop across pipes
function constraint_on_off_pressure_drop{T}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = getvariable(gm.model, :yp)[pipe_idx]
    yn = getvariable(gm.model, :yn)[pipe_idx]
  
    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]

    c = @constraint(gm.model, (1-yp)*connection["pd_min"] <= pi - pj <= (1-yn)*connection["pd_max"])
    return Set([c])  
end

# constraints on flow across pipes
function constraint_on_off_pipe_flow_direction{T}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = getvariable(gm.model, :yp)[pipe_idx]
    yn = getvariable(gm.model, :yn)[pipe_idx]
    f = getvariable(gm.model, :f)[pipe_idx]
    
    max_flow = gm.data["max_flow"]
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    w = pipe["resistance"]  
    
    c = @constraint(gm.model, -(1-yp)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))) <= f <= (1-yn)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))      
    return Set([c])    
end

# constraints on flow across compressors
function constraint_on_off_compressor_flow_direction{T}(gm::GenericGasModel{T}, compressor)
    c_idx = compressor["index"]
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    yp = getvariable(gm.model, :yp)[c_idx]
    yn = getvariable(gm.model, :yn)[c_idx]
    f = getvariable(gm.model, :f)[c_idx]

    c = @constraint(gm.model, -(1-yp)*data["max_flow"] <= f <= (1-yn)*gm.data["max_flow"])
    return Set([c])      
end 

# enforces pressure changes bounds that obey compression ratios
function constraint_on_off_compressor_ratios{T}(gm::GenericGasModel{T}, compressor)
    c_idx = compressor["index"]
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
      
    i = gm.data.junctions[i_junction_idx]  
    j = gm.data.junctions[j_junction_idx]  

    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]
    yp = getvariable(gm.model, :yp)[c_idx]
    yn = getvariable(gm.model, :yn)[c_idx]
    

    c1 = @constraint(gm.model, pj - compressor["max_ratio"]^2*pi <= (1-yp)*(j["p_max"]^2 - compressor["max_ratio"]^2*i["p_min"]^2))
    c2 = @constraint(gm.model, compressor["min_ratio"]^2*pi - pj <= (1-yp)*(compressor["min_ratio"]^2*i["p_max"]^2 - j["p_min"]^2))
    c3 = @constraint(gm.model, pi - compressor["max_ratio"]^2*pj <= (1-yn)*(i["p_max"]^2 - compressor["max_ratio"]^2*j["p_min"]^2))
    c4 = @constraint(gm.model, compressor["min_ratio"]^2*pj - pi <= (1-yn)*(compressor["min_ratio"]^2*j["p_max"]^2 - i["p_min"]^2))
          
    return Set([c1,c2,c3,c4])          
end

# standard flow balance equation where demand and production is fixed
function constraint_junction_flow_balance{T}(gm::GenericGasModel{T}, junction)
    i = junction["index"]
    junction_branches = pm.set.junction_branches[i]
    
    f_branches = filter(a -> gm.set.connection_lookup[a]["f_junction"] == i)
    t_branches = filter(a -> gm.set.connection_lookup[a]["t_junction"] == i)
      
    v = getvariable(pm.model, :v)
    p = getvariable(pm.model, :p)
    pg = getvariable(pm.model, :pg)

    c = @constraint(gm.model, junction["qmax"] == sum{f[a], a in f_branches} - sum{f[a], a in t_branches} )
                  
    return Set([c])
end

# constraints on flow across short pipes
function constraint_on_off_short_pipe_flow_direction{T}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp = getvariable(gm.model, :yp)[pipe_idx]
    yn = getvariable(gm.model, :yn)[pipe_idx]
    f = getvariable(gm.model, :f)[pipe_idx]
  
    c = @constraint(gm.model, -gm.data["max_flow"]*(1-yp) <= f <= gm.data["max_flow"]*(1-yn))
    return Set([c])    
end

# constraints on pressure drop across pipes
function constraint_short_pipe_pressure_drop{T}(gm::GenericGasModel{T}, pipe)
    pipe_idx = pipe["index"]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]

    c = @constraint(gm.model,  pi == pj)
    return Set([c])  
end

# constraints on flow across valves
function constraint_on_off_valve_flow_direction{T}(gm::GenericGasModel{T}, valve)
    valve_idx = valve["index"]
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]

    yp = getvariable(gm.model, :yp)[valve_idx]
    yn = getvariable(gm.model, :yn)[valve_idx]
    f = getvariable(gm.model, :f)[valve_idx]
    v = getvariable(gm.model, :v)[valve_idx]
        
    c1 = @constraint(gm.model, -gm.data["max_flow"]*(1-yp) <= f <= gm.data["max_flow"]*(1-yn))
    c2 = @constraint(gm.model, -gm.data["max_flow"]*v <= f <= gm.data["max_flow"]*v)
      
    return Set([c1, c2])    
end

# constraints on pressure drop across valves
function constraint_on_off_valve_pressure_drop{T}(gm::GenericGasModel{T}, valve)
    valve_idx = valve["index"]
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]
  
    i = gm.data.junctions[i_junction_idx]  
    j = gm.data.junctions[j_junction_idx]  
        
    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]

    v = getvariable(gm.model, :v)[valve_idx]
    c = @constraint(gm.model,  pj - ((1-v)*j["p_max"]^2) <= pi <= pj + ((1-v)*i["p_max"]^2))
    return Set([c])  
end

# constraints on flow across control valves
function constraint_on_off_valve_flow_direction{T}(gm::GenericGasModel{T}, valve)
    valve_idx = valve["index"]
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]

    yp = getvariable(gm.model, :yp)[valve_idx]
    yn = getvariable(gm.model, :yn)[valve_idx]
    f = getvariable(gm.model, :f)[valve_idx]
    v = getvariable(gm.model, :v)[valve_idx]
    
    max_flow = gm.data["max_flow"]

    c1 = @constraint(gm.model, -max_flow*(1-yp) <= f <= max_flow*(1-yn))
    c2 = @constraint(gm.model, -max_flow*v <= f <= max_flow*v)
      
    return Set([c1, c2])    
end

# constraints on pressure drop across control valves
function constraint_on_off_control_valve_pressure_drop{T}(gm::GenericGasModel{T}, valve)
    valve_idx = valve["index"]
    i_junction_idx = valve["f_junction"]
    j_junction_idx = valve["t_junction"]
  
    i = gm.data.junctions[i_junction_idx]  
    j = gm.data.junctions[j_junction_idx]  
        
    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]
    yp = getvariable(gm.model, :yp)[valve_idx]
    yn = getvariable(gm.model, :yn)[valve_idx]
    
    v = getvariable(gm.model, :v)[valve_idx]
    
    c1 = @constraint(gm.model,  pj - (valve["max_ratio"]*pi) <= (2-yp-v)*j["p_max"]^2)
    c2 = @constraint(gm.model,  (valve["min_ratio"]*pi) - pj <= (2-yp-v)*(valve["min_ratio"]*i["p_min"]^2) )
    c3 = @constraint(gm.model,  pi - (valve["max_ratio"]*pj) <= (2-yn-v)*i["p_max"]^2)
    c4 = @constraint(gm.model,  (valve["min_ratio"]*pj) - pi <= (2-yn-v)*(valve["min_ratio"]*j["p_min"]^2))
    
    return Set([c1, c2, c3, c4])  
end

# Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes)
function constraint_source_flow{T}(gm::GenericGasModel{T}, junction)
    f_branches = filter(a -> gm.set.connection_lookup[a]["f_junction"] == junction["index"])
    t_branches = filter(a -> gm.set.connection_lookup[a]["t_junction"] == junction["index"]) 
  
    c = @constraint(gm.model, sum{yp[a], a in f_branches} + sum{yn[a], a in t_branches} >= 1)
    return Set([c])  
end

# Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes)
function constraint_sink_flow{T}(gm::GenericGasModel{T}, junction)
    f_branches = filter(a -> gm.set.connection_lookup[a]["f_junction"] == junction["index"])
    t_branches = filter(a -> gm.set.connection_lookup[a]["t_junction"] == junction["index"]) 
  
    c = @constraint(gm.model, sum{yn[a], a in f_branches} + sum{yp[a], a in t_branches} >= 1)
    return Set([c])  
end

# This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption
function constraint_conserve_flow{T}(gm::GenericGasModel{T}, junction)
    idx = junction["index"]
    first = nothing
    last = nothing
    
    for i in gm.sets.junction_connections[idx] 
        connection = gm.sets.connection_lookup[i]
        if connection["f_junction"] == idx
            other = connection["t_junction"]
        else
            other = connection["f_junction"]
        end
        
        if first == nothing
            first = other
        elseif first != other
            last = other    
        end      
    end
    
    f_branches_first = filter(i -> i in gm.sets.junction_connections[idx] && gm.set.connection_lookup[i]["f_junction"] == first)
    t_branches_first = filter(i -> i in gm.sets.junction_connections[idx] && gm.set.connection_lookup[i]["f_junction"] == first)
    t_branches_last  = filter(i -> i in gm.sets.junction_connections[idx] && gm.set.connection_lookup[i]["t_junction"] == last)
    f_branches_last  = filter(i -> i in gm.sets.junction_connections[idx] && gm.set.connection_lookup[i]["f_junction"] == last)
    
        
    c = @constraint(gm.model, sum{yp[i], i in f_branches_first} + sum{yn[i], i in t_branches_first} == sum{yp[i], i in t_branches_last} + sum{yn[i], i in f_branches_last})     
    return Set([c])  
end

# ensures that parallel lines have flow in the same direction
function constraint_parallel_flow{T}(gm::GenericGasModel{T}, connection)
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])
    idx = connection["index"]
    
    f_connections = filter(i -> i in gm.sets.parallel_connections[(i,j)] && gm.connection_lookup[i]["f_junction"] == connection["f_junction"])
    t_connections = filter(i -> gm.sets.parallel_connections[(i,j)] && gm.connection_lookup[i]["f_junction"] != connection["f_junction"])
                           
    c = @constraint(gm.model, sum{yp[i], i in f_connections} + sum{yn[i], i in t_connections} == yp[idx] * size(gm.sets.parallel_connections[(i,j)]))
    return Set([c])    
end

