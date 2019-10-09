##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

"variables associated with pressure squared"
function variable_pressure_sqr(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    if bounded
        gm.var[:nw][n][:p] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], base_name="$(n)_p", lower_bound=gm.ref[:nw][n][:junction][i]["pmin"]^2, upper_bound=gm.ref[:nw][n][:junction][i]["pmax"]^2, start = comp_start_value(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))
    else
        gm.var[:nw][n][:p] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:junction])], base_name="$(n)_p", start = comp_start_value(gm.ref[:nw][n][:junction], i, "p_start", gm.ref[:nw][n][:junction][i]["pmin"]^2))
    end
end


"variables associated with mass flow"
function variable_mass_flow(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    if bounded
        gm.var[:nw][n][:f_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_f_pipe", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_compressor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_f_compressor", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:compressor], i, "f_start", 0))
        gm.var[:nw][n][:f_resistor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_f_resistor", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:resistor], i, "f_start", 0))
        gm.var[:nw][n][:f_short_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:short_pipe])], base_name="$(n)_f_short_pipe", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:short_pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_valve] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:valve])], base_name="$(n)_f_valve", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:valve], i, "f_start", 0))
        gm.var[:nw][n][:f_control_valve] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:control_valve])], base_name="$(n)_f_control_valve", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:control_valve], i, "f_start", 0))
    else
        gm.var[:nw][n][:f_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_f", start = comp_start_value(gm.ref[:nw][n][:pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_compressor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_f", start = comp_start_value(gm.ref[:nw][n][:compressor], i, "f_start", 0))
        gm.var[:nw][n][:f_resistor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_f", start = comp_start_value(gm.ref[:nw][n][:resistor], i, "f_start", 0))
        gm.var[:nw][n][:f_short_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:short_pipe])], base_name="$(n)_f", start = comp_start_value(gm.ref[:nw][n][:short_pipe], i, "f_start", 0))
        gm.var[:nw][n][:f_valve] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:valve])], base_name="$(n)_f", start = comp_start_value(gm.ref[:nw][n][:valve], i, "f_start", 0))
        gm.var[:nw][n][:f_control_valve] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:control_valve])], base_name="$(n)_f", start = comp_start_value(gm.ref[:nw][n][:control_valve], i, "f_start", 0))
    end
end


"variables associated with mass flow in expansion planning"
function variable_mass_flow_ne(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    if bounded
         gm.var[:nw][n][:f_ne_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_f_ne", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:ne_pipe], i, "f_start", 0))
         gm.var[:nw][n][:f_ne_compressor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_compressor])], base_name="$(n)_f_ne", lower_bound=-max_flow, upper_bound=max_flow, start = comp_start_value(gm.ref[:nw][n][:ne_compressor], i, "f_start", 0))
    else
         gm.var[:nw][n][:f_ne_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_f_ne", start = comp_start_value(gm.ref[:nw][n][:ne_pipe], i, "f_start", 0))
         gm.var[:nw][n][:f_ne_compressor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_compressor])], base_name="$(n)_f_ne", start = comp_start_value(gm.ref[:nw][n][:ne_compressor], i, "f_start", 0))

    end
end


"variables associated with building pipes"
function variable_pipe_ne(gm::AbstractGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zp] = JuMP.@variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_pipe])], binary=true, base_name="$(n)_zp", start = comp_start_value(gm.ref[:nw][n][:ne_pipe], l, "zp_start", 0.0))
end


"variables associated with building compressors"
function variable_compressor_ne(gm::AbstractGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:zc] = JuMP.@variable(gm.model, [l in keys(gm.ref[:nw][n][:ne_compressor])], binary=true, base_name="$(n)_zc", start = comp_start_value(gm.ref[:nw][n][:ne_compressor], l, "zc_start", 0.0))
end


"0-1 variables associated with operating valves"
function variable_valve_operation(gm::AbstractGasModel, n::Int=gm.cnw)
    gm.var[:nw][n][:v_valve]         = JuMP.@variable(gm.model, [l in keys(gm.ref[:nw][n][:valve])], binary=true, base_name="$(n)_v_valve", start = comp_start_value(gm.ref[:nw][n][:valve], l, "v_start", 1.0))
    gm.var[:nw][n][:v_control_valve] = JuMP.@variable(gm.model, [l in keys(gm.ref[:nw][n][:control_valve])], binary=true, base_name="$(n)_v_control_valve", start = comp_start_value(gm.ref[:nw][n][:control_valve], l, "v_start", 1.0))
end


"variables associated with demand"
function variable_load_mass_flow(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool=true)
    if bounded
        gm.var[:nw][n][:fl] = JuMP.@variable(gm.model, [i in keys(ref(gm,n,:dispatch_consumer))], base_name="$(n)_fl", lower_bound=_calc_flmin(gm.data, gm.ref[:nw][n][:consumer][i]), upper_bound=_calc_flmax(gm.data, gm.ref[:nw][n][:consumer][i]), start = comp_start_value(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    else
        gm.var[:nw][n][:fl] = JuMP.@variable(gm.model, [i in keys(ref(gm,n,:dispatch_consumer))], base_name="$(n)_fl", start = comp_start_value(gm.ref[:nw][n][:consumer], i, "fl_start", 0.0))
    end
end


"variables associated with production"
function variable_production_mass_flow(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool=true)
    if bounded
        gm.var[:nw][n][:fg] = JuMP.@variable(gm.model, [i in keys(ref(gm,n,:dispatch_producer))], base_name="$(n)_fg", lower_bound=_calc_fgmin(gm.data, ref(gm,n,:producer,i)), upper_bound=_calc_fgmax(gm.data, ref(gm,n,:producer,i)), start = comp_start_value(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    else
        gm.var[:nw][n][:fg] = JuMP.@variable(gm.model, [i in keys(ref(gm,n,:dispatch_producer))], base_name="$(n)_fg", start = comp_start_value(gm.ref[:nw][n][:producer], i, "fg_start", 0.0))
    end
end


"variables associated with direction of flow on the connections. yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction"
function variable_connection_direction(gm::AbstractGasModel, n::Int=gm.cnw; pipe=gm.ref[:nw][n][:pipe], compressor=gm.ref[:nw][n][:compressor], short_pipe=gm.ref[:nw][n][:short_pipe], resistor=gm.ref[:nw][n][:resistor], valve=gm.ref[:nw][n][:valve], control_valve=gm.ref[:nw][n][:control_valve])
    gm.var[:nw][n][:y_pipe]          = JuMP.@variable(gm.model, [l in keys(pipe)], binary=true, base_name="$(n)_y", start = comp_start_value(pipe, l, "y_start", 1.0))
    gm.var[:nw][n][:y_compressor]    = JuMP.@variable(gm.model, [l in keys(compressor)], binary=true, base_name="$(n)_y", start = comp_start_value(compressor, l, "y_start", 1.0))
    gm.var[:nw][n][:y_resistor]      = JuMP.@variable(gm.model, [l in keys(resistor)], binary=true, base_name="$(n)_y", start = comp_start_value(resistor, l, "y_start", 1.0))
    gm.var[:nw][n][:y_short_pipe]    = JuMP.@variable(gm.model, [l in keys(short_pipe)], binary=true, base_name="$(n)_y", start = comp_start_value(short_pipe, l, "y_start", 1.0))
    gm.var[:nw][n][:y_valve]         = JuMP.@variable(gm.model, [l in keys(valve)], binary=true, base_name="$(n)_y", start = comp_start_value(valve, l, "y_start", 1.0))
    gm.var[:nw][n][:y_control_valve] = JuMP.@variable(gm.model, [l in keys(control_valve)], binary=true, base_name="$(n)_y", start = comp_start_value(control_valve, l, "y_start", 1.0))
end


"variables associated with direction of flow on the connections yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction"
function variable_connection_direction_ne(gm::AbstractGasModel, n::Int=gm.cnw; ne_pipe=gm.ref[:nw][n][:ne_pipe], ne_compressor=gm.ref[:nw][n][:ne_compressor])
     gm.var[:nw][n][:y_ne_pipe] = JuMP.@variable(gm.model, [l in keys(ne_pipe)], binary=true, base_name="$(n)_y_ne_pipe", start = comp_start_value(ne_pipe, l, "y_start", 1.0))
     gm.var[:nw][n][:y_ne_compressor] = JuMP.@variable(gm.model, [l in keys(ne_compressor)], binary=true, base_name="$(n)_y_ne_compressor", start = comp_start_value(ne_compressor, l, "y_start", 1.0))
end


"Variable Set: Define variables needed for modeling flow across connections"
function variable_flow(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow(gm,n; bounded=bounded)
end


"Variable Set: Define variables needed for modeling flow across connections where some flows are directionally constrained"
function variable_flow_directed(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow(gm,n; bounded=bounded)
end


"Variable Set: Define variables needed for modeling flow across connections that are expansions"
function variable_flow_ne(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow_ne(gm,n; bounded=bounded)
end


"Variable Set: Define variables needed for modeling flow across connections that are expansions and some flows are directionally constrained"
function variable_flow_ne_directed(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow_ne(gm,n; bounded=bounded)
end


"Variable Set: variables associated with compression ratios"
function variable_compression_ratio(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    variable_compression_ratio_value(gm,n,bounded=bounded)
end


"variables associated with compression ratio values"
function variable_compression_ratio_value(gm::AbstractGasModel, n::Int=gm.cnw; bounded::Bool = true)
    if bounded
        gm.var[:nw][n][:r] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_r", lower_bound=ref(gm,n,:compressor,i)["c_ratio_min"]^2, upper_bound=ref(gm,n,:compressor,i)["c_ratio_max"]^2, start = comp_start_value(gm.ref[:nw][n][:compressor], i, "ratio_start", 0))
    else
        gm.var[:nw][n][:r] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:compressor])], base_name="$(n)_r", start = comp_start_value(gm.ref[:nw][n][:compressor], i, "ratio_start", 0))
    end
end
