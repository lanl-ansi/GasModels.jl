##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################


"function for costing expansion of pipes and compressors: ``\\sum_{k \\in ne\\_pipe} c_k zp_k  +  \\sum_{k \\in ne\\_compressor} c_k zc_k``"
function objective_min_ne_cost(gm::AbstractGasModel, nws = [nw_id_default])
    zp = Dict(n => var(gm, n, :zp) for n in nws)
    zc = Dict(n => var(gm, n, :zc) for n in nws)

    return JuMP.@objective(
        gm.model,
        Min,
        sum(
            sum(
                ref(gm, n, :ne_pipe)[i]["construction_cost"] * zp[n][i]
                for i in keys(ref(gm, n, :ne_pipe))
            ) + sum(
                ref(gm, n, :ne_compressor)[i]["construction_cost"] * zc[n][i]
                for i in keys(ref(gm, n, :ne_compressor))
            ) for n in nws
        )
    )
end


"function for maximizing prioritzed load: ``\\max \\sum_{i \\in {\\cal D }} \\omega_i \\boldsymbol{d}_i``"
function objective_max_load(gm::AbstractGasModel, nws = [nw_id_default])
    load_set = Dict(
        n => collect(keys(Dict(
            x for x in ref(gm, n, :delivery) if x.second["is_dispatchable"] == 1
        ))) for n in nws
    )
    priorities = Dict(
        n => Dict(
            i => haskey(ref(gm, n, :delivery, i), "priority") ?
                        ref(gm, n, :delivery, i)["priority"] : 1.0 for i in load_set[n]
        ) for n in nws
    )
    fl = Dict(n => var(gm, n, :fl) for n in nws)
    for n in nws
        if length(load_set[n]) == 0
            delete!(load_set, n)
        end
    end
    if length(load_set) == 0
        return 0
    else
        return JuMP.@objective(
            gm.model,
            Max,
            sum(sum(priorities[n][i] * fl[n][i] for i in load_set[n]) for n in nws)
        )
    end
end


"function for minimizing compressor energy"
function objective_min_compressor_energy(gm::AbstractGasModel, nws = [nw_id_default])
    r = Dict(n => var(gm, n, :rsqr) for n in nws)
    f = Dict(n => var(gm, n, :f_compressor) for n in nws)
    gamma = get_specific_heat_capacity_ratio(gm.data)
    m = (gamma - 1) / gamma

    # some solvers only support support nonlinear objectives by placing them in the constraints
    z = JuMP.@variable(gm.model)
    JuMP.@constraint(gm.model, z >= sum(sum((r[n][i]^m - 1) * f[n][i] for (i, compressor) in ref(gm, n, :compressor)) for n in nws))
    return JuMP.@objective(gm.model, Min, z)
end


"function for minimizing economic costs: ``\\min \\sum_{j \\in {\\cal D}} \\kappa_j \\boldsymbol{d}_j - \\sum_{j \\in {\\cal T}} \\kappa_j \\boldsymbol{\\tau}_j - \\sum_{j \\in {\\cal R}} \\kappa_j \\boldsymbol{r}_j -
    \\sum_{ijk \\in {\\cal C}} \\boldsymbol{f}_{ijk} (\\boldsymbol{\\alpha}_{ijk}^m - 1)``"
function objective_min_economic_costs(gm::AbstractGasModel, nws = [nw_id_default])
    r = Dict(n => var(gm, n, :rsqr) for n in nws)
    f = Dict(n => var(gm, n, :f_compressor) for n in nws)
    fl = Dict(n => var(gm, n, :fl) for n in nws)
    fg = Dict(n => var(gm, n, :fg) for n in nws)
    ft = Dict(n => var(gm, n, :ft) for n in nws)
    gamma = get_specific_heat_capacity_ratio(gm.data)
    m = ((gamma - 1) / gamma) / 2
    T = get_temperature(gm.data)
    G = get_gas_specific_gravity(gm.data)
    work = _calc_compressor_work(gamma, G, T)
    base_flow = get_base_flow(gm.data)

    load_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :delivery) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    transfer_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :transfer) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    prod_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :receipt) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    load_prices = Dict(
        n => Dict(
            i => get(ref(gm, n, :delivery, i), "bid_price", 1.0) for i in load_set[n]
        ) for n in nws
    )
    prod_prices = Dict(
        n => Dict(
            i => get(ref(gm, n, :receipt, i), "offer_price", 1.0) for i in prod_set[n]
        ) for n in nws
    )
    transfer_prices = Dict(
        n => Dict(
            i => ref(gm, n, :transfer, i)["withdrawal_min"] >= 0.0 ?  get(ref(gm, n, :transfer, i), "bid_price", 1.0) : (-1) * get(ref(gm, n, :transfer, i), "offer_price", 1.0) for i in transfer_set[n]
        ) for n in nws
    )

    economic_weighting = get_economic_weighting(gm.data)

    # prices are already normalized by base_flow, so we also need to normalize compressor power by base_flow in the objective
    z = JuMP.@variable(gm.model)
    JuMP.@constraint(gm.model, z >= sum(
                                          economic_weighting * sum(-load_prices[n][i] * fl[n][i] for i in load_set[n]) +
                                          economic_weighting *
                                          sum(-transfer_prices[n][i] * ft[n][i] for i in transfer_set[n]) +
                                          economic_weighting * sum(prod_prices[n][i] * fg[n][i] for i in prod_set[n]) +
                                          (1.0 - economic_weighting) *
                                          sum(abs(f[n][i]) * (r[n][i]^m - 1) * work * base_flow for (i, compressor) in ref(gm, n, :compressor))
                                          for n in nws
                                       ))
    return JuMP.@objective(gm.model, Min, z)
end

"function for minimizing supply demand costs: ``\\min \\sum_{j \\in {\\cal D}} \\kappa_j \\boldsymbol{d}_j - \\sum_{j \\in {\\cal T}} \\kappa_j \\boldsymbol{\\tau}_j - \\sum_{j \\in {\\cal R}} \\kappa_j \\boldsymbol{r}_j
    ``"
function objective_min_supply_demand_costs(gm::AbstractGasModel, nws = [nw_id_default])
    r = Dict(n => var(gm, n, :rsqr) for n in nws)
    f = Dict(n => var(gm, n, :f_compressor) for n in nws)
    fl = Dict(n => var(gm, n, :fl) for n in nws)
    fg = Dict(n => var(gm, n, :fg) for n in nws)
    ft = Dict(n => var(gm, n, :ft) for n in nws)
    gamma = get_specific_heat_capacity_ratio(gm.data)
    m = ((gamma - 1) / gamma) / 2
    T = get_temperature(gm.data)
    G = get_gas_specific_gravity(gm.data)
    work = _calc_compressor_work(gamma, G, T)
    base_flow = get_base_flow(gm.data)

    load_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :delivery) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    transfer_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :transfer) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    prod_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :receipt) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    load_prices = Dict(
        n => Dict(
            i => get(ref(gm, n, :delivery, i), "bid_price", 1.0) for i in load_set[n]
        ) for n in nws
    )
    prod_prices = Dict(
        n => Dict(
            i => get(ref(gm, n, :receipt, i), "offer_price", 1.0) for i in prod_set[n]
        ) for n in nws
    )
    transfer_prices = Dict(
        n => Dict(
            i => ref(gm, n, :transfer, i)["withdrawal_min"] >= 0.0 ?  get(ref(gm, n, :transfer, i), "bid_price", 1.0) : (-1) * get(ref(gm, n, :transfer, i), "offer_price", 1.0) for i in transfer_set[n]
        ) for n in nws
    )

    # prices are already normalized by base_flow, so we also need to normalize compressor power by base_flow in the objective
    z = JuMP.@variable(gm.model)
    JuMP.@constraint(gm.model, z >= sum(
                                          sum(-load_prices[n][i] * fl[n][i] for i in load_set[n]) +
                                          sum(-transfer_prices[n][i] * ft[n][i] for i in transfer_set[n]) +
                                          sum(prod_prices[n][i] * fg[n][i] for i in prod_set[n])                                          
                                          for n in nws
                                       ))
    return JuMP.@objective(gm.model, Min, z)
end

"transient objective for minimizing a linear combination of compressor power and load shed"
function objective_min_transient_economic_costs(gm::AbstractGasModel, time_points)
    econ_weight = gm.ref[:it][gm_it_sym][:economic_weighting]
    load_shed_expression = 0.0
    compressor_power_expression = 0.0
    load_shed_expressions = []
    compressor_power_expressions = []
    base_flow = get_base_flow(gm.data)

    for nw in time_points[1:end-1]
        for (i, receipt) in ref(gm, nw, :dispatchable_receipt)
            load_shed_expression += (receipt["offer_price"] * var(gm, nw, :injection)[i])
        end
        for (i, delivery) in ref(gm, nw, :dispatchable_delivery)
            load_shed_expression -= (delivery["bid_price"] * var(gm, nw, :withdrawal)[i])
        end
        for (i, transfer) in ref(gm, nw, :dispatchable_transfer)
            load_shed_expression += (
                transfer["offer_price"] * var(gm, nw, :transfer_injection)[i] -
                transfer["bid_price"] * var(gm, nw, :transfer_withdrawal)[i]
            )
        end
        for (i, compressor) in ref(gm, nw, :compressor)
            compressor_power_expression += var(gm, nw, :compressor_power_var, i)
        end
    end

    # bid price are normalized by base_flow, so also need normalize the coefficient of compressor energy (so 1 * base_flow)
    return JuMP.@objective(
        gm.model,
        Min,
        econ_weight * load_shed_expression +
        (1 - econ_weight) * base_flow * compressor_power_expression
    )
end

"minimum load shedding objective for transient OGF problem"
function objective_min_transient_load_shed(gm::AbstractGasModel, time_points)
    load_shed_expression = 0.0
    for nw in time_points[1:end-1]
        for (i, receipt) in ref(gm, nw, :dispatchable_receipt)
            load_shed_expression += (receipt["offer_price"] * var(gm, nw, :injection)[i])
        end
        for (i, delivery) in ref(gm, nw, :dispatchable_delivery)
            load_shed_expression -= (delivery["bid_price"] * var(gm, nw, :withdrawal)[i])
        end
        for (i, transfer) in ref(gm, nw, :dispatchable_transfer)
            load_shed_expression += (
                transfer["offer_price"] * var(gm, nw, :transfer_injection)[i] -
                transfer["bid_price"] * var(gm, nw, :transfer_withdrawal)[i]
            )
        end
    end

    return JuMP.@objective(gm.model, Min, load_shed_expression)
end

"minium compressor power objective for transient OGF problem"
function objective_min_transient_compressor_power(gm::AbstractGasModel, time_points)
    compressor_power_expression = 0

    for nw in time_points[1:end-1]
        for (i, compressor) in ref(gm, nw, :compressor)
            compressor_power_expression += var(gm, nw, :compressor_power_var)[i]
        end
    end

    return JuMP.@objective(gm.model, Min, compressor_power_expression)
end



"function for minimizing new economic costs: ``\\min \\sum_{j \\in {\\cal D}} \\kappa_j \\boldsymbol{d}_j - \\sum_{j \\in {\\cal T}} \\kappa_j \\boldsymbol{\\tau}_j - \\sum_{j \\in {\\cal R}} \\kappa_j \\boldsymbol{r}_j -
    \\sum_{k \\in {\\cal C}} |\\boldsymbol{p^2}_{jk} - \\boldsymbol{p^2}_{ik}| ``"
function objective_min_proxy_economic_costs(gm::AbstractGasModel, nws = [nw_id_default])
    mpp = Dict(n => var(gm, n, :min_power_proxy) for n in nws)
    f = Dict(n => var(gm, n, :f_compressor) for n in nws)
    p2 = Dict(n => var(gm, n, :psqr) for n in nws)
    fl = Dict(n => var(gm, n, :fl) for n in nws)
    fg = Dict(n => var(gm, n, :fg) for n in nws)
    ft = Dict(n => var(gm, n, :ft) for n in nws)
    gamma = get_specific_heat_capacity_ratio(gm.data)
    m = ((gamma - 1) / gamma) / 2
    T = get_temperature(gm.data)
    G = get_gas_specific_gravity(gm.data)
    work = _calc_compressor_work(gamma, G, T)
    base_flow = get_base_flow(gm.data)

    load_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :delivery) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    transfer_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :transfer) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    prod_set = Dict(
        n => keys(Dict(
            x for x in ref(gm, n, :receipt) if x.second["is_dispatchable"] == 1
        )) for n in nws
    )
    load_prices = Dict(
        n => Dict(
            i => get(ref(gm, n, :delivery, i), "bid_price", 1.0) for i in load_set[n]
        ) for n in nws
    )
    prod_prices = Dict(
        n => Dict(
            i => get(ref(gm, n, :receipt, i), "offer_price", 1.0) for i in prod_set[n]
        ) for n in nws
    )
    transfer_prices = Dict(
        n => Dict(
            i => get(ref(gm, n, :transfer, i), "bid_price", 1.0) for i in transfer_set[n]
        ) for n in nws
    )

    economic_weighting = get_economic_weighting(gm.data)

    # prices are already normalized by base_flow, so we also need to normalize compressor power by base_flow in the objective
    z = JuMP.@variable(gm.model)
    JuMP.@constraint(gm.model, z >= sum(
                                          economic_weighting * sum(-load_prices[n][i] * fl[n][i] for i in load_set[n]) +
                                          economic_weighting *
                                          sum(-transfer_prices[n][i] * ft[n][i] for i in transfer_set[n]) +
                                          economic_weighting * sum(prod_prices[n][i] * fg[n][i] for i in prod_set[n]) +
                                          (1.0 - economic_weighting) *
                                          sum(mpp[n][i] for (i, compressor) in ref(gm, n, :compressor))
                                          for n in nws
                                       ))
    return JuMP.@objective(gm.model, Min, z)
end
