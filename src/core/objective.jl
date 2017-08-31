##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################

" function for costing expansion of pipes and compressors "
function objective_min_ne_cost{T}(gm::GenericGasModel{T}; normalization=1000000.0)
    zp = gm.var[:zp] 
    zc = gm.var[:zc] 
    obj = @objective(gm.model, Min, sum(gm.ref[:ne_connection][i]["construction_cost"]/normalization * zp[i] for i in keys(gm.ref[:ne_pipe])) 
      + sum(gm.ref[:ne_connection][i]["construction_cost"] * zc[i] for i in keys(gm.ref[:ne_compressor])))      
    return obj
end

" function for maximizing load "
function objective_max_load{T}(gm::GenericGasModel{T})
    load_set = filter(i -> gm.ref[:junction][i]["qlmin"] != gm.ref[:junction][i]["qlmax"], keys(gm.ref[:junction]))    
    ql = gm.var[:ql] 
    obj = @objective(gm.model, Max, sum(ql[i] for i in load_set))      
    return obj
 end
 

