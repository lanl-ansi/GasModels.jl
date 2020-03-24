##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################

"function for costing expansion of pipes and compressors"
function objective_min_ne_cost(gm::AbstractGasModel, nws=[gm.cnw])
    normalization = get(gm.data, "objective_normalization", 1.0)

    zp = Dict(n => gm.var[:nw][n][:zp] for n in nws)
    zc = Dict(n => gm.var[:nw][n][:zc] for n in nws)

    obj = JuMP.@objective(gm.model, Min, sum(
                                        sum(gm.ref[:nw][n][:ne_pipe][i]["construction_cost"]/normalization * zp[n][i] for i in keys(gm.ref[:nw][n][:ne_pipe])) +
                                        sum(gm.ref[:nw][n][:ne_compressor][i]["construction_cost"]/normalization * zc[n][i] for i in keys(gm.ref[:nw][n][:ne_compressor]))
                                        for n in nws))
end


"function for maximizing load"
function objective_max_load(gm::AbstractGasModel, nws=[gm.cnw])
    load_set   = Dict(n => collect(keys(Dict(x for x in ref(gm,n,:delivery) if x.second["is_dispatchable"] == 1))) for n in nws)
    priorities = Dict(n => Dict(i => haskey(ref(gm,n,:delivery,i),"priority") ?  ref(gm,n,:delivery,i)["priority"] : 1.0 for i in load_set[n]) for n in nws)
    fl         =  Dict(n => var(gm,n,:fl) for n in nws)
    for n in nws
        if length(load_set[n]) == 0
            delete!(load_set, n)
        end
    end
    if length(load_set) == 0
        obj = 0
    else
        obj = JuMP.@objective(gm.model, Max, sum(sum(priorities[n][i] *  fl[n][i] for i in load_set[n]) for n in nws))
    end
 end


 "function for minimizing compressor energy"
 function objective_min_compressor_energy(gm::AbstractGasModel, nws=[gm.cnw])
     r          = Dict(n => var(gm,n,:r) for n in nws)
     f          = Dict(n => var(gm,n,:f_compressor) for n in nws)
     gamma      = gm.data["specific_heat_capacity_ratio"]
     m          = (gamma - 1) / gamma

     obj = JuMP.@NLobjective(gm.model, Min, sum(sum(  (r[n][i]^m - 1)  * f[n][i] for (i,compressor) in ref(gm,n,:compressor)) for n in nws))
end


"function for minimizing economic costs"
function objective_min_economic_costs(gm::AbstractGasModel, nws=[gm.cnw])
    r               = Dict(n => var(gm,n,:r) for n in nws)
    f               = Dict(n => var(gm,n,:f_compressor) for n in nws)
    fl              = Dict(n => var(gm,n,:fl) for n in nws)
    fg              = Dict(n => var(gm,n,:fg) for n in nws)
    ft              = Dict(n => var(gm,n,:ft) for n in nws)
    gamma           = gm.data["specific_heat_capacity_ratio"]
    m               = ((gamma - 1) / gamma) / 2
    load_set        = Dict(n => keys(Dict(x for x in ref(gm,n,:delivery) if x.second["is_dispatchable"] == 1)) for n in nws)
    transfer_set    = Dict(n => keys(Dict(x for x in ref(gm,n,:transfer) if x.second["is_dispatchable"] == 1)) for n in nws)
    prod_set        = Dict(n => keys(Dict(x for x in ref(gm,n,:receipt) if x.second["is_dispatchable"] == 1)) for n in nws)
    load_prices     = Dict(n => Dict(i => get(ref(gm,n,:delivery,i),"bid_price",1.0) for i in load_set[n]) for n in nws)
    prod_prices     = Dict(n => Dict(i => get(ref(gm,n,:receipt,i),"offer_price",1.0) for i in prod_set[n]) for n in nws)
    transfer_prices = Dict(n => Dict(i => get(ref(gm,n,:transfer,i),"bid_price", 1.0) for i in transfer_set[n]) for n in nws)

    economic_weighting = get(gm.data, "economic_weighting", 1.0)

    JuMP.@NLobjective(gm.model, Min, sum( economic_weighting*sum(-load_prices[n][i] * fl[n][i] for i in load_set[n]) +
                                                economic_weighting*sum(-transfer_prices[n][i] * ft[n][i] for i in transfer_set[n]) +
                                                economic_weighting*sum(prod_prices[n][i]  * fg[n][i] for i in prod_set[n]) +
                                               (1.0-economic_weighting)*sum(f[n][i] * (r[n][i]^m - 1) for (i,compressor) in ref(gm,n,:compressor))
                                           for n in nws))
end
