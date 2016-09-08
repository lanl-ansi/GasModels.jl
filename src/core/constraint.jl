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
  
    c = @constraint(gm.model, -(1-yp)*min(gm.data["max_flow"], sqrt(pipe["resistance"]*max(pipe["pd_max"], abs(pipe["pd_min"])))) <= f <= (1-yn)*min(gm.data["max_flow"], sqrt(pipe["resistance"]*max(pipe["pd_max"], abs(pipe["pd_min"])))
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
    bus_gens = pm.set.bus_gens[i]

    v = getvariable(pm.model, :v)
    p = getvariable(pm.model, :p)
    pg = getvariable(pm.model, :pg)

    c = @constraint(gm.model, bus["qmax"] == sum{f[a], a in junction_branches && gm.set.connection_lookup[a]["f_junction"] == i} - sum{f[a], a in junction_branches && gm.set.connection_lookup[a]["t_junction"] == i} )
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
    c = @constraint(gm.model,  pj - ((1-v)*j["p_max"]^2) <= pi <= pj + ((1-v)*i["p_max"]^2)
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

    c1 = @constraint(gm.model, -gm.data["max_flow"]*(1-yp) <= f <= gm.data["max_flow"]*(1-yn)
    c2 = @constraint(gm.model, -gm.data["max_flow"]*v <= f <= gm.data["max_flow"]*v)
      
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




#MISCOP constraints

# Expansion
subject to exclusive {id in new_pid}: sum{(id0,i,j) in parallel[id] diff orig_pipes} zp[id0] + zp[id] <= 1;


######## MIP Cuts ########
subject to source_flow{i in nodes: ql[i] > 0}: sum{(id,i,j) in lines diff new_pipes_in_parallel_with_existing_lines} yp[id,i,j] + sum{(id,j,i) in lines diff new_pipes} yn[id,j,i] >= 1;
subject to sink_flow{i in nodes: ql[i] < 0}: sum{(id,j,i) in lines diff new_pipes_in_parallel_with_existing_lines} yp[id,j,i] + sum{(id,i,j) in lines diff new_pipes} yn[id,i,j] >= 1;
subject to cons_flow{i in nodes: deg[i]==2 && ql[i]==0}: sum{(id,j,i) in lines diff new_pipes: j == first(neighb[i])} yp[id,j,i] + sum{(id,i,j) in lines diff new_pipes: j == first(neighb[i])} yn[id,i,j] == sum{(id,i,j) in lines diff new_pipes: j == last(neighb[i])} yp[id,i,j] + sum{(id,j,i) in lines diff new_pipes: j == last(neighb[i])} yn[id,j,i];
subject to parallel_dir {(id,i,j) in lines}: sum{(id0,i,j) in parallel_all[id]} yp[id0,i,j] = (card(parallel_all[id]))*yp[id,i,j];
  
### SOC only???  
subject to lbound_l{(id,i,j) in ALLpipes}: l[id,i,j] >= -1/w[id]*(max_flow)^2;
subject to ubound_l{(id,i,j) in ALLpipes}: l[id,i,j] <= 1/w[id]*(max_flow)^2;
######## McCormick ########
subject to flow_dir_M1{(id,i,j) in ALLpipes}: l[id,i,j] >= p[j] - p[i] + pd_min[id,i,j]*(yp[id,i,j] - yn[id,i,j] + 1);
subject to flow_dir_M2{(id,i,j) in ALLpipes}: l[id,i,j] >= p[i] - p[j] + pd_max[id,i,j]*(yp[id,i,j] - yn[id,i,j] - 1);
subject to flow_dir_M3{(id,i,j) in ALLpipes}: l[id,i,j] <= p[j] - p[i] + pd_max[id,i,j]*(yp[id,i,j] - yn[id,i,j] + 1);
subject to flow_dir_M4{(id,i,j) in ALLpipes}: l[id,i,j] <= p[i] - p[j] + pd_min[id,i,j]*(yp[id,i,j] - yn[id,i,j] - 1);

######## SOCP Flow  ########
subject to conv_flow {(id,i,j) in orig_pipes}: w[id]*l[id,i,j] >= f[id,i,j]^2;
subject to on_off_flow {(id,i,j) in new_pipes}: zp[id]*w[id]*l[id,i,j] >= f[id,i,j]^2;



  
  
  #MINLP constraints
  



subject to exclusive {id in new_pid}: sum{(id0,i,j) in parallel[id] diff orig_pipes} zp[id0] + zp[id] <= 1;


######## MIP Cuts ########
subject to source_flow{i in nodes: ql[i] > 0}: sum{(id,i,j) in lines diff new_pipes_in_parallel_with_existing_lines} yp[id,i,j] + sum{(id,j,i) in lines diff new_pipes} yn[id,j,i] >= 1;
subject to sink_flow{i in nodes: ql[i] < 0}: sum{(id,j,i) in lines diff new_pipes_in_parallel_with_existing_lines} yp[id,j,i] + sum{(id,i,j) in lines diff new_pipes} yn[id,i,j] >= 1;
subject to cons_flow{i in nodes: deg[i]==2 && ql[i]==0}: sum{(id,j,i) in lines diff new_pipes: j == first(neighb[i])} yp[id,j,i] + sum{(id,i,j) in lines diff new_pipes: j == first(neighb[i])} yn[id,i,j] == sum{(id,i,j) in lines diff new_pipes: j == last(neighb[i])} yp[id,i,j] + sum{(id,j,i) in lines diff new_pipes: j == last(neighb[i])} yn[id,j,i];
subject to parallel_dir {(id,i,j) in lines}: sum{(id0,i,j) in parallel_all[id]} yp[id0,i,j] = (card(parallel_all[id]))*yp[id,i,j];




######## Non-Convex flow Constraints ########
subject to flowp {(id,i,j) in orig_pipes}: w[id]*(p[i] - p[j]) >= f[id,i,j]^2 - (1-yp[id,i,j])*max_flow^2;
subject to flowp_ {(id,i,j) in orig_pipes}: w[id]*(p[i] - p[j]) <= f[id,i,j]^2 + (1-yp[id,i,j])*max_flow^2;
subject to flown {(id,i,j) in orig_pipes}: w[id]*(p[j] - p[i]) >= f[id,i,j]^2 - (1-yn[id,i,j])*max_flow^2;
subject to flown_ {(id,i,j) in orig_pipes}: w[id]*(p[j] - p[i]) <= f[id,i,j]^2 + (1-yn[id,i,j])*max_flow^2;

subject to flow_newp {(id,i,j) in new_pipes}: w[id]*(p[i] - p[j]) >= f[id,i,j]^2 - (2 - yp[id,i,j] - zp[id])*max_flow^2;
subject to flow_newp_ {(id,i,j) in new_pipes}: w[id]*(p[i] - p[j]) <= f[id,i,j]^2 + (2 - yp[id,i,j] - zp[id])*max_flow^2;
subject to flow_newn {(id,i,j) in new_pipes}: w[id]*(p[j] - p[i]) >= f[id,i,j]^2 - (2 - yn[id,i,j] - zp[id])*max_flow^2;
subject to flow_newn_ {(id,i,j) in new_pipes}: w[id]*(p[j] - p[i]) <= f[id,i,j]^2 + (2 - yn[id,i,j] - zp[id])*max_flow^2;



  
  
  
   
  
  