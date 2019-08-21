##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

"extracts the start value"
function getstart(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)
end

" variables associated with pressure squared "
function variable_pressure_sqr(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractGasFormulation
    if bounded
        gm.var[:nw][n][:p] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], base_name="$(n)_p", lower_bound=gm.ref[:nw][n][:junction][i]["pmin"]^2, upper_bound=gm.ref[:nw][n][:junction][i]["pmax"]^2, start = getstart(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))
    else
        gm.var[:nw][n][:p] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], base_name="$(n)_p", start = getstart(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))
    end
end

" variables associated with mass flow "
function variable_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    if bounded
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], base_name="$(n)_f", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))
    else
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))
    end
end

" variables associated with mass flow in expansion planning "
function variable_mass_flow_ne(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    if bounded
         gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], base_name="$(n)_f_ne", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))
    else
         gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], base_name="$(n)_f_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))
    end
end

" variables associated with building pipes "
function variable_pipe_ne(gm::GenericGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zp] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_pipe])], binary=true, base_name="$(n)_zp", start = getstart(gm.ref[:nw][n][:ne_connection], l, "zp_start", 0.0))
end

" variables associated with building compressors "
function variable_compressor_ne(gm::GenericGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zc] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_compressor])], binary=true, base_name="$(n)_zc", start = getstart(gm.ref[:nw][n][:ne_connection], l, "zc_start", 0.0))
end

" 0-1 variables associated with operating valves "
function variable_valve_operation(gm::GenericGasModel{T}, n::Int=gm.cnw) where T <: AbstractGasFormulation
    gm.var[:nw][n][:v] = @variable(gm.model, [l in [collect(keys(gm.ref[:nw][n][:valve])); collect(keys(gm.ref[:nw][n][:control_valve]))]], binary=true, base_name="$(n)_v", start = getstart(gm.ref[:nw][n][:connection], l, "v_start", 1.0))
end

" variables associated with demand "
function variable_load_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    load_set = collect(keys(Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["qlmax"] != 0 || x.second["qlmin"] != 0)))
    if bounded
        gm.var[:nw][n][:fl] = @variable(gm.model, [i in load_set], base_name="$(n)_fl", lower_bound=calc_flmin(gm.data, gm.ref[:nw][n][:consumer][i]), upper_bound=calc_flmax(gm.data, gm.ref[:nw][n][:consumer][i]), start = getstart(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    else
        gm.var[:nw][n][:fl] = @variable(gm.model, [i in load_set], base_name="$(n)_fl", start = getstart(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    end
end

" variables associated with production "
function variable_production_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    prod_set = collect(keys(Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qgmax"] != 0 || x.second["qgmin"] != 0)))
    if bounded
        gm.var[:nw][n][:fg] = @variable(gm.model, [i in prod_set], base_name="$(n)_fg", lower_bound=calc_fgmin(gm.data, gm.ref[:nw][n][:producer][i]), upper_bound=calc_fgmax(gm.data, gm.ref[:nw][n][:producer][i]), start = getstart(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    else
        gm.var[:nw][n][:fg] = @variable(gm.model, [i in prod_set], base_name="$(n)_fg", start = getstart(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    end
end

" variables associated with direction of flow on the connections. yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction "
function variable_connection_direction(gm::GenericGasModel{T}, n::Int=gm.cnw; connection=gm.ref[:nw][n][:connection]) where T <: AbstractGasFormulation
    gm.var[:nw][n][:yp] = @variable(gm.model, [l in keys(connection)], binary=true, base_name="$(n)_yp", start = getstart(connection, l, "yp_start", 1.0))
    gm.var[:nw][n][:yn] = @variable(gm.model, [l in keys(connection)], binary=true, base_name="$(n)_yn", start = getstart(connection, l, "yn_start", 0.0))
end

" variables associated with direction of flow on the connections yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction "
function variable_connection_direction_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; ne_connection=gm.ref[:nw][n][:ne_connection]) where T <: AbstractGasFormulation
     gm.var[:nw][n][:yp_ne] = @variable(gm.model, [l in keys(ne_connection)], binary=true, base_name="$(n)_yp_ne", start = getstart(ne_connection, l, "yp_start", 1.0))
     gm.var[:nw][n][:yn_ne] = @variable(gm.model, [l in keys(ne_connection)], binary=true, base_name="$(n)_yn_ne", start = getstart(ne_connection, l, "yn_start", 0.0))
end

"Variable Set: Define variables needed for modeling flow across connections"
function variable_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow(gm,n; bounded=bounded)
end

"Variable Set: Define variables needed for modeling flow across connections where some flows are directionally constrained"
function variable_flow_directed(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow(gm,n; bounded=bounded)
end

"Variable Set: Define variables needed for modeling flow across connections that are expansions"
function variable_flow_ne(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow_ne(gm,n; bounded=bounded)
end

"Variable Set: Define variables needed for modeling flow across connections that are expansions and some flows are directionally constrained"
function variable_flow_ne_directed(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow_ne(gm,n; bounded=bounded)
end
