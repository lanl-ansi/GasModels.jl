"variables associated with density (transient)"
function variable_density(
    gm::AbstractGasModel,
    nw::Int = gm.cnw;
    bounded::Bool = true,
    report::Bool = true,
)
    rho =
        var(gm, nw)[:density] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :junction)],
            base_name = "$(nw)_rho",
            start = comp_start_value(
                ref(gm, nw, :junction),
                i,
                "rho_start",
                ref(gm, nw, :junction, i)["p_min"],
            )
        )

    if bounded
        for (i, junction) in ref(gm, nw, :junction)
            JuMP.set_lower_bound(rho[i], junction["p_min"])
            JuMP.set_upper_bound(rho[i], junction["p_max"])
        end
    end

    report &&
    _IM.sol_component_value(gm, nw, :junction, :density, ids(gm, nw, :junction), rho)
    report &&
    _IM.sol_component_value(gm, nw, :junction, :pressure, ids(gm, nw, :junction), rho)
end

"variables associated with compressor mass flow (transient)"
function variable_compressor_flow(
    gm::AbstractGasModel,
    nw::Int = gm.cnw;
    bounded::Bool = true,
    report::Bool = true,
)
    max_mass_flow = ref(gm, nw, :max_mass_flow)
    f =
        var(gm, nw)[:compressor_flow] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :compressor)],
            base_name = "$(nw)_f_compressor",
            start = comp_start_value(
                ref(gm, nw, :compressor),
                i,
                "f_compressor_start",
                0.0,
            )
        )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(f[i], -max_mass_flow)
            JuMP.set_upper_bound(f[i], max_mass_flow)
        end
    end

    report &&
    _IM.sol_component_value(gm, nw, :compressor, :flow, ids(gm, nw, :compressor), f)
end

"variables associated with pipe flux (transient)"
function variable_pipe_flux(
    gm::AbstractGasModel,
    nw::Int = gm.cnw;
    bounded::Bool = true,
    report::Bool = true,
)
    phi =
        var(gm, nw)[:pipe_flux] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            base_name = "$(nw)_flux_pipe",
            start = comp_start_value(
                ref(gm, nw, :pipe),
                i,
                "phi_start",
                ref(gm, nw, :pipe, i)["flux_min"],
            )
        )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(phi[i], pipe["flux_min"])
            JuMP.set_upper_bound(phi[i], pipe["flux_max"])
        end
    end

    if report
        _IM.sol_component_value(gm, nw, :pipe, :flux, ids(gm, nw, :pipe), phi)
        sol_f =
            Dict(i => phi[i] * ref(gm, nw, :pipe, i)["area"] for i in ids(gm, nw, :pipe))
        _IM.sol_component_value(gm, nw, :pipe, :flow, ids(gm, nw, :pipe), sol_f)
    end
end

"variables associated with compression ratio (transient)"
function variable_c_ratio(
    gm::AbstractGasModel,
    nw::Int = gm.cnw;
    bounded::Bool = true,
    report::Bool = true,
)
    c_ratio =
        var(gm, nw)[:compressor_ratio] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :compressor)],
            base_name = "$(nw)_c_ratio",
            start = comp_start_value(ref(gm, nw, :compressor), i, "c_ratio_start", 1.0)
        )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(c_ratio[i], compressor["c_ratio_min"])
            JuMP.set_upper_bound(c_ratio[i], compressor["c_ratio_max"])
        end
    end

    report && _IM.sol_component_value(
        gm,
        nw,
        :compressor,
        :c_ratio,
        ids(gm, nw, :compressor),
        c_ratio,
    )
end

"variables associated with injection in receipts (transient)"
function variable_injection(
    gm::AbstractGasModel,
    nw::Int = gm.cnw;
    bounded::Bool = true,
    report::Bool = true,
)
    s =
        var(gm, nw)[:injection] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_receipt)],
            base_name = "$(nw)_injection",
            start = comp_start_value(
                ref(gm, nw, :dispatchable_receipt),
                i,
                "receipt_start",
                ref(gm, nw, :dispatchable_receipt, i)["injection_min"],
            )
        )

    if bounded
        for (i, receipt) in ref(gm, nw, :dispatchable_receipt)
            JuMP.set_lower_bound(s[i], receipt["injection_min"])
            JuMP.set_upper_bound(s[i], receipt["injection_max"])
        end
    end

    if report
        sol_injection = Dict()
        for (i, receipt) in ref(gm, nw, :receipt)
            if receipt["is_dispatchable"] == true
                sol_injection[i] = s[i]
            else
                sol_injection[i] = receipt["injection_nominal"]
            end
        end
        _IM.sol_component_value(
            gm,
            nw,
            :receipt,
            :injection,
            ids(gm, nw, :receipt),
            sol_injection,
        )
    end
end

"variables associated with withdrawal in deliveries (transient)"
function variable_withdrawal(
    gm::AbstractGasModel,
    nw::Int = gm.cnw;
    bounded::Bool = true,
    report::Bool = true,
)
    d =
        var(gm, nw)[:withdrawal] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_delivery)],
            base_name = "$(nw)_withdrawal",
            start = comp_start_value(
                ref(gm, nw, :dispatchable_delivery),
                i,
                "receipt_start",
                ref(gm, nw, :dispatchable_delivery, i)["withdrawal_min"],
            )
        )

    if bounded
        for (i, receipt) in ref(gm, nw, :dispatchable_delivery)
            JuMP.set_lower_bound(d[i], receipt["withdrawal_min"])
            JuMP.set_upper_bound(d[i], receipt["withdrawal_max"])
        end
    end

    if report
        sol_withdrawal = Dict()
        for (i, delivery) in ref(gm, nw, :delivery)
            if delivery["is_dispatchable"] == true
                sol_withdrawal[i] = d[i]
            else
                sol_withdrawal[i] = delivery["withdrawal_nominal"]
            end
        end
        _IM.sol_component_value(
            gm,
            nw,
            :delivery,
            :withdrawal,
            ids(gm, nw, :delivery),
            sol_withdrawal,
        )
    end
end

"variables associated with net withdrawal in transfers (transient)"
function variable_transfer_flow(
    gm::AbstractGasModel,
    nw::Int = gm.cnw;
    bounded::Bool = true,
    report::Bool = true,
)
    t =
        var(gm, nw)[:transfer_effective] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_transfer)],
            base_name = "$(nw)_transfer_effective"
        )

    s =
        var(gm, nw)[:transfer_injection] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_transfer)],
            base_name = "$(nw)_transfer_injection"
        )

    d =
        var(gm, nw)[:transfer_withdrawal] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_transfer)],
            base_name = "$(nw)_transfer_withdrawal"
        )

    if bounded
        for (i, transfer) in ref(gm, nw, :dispatchable_transfer)
            JuMP.set_lower_bound(t[i], min(transfer["withdrawal_min"], 0.0))
            JuMP.set_upper_bound(t[i], max(0.0, transfer["withdrawal_max"]))
            JuMP.set_lower_bound(s[i], 0.0)
            JuMP.set_upper_bound(s[i], max(0.0, -transfer["withdrawal_min"]))
            JuMP.set_lower_bound(d[i], 0.0)
            JuMP.set_upper_bound(d[i], max(transfer["withdrawal_max"], 0.0))
        end
    end

    if report
        sol_injection = Dict()
        sol_withdrawal = Dict()
        for (i, transfer) in ref(gm, nw, :transfer)
            if transfer["is_dispatchable"] == true
                sol_injection[i] = s[i]
                sol_withdrawal[i] = d[i]
            else
                sol_injection[i] = 0.0
                sol_withdrawal[i] = transfer["withdrawal_nominal"]
            end
        end
        _IM.sol_component_value(
            gm,
            nw,
            :transfer,
            :injection,
            ids(gm, nw, :transfer),
            sol_injection,
        )
        _IM.sol_component_value(
            gm,
            nw,
            :transfer,
            :withdrawal,
            ids(gm, nw, :transfer),
            sol_withdrawal,
        )
    end
end
