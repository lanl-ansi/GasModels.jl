##########################################################################################################
# The purpose of this file is to define commonly used and created variables used in gas flow models
##########################################################################################################

"variables associated with pressure squared"
function variable_pressure_sqr(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    psqr = gm.var[:nw][nw][:psqr] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:junction)],
        base_name="$(nw)_p",
        start=comp_start_value(gm.ref[:nw][nw][:junction], i, "p_start", gm.ref[:nw][nw][:junction][i]["p_min"]^2))

    if bounded
        for (i, junction) in ref(gm, nw, :junction)
            JuMP.set_lower_bound(psqr[i], gm.ref[:nw][nw][:junction][i]["p_min"]^2)
            JuMP.set_upper_bound(psqr[i], gm.ref[:nw][nw][:junction][i]["p_max"]^2)
        end
    end

    report && _IM.sol_component_value(gm, nw, :junction, :psqr, ids(gm, nw, :junction), psqr)
end

"variables associated with mass flow in pipes"
function variable_pipe_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    max_flow = gm.ref[:nw][nw][:max_mass_flow]

    f_pipe = gm.var[:nw][nw][:f_pipe] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:pipe)],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:pipe], i, "f_start", 0)
    )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(f_pipe[i], -max_flow)
            JuMP.set_upper_bound(f_pipe[i],  max_flow)
        end
    end

    report && _IM.sol_component_value(gm, nw, :pipe, :f, ids(gm, nw, :pipe), f_pipe)
end

"variables associated with mass flow in compressors"
function variable_compressor_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    f_compressor = gm.var[:nw][nw][:f_compressor] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:compressor)],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:compressor], i, "f_start", 0)
    )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(f_compressor[i], compressor["flow_min"])
            JuMP.set_upper_bound(f_compressor[i], compressor["flow_max"])
        end
    end

    report && _IM.sol_component_value(gm, nw, :compressor, :f, ids(gm, nw, :compressor), f_compressor)
end

"variables associated with mass flow in resistors"
function variable_resistor_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    f_resistor = gm.var[:nw][nw][:f_resistor] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:resistor)],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:resistor], i, "f_start", 0)
    )

    if bounded
        for (i, resistor) in ref(gm, nw, :resistor)
            JuMP.set_lower_bound(f_resistor[i], resistor["flow_min"])
            JuMP.set_upper_bound(f_resistor[i], resistor["flow_max"])
        end
    end

    report && _IM.sol_component_value(gm, nw, :resistor, :f, ids(gm, nw, :resistor), f_resistor)
end

"variables associated with mass flow in short pipes"
function variable_short_pipe_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    f_short_pipe = gm.var[:nw][nw][:f_short_pipe] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:short_pipe)],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:short_pipe], i, "f_start", 0)
    )

    if bounded
        for (i, short_pipe) in ref(gm, nw, :short_pipe)
            JuMP.set_lower_bound(f_short_pipe[i], short_pipe["flow_min"])
            JuMP.set_upper_bound(f_short_pipe[i], short_pipe["flow_max"])
        end
    end

    report && _IM.sol_component_value(gm, nw, :short_pipe, :f, ids(gm, nw, :short_pipe), f_short_pipe)
end


"variables associated with mass flow in valves"
function variable_valve_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    f_valve = gm.var[:nw][nw][:f_valve] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:valve)],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:valve], i, "f_start", 0)
    )

    if bounded
        for (i, valve) in ref(gm, nw, :valve)
            # since valves have on/off capabilities, zero needs
            # to be a valid value in the bounds
            flow_min =  min(valve["flow_min"], 0)
            flow_max =  max(valve["flow_max"], 0)
            JuMP.set_lower_bound(f_valve[i], flow_min)
            JuMP.set_upper_bound(f_valve[i], flow_max)
        end
    end

    report && _IM.sol_component_value(gm, nw, :valve, :f, ids(gm, nw, :valve), f_valve)
end

"variables associated with mass flow in regulators"
function variable_regulator_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    f_regulator = gm.var[:nw][nw][:f_regulator] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:regulator)],
        base_name="$(nw)_f",
        start=comp_start_value(gm.ref[:nw][nw][:regulator], i, "f_start", 0)
    )

    if bounded
        for (i, regulator) in ref(gm, nw, :regulator)
            # since regulators have on/off capabilities, zero needs
            # to be a valid value in the bounds
            flow_min =  min(regulator["flow_min"], 0)
            flow_max =  max(regulator["flow_max"], 0)
            JuMP.set_lower_bound(f_regulator[i], flow_min)
            JuMP.set_upper_bound(f_regulator[i], flow_max)
        end
    end

    report && _IM.sol_component_value(gm, nw, :regulator, :f, ids(gm, nw, :regulator), f_regulator)
end

"all variables associated with mass flow"
function variable_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_pipe_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_compressor_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_resistor_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_short_pipe_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_valve_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_regulator_mass_flow(gm, nw; bounded=bounded, report=report)
end

"variables associated with mass flow in pipes in expansion planning"
function variable_pipe_mass_flow_ne(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    f_ne_pipe = gm.var[:nw][nw][:f_ne_pipe] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:ne_pipe)],
        base_name="$(nw)_f_ne",
        start=comp_start_value(gm.ref[:nw][nw][:ne_pipe], i, "f_start", 0)
    )

    if bounded
        for (i, ne_pipe) in ref(gm, nw, :ne_pipe)
            # since valves have on/off capabilities, zero needs
            # to be a valid value in the bounds
            flow_min =  min(ne_pipe["flow_min"], 0)
            flow_max =  max(ne_pipe["flow_max"], 0)
            JuMP.set_lower_bound(f_ne_pipe[i], flow_min)
            JuMP.set_upper_bound(f_ne_pipe[i], flow_max)
        end
    end

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :f, ids(gm, nw, :ne_pipe), f_ne_pipe)
end


"variables associated with mass flow in compressors in expansion planning"
function variable_compressor_mass_flow_ne(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    f_ne_compressor = gm.var[:nw][nw][:f_ne_compressor] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:ne_compressor)],
        base_name="$(nw)_f_ne",
        start=comp_start_value(gm.ref[:nw][nw][:ne_compressor], i, "f_start", 0))

    if bounded
        for (i, ne_compressor) in ref(gm, nw, :ne_compressor)
            # since ne compressors have on/off capabilities, zero needs
            # to be a valid value in the bounds
            flow_min =  min(ne_compressor["flow_min"], 0)
            flow_max =  max(ne_compressor["flow_max"], 0)
            JuMP.set_lower_bound(f_ne_compressor[i], flow_min)
            JuMP.set_upper_bound(f_ne_compressor[i], flow_max)
        end
    end

    report && _IM.sol_component_value(gm, nw, :ne_compressor, :f, ids(gm, nw, :ne_compressor), f_ne_compressor)
end

"all variables associated with mass flow in expansion planning"
function variable_mass_flow_ne(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_pipe_mass_flow_ne(gm, nw; bounded=bounded, report=report)
    variable_compressor_mass_flow_ne(gm, nw; bounded=bounded, report=report)
end


"variables associated with building pipes"
function variable_pipe_ne(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    zp = gm.var[:nw][nw][:zp] = JuMP.@variable(gm.model, [l in ids(gm,nw,:ne_pipe)], binary=true, base_name="$(nw)_zp", start=comp_start_value(gm.ref[:nw][nw][:ne_pipe], l, "zp_start", 0.0))

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :z, ids(gm, nw, :ne_pipe), zp)
end


"variables associated with building compressors"
function variable_compressor_ne(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    zc = gm.var[:nw][nw][:zc] = JuMP.@variable(gm.model,
        [l in ids(gm,nw,:ne_compressor)],
        binary=true,
        base_name="$(nw)_zc",
        start=comp_start_value(gm.ref[:nw][nw][:ne_compressor], l, "zc_start", 0.0)
    )

    report && _IM.sol_component_value(gm, nw, :ne_compressor, :z, ids(gm, nw, :ne_compressor), zc)
end

"0-1 variables associated with operating valves"
function variable_valve_on_off_operation(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    v_valve = gm.var[:nw][nw][:v_valve] = JuMP.@variable(gm.model,
        [l in ids(gm,nw,:valve)],
        binary=true,
        base_name="$(nw)_v_valve",
        start=comp_start_value(gm.ref[:nw][nw][:valve], l, "v_start", 1.0)
    )

    report && _IM.sol_component_value(gm, nw, :valve, :v, ids(gm, nw, :valve), v_valve)
end


"0-1 variables associated with operating regulators"
function variable_regulator_on_off_operation(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    v_regulator = gm.var[:nw][nw][:v_regulator] = JuMP.@variable(gm.model,
        [l in keys(gm.ref[:nw][nw][:regulator])],
        binary=true,
        base_name="$(nw)_v_regulator",
        start=comp_start_value(gm.ref[:nw][nw][:regulator], l, "v_start", 1.0)
    )

    report && _IM.sol_component_value(gm, nw, :regulator, :v, ids(gm, nw, :regulator), v_regulator)
end

"0-1 variables associated with operating edge components"
function variable_on_off_operation(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    variable_valve_on_off_operation(gm, nw; report=report)
    variable_regulator_on_off_operation(gm, nw; report=report)
end


"variables associated with demand"
function variable_load_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    fl = gm.var[:nw][nw][:fl] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_delivery)],
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
        _IM.sol_component_value(gm, nw, :delivery, :fd, ids(gm, nw, :dispatchable_delivery), fl)
        if haskey(gm.data, "standard_density")
            sol_ql = Dict(i => fl[i] / gm.data["standard_density"] for i in ids(gm, nw, :dispatchable_delivery))
            _IM.sol_component_value(gm, nw, :delivery, :qd, ids(gm, nw, :dispatchable_delivery), sol_ql)
        end
    end
end


"variables associated with transfer"
function variable_transfer_mass_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    ft = gm.var[:nw][nw][:ft] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_transfer)],
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
        [i in ids(gm,nw,:dispatchable_receipt)],
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
            sol_qg = Dict(i => fg[i] / gm.data["standard_density"] for i in ids(gm, nw, :dispatchable_receipt))
            _IM.sol_component_value(gm, nw, :receipt, :qg, ids(gm, nw, :dispatchable_receipt), sol_qg)
        end
    end
end


"variables associated with direction of flow on on pipes. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so flow_direction and is_birection cannot be used to replace the constants with variables"
function variable_pipe_direction(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    pipe       = Dict(x for x in ref(gm,nw,:pipe)       if get(x.second, "is_bidirectional", 1) == 1 &&
                                                          get(x.second, "flow_direction", 0) == 0 &&
                                                          get(x.second, "flow_max", 0) >= 0 &&
                                                          get(x.second, "flow_min", 0) <= 0)
    y_pipe_var =  JuMP.@variable(gm.model,
        [k in keys(pipe)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(pipe, k, "y_start", 1)
    )

    y_pipe = gm.var[:nw][nw][:y_pipe] = Dict()
    for k in keys(pipe)
        y_pipe[k] = y_pipe_var[k]
    end

    for (k,pipe) in ref(gm,nw,:pipe)
        if get(pipe, "is_bidirectional", 1) == 0 || get(pipe, "flow_direction", 0) == 1 || get(pipe, "flow_min", 0) > 0
            y_pipe[k] = 1
        elseif get(pipe, "flow_direction", 0) == -1 || get(pipe, "flow_max", 0) < 0
            y_pipe[k] = 0
        end
    end

    report && _IM.sol_component_value(gm, nw, :pipe, :y, keys(pipe), y_pipe_var)
end


"variables associated with direction of flow on a compressor. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so flow_direction and is_birection cannot be used to replace the constants with variables"
function variable_compressor_direction(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    compressor     = Dict(x for x in ref(gm,nw,:compressor) if ((get(x.second, "directionality", 0) == 0 ||
                                                               (get(x.second, "directionality", 0) == 2) && get(x.second, "flow_direction", 0) == 0)) &&
                                                               get(x.second, "flow_min", 0) <= 0 &&
                                                               get(x.second, "flow_max", 0) >= 0
                                                            )

    y_compressor_var = JuMP.@variable(gm.model,
        [l in keys(compressor)],
        binary=true, base_name="$(nw)_y",
        start=comp_start_value(compressor, l, "y_start", 1)
    )

    y_compressor = gm.var[:nw][nw][:y_compressor] = Dict()
    for l in keys(compressor)
        y_compressor[l] = y_compressor_var[l]
    end

    for (i,compressor) in ref(gm,nw,:compressor)
        if get(compressor, "directionality", 0) == 1 || get(compressor, "flow_direction", 0) == 1 || get(compressor, "flow_min", 0) > 0
            y_compressor[i] = 1
        end
        if get(compressor, "flow_direction", 0) == -1 || get(compressor, "flow_max", 0) < 0
            y_compressor[i] = 0
        end
    end

    report && _IM.sol_component_value(gm, nw, :compressor, :y, keys(compressor), y_compressor_var)
end


"variables associated with direction of flow on on resistors. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so flow_direction and is_birection cannot be used to replace the constants with variables"
function variable_resistor_direction(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    resistor = Dict(x for x in ref(gm,nw,:resistor) if x.second["flow_max"] >= 0 && x.second["flow_min"] <= 0)

    y_resistor_var = JuMP.@variable(gm.model,
        [l in keys(resistor)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(resistor, l, "y_start", 1)
    )

    y_resistor = gm.var[:nw][nw][:y_resistor] = Dict()
    for l in keys(resistor)
        y_resistor[l] = y_resistor_var[l]
    end

    for (i,resistor) in ref(gm,nw,:resistor)
        if resistor["flow_min"] > 0
            y_resistor[i] = 1
        elseif resistor["flow_max"] < 0
            y_resistor[i] = 0
        end
    end

    report && _IM.sol_component_value(gm, nw, :resistor, :y, keys(resistor), y_resistor_var)
end


"variables associated with direction of flow on short pipes. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so flow_direction and is_birection cannot be used to replace the constants with variables"
function variable_short_pipe_direction(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    short_pipe = Dict(x for x in ref(gm,nw,:short_pipe) if x.second["flow_max"] >= 0 && x.second["flow_min"] <= 0)

    y_short_pipe_var = JuMP.@variable(gm.model,
        [l in keys(short_pipe)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(short_pipe, l, "y_start", 1)
    )

    y_short_pipe = gm.var[:nw][nw][:y_short_pipe] = Dict()
    for l in keys(short_pipe)
        y_short_pipe[l] = y_short_pipe_var[l]
    end

    for (i,pipe) in ref(gm,nw,:short_pipe)
        if pipe["flow_min"] > 0
            y_short_pipe[i] = 1
        elseif pipe["flow_max"] < 0
            y_short_pipe[i] = 0
        end
    end

    report && _IM.sol_component_value(gm, nw, :short_pipe, :y, keys(short_pipe), y_short_pipe_var)
end


"variables associated with direction of flow on valves. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so valves need to have the freedom to choose a direction when off"
function variable_valve_direction(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    valve = ref(gm,nw,:valve)

    y_valve_var = JuMP.@variable(gm.model,
        [l in keys(valve)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(valve, l, "y_start", 1)
    )

    y_valve = gm.var[:nw][nw][:y_valve] = Dict()
    for l in keys(valve)
        y_valve[l] = y_valve_var[l]
    end

    report && _IM.sol_component_value(gm, nw, :valve, :y, keys(valve), y_valve_var)
end


"variables associated with direction of flow on regulators. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1,  O flow can have y = 0 or 1, so valves need to have the freedom to choose a direction when off"
function variable_regulator_direction(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    regulator  = ref(gm,nw,:regulator)

    y_regulator_var = JuMP.@variable(gm.model,
        [l in keys(regulator)],
        binary=true,
        base_name="$(nw)_y",
        start=comp_start_value(regulator, l, "y_start", 1)
    )

    y_regulator = gm.var[:nw][nw][:y_regulator] = Dict()
    for l in keys(regulator)
        y_regulator[l] = y_regulator_var[l]
    end

    report && _IM.sol_component_value(gm, nw, :regulator, :y, keys(regulator), y_regulator_var)
end


"variables associated with direction of flow on the connections. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so flow_direction and is_birection cannot be used to replace the constants with variables"
function variable_connection_direction(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    variable_pipe_direction(gm, nw; report=report)
    variable_compressor_direction(gm, nw; report=report)
    variable_resistor_direction(gm, nw; report=report)
    variable_short_pipe_direction(gm, nw; report=report)
    variable_valve_direction(gm, nw; report=report)
    variable_regulator_direction(gm, nw; report=report)
end


"variables associated with direction of flow on new pipes. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so flow_direction and is_birection cannot be used to replace the constants with variables"
function variable_pipe_direction_ne(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    ne_pipe = Dict(x for x in ref(gm,nw,:ne_pipe) if get(x.second, "is_bidirectional", 1) == 1 &&
                                                     get(x.second, "flow_direction", 0) == 0 &&
                                                     get(x.second, "flow_max", 0) >= 0 &&
                                                     get(x.second, "flow_min", 0) <= 0)

    y_ne_pipe_var = JuMP.@variable(gm.model,
        [l in keys(ne_pipe)],
        binary=true,
        base_name="$(nw)_y_ne_pipe",
        start=comp_start_value(ne_pipe, l, "y_start", 1)
    )

    y_ne_pipe = gm.var[:nw][nw][:y_ne_pipe] = Dict()
    for l in keys(ne_pipe)
        y_ne_pipe[l] = y_ne_pipe_var[l]
    end

    for (i,pipe) in ref(gm,nw,:ne_pipe)
        if get(pipe, "is_bidirectional", 1) == 0 || get(pipe, "flow_direction", 0) == 1 || get(pipe, "flow_min", 0) > 0
            y_ne_pipe[i] = 1
        end
        if get(pipe, "flow_direction", 0) == -1 || get(pipe, "flow_max", 0) < 0
            y_ne_pipe[i] = 0
        end
    end

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :y, keys(ne_pipe), y_ne_pipe_var)
end


"variables associated with direction of flow on new compressors. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction. O flow can have y = 0 or 1, so flow_direction and is_birection cannot be used to replace the constants with variables"
function variable_compressor_direction_ne(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    ne_compressor = ref(gm,nw,:ne_compressor)

    y_ne_compressor_var = JuMP.@variable(gm.model,
        [l in keys(ne_compressor)],
        binary=true,
        base_name="$(nw)_y_ne_compressor",
        start=comp_start_value(ne_compressor, l, "y_start", 1)
    )

    y_ne_compressor = gm.var[:nw][nw][:y_ne_compressor] = Dict()
    for l in keys(ne_compressor)
        y_ne_compressor[l] = y_ne_compressor_var[l]
    end

    report && _IM.sol_component_value(gm, nw, :ne_compressor, :y, keys(ne_compressor), y_ne_compressor_var)
end

"variables associated with direction of flow on new connections. y = 1 imples flow goes from f_junction to t_junction. y = 0 imples flow goes from t_junction to f_junction"
function variable_connection_direction_ne(gm::AbstractGasModel, nw::Int=gm.cnw; report::Bool=true)
    variable_pipe_direction_ne(gm, nw; report=report)
    variable_compressor_direction_ne(gm, nw; report=report)
end


"Variable Set: Define variables needed for modeling flow across connections"
function variable_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow(gm,nw,bounded=bounded,report=report)
end


"Variable Set: Define variables needed for modeling flow across connections that are expansions"
function variable_flow_ne(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow_ne(gm,nw; bounded=bounded,report=report)
end


"Variable Set: variables associated with compression ratios"
function variable_compressor_ratio_sqr(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    rsqr = gm.var[:nw][nw][:rsqr] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:compressor)],
        base_name="$(nw)_r",
        start=comp_start_value(gm.ref[:nw][nw][:compressor], i, "ratio_start", 0.0)
    )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(rsqr[i], ref(gm,nw,:compressor,i)["c_ratio_min"]^2)
            JuMP.set_upper_bound(rsqr[i], ref(gm,nw,:compressor,i)["c_ratio_max"]^2)
        end
    end

    report && _IM.sol_component_value(gm, nw, :compressor, :rsqr, ids(gm, nw, :compressor), rsqr)
end
