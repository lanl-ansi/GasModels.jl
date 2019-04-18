##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################

" function for costing expansion of pipes and compressors "
function objective_min_ne_cost(gm::GenericGasModel, nws=[gm.cnw]; normalization=1.0)
    zp = Dict(n => var(gm,n,:zp) for n in nws)
    zc = Dict(n => var(gm,n,:zc) for n in nws)
    obj = @objective(gm.model, Min, sum(
                                        sum(ref(gm,n,:ne_connection,i)["construction_cost"]/normalization * zp[n][i] for i in keys(ref(gm,n,:ne_pipe))) +
                                        sum(ref(gm,n,:ne_connection,i)["construction_cost"]/normalization * zc[n][i] for i in keys(ref(gm,n,:ne_compressor)))
                                        for n in nws))
end

" function for maximizing load "
function objective_max_load(gm::GenericGasModel, nws=[gm.cnw])
    load_set = Dict(n => keys(Dict(x for x in ref(gm,n,:consumer) if x.second["dispatchable"] == 1)) for n in nws)
    fl =  Dict(n => var(gm,n,:fl) for n in nws)
    obj = @objective(gm.model, Max, sum(sum(ref(gm,n,:consumer,i)["priority"] *  fl[n][i] for i in load_set[n]) for n in nws))
 end
