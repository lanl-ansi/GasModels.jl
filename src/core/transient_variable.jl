"variables associated with density (transient)"
function variable_density(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    rho = var(gm, nw)[:density] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :junction)],
            base_name = "$(nw)_rho",
        )

    if bounded
        for (i, junction) in ref(gm, nw, :junction)
            JuMP.set_lower_bound(rho[i], junction["p_min"])
            JuMP.set_upper_bound(rho[i], junction["p_max"])
        end
    end

    report &&
        sol_component_value(gm, nw, :junction, :density, ids(gm, nw, :junction), rho)
    report &&
        sol_component_value(gm, nw, :junction, :pressure, ids(gm, nw, :junction), rho)
end

"variables associated with compressor mass flow (transient)"
function variable_compressor_flow(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    max_mass_flow = ref(gm, nw, :max_mass_flow)
    f = var(gm, nw)[:compressor_flow] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :compressor)],
            base_name = "$(nw)_f_compressor",
        )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            type = get(compressor, "directionality", 0)
            if (type == 1)
                JuMP.set_lower_bound(f[i], 0.0)
            else
                JuMP.set_lower_bound(f[i], -max_mass_flow)
            end
            JuMP.set_upper_bound(f[i], max_mass_flow)
        end
    end

    report &&
        sol_component_value(gm, nw, :compressor, :flow, ids(gm, nw, :compressor), f)
end

"variables associated with pipe flux (transient)"
function variable_pipe_flux(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    phi = var(gm, nw)[:pipe_flux] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            base_name = "$(nw)_flux_pipe",
        )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(phi[i], pipe["flux_min"])
            JuMP.set_upper_bound(phi[i], pipe["flux_max"])
        end
    end

    if report
        sol_component_value(gm, nw, :pipe, :flux, ids(gm, nw, :pipe), phi)
        sol_f = Dict(i => phi[i] * ref(gm, nw, :pipe, i)["area"] for i in ids(gm, nw, :pipe))
        sol_component_value(gm, nw, :pipe, :flow, ids(gm, nw, :pipe), sol_f)
    end
end

"variables associated with pipe flux average (transient)"
function variable_pipe_flux_avg(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    phi = var(gm, nw)[:pipe_flux_avg] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            base_name = "$(nw)_flux_pipe_avg",
        )

    flow = var(gm, nw)[:pipe_flow_avg] = JuMP.@expression(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            phi[i] * ref(gm, nw, :pipe, i)["area"]
        )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(phi[i], pipe["flux_min"])
            JuMP.set_upper_bound(phi[i], pipe["flux_max"])
        end
    end

    if report
        sol_component_value(gm, nw, :pipe, :flux_avg, ids(gm, nw, :pipe), phi)
        sol_component_value(gm, nw, :pipe, :flow_avg, ids(gm, nw, :pipe), flow)
    end
end

"variables associated with pipe flux negative (transient)"
function variable_pipe_flux_neg(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    phi = var(gm, nw)[:pipe_flux_neg] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            base_name = "$(nw)_flux_pipe_neg",
        )

    flow = var(gm, nw)[:pipe_flow_neg] = JuMP.@expression(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            phi[i] * ref(gm, nw, :pipe, i)["area"]
        )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(phi[i], pipe["flux_min"])
            JuMP.set_upper_bound(phi[i], pipe["flux_max"])
        end
    end

    if report
        sol_component_value(gm, nw, :pipe, :flux_neg, ids(gm, nw, :pipe), phi)
        sol_component_value(gm, nw, :pipe, :flow_neg, ids(gm, nw, :pipe), flow)
    end
end

"variables associated with pipe flux (from)"
function variable_pipe_flux_fr(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    phi = var(gm, nw)[:pipe_flux_fr] = JuMP.@expression(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            var(gm, nw, :pipe_flux_avg, i) - var(gm, nw, :pipe_flux_neg, i)
        )

    flow = var(gm, nw)[:pipe_flow_fr] = JuMP.@expression(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            phi[i] * ref(gm, nw, :pipe, i)["area"]
        )

    if report
        sol_component_value(gm, nw, :pipe, :flux_fr, ids(gm, nw, :pipe), phi)
        sol_component_value(gm, nw, :pipe, :flow_fr, ids(gm, nw, :pipe), flow)
    end
end

"variables associated with pipe flux (to)"
function variable_pipe_flux_to(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    phi = var(gm, nw)[:pipe_flux_to] = JuMP.@expression(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            var(gm, nw, :pipe_flux_avg, i) + var(gm, nw, :pipe_flux_neg, i)
        )

    flow = var(gm, nw)[:pipe_flow_to] = JuMP.@expression(
            gm.model,
            [i in ids(gm, nw, :pipe)],
            phi[i] * ref(gm, nw, :pipe, i)["area"]
        )

    if report
        sol_component_value(gm, nw, :pipe, :flux_to, ids(gm, nw, :pipe), phi)
        sol_component_value(gm, nw, :pipe, :flow_to, ids(gm, nw, :pipe), flow)
    end
end

"variables associated with compression ratio (transient)"
function variable_c_ratio(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    c_ratio = var(gm, nw)[:compressor_ratio] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :compressor)],
            base_name = "$(nw)_c_ratio",
        )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(c_ratio[i], compressor["c_ratio_min"])
            JuMP.set_upper_bound(c_ratio[i], compressor["c_ratio_max"])
        end
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :compressor,
        :c_ratio,
        ids(gm, nw, :compressor),
        c_ratio,
    )
end

"variables associated with compression power (transient)"
function variable_compressor_power(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    c_power = var(gm, nw)[:compressor_power_var] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :compressor)],
            base_name = "$(nw)_c_power",
        )

    if bounded
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(c_power[i], 0.0)
            JuMP.set_upper_bound(c_power[i], compressor["power_max"])
        end
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :compressor,
        :power_var,
        ids(gm, nw, :compressor),
        c_power,
    )
end

"variables associated with injection in receipts (transient)"
function variable_injection(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    s = var(gm, nw)[:injection] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_receipt)],
            base_name = "$(nw)_injection",
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
            gm_it_sym,
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
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    d = var(gm, nw)[:withdrawal] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_delivery)],
            base_name = "$(nw)_withdrawal"
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
            gm_it_sym,
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
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    s = var(gm, nw)[:transfer_injection] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_transfer)],
            base_name = "$(nw)_transfer_injection"
        )

    d = var(gm, nw)[:transfer_withdrawal] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :dispatchable_transfer)],
            base_name = "$(nw)_transfer_withdrawal"
        )

    t = var(gm, nw)[:transfer_effective] = JuMP.@expression(
            gm.model,
            [i in ids(gm, nw, :dispatchable_transfer)],
            d[i] - s[i]
        )

    if bounded
        for (i, transfer) in ref(gm, nw, :dispatchable_transfer)
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
            gm_it_sym,
            nw,
            :transfer,
            :injection,
            ids(gm, nw, :transfer),
            sol_injection,
        )
        _IM.sol_component_value(
            gm,
            gm_it_sym,
            nw,
            :transfer,
            :withdrawal,
            ids(gm, nw, :transfer),
            sol_withdrawal,
        )
    end
end

"variables associated with storage flows"
function variable_storage_flow(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)

    f_s = var(gm, nw)[:storage_flow] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :storage)],
            base_name = "$(nw)_storage_flow"
        )

    if bounded
        for (i, storage) in ref(gm, nw, :storage)
            lb = min(-storage["flow_injection_rate_max"], 0.0)
            ub = max(storage["flow_withdrawal_rate_max"], 0.0)
            JuMP.set_lower_bound(f_s[i], lb)
            JuMP.set_upper_bound(f_s[i], ub)
        end
    end

    if report
        _IM.sol_component_value(
            gm,
            gm_it_sym,
            nw,
            :storage,
            :storage_flow,
            ids(gm, nw, :storage),
            f_s,
        )
    end
end

"variables associated with reservoir density"
function variable_reservoir_density(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    rho_reservoir = var(gm, nw)[:reservoir_density] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :storage)],
            base_name = "$(nw)_density_reservoir"
        )

    if bounded
        for (i, storage) in ref(gm, nw, :storage)
            JuMP.set_lower_bound(rho_reservoir[i], storage["reservoir_density_min"])
            JuMP.set_upper_bound(rho_reservoir[i], storage["reservoir_density_max"])
        end
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :reservoir_density,
        ids(gm, nw, :storage),
        rho_reservoir,
    )
    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :reservoir_pressure,
        ids(gm, nw, :storage),
        rho_reservoir,
    )
end
