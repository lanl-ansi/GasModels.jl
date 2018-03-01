##########################################################################################################
# The purpose of this file is to define commonly used and created objective functions used in gas models
##########################################################################################################

" function for costing expansion of pipes and compressors "
function objective_min_ne_cost{T}(gm::GenericGasModel{T}, nws=[gm.cnw]; normalization=1.0)
    zp = Dict(n => gm.var[:nw][n][:zp] for n in nws)  
    zc = Dict(n => gm.var[:nw][n][:zc] for n in nws)  
    
    obj = @objective(gm.model, Min, sum(
                                        sum(gm.ref[:nw][n][:ne_connection][i]["construction_cost"]/normalization * zp[n][i] for i in keys(gm.ref[:nw][n][:ne_pipe])) + 
                                        sum(gm.ref[:nw][n][:ne_connection][i]["construction_cost"]/normalization * zc[n][i] for i in keys(gm.ref[:nw][n][:ne_compressor])) 
                                        for n in nws)
                    )      
end

" function for maximizing load "
function objective_max_load{T}(gm::GenericGasModel{T}, nws=[gm.cnw])
    load_set = Dict(n => filter(i -> gm.ref[:nw][n][:consumer][i]["qlmax"] != 0 || gm.ref[:nw][n][:consumer][i]["qlmin"] != 0, keys(gm.ref[:nw][n][:consumer])) for n in nws)
    ql =  Dict(n => gm.var[:nw][n][:ql] for n in nws)  
    obj = @objective(gm.model, Max, sum(sum(ql[n][i] for i in load_set[n]) for n in nws))      
 end
 

