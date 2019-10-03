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
        gm.var[:nw][n][:f_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_f_pipe", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_compressor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_f_compressor", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:compressor], i, "f_start", 0))
        gm.var[:nw][n][:f_resistor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_f_resistor", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:resistor], i, "f_start", 0))
        gm.var[:nw][n][:f_short_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:short_pipe])], base_name="$(n)_f_short_pipe", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:short_pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_valve] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:valve])], base_name="$(n)_f_valve", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:valve], i, "f_start", 0))
        gm.var[:nw][n][:f_control_valve] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:control_valve])], base_name="$(n)_f_control_valve", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:control_valve], i, "f_start", 0))
    else
        gm.var[:nw][n][:f_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_compressor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:compressor], i, "f_start", 0))
        gm.var[:nw][n][:f_resistor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:resistor], i, "f_start", 0))
        gm.var[:nw][n][:f_short_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:short_pipe])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:short_pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_valve] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:valve])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:valve], i, "f_start", 0))
        gm.var[:nw][n][:f_control_valve] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:control_valve])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:control_valve], i, "f_start", 0))
    end
end

" variables associated with mass flow in expansion planning "
function variable_mass_flow_ne(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    if bounded
         gm.var[:nw][n][:f_ne_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_f_ne", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:ne_pipe], i, "f_start", 0))
         gm.var[:nw][n][:f_ne_compressor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_compressor])], base_name="$(n)_f_ne", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:ne_compressor], i, "f_start", 0))
    else
         gm.var[:nw][n][:f_ne_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_f_ne", start = getstart(gm.ref[:nw][n][:ne_pipe], i, "f_start", 0))
         gm.var[:nw][n][:f_ne_compressor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_compressor])], base_name="$(n)_f_ne", start = getstart(gm.ref[:nw][n][:ne_compressor], i, "f_start", 0))

    end
end

" variables associated with building pipes "
function variable_pipe_ne(gm::GenericGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zp] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_pipe])], binary=true, base_name="$(n)_zp", start = getstart(gm.ref[:nw][n][:ne_pipe], l, "zp_start", 0.0))
end

" variables associated with building compressors "
function variable_compressor_ne(gm::GenericGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zc] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_compressor])], binary=true, base_name="$(n)_zc", start = getstart(gm.ref[:nw][n][:ne_compressor], l, "zc_start", 0.0))
end

" 0-1 variables associated with operating valves "
function variable_valve_operation(gm::GenericGasModel{T}, n::Int=gm.cnw) where T <: AbstractGasFormulation
    gm.var[:nw][n][:v_valve]         = @variable(gm.model, [l in keys(gm.ref[:nw][n][:valve])], binary=true, base_name="$(n)_v_valve", start = getstart(gm.ref[:nw][n][:valve], l, "v_start", 1.0))
    gm.var[:nw][n][:v_control_valve] = @variable(gm.model, [l in keys(gm.ref[:nw][n][:control_valve])], binary=true, base_name="$(n)_v_control_valve", start = getstart(gm.ref[:nw][n][:control_valve], l, "v_start", 1.0))
end

" variables associated with demand "
function variable_load_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
#    load_set = collect(keys(Dict(x for x in gm.ref[:nw][n][:dispatch_consumer] if x.second["qlmax"] != 0 || x.second["qlmin"] != 0)))
    if bounded
        gm.var[:nw][n][:fl] = @variable(gm.model, [i in keys(ref(gm,n,:dispatch_consumer))], base_name="$(n)_fl", lower_bound=calc_flmin(gm.data, gm.ref[:nw][n][:consumer][i]), upper_bound=calc_flmax(gm.data, gm.ref[:nw][n][:consumer][i]), start = getstart(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    else
        gm.var[:nw][n][:fl] = @variable(gm.model, [i in keys(ref(gm,n,:dispatch_consumer))], base_name="$(n)_fl", start = getstart(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    end
end

" variables associated with production "
function variable_production_mass_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
#    prod_set = collect(keys(Dict(x for x in gm.ref[:nw][n][:dispatch_producer] if x.second["qgmax"] != 0 || x.second["qgmin"] != 0)))
    if bounded
        gm.var[:nw][n][:fg] = @variable(gm.model, [i in keys(ref(gm,n,:dispatch_producer))], base_name="$(n)_fg", lower_bound=calc_fgmin(gm.data, ref(gm,n,:producer,i)), upper_bound=calc_fgmax(gm.data, ref(gm,n,:producer,i)), start = getstart(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    else
        gm.var[:nw][n][:fg] = @variable(gm.model, [i in keys(ref(gm,n,:dispatch_producer))], base_name="$(n)_fg", start = getstart(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    end
end

" variables associated with direction of flow on the connections. yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction "
function variable_connection_direction(gm::GenericGasModel{T}, n::Int=gm.cnw; pipe=gm.ref[:nw][n][:pipe], compressor=gm.ref[:nw][n][:compressor], short_pipe=gm.ref[:nw][n][:short_pipe], resistor=gm.ref[:nw][n][:resistor], valve=gm.ref[:nw][n][:valve], control_valve=gm.ref[:nw][n][:control_valve]) where T <: AbstractGasFormulation
    gm.var[:nw][n][:y_pipe]          = @variable(gm.model, [l in keys(pipe)], binary=true, base_name="$(n)_y", start = getstart(pipe, l, "y_start", 1.0))
    gm.var[:nw][n][:y_compressor]    = @variable(gm.model, [l in keys(compressor)], binary=true, base_name="$(n)_y", start = getstart(compressor, l, "y_start", 1.0))
    gm.var[:nw][n][:y_resistor]      = @variable(gm.model, [l in keys(resistor)], binary=true, base_name="$(n)_y", start = getstart(resistor, l, "y_start", 1.0))
    gm.var[:nw][n][:y_short_pipe]    = @variable(gm.model, [l in keys(short_pipe)], binary=true, base_name="$(n)_y", start = getstart(short_pipe, l, "y_start", 1.0))
    gm.var[:nw][n][:y_valve]         = @variable(gm.model, [l in keys(valve)], binary=true, base_name="$(n)_y", start = getstart(valve, l, "y_start", 1.0))
    gm.var[:nw][n][:y_control_valve] = @variable(gm.model, [l in keys(control_valve)], binary=true, base_name="$(n)_y", start = getstart(control_valve, l, "y_start", 1.0))
end

" variables associated with direction of flow on the connections yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction "
function variable_connection_direction_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; ne_pipe=gm.ref[:nw][n][:ne_pipe], ne_compressor=gm.ref[:nw][n][:ne_compressor]) where T <: AbstractGasFormulation
     gm.var[:nw][n][:y_ne_pipe] = @variable(gm.model, [l in keys(ne_pipe)], binary=true, base_name="$(n)_y_ne_pipe", start = getstart(ne_pipe, l, "y_start", 1.0))
     gm.var[:nw][n][:y_ne_compressor] = @variable(gm.model, [l in keys(ne_compressor)], binary=true, base_name="$(n)_y_ne_compressor", start = getstart(ne_compressor, l, "y_start", 1.0))
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

"Variable Set: variables associated with compression ratios "
function variable_compression_ratio(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_compression_ratio_value(gm,n,bounded=bounded)
end

" variables associated with compression ratio values "
function variable_compression_ratio_value(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true)
    if bounded
        gm.var[:nw][n][:r] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_r", lower_bound=ref(gm,n,:compressor,i)["c_ratio_min"]^2, upper_bound=ref(gm,n,:compressor,i)["c_ratio_max"]^2, start = getstart(gm.ref[:nw][n][:compressor], i, "ratio_start", 0))
    else
        gm.var[:nw][n][:r] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_r", start = getstart(gm.ref[:nw][n][:compressor], i, "ratio_start", 0))
    end
end
