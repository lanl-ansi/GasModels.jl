##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

"extracts the start value"
function getstart(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)
end

" variables associated with pressure squared "
function variable_pressure_sqr(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    if bounded
        gm.var[:nw][n][:p] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], basename="$(n)_p", lowerbound=gm.ref[:nw][n][:junction][i]["pmin"]^2, upperbound=gm.ref[:nw][n][:junction][i]["pmax"]^2, start = getstart(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))
    else
        gm.var[:nw][n][:p] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], basename="$(n)_p", start = getstart(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))
    end
end

" variables associated with mass flow "
function variable_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    if bounded
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="$(n)_f", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))
    else
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="$(n)_f", start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))
    end
end

" variables associated with mass flow in expansion planning "
function variable_mass_flow_ne(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    if bounded
         gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="$(n)_f_ne", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))
    else
         gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="$(n)_f_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))
    end
end

" variables associated with building pipes "
function variable_pipe_ne(gm::GenericGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zp] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_pipe])], category = :Bin, basename="$(n)_zp", lowerbound=0, upperbound=1, start = getstart(gm.ref[:nw][n][:ne_connection], l, "zp_start", 0.0))
end

" variables associated with building compressors "
function variable_compressor_ne(gm::GenericGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zc] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_compressor])], category = :Bin,basename="$(n)_zc", lowerbound=0, upperbound=1, start = getstart(gm.ref[:nw][n][:ne_connection], l, "zc_start", 0.0))
end

" 0-1 variables associated with operating valves "
function variable_valve_operation(gm::GenericGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:v] = @variable(gm.model, [l in [collect(keys(gm.ref[:nw][n][:valve])); collect(keys(gm.ref[:nw][n][:control_valve]))]], category = :Bin, basename="$(n)_v", lowerbound=0, upperbound=1, start = getstart(gm.ref[:nw][n][:connection], l, "v_start", 1.0))
end

" variables associated with demand "
function variable_load_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    load_set = collect(keys(Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["dispatchable"] == 1)))
    if bounded
        gm.var[:nw][n][:fl] = @variable(gm.model, [i in load_set], basename="$(n)_fl", lowerbound=calc_flmin(gm.data, gm.ref[:nw][n][:consumer][i]), upperbound=calc_flmax(gm.data, gm.ref[:nw][n][:consumer][i]), start = getstart(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    else
        gm.var[:nw][n][:fl] = @variable(gm.model, [i in load_set], basename="$(n)_fl", start = getstart(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    end
end

" variables associated with production "
function variable_production_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    prod_set = collect(keys(Dict(x for x in ref(gm,n,:producer) if x.second["dispatchable"] == 1)))
    if bounded
        gm.var[:nw][n][:fg] = @variable(gm.model, [i in prod_set], basename="$(n)_fg", lowerbound=calc_fgmin(gm.data, gm.ref[:nw][n][:producer][i]), upperbound=calc_fgmax(gm.data, gm.ref[:nw][n][:producer][i]), start = getstart(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    else
        gm.var[:nw][n][:fg] = @variable(gm.model, [i in prod_set], basename="$(n)_fg", start = getstart(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    end
end

" variables associated with direction of flow on the connections. yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction "
function variable_connection_direction(gm::GenericGasModel, n::Int=gm.cnw; connection=gm.ref[:nw][n][:connection])
    gm.var[:nw][n][:yp] = @variable(gm.model, [l in keys(connection)], category = :Bin, basename="$(n)_yp", lowerbound=0, upperbound=1, start = getstart(connection, l, "yp_start", 1.0))
    gm.var[:nw][n][:yn] = @variable(gm.model, [l in keys(connection)], category = :Bin, basename="$(n)_yn", lowerbound=0, upperbound=1, start = getstart(connection, l, "yn_start", 0.0))
end

" variables associated with direction of flow on the connections yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction "
function variable_connection_direction_ne(gm::GenericGasModel, n::Int=gm.cnw; ne_connection=gm.ref[:nw][n][:ne_connection])
     gm.var[:nw][n][:yp_ne] = @variable(gm.model, [l in keys(ne_connection)], category = :Bin, basename="$(n)_yp_ne", lowerbound=0, upperbound=1, start = getstart(ne_connection, l, "yp_start", 1.0))
     gm.var[:nw][n][:yn_ne] = @variable(gm.model, [l in keys(ne_connection)], category = :Bin, basename="$(n)_yn_ne", lowerbound=0, upperbound=1, start = getstart(ne_connection, l, "yn_start", 0.0))
end
