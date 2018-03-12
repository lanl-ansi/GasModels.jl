# tools for working with GasModels internal data format

"Computes the maximum flow of the Gas Model"
function calc_max_flow(data::Dict{String,Any})
    max_flow = 0  
    for (idx, producer) in data["producer"]
        if producer["qgmax"] > 0
          max_flow = max_flow + producer["qgmax"]
        end
        if producer["qgfirm"] > 0
          max_flow = max_flow + producer["qgfirm"]
        end
    end 
    return max_flow   
end

"Ensures that status exists as a field in connections"
function add_default_status(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)
    
    for (n,data) in nws_data  
        for entry in [data["connection"]; data["ne_connection"]; data["junction"]; data["consumer"]; data["producer"]]
            for (idx,component) in entry
                if !haskey(component,"status")
                    component["status"] = 1
                end          
            end    
        end
    end      
end

"Ensures that construction cost exists as a field for new connections"
function add_default_construction_cost(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)
    
    for (n,data) in nws_data      
        for (idx, connection) in data["ne_connection"]
            if !haskey(connection,"construction_cost")
                connection["construction_cost"] = 0
            end
        end    
    end
end

"Add the degree information"
function add_degree(ref::Dict{Symbol,Any})
    for (i,junction) in ref[:junction]
        junction["degree"] = 0
        junction["degree_all"] = 0 
    end

    for (i,j) in keys(ref[:parallel_connections])
        if length(ref[:parallel_connections]) > 0
            ref[:junction][i]["degree"] = ref[:junction][i]["degree"] + 1
            ref[:junction][j]["degree"] = ref[:junction][j]["degree"] + 1          
        end
    end
    
    for (i,j) in keys(ref[:all_parallel_connections])
        if length(ref[:parallel_connections]) > 0
            ref[:junction][i]["degree_all"] = ref[:junction][i]["degree_all"] + 1
            ref[:junction][j]["degree_all"] = ref[:junction][j]["degree_all"] + 1          
        end
    end
end

"Add the bounds for minimum and maximum pressure"
function add_pd_bounds_sqr(ref::Dict{Symbol,Any})
    for entry in [ref[:connection]; ref[:ne_connection]]
        for (idx,connection) in entry
            i_idx = connection["f_junction"]
            j_idx = connection["t_junction"]
      
            i = ref[:junction][i_idx]
            j = ref[:junction][j_idx]  
                
            pd_max = i["pmax"]^2 - j["pmin"]^2
            pd_min = i["pmin"]^2 - j["pmax"]^2
                 
            connection["pd_max"] =  pd_max
            connection["pd_min"] =  pd_min
        end
    end
end