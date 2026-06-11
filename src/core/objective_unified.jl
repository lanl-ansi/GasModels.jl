"function for minimizing economic costs: ``\\min \\sum_{j \\in {\\cal D}} \\kappa_j \\boldsymbol{d}_j - \\sum_{j \\in {\\cal T}} \\kappa_j \\boldsymbol{\\tau}_j - \\sum_{j \\in {\\cal R}} \\kappa_j \\boldsymbol{r}_j -
    \\sum_{ijk \\in {\\cal C}} \\boldsymbol{f}_{ijk} (\\boldsymbol{\\alpha}_{ijk}^m - 1)``"
function objective_min_economic_costs_unified(gm::AbstractGasModel, nws = [nw_id_default])
    transfer_price(transfer) = transfer["withdrawal_min"] >= 0.0 ?
        get(transfer, "bid_price", 1.0) : (-1) * get(transfer, "offer_price", 1.0)

    # r = Dict(n => var(gm, n, :rsqr) for n in nws)
    # f = Dict(n => var(gm, n, :f_compressor) for n in nws)
    fl = Dict(n => var(gm, n, :withdrawal_delivery) for n in nws)
    fg = Dict(n => var(gm, n, :injection_receipt) for n in nws)
    ft = Dict(n => var(gm, n, :withdrawal_transfer) for n in nws)

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
            i => transfer_price(ref(gm, n, :transfer, i)) for i in transfer_set[n]
        ) for n in nws
    )

    economic_weighting = get_economic_weighting(gm.data)

    # prices are already normalized by base_flow, so we also need to normalize compressor power by base_flow in the objective
    z = JuMP.@variable(gm.model)
    JuMP.@constraint(gm.model, z >= sum(economic_weighting * sum(-load_prices[n][i] * fl[n][i] for i in load_set[n]) +
                                        economic_weighting * sum(-transfer_prices[n][i] * ft[n][i] for i in transfer_set[n]) +
                                        economic_weighting * sum(prod_prices[n][i] * fg[n][i] for i in prod_set[n]) +
                                        (1.0 - economic_weighting) * 
                                        sum(
                                            var(gm, n, :potential, compressor["to_junction"]) - 
                                            var(gm, n, :potential, compressor["fr_junction"])
                                        for (i, compressor) in ref(gm, n, :compressor) if get(compressor, "directionality", 0) != 0; 
                                            init=0.0) + 
                                        sum(
                                            var(gm, n, :potential, compressor["to_junction"]) +
                                            var(gm, n, :potential, compressor["fr_junction"]) - 
                                            2*var(gm, n, :potential_compressor, i)
                                        for (i, compressor) in ref(gm, n, :compressor) if get(compressor, "directionality", 0) == 0; 
                                            init=0.0
                                        )
                                          for n in nws
                                       ))
    return JuMP.@objective(gm.model, Min, z)
end
