"variables associate with nodal potential"
function variable_potential(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    b1, b2 = ref(gm, nw, :non_ideal_coeffs)

    get_potential = x -> b1 * x^2/0.5 + b2 * x^3/3.0 
    
    function find_ub(val::Float64, ub::Float64)::Float64
        @assert ub > 0
        while get_potential(ss, ub) < val
            ub = 1.5 * ub
        end 
        return ub
    end 
    
    function find_lb(val::Float64, lb::Float64)::Float64
        @assert lb < 0
        while get_potential(ss, lb) > val
            lb = 1.5 * lb
        end 
        return lb
    end 

    function bisect(lb::Float64, ub::Float64, val::Float64)::Float64  
        @assert ub > lb
        mb = 1.0
        while (ub - lb) > 1e-7
            mb = (ub + lb) / 2.0
            if get_potential(mb) > val
                ub = mb
            else
                lb = mb 
            end
        end
        return mb
    end

    invert_positive_potential = val -> bisect(0.0, find_ub(val, 1.0), val)
    invert_negative_potential = val -> bisect(find_lb(val, -1.0), 0.0, val)
    invert_potential = val -> (val >= 0) ? invert_positive_potential(val) : invert_negative_potential(val)

    potential = var(gm, nw)[:potential] = JuMP.@variable(
        gm.model, [i in ids(gm, nw, :junction)], base_name="$(nw)_potential",
        start=get_potential(comp_start_value(ref(gm, nw, :junction), i, "p_start")),
        get_potential(ref(gm, nw, :junction, i)["p_min"])
    )

    if bounded
        for (i, _) in ref(gm, nw, :junction)
            JuMP.set_lower_bound(potential[i], get_potential(ref(gm, nw, :junction, i)["p_min"]))
            JuMP.set_upper_bound(potential[i], get_potential(ref(gm, nw, :junction, i)["p_max"]))
        end
    end

    report && sol_component_value(gm, nw, :junction, :potential, ids(gm, nw, :junction), potential)
    report && sol_component_value(gm, nw, :junction, :pressure, ids(gm, nw, :junction), invert_potential(potential))
end 

"all variables associated with edge flows"
function variable_flow_unified(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    variable_pipe_flow(gm, nw; bounded=bounded, report=report)
    variable_compressor_flow(gm, nw; bounded=bounded, report=report)
end

"variables associated with flow in pipes"
function variable_pipe_flow(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    f_pipe = var(gm, nw)[:f_pipe] = JuMP.@variable(gm.model,
        [i in ids(gm, nw, :pipe)],
        base_name="$(nw)_f_pipe",
        start=comp_start_value(ref(gm, nw, :pipe), i, "f_start", 0)
    )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(f_pipe[i], pipe["flow_min"])
            JuMP.set_upper_bound(f_pipe[i], pipe["flow_max"])
        end
    end
    
    report && sol_component_value(gm, nw, :pipe, :f, ids(gm, nw, :pipe), f_pipe)
end

"variables associated with mass flow in compressors"
function variable_compressor_flow(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    f_compressor = var(gm, nw)[:f_compressor] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:compressor)],
        base_name="$(nw)_f_compressor",
        start=comp_start_value(ref(gm, nw, :compressor), i, "f_start", 0)
    )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            if (compressor["directionality"] == 1) 
                JuMP.set_lower_bound(f_compressor[i], 0.0)
            else
                JuMP.set_lower_bound(f_compressor[i], compressor["flow_min"])
            end 
            JuMP.set_upper_bound(f_compressor[i], compressor["flow_max"])
        end
    end

    report && sol_component_value(gm, nw, :compressor, :f, ids(gm, nw, :compressor), f_compressor)
end

"variables associated with demand"
function variable_delivery(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true, is_nominal::Bool=false)
    withdrawal_type = is_nominal ? "withdrawal_nominal" : "withdrawal_max"
    fl = var(gm, nw)[:withdrawal_delivery] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_delivery)],
        base_name="$(nw)_fl",
        start=comp_start_value(ref(gm, nw, :delivery), i, "fl_start", 
        ref(gm,nw,:delivery,i)[withdrawal_type])
    )

    if bounded
        for (i, _) in ref(gm, nw, :dispatchable_delivery)
            JuMP.set_lower_bound(fl[i], ref(gm,nw,:delivery,i)["withdrawal_min"])
            JuMP.set_upper_bound(fl[i], ref(gm,nw,:delivery,i)[withdrawal_type])
        end
    end

    if report
        sol_component_value(gm, nw, :delivery, :withdrawal_delivery, ids(gm, nw, :dispatchable_delivery), fl)
    end
end


"variables associated with transfer"
function variable_transfer(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true, is_nominal::Bool=false)
    withdrawal_type = is_nominal ? "withdrawal_nominal" : "withdrawal_max"
    ft = var(gm, nw)[:withdrawal_transfer] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_transfer)],
        base_name="$(nw)_ft",
        start= ref(gm, nw, :transfer, i)["withdrawal_min"] < 0.0 ?
            ref(gm, nw, :transfer, i)["withdrawal_min"] :
            ref(gm, nw, :transfer, i)[withdrawal_type]
    )

    if bounded
        for (i, _) in ref(gm, nw, :dispatchable_transfer)
            JuMP.set_lower_bound(ft[i], ref(gm, nw, :transfer, i)["withdrawal_min"])
            JuMP.set_upper_bound(ft[i], ref(gm, nw, :transfer, i)[withdrawal_type])
        end
    end

    if report
        sol_component_value(gm, nw, :transfer, :withdrawal_transfer, ids(gm, nw, :dispatchable_transfer), ft)
    end
end


"variables associated with production"
function variable_receipt(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true, is_nominal::Bool=false)
    injection_type = is_nominal ? "injection_nominal" : "injection_max"
    
    fg = var(gm, nw)[:injection_receipt] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_receipt)],
        base_name="$(nw)_fg",
        start=comp_start_value(ref(gm, nw, :receipt), i, "fg_start", 
        ref(gm,nw,:receipt,i)[injection_type]
        )
    )

    if bounded
        for (i, _) in ref(gm, nw, :dispatchable_receipt)
            JuMP.set_lower_bound(fg[i], ref(gm,nw,:receipt,i)["injection_min"])
            JuMP.set_upper_bound(fg[i], ref(gm,nw,:receipt,i)[injection_type])
        end
    end

    if report
        sol_component_value(gm, nw, :receipt, :injection_receipt, ids(gm, nw, :dispatchable_receipt), fg)
    end
end

"variables associated with storage flows"
function variable_storage_unified(gm::AbstractGasModel,nw::Int = nw_id_default; bounded::Bool = true,report::Bool = true)
    f_wh = var(gm, nw)[:withdrawal_storage] = 
        JuMP.@variable(gm.model,[i in ids(gm, nw, :storage)],base_name = "$(nw)_storage_well_head")

    if bounded
        for (i, storage) in ref(gm, nw, :storage)
            lb = min(-storage["flow_injection_rate_max"], 0.0)
            ub = max(storage["flow_withdrawal_rate_max"], 0.0)
            JuMP.set_lower_bound(f_wh[i], lb)
            JuMP.set_upper_bound(f_wh[i], ub)
        end
    end

    if report
        _IM.sol_component_value(gm,gm_it_sym,nw,:storage, :withdrawal_storage, ids(gm, nw, :storage), f_wh)
    end
end