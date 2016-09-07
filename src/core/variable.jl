##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

# extracts the start value from data,
function getstart(set, item_key, value_key, default = 0.0)
    try
        return set[item_key][value_key]
    catch
        return default
    end
end

# variables associated with pressure squared
function variable_pressure_sqr{T}(gm::GenericGasModel{T}; bounded = true)
    if bounded
        @variable(gm.model, gm.set.junctions[i]["pmin"]^2 <= p[i in gm.set.junction_indexes] <= gm.set.junctions[i]["pmax"]^2, start = getstart(pm.set.junctions, i, "p_start", gm.set.junctions[i]["pmin"]^2))
    else
        @variable(gm.model, p[i in gm.set.junction_indexes] >= 0, start = getstart(pm.set.junctions, i, "p_start", gm.set.junctions[i]["pmin"]^2))
    end
    return p
end

# variables associated with flux
function variable_flux{T}(gm::GenericGasModel{T}; bounded = true)
    if bounded
        max_flow = sum{ gm.set.junctions[i]["qmax"], i in gm.set.junction_indexes : gm.set.junctions[i]["qmax"] > 0}
        @variable(gm.model, -max_flow <= f[i in gm.set.connection_indexes] <= max_flow, start = getstart(pm.set.connections, i, "f_start", 0))
    else
        @variable(gm.model, f[i in gm.set.connection_indexes], start = getstart(pm.set.connections, i, "f_start", 0))
    end
    return f
end

# variables associated with direction of flow on the connections
function variable_connection_direction{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= yp[l in gm.set.connection_indexes] <= 1, Int, start = getstart(gm.set.connections, l, "yp_start", 1.0))
    @variable(gm.model, 0 <= yn[l in gm.set.connection_indexes] <= 1, Int, start = getstart(gm.set.connections, l, "yn_start", 0.0))      
    return yp, yn
end

# variables associated with the flux squared
function variable_flux_square{T}(gm::GenericGasModel{T}; bounded = true)
    if bounded
        max_flow = sum{ gm.set.junctions[i]["qmax"], i in gm.set.junction_indexes : gm.set.junctions[i]["qmax"] > 0}
        @variable(gm.model, -max_flow^2 <= l[i in gm.set.pipe_indexes,gm.set.resistor_indexes] <= max_flow^2, start = getstart(pm.set.connections, i, "l_start", 0))
    else
        @variable(gm.model, l[i in gm.set.connection_indexes], start = getstart(pm.set.connections, i, "l_start", 0))
    end
     return l
end


# variables associated with building pipes
function variable_pipe_expansion{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= zp[l in pm.set.new_pipes] <= 1, Int, start = getstart(pm.set.connections, l, "zp_start", 0.0))
    return zp
end

# variables associated with building compressors
function variable_compressor_expansion{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= zc[l in pm.set.new_compressors] <= 1, Int, start = getstart(pm.set.connections, l, "zc_start", 0.0))
    return zc
end

# 0-1 variables associated with operating valves
function variable_valve_operation{T}(gm::GenericGasModel{T})
    @variable(gm.model, 0 <= v[l in pm.set.valve_indexes, pm.set.control_valve_indexes] <= 1, Int, start = getstart(pm.set.connections, l, "v_start", 1.0))
    return v
end
