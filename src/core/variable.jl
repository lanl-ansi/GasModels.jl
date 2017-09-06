##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

"extracts the start value"
function getstart(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)      
end

" variables associated with pressure squared "
function variable_pressure_sqr{T}(gm::GenericGasModel{T})
    gm.var[:p] = @variable(gm.model, [i in keys(gm.ref[:junction])], basename="p", lowerbound=gm.ref[:junction][i]["pmin"]^2, upperbound=gm.ref[:junction][i]["pmax"]^2, start = getstart(gm.ref[:junction], i, "p_start", gm.ref[:junction][i]["pmin"]^2))
end

" variables associated with flux "
function variable_flux{T}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow]
    gm.var[:f] = @variable(gm.model, [i in keys(gm.ref[:connection])], basename="f", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:connection], i, "f_start", 0))                  
end

" variables associated with flux in expansion planning "
function variable_flux_ne{T}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow]
    gm.var[:f_ne] = @variable(gm.model, [i in keys(gm.ref[:ne_connection])], basename="f_ne", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:ne_connection], i, "f_start", 0))                        
end

" variables associated with direction of flow on the connections "
function variable_connection_direction{T}(gm::GenericGasModel{T})
    gm.var[:yp] = @variable(gm.model, [l in keys(gm.ref[:connection])], category = :Int, basename="yp", lowerbound=0, upperbound=1, start = getstart(gm.ref[:connection], l, "yp_start", 1.0))                  
    gm.var[:yn] = @variable(gm.model, [l in keys(gm.ref[:connection])], category = :Int, basename="yn", lowerbound=0, upperbound=1, start = getstart(gm.ref[:connection], l, "yn_start", 0.0))                  
end

" variables associated with direction of flow on the connections "
function variable_connection_direction_ne{T}(gm::GenericGasModel{T})
     gm.var[:yp_ne] = @variable(gm.model, [l in keys(gm.ref[:ne_connection])], category = :Int,basename="yp_ne", lowerbound=0, upperbound=1, start = getstart(gm.ref[:ne_connection], l, "yp_start", 1.0))                  
     gm.var[:yn_ne] = @variable(gm.model, [l in keys(gm.ref[:ne_connection])], category = :Int, basename="yn_ne", lowerbound=0, upperbound=1, start = getstart(gm.ref[:ne_connection], l, "yn_start", 0.0))                  
end

" variables associated with building pipes "
function variable_pipe_ne{T}(gm::GenericGasModel{T})
    gm.var[:zp] = @variable(gm.model, [l in keys(gm.ref[:ne_pipe])], category = :Int, basename="zp", lowerbound=0, upperbound=1, start = getstart(gm.ref[:ne_connection], l, "zp_start", 0.0))                  
end

" variables associated with building compressors "
function variable_compressor_ne{T}(gm::GenericGasModel{T})
    gm.var[:zc] = @variable(gm.model, [l in keys(gm.ref[:ne_compressor])], category = :Int,basename="zc", lowerbound=0, upperbound=1, start = getstart(gm.ref[:ne_connection], l, "zc_start", 0.0))                  
end

" 0-1 variables associated with operating valves "
function variable_valve_operation{T}(gm::GenericGasModel{T})
    gm.var[:v] = @variable(gm.model, [l in [collect(keys(gm.ref[:valve])); collect(keys(gm.ref[:control_valve]))]], category = :Int, basename="v", lowerbound=0, upperbound=1, start = getstart(gm.ref[:connection], l, "v_start", 1.0))                  
end

" variables associated with demand "
function variable_load{T}(gm::GenericGasModel{T})
    load_set = filter(i -> gm.ref[:junction][i]["qlmin"] != gm.ref[:junction][i]["qlmax"], collect(keys(gm.ref[:junction])))    
    gm.var[:ql] = @variable(gm.model, [i in load_set], basename="ql", lowerbound=gm.ref[:junction][i]["qlmin"], upperbound=gm.ref[:junction][i]["qlmax"], start = getstart(gm.ref[:junction], i, "ql_start", 0.0))                  
end

" variables associated with production "
function variable_production{T}(gm::GenericGasModel{T})
    prod_set = filter(i -> gm.ref[:junction][i]["qgmin"] != gm.ref[:junction][i]["qgmax"], collect(keys(gm.ref[:junction])))        
    gm.var[:qg] = @variable(gm.model, [i in prod_set], basename="qg", lowerbound=gm.ref[:junction][i]["qgmin"], upperbound=gm.ref[:junction][i]["qgmax"], start = getstart(gm.ref[:junction], i, "qg_start", 0.0))                  
end
