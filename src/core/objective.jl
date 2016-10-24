##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################

# function for costing expansion of pipes and compressors
function objective_min_ne_cost{T}(gm::GenericGasModel{T}; normalization=1000000.0)
    zp = getvariable(gm.model, :zp)
    zc = getvariable(gm.model, :zc)
    obj = @objective(gm.model, Min, sum{gm.set.new_connections[i]["construction_cost"]/normalization * zp[i], i in gm.set.new_pipe_indexes} + sum{gm.set.new_connections[i]["construction_cost"] * zc[i], i in gm.set.new_compressor_indexes})      
    return obj
 end

# function for maximizing load
function objective_max_load{T}(gm::GenericGasModel{T})
    ql = getvariable(gm.model, :ql_gas)
    obj = @objective(gm.model, Max, sum{ql[i], (i,junction) in gm.set.junctions})      
    return obj
 end
 

