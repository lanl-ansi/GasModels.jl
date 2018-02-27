##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

"extracts the start value"
function getstart(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)      
end

" variables associated with pressure squared "
function variable_pressure_sqr{T}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    if bounded
        gm.var[:nw][n][:p] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], basename="$(n)_p", lowerbound=gm.ref[:nw][n][:junction][i]["pmin"]^2, upperbound=gm.ref[:nw][n][:junction][i]["pmax"]^2, start = getstart(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))
    else
        gm.var[:nw][n][:p] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], basename="$(n)_p", start = getstart(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))      
    end
end

" variables associated with flux "
function variable_flux{T}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_flow]
    if bounded  
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="$(n)_f", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))                  
    else
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="$(n)_f", start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))                  
    end
end

" variables associated with flux in expansion planning "
function variable_flux_ne{T}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_flow]
    if bounded  
         gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="$(n)_f_ne", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))
    else
         gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="$(n)_f_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))      
    end                       
end

" variables associated with building pipes "
function variable_pipe_ne{T}(gm::GenericGasModel{T}, n::Int=gm.cnw)
    gm.var[:nw][n][:zp] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_pipe])], category = :Bin, basename="$(n)_zp", lowerbound=0, upperbound=1, start = getstart(gm.ref[:nw][n][:ne_connection], l, "zp_start", 0.0))                  
end

" variables associated with building compressors "
function variable_compressor_ne{T}(gm::GenericGasModel{T}, n::Int=gm.cnw)
    gm.var[:nw][n][:zc] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_compressor])], category = :Bin,basename="$(n)_zc", lowerbound=0, upperbound=1, start = getstart(gm.ref[:nw][n][:ne_connection], l, "zc_start", 0.0))                  
end

" 0-1 variables associated with operating valves "
function variable_valve_operation{T}(gm::GenericGasModel{T}, n::Int=gm.cnw)
    gm.var[:nw][n][:v] = @variable(gm.model, [l in [collect(keys(gm.ref[:nw][n][:valve])); collect(keys(gm.ref[:nw][n][:control_valve]))]], category = :Bin, basename="$(n)_v", lowerbound=0, upperbound=1, start = getstart(gm.ref[:nw][n][:connection], l, "v_start", 1.0))                  
end

" variables associated with demand "
function variable_load{T}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    load_set = filter(i -> gm.ref[:nw][n][:consumer][i]["qlmax"] != 0 || gm.ref[:nw][n][:consumer][i]["qlmin"] != 0, collect(keys(gm.ref[:nw][n][:consumer])))
    if bounded       
        gm.var[:nw][n][:ql] = @variable(gm.model, [i in load_set], basename="$(n)_ql", lowerbound=gm.ref[:nw][n][:consumer][i]["qlmin"], upperbound=gm.ref[:nw][n][:consumer][i]["qlmax"], start = getstart(gm.ref[:nw][n][:consumer], i, "ql_start", 0.0))                  
    else
        gm.var[:nw][n][:ql] = @variable(gm.model, [i in load_set], basename="$(n)_ql", start = getstart(gm.ref[:nw][n][:consumer], i, "ql_start", 0.0))                        
    end
end

" variables associated with production "
function variable_production{T}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    prod_set = filter(i -> gm.ref[:nw][n][:producer][i]["qgmax"] != 0 || gm.ref[:nw][n][:producer][i]["qgmin"] != 0, collect(keys(gm.ref[:nw][n][:producer])))
    if bounded          
        gm.var[:nw][n][:qg] = @variable(gm.model, [i in prod_set], basename="$(n)_qg", lowerbound=gm.ref[:nw][n][:producer][i]["qgmin"], upperbound=gm.ref[:nw][n][:producer][i]["qgmax"], start = getstart(gm.ref[:nw][n][:producer], i, "qg_start", 0.0))                  
    else
        gm.var[:nw][n][:qg] = @variable(gm.model, [i in prod_set], basename="$(n)_qg", start = getstart(gm.ref[:nw][n][:producer], i, "qg_start", 0.0))                        
    end
end
