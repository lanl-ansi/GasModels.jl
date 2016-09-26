##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################

# function for costing expansion of pipes and compressors
function objective_min_expansion_cost{T}(gm::GenericGasModel{T}; normalization=1000000.0)
    zp = getvariable(gm.model, :zp)
    zc = getvariable(gm.model, :zc)
    return @objective(gm.model, Min, sum{gm.set.connections[i]["construction_cost"]/normalization * zp[i], i in gm.set.new_pipes} + sum{gm.set.connections[i]["construction_cost"] * zc[i], i in gm.set.new_compressors})      
 end



