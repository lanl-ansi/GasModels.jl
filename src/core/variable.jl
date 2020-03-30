##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

"variables associated with pressure squared"
function variable_pressure_sqr(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    psqr = gm.var[:nw][nw][:p] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:junction])],
        base_name="$(nw)_p",
        start=comp_start_value(gm.ref[:nw][nw][:junction], i, "p_start", gm.ref[:nw][nw][:junction][i]["p_min"]^2))

    if bounded
        for (i, junction) in ref(gm, nw, :junction)
            JuMP.set_lower_bound(psqr[i], gm.ref[:nw][nw][:junction][i]["p_min"]^2)
            JuMP.set_upper_bound(psqr[i], gm.ref[:nw][nw][:junction][i]["p_max"]^2)
        end
    end

    if report
        sol_p = Dict(i => JuMP.@NLexpression(gm.model, sqrt(psqr[i])) for i in ids(gm, nw, :junction))
        _IM.sol_component_value(gm, nw, :junction, :p, ids(gm, nw, :junction), sol_p)
    end
end


"variables associated with mass flow"
function variable_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    max_flow = gm.ref[:nw][nw][:max_mass_flow]

    f_pipe = gm.var[:nw][nw][:f_pipe] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:pipe])],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:pipe], i, "f_start", 0)
    )

    f_compressor = gm.var[:nw][nw][:f_compressor] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:compressor])],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:compressor], i, "f_start", 0)
    )

    f_resistor = gm.var[:nw][nw][:f_resistor] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:resistor])],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:resistor], i, "f_start", 0)
    )

    f_short_pipe = gm.var[:nw][nw][:f_short_pipe] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:short_pipe])],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:short_pipe], i, "f_start", 0)
    )

    f_valve = gm.var[:nw][nw][:f_valve] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:valve])],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:valve], i, "f_start", 0)
    )

    f_regulator = gm.var[:nw][nw][:f_regulator] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:regulator])],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:regulator], i, "f_start", 0)
    )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(f_pipe[i], -max_flow)
            JuMP.set_upper_bound(f_pipe[i],  max_flow)
        end

        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(f_compressor[i], -max_flow)
            JuMP.set_upper_bound(f_compressor[i],  max_flow)
        end

        for (i, resistor) in ref(gm, nw, :resistor)
            JuMP.set_lower_bound(f_resistor[i], -max_flow)
            JuMP.set_upper_bound(f_resistor[i],  max_flow)
        end

        for (i, short_pipe) in ref(gm, nw, :short_pipe)
            JuMP.set_lower_bound(f_short_pipe[i], -max_flow)
            JuMP.set_upper_bound(f_short_pipe[i],  max_flow)
        end

        for (i, valve) in ref(gm, nw, :valve)
            JuMP.set_lower_bound(f_valve[i], -max_flow)
            JuMP.set_upper_bound(f_valve[i],  max_flow)
        end

        for (i, regulator) in ref(gm, nw, :regulator)
            JuMP.set_lower_bound(f_regulator[i], -max_flow)
            JuMP.set_upper_bound(f_regulator[i],  max_flow)
        end
    end

    report && _IM.sol_component_value(gm, nw, :pipe, :f, ids(gm, nw, :pipe), f_pipe)
    report && _IM.sol_component_value(gm, nw, :compressor, :f, ids(gm, nw, :compressor), f_compressor)
    report && _IM.sol_component_value(gm, nw, :resistor, :f, ids(gm, nw, :resistor), f_resistor)
    report && _IM.sol_component_value(gm, nw, :short_pipe, :f, ids(gm, nw, :short_pipe), f_short_pipe)
    report && _IM.sol_component_value(gm, nw, :valve, :f, ids(gm, nw, :valve), f_valve)
    report && _IM.sol_component_value(gm, nw, :regulator, :f, ids(gm, nw, :regulator), f_regulator)
end


"variables associated with mass flow in expansion planning"
function variable_mass_flow_ne(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    max_flow = gm.ref[:nw][nw][:max_mass_flow]

    f_ne_pipe = gm.var[:nw][nw][:f_ne_pipe] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:ne_pipe])],
        base_name="$(nw)_f_ne",
        start=comp_start_value(gm.ref[:nw][nw][:ne_pipe], i, "f_start", 0)
    )

    f_ne_compressor = gm.var[:nw][nw][:f_ne_compressor] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:ne_compressor])],
        base_name="$(nw)_f_ne",
        start=comp_start_value(gm.ref[:nw][nw][:ne_compressor], i, "f_start", 0))

    if bounded
        for (i, ne_pipe) in ref(gm, nw, :ne_pipe)
            JuMP.set_lower_bound(f_ne_pipe[i], -max_flow)
            JuMP.set_upper_bound(f_ne_pipe[i],  max_flow)
        end

        for (i, ne_compressor) in ref(gm, nw, :ne_compressor)
            JuMP.set_lower_bound(f_ne_compressor[i], -max_flow)
            JuMP.set_upper_bound(f_ne_compressor[i],  max_flow)
        end
    end

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :f, ids(gm, nw, :ne_pipe), f_ne_pipe)
    report && _IM.sol_component_value(gm, nw, :ne_compressor, :f, ids(gm, nw, :ne_compressor), f_ne_compressor)
end


"variables associated with building pipes"
function variable_pipe_ne(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    zp = gm.var[:nw][nw][:zp] = JuMP.@variable(gm.model, [l in keys(gm.ref[:nw][nw][:ne_pipe])], binary=true, base_name="$(nw)_zp", start=comp_start_value(gm.ref[:nw][nw][:ne_pipe], l, "zp_start", 0.0))

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :z, ids(gm, nw, :ne_pipe), zp)
end


"variables associated with building compressors"
function variable_compressor_ne(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    zc = gm.var[:nw][nw][:zc] = JuMP.@variable(gm.model,
        [l in keys(gm.ref[:nw][nw][:ne_compressor])],
        binary=true,
        base_name="$(nw)_zc",
        start=comp_start_value(gm.ref[:nw][nw][:ne_compressor], l, "zc_start", 0.0)
    )

    report && _IM.sol_component_value(gm, nw, :ne_compressor, :z, ids(gm, nw, :ne_compressor), zc)
end


"0-1 variables associated with operating valves"
function variable_valve_operation(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    v_valve = gm.var[:nw][nw][:v_valve] = JuMP.@variable(gm.model,
        [l in keys(gm.ref[:nw][nw][:valve])],
        binary=true,
        base_name="$(nw)_v_valve",
        start=comp_start_value(gm.ref[:nw][nw][:valve], l, "v_start", 1.0)
    )

    v_regulator = gm.var[:nw][nw][:v_regulator] = JuMP.@variable(gm.model,
        [l in keys(gm.ref[:nw][nw][:regulator])],
        binary=true,
        base_name="$(nw)_v_regulator",
        start=comp_start_value(gm.ref[:nw][nw][:regulator], l, "v_start", 1.0)
    )

    report && _IM.sol_component_value(gm, nw, :valve, :v, ids(gm, nw, :valve), v_valve)
    report && _IM.sol_component_value(gm, nw, :regulator, :v, ids(gm, nw, :regulator), v_regulator)
end


"variables associated with demand"
function variable_load_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    fl = gm.var[:nw][nw][:fl] = JuMP.@variable(gm.model,
        [i in keys(ref(gm,nw,:dispatchable_delivery))],
        base_name="$(nw)_fl",
        start=comp_start_value(gm.ref[:nw][nw][:delivery], i, "fl_start", 0.0)
    )

    if bounded
        for (i, delivery) in ref(gm, nw, :dispatchable_delivery)
            JuMP.set_lower_bound(fl[i], ref(gm,nw,:delivery,i)["withdrawal_min"])
            JuMP.set_upper_bound(fl[i], ref(gm,nw,:delivery,i)["withdrawal_max"])
        end
    end

    if report
        _IM.sol_component_value(gm, nw, :delivery, :fl, ids(gm, nw, :dispatchable_delivery), fl)
        if haskey(gm.data, "standard_density")
            sol_ql = Dict(i => fl[i] / gm.data["standard_density"] for i in ids(gm, nw, :dispatchable_delivery))
            _IM.sol_component_value(gm, nw, :delivery, :ql, ids(gm, nw, :dispatchable_delivery), sol_ql)
        end
    end
end


"variables associated with transfer"
function variable_transfer_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    ft = gm.var[:nw][nw][:ft] = JuMP.@variable(gm.model,
        [i in keys(ref(gm,nw,:dispatchable_transfer))],
        base_name="$(nw)_ft",
        start=comp_start_value(gm.ref[:nw][nw][:transfer], i, "ft_start", 0.0)
    )

    if bounded
        for (i, transfer) in ref(gm, nw, :dispatchable_transfer)
            JuMP.set_lower_bound(ft[i], ref(gm,nw,:transfer,i)["withdrawal_min"])
            JuMP.set_upper_bound(ft[i], ref(gm,nw,:transfer,i)["withdrawal_max"])
        end
    end

    if report
        _IM.sol_component_value(gm, nw, :transfer, :ft, ids(gm, nw, :dispatchable_transfer), ft)
        if haskey(gm.data, "standard_density")
            sol_qt = Dict(i => ft[i] / gm.data["standard_density"] for i in ids(gm, nw, :dispatchable_transfer))
            _IM.sol_component_value(gm, nw, :transfer, :qt, ids(gm, nw, :dispatchable_transfer), sol_qt)
        end
    end
end


"variables associated with production"
function variable_production_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    fg = gm.var[:nw][nw][:fg] = JuMP.@variable(gm.model,
        [i in keys(ref(gm,nw,:dispatchable_receipt))],
        base_name="$(nw)_fg",
        start=comp_start_value(gm.ref[:nw][nw][:receipt], i, "fg_start", 0.0)
    )

    if bounded
        for (i, receipt) in ref(gm, nw, :dispatchable_receipt)
            JuMP.set_lower_bound(fg[i], ref(gm,nw,:receipt,i)["injection_min"])
            JuMP.set_upper_bound(fg[i], ref(gm,nw,:receipt,i)["injection_max"])
        end
    end

    if report
        _IM.sol_component_value(gm, nw, :receipt, :fg, ids(gm, nw, :dispatchable_receipt), fg)
        if haskey(gm.data, "standard_density")
            sol_qg = Dict(i => fl[i] / gm.data["standard_density"] for i in ids(gm, nw, :dispatchable_receipt))
            _IM.sol_component_value(gm, nw, :receipt, :qg, ids(gm, nw, :dispatchable_receipt), sol_qg)
        end
    end
end


"variables associated with direction of flow on the connections. yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction"
function variable_connection_direction(gm::AbstractGasModel, nw::Int=gm.cnw; pipe=gm.ref[:nw][nw][:pipe], compressor=gm.ref[:nw][nw][:compressor], short_pipe=gm.ref[:nw][nw][:short_pipe], resistor=gm.ref[:nw][nw][:resistor], valve=gm.ref[:nw][nw][:valve], regulator=gm.ref[:nw][nw][:regulator], report::Bool=true)
    y_pipe = gm.var[:nw][nw][:y_pipe] = JuMP.@variable(gm.model,
        [l in keys(pipe)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(pipe, l, "y_start", 1)
    )

    y_compressor = gm.var[:nw][nw][:y_compressor] = JuMP.@variable(gm.model,
        [l in keys(compressor)],
        binary=true, base_name="$(nw)_y",
        start=comp_start_value(compressor, l, "y_start", 1)
    )

    y_resistor = gm.var[:nw][nw][:y_resistor] = JuMP.@variable(gm.model,
        [l in keys(resistor)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(resistor, l, "y_start", 1)
    )

    y_short_pipe = gm.var[:nw][nw][:y_short_pipe] = JuMP.@variable(gm.model,
        [l in keys(short_pipe)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(short_pipe, l, "y_start", 1)
    )

    y_valve = gm.var[:nw][nw][:y_valve] = JuMP.@variable(gm.model,
        [l in keys(valve)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(valve, l, "y_start", 1)
    )

    y_regulator = gm.var[:nw][nw][:y_regulator] = JuMP.@variable(gm.model,
        [l in keys(regulator)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(regulator, l, "y_start", 1)
    )

    report && _IM.sol_component_value(gm, nw, :pipe, :y, keys(pipe), y_pipe)
    report && _IM.sol_component_value(gm, nw, :compressor, :y, keys(compressor), y_compressor)
    report && _IM.sol_component_value(gm, nw, :resistor, :y, keys(resistor), y_resistor)
    report && _IM.sol_component_value(gm, nw, :short_pipe, :y, keys(short_pipe), y_short_pipe)
    report && _IM.sol_component_value(gm, nw, :valve, :y, keys(valve), y_valve)
    report && _IM.sol_component_value(gm, nw, :regulator, :y, keys(regulator), y_regulator)
end


"variables associated with direction of flow on the connections yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction"
function variable_connection_direction_ne(gm::AbstractGasModel, nw::Int=gm.cnw; ne_pipe=gm.ref[:nw][nw][:ne_pipe], ne_compressor=gm.ref[:nw][nw][:ne_compressor], report::Bool=true)
    y_ne_pipe = gm.var[:nw][nw][:y_ne_pipe] = JuMP.@variable(gm.model,
        [l in keys(ne_pipe)],
        binary=true,
        base_name="$(nw)_y_ne_pipe",
        start=comp_start_value(ne_pipe, l, "y_start", 1)
    )

    y_ne_compressor = gm.var[:nw][nw][:y_ne_compressor] = JuMP.@variable(gm.model,
        [l in keys(ne_compressor)],
        binary=true,
        base_name="$(nw)_y_ne_compressor",
        start=comp_start_value(ne_compressor, l, "y_start", 1)
    )

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :y, keys(ne_pipe), y_ne_pipe)
    report && _IM.sol_component_value(gm, nw, :ne_compressor, :y, keys(ne_compressor), y_ne_compressor)
end


"Variable Set: Define variables needed for modeling flow across connections"
function variable_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow(gm,nw,bounded=bounded,report=report)
end


"Variable Set: Define variables needed for modeling flow across connections where some flows are directionally constrained"
function variable_flow_directed(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow(gm,nw,bounded=bounded,report=report)
end


"Variable Set: Define variables needed for modeling flow across connections that are expansions"
function variable_flow_ne(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow_ne(gm,nw; bounded=bounded,report=report)
end


"Variable Set: Define variables needed for modeling flow across connections that are expansions and some flows are directionally constrained"
function variable_flow_ne_directed(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow_ne(gm,nw,bounded=bounded,report=report)
end


"Variable Set: variables associated with compression ratios"
function variable_compression_ratio(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_compression_ratio_value(gm,nw,bounded=bounded,report=report)
end


"variables associated with compression ratio values"
function variable_compression_ratio_value(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    rsqr = gm.var[:nw][nw][:r] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:compressor])],
        base_name="$(nw)_r",
        start=comp_start_value(gm.ref[:nw][nw][:compressor], i, "ratio_start", 0.0)
    )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(rsqr[i], ref(gm,nw,:compressor,i)["c_ratio_min"]^2)
            JuMP.set_upper_bound(rsqr[i], ref(gm,nw,:compressor,i)["c_ratio_max"]^2)
        end
    end

    if report
        sol_r = Dict(i => JuMP.@NLexpression(gm.model, sqrt(rsqr[i])) for i in ids(gm, nw, :compressor))
        _IM.sol_component_value(gm, nw, :compressor, :r, ids(gm, nw, :compressor), sol_r)
    end
end
