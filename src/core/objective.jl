##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################

function objective_min_expansion_cost{T}(gm::GenericGasModel{T}; normalization=1000000.0)
    zp = getvariable(gm.model, :zp)
    zc = getvariable(gm.model, :zc)
    cost = (i) -> gm.set.connections[i]["construction_cost"]
    return @objective(gm.model, Min, sum{cost(i)/normalization * zp[i], i in keys(zp)} + sum{cost(i) * zc[i], i in keys(zc)})
 end



