##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

# extracts the start value from data,
function getstart(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)      
    #try
         
#        return set[item_key][value_key]
    #catch
     #   return default
    #end
end

# variables associated with pressure squared
function variable_pressure_sqr{T}(gm::GenericGasModel{T})
    @variable(gm.model, gm.ref[:junction][i]["pmin"]^2 <= p_gas[i in keys(gm.ref[:junction])] <= gm.ref[:junction][i]["pmax"]^2, start = getstart(gm.ref[:junction], i, "p_start", gm.ref[:junction][i]["pmin"]^2))
    return p_gas
end

# variables associated with flux
function variable_flux{T}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow]
    @variable(gm.model, -max_flow <= f[i in keys(gm.ref[:connection])] <= max_flow, start = getstart(gm.ref[:connection], i, "f_start", 0))
    return f
end

# variables associated with flux in expansion planning
function variable_flux_ne{T}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow]
    @variable(gm.model, -max_flow <= f_ne[i in keys(gm.ref[:ne_connection])] <= max_flow, start = getstart(gm.ref[:ne_connection], i, "f_start", 0))
    return f_ne
end

# variables associated with direction of flow on the connections
function variable_connection_direction{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= yp[l in keys(gm.ref[:connection])] <= 1, Int, start = getstart(gm.ref[:connection], l, "yp_start", 1.0))
    @variable(gm.model, 0 <= yn[l in keys(gm.ref[:connection])] <= 1, Int, start = getstart(gm.ref[:connection], l, "yn_start", 0.0))      
    return yp, yn
end

# variables associated with direction of flow on the connections
function variable_connection_direction_ne{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= yp_ne[l in keys(gm.ref[:ne_connection])] <= 1, Int, start = getstart(gm.ref[:ne_connection], l, "yp_start", 1.0))
    @variable(gm.model, 0 <= yn_ne[l in keys(gm.ref[:ne_connection])] <= 1, Int, start = getstart(gm.ref[:ne_connection], l, "yn_start", 0.0))      
    return yp_ne, yn_ne
end

# variables associated with building pipes
function variable_pipe_ne{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= zp[l in keys(gm.ref[:ne_pipe])] <= 1, Int, start = getstart(gm.ref[:ne_connection], l, "zp_start", 0.0))
    return zp
end

# variables associated with building compressors
function variable_compressor_ne{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= zc[l in keys(gm.ref[:ne_compressor])] <= 1, Int, start = getstart(gm.ref[:ne_connection], l, "zc_start", 0.0))
    return zc
end

# 0-1 variables associated with operating valves
function variable_valve_operation{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= valve[l in [collect(keys(gm.ref[:valve])); collect(keys(gm.ref[:control_valve]))]] <= 1, Int, start = getstart(gm.ref[:connection], l, "v_start", 1.0))
    return valve
end

# variables associated with demand
function variable_load{T}(gm::GenericGasModel{T})
    load_set = filter(i -> gm.ref[:junction][i]["qlmin"] != gm.ref[:junction][i]["qlmax"], collect(keys(gm.ref[:junction])))    
    @variable(gm.model, gm.ref[:junction][i]["qlmin"] <= ql_gas[i in load_set] <= gm.ref[:junction][i]["qlmax"], start = getstart(gm.ref[:junction], i, "ql_start", 0.0))   
    return ql_gas
end

# variables associated with production
function variable_production{T}(gm::GenericGasModel{T})
    prod_set = filter(i -> gm.ref[:junction][i]["qgmin"] != gm.ref[:junction][i]["qgmax"], collect(keys(gm.ref[:junction])))        
    @variable(gm.model, gm.ref[:junction][i]["qgmin"] <= qg_gas[i in prod_set] <= gm.ref[:junction][i]["qgmax"], start = getstart(gm.ref[:junction], i, "qg_start", 0.0))  
    return qg_gas
end
