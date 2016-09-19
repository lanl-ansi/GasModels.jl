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
    
    pd_min = pipe["pd_min"]
    pd_max = pipe["pd_max"]

      
    c1 = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)
    c2 = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)
    
        
    return Set([c1,c2])  
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
    
    c1 = @constraint(gm.model, -(1-yp)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))) <= f)      
    c2 = @constraint(gm.model, f <= (1-yn)*min(max_flow, sqrt(w*max(pd_max, abs(pd_min)))))      
         
    return Set([c1, c2])    
end

# constraints on flow across compressors
function constraint_on_off_compressor_flow_direction{T}(gm::GenericGasModel{T}, compressor)
    c_idx = compressor["index"]
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]

    yp = getvariable(gm.model, :yp)[c_idx]
    yn = getvariable(gm.model, :yn)[c_idx]
    f = getvariable(gm.model, :f)[c_idx]

    c1 = @constraint(gm.model, -(1-yp)*gm.data["max_flow"] <= f)
    c2 = @constraint(gm.model, f <= (1-yn)*gm.data["max_flow"])
            
    return Set([c1, c2])      
end 

# enforces pressure changes bounds that obey compression ratios
function constraint_on_off_compressor_ratios{T}(gm::GenericGasModel{T}, compressor)
    c_idx = compressor["index"]
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
      
    i = gm.set.junctions[i_junction_idx]  
    j = gm.set.junctions[j_junction_idx]  

    pi = getvariable(gm.model, :p)[i_junction_idx]
    pj = getvariable(gm.model, :p)[j_junction_idx]
    yp = getvariable(gm.model, :yp)[c_idx]
    yn = getvariable(gm.model, :yn)[c_idx]
    
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]

    c1 = @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j["pmax"]^2 - max_ratio^2*i["pmin"]^2))
    c2 = @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(min_ratio^2*i["pmax"]^2 - j["pmin"]^2))
    c3 = @constraint(gm.model, pi - max_ratio^2*pj <= (1-yn)*(i["pmax"]^2 - max_ratio^2*j["pmin"]^2))
    c4 = @constraint(gm.model, min_ratio^2*pj - pi <= (1-yn)*(min_ratio^2*j["pmax"]^2 - i["pmin"]^2))
          
    return Set([c1,c2,c3,c4])          
end

# standard flow balance equation where demand and production is fixed
function constraint_junction_flow_balance{T}(gm::GenericGasModel{T}, junction)
    i = junction["index"]
    junction_branches = gm.set.junction_connections[i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.set.connections)))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.set.connections)))
      
    v = getvariable(gm.model, :v)
    p = getvariable(gm.model, :p)
    f = getvariable(gm.model, :f)

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
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == junction["index"], gm.set.connections)))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == junction["index"], gm.set.connections))) 

    yp = getvariable(gm.model, :yp)
    yn = getvariable(gm.model, :yn)
         
    c = @constraint(gm.model, sum{yp[a], a in f_branches} + sum{yn[a], a in t_branches} >= 1)
    return Set([c])  
end

# Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes)
function constraint_sink_flow{T}(gm::GenericGasModel{T}, junction)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == junction["index"], gm.set.connections)))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == junction["index"], gm.set.connections))) 

    yp = getvariable(gm.model, :yp)
    yn = getvariable(gm.model, :yn)
          
    c = @constraint(gm.model, sum{yn[a], a in f_branches} + sum{yp[a], a in t_branches} >= 1)
    return Set([c])  
end

# This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption
function constraint_conserve_flow{T}(gm::GenericGasModel{T}, junction)
    idx = junction["index"]
    first = nothing
    last = nothing
    
    for i in gm.set.junction_connections[idx] 
        connection = gm.set.connections[i]
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
    
    yp_first = filter(i -> gm.set.connections[i]["f_junction"] == first, gm.set.junction_connections[idx])
    yn_first = filter(i -> gm.set.connections[i]["t_junction"] == first, gm.set.junction_connections[idx])
    yp_last  = filter(i -> gm.set.connections[i]["t_junction"] == last,  gm.set.junction_connections[idx])
    yn_last  = filter(i -> gm.set.connections[i]["f_junction"] == last,  gm.set.junction_connections[idx])
    
    yp = getvariable(gm.model, :yp)
    yn = getvariable(gm.model, :yn)
                
    c =  Set([])           
    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
              c1 = @constraint(gm.model, yn[i1]  == yp[i2])
              c = Set([c;c1])
            end 
        end      
    end  
      
  
   if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
              c1 = @constraint(gm.model, yn[i1] == yn[i2])
              c = Set([c;c1])              
            end 
        end      
    end  
              
    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
              c1 = @constraint(gm.model, yp[i1]  == yp[i2])
              c = Set([c;c1])              
            end 
        end      
    end  
      
    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
              c1 = @constraint(gm.model, yp[i1] == yn[i2])
              c = Set([c;c1])              
            end 
        end      
    end  


    return c      
end

# ensures that parallel lines have flow in the same direction
function constraint_parallel_flow{T}(gm::GenericGasModel{T}, connection)
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])
    idx = connection["index"]
    
    f_connections = filter(i -> gm.set.connections[i]["f_junction"] == connection["f_junction"], gm.set.parallel_connections[(i,j)])
    t_connections = filter(i -> gm.set.connections[i]["f_junction"] != connection["f_junction"], gm.set.parallel_connections[(i,j)])

    yp = getvariable(gm.model, :yp)
    yn = getvariable(gm.model, :yn)
                                  
    c = @constraint(gm.model, sum{yp[i], i in f_connections} + sum{yn[i], i in t_connections} == yp[idx] * length(gm.set.parallel_connections[(i,j)]))
    return Set([c])    
end

