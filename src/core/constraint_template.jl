#
# Constraint Template Definitions
#
# Constraint templates help simplify data wrangling across multiple Gas
# Flow formulations by providing an abstraction layer between the network data
# and network constraint definitions.  The constraint template's job is to
# extract the required parameters from a given network data structure and
# pass the data as named arguments to the Gas Flow formulations.
#
# Constraint templates should always be defined over "GenericGasModel"
# and should never refer to model variables

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop{T}(gm::GenericGasModel{T}, n::Int, k)
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    yp             = haskey(pipe, "yp") ? pipe["yp"] : nothing
    yn             = haskey(pipe, "yn") ? pipe["yn"] : nothing
            
    constraint_on_off_pressure_drop(gm, n, k, i, j, pd_min, pd_max; yp=yp, yn=yn)        
end
constraint_on_off_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop(gm, gm.cnw, k)

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne{T}(gm::GenericGasModel{T}, n::Int, k)
    pipe = ref(gm, n, :ne_connection, k) 
    
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    yp             = haskey(pipe, "yp") ? pipe["yp"] : nothing
    yn             = haskey(pipe, "yn") ? pipe["yn"] : nothing    
      
    constraint_on_off_pressure_drop_ne(gm, n, k, i, j, pd_min, pd_max; yp = yp, yn = yn)        
end
constraint_on_off_pressure_drop_ne(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop_ne(gm, gm.cnw, k)

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction{T}(gm::GenericGasModel{T}, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:connection,k)
    
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]    
    mf             = gm.ref[:nw][n][:max_flow]
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = pipe["type"] == "pipe" ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe) 
    yp             = haskey(pipe, "yp") ? pipe["yp"] : nothing
    yn             = haskey(pipe, "yn") ? pipe["yn"] : nothing  
    
    constraint_on_off_pipe_flow_direction(gm, n, k, i, j, mf, pd_min, pd_max, w; yp=yp, yn=yn)  
end
constraint_on_off_pipe_flow_direction(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_flow_direction(gm, gm.cnw, k)

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction_ne{T}(gm::GenericGasModel{T}, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:ne_connection, k) 
     
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    mf             = gm.ref[:nw][n][:max_flow]
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = pipe["type"] == "pipe" ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)  
    yp             = haskey(pipe, "yp") ? pipe["yp"] : nothing
    yn             = haskey(pipe, "yn") ? pipe["yn"] : nothing    

    constraint_on_off_pipe_flow_direction_ne(gm, n, k, i, j, mf, pd_min, pd_max, w; yp=yp, yn=yn) 
end
constraint_on_off_pipe_flow_direction_ne(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_flow_direction_ne(gm, gm.cnw, k)

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction{T}(gm::GenericGasModel{T}, n::Int, k)
    compressor = ref(gm, n, :connection, k)
  
    i        = compressor["f_junction"]
    j        = compressor["t_junction"]
    mf       = gm.ref[:nw][n][:max_flow]
    yp       = haskey(compressor, "yp") ? compressor["yp"] : nothing
    yn       = haskey(compressor, "yn") ? compressor["yn"] : nothing    

    constraint_on_off_compressor_flow_direction(gm, n, k, i, j, mf; yp=yp, yn=yn)  
end 
constraint_on_off_compressor_flow_direction(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_flow_direction(gm, gm.cnw, k)

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction_ne{T}(gm::GenericGasModel{T}, n::Int, k)
    compressor     = ref(gm,n,:ne_connection,k)  

    i        = compressor["f_junction"]
    j        = compressor["t_junction"]
    mf       = gm.ref[:nw][n][:max_flow]
    yp       = haskey(compressor, "yp") ? compressor["yp"] : nothing
    yn       = haskey(compressor, "yn") ? compressor["yn"] : nothing    
    
    constraint_on_off_compressor_flow_direction_ne(gm, n, k, i, j, mf; yp=yp, yn=yn)  
end 
constraint_on_off_compressor_flow_direction_ne(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_flow_direction_ne(gm, gm.cnw, i)

" enforces pressure changes bounds that obey compression ratios "
function constraint_on_off_compressor_ratios{T}(gm::GenericGasModel{T}, n::Int, k)
    compressor     = ref(gm,n,:connection,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = gm.ref[:nw][n][:junction][j]["pmax"]  
    j_pmin         = gm.ref[:nw][n][:junction][j]["pmin"]  
    i_pmax         = gm.ref[:nw][n][:junction][i]["pmax"]  
    i_pmin         = gm.ref[:nw][n][:junction][i]["pmin"]
    yp             = haskey(compressor, "yp") ? compressor["yp"] : nothing
    yn             = haskey(compressor, "yn") ? compressor["yn"] : nothing    
    
    constraint_on_off_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin; yp=yp, yn=yn)             
end
constraint_on_off_compressor_ratios(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_ratios(gm, gm.cnw, k)

" constraints on pressure drop across control valves "
function constraint_on_off_compressor_ratios_ne{T}(gm::GenericGasModel{T}, n::Int, k)
    compressor = ref(gm,n,:ne_connection, k)  
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = gm.ref[:nw][n][:junction][j]["pmax"]  
    i_pmax         = gm.ref[:nw][n][:junction][i]["pmax"]  
            
    constraint_on_off_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, j_pmax, i_pmax)          
end
constraint_on_off_compressor_ratios_ne(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_ratios_ne(gm, gm.cnw, k)

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance{T}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])
      
    junction_branches = gm.ref[:nw][n][:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection])))
    qgfirm     = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0
    qlfirm     = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0
      
    constraint_junction_flow_balance(gm, n, i, f_branches, t_branches, qgfirm, qlfirm)  
end
constraint_junction_flow_balance(gm::GenericGasModel, i::Int) = constraint_junction_flow_balance(gm, gm.cnw, i)

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ne{T}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)   
    junction_branches = gm.ref[:nw][n][:junction_connections][i]
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])  
          
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection])))

    f_branches_ne = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:ne_connection])))
    t_branches_ne = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:ne_connection])))
   
    qgfirm     = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0
    qlfirm     = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0
    
    constraint_junction_flow_balance_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, qgfirm, qlfirm)  
end
constraint_junction_flow_balance_ne(gm::GenericGasModel, i::Int) = constraint_junction_flow_balance_ne(gm, gm.cnw, i)

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ls{T}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)    
    junction_branches = gm.ref[:nw][n][:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection])))
    
    # collect the firm load numbers    
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])  
    qgfirm  = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0
    qlfirm  = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0

    # collect the possible consumer and producer indices
    v_consumers = collect(keys(filter( (a, consumer) -> consumer["ql_junc"] == i && (consumer["qlmax"] != 0 || consumer["qlmin"]) != 0, gm.ref[:nw][n][:consumer])))
    v_producers = collect(keys(filter( (a, producer) -> producer["qg_junc"] == i && (producer["qgmax"] != 0 || producer["qgmin"]) != 0, gm.ref[:nw][n][:producer])))
          
    constraint_junction_flow_balance_ls(gm, n, i, f_branches, t_branches, qlfirm, qgfirm, v_consumers, v_producers)
end
constraint_junction_flow_balance_ls(gm::GenericGasModel, i::Int) = constraint_junction_flow_balance_ls(gm, gm.cnw, i)

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance_ne_ls{T}(gm::GenericGasModel{T}, n::Int, i)  
    junction = ref(gm,n,:junction,i)  
    junction_branches = gm.ref[:nw][n][:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection])))

    f_branches_ne = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:ne_connection])))
    t_branches_ne = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:ne_connection])))
    
    # collect the firm load numbers    
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])  
    qgfirm  = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0
    qlfirm  = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0

    # collect the possible consumer and producer indices
    v_consumers = collect(keys(filter( (a, consumer) -> consumer["ql_junc"] == i && (consumer["qlmax"] != 0 || consumer["qlmin"]) != 0, gm.ref[:nw][n][:consumer])))
    v_producers = collect(keys(filter( (a, producer) -> producer["qg_junc"] == i && (producer["qgmax"] != 0 || producer["qgmin"]) != 0, gm.ref[:nw][n][:producer])))
              
    constraint_junction_flow_balance_ne_ls(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, qlfirm, qgfirm, v_consumers, v_producers)     
end
constraint_junction_flow_balance_ne_ls(gm::GenericGasModel, i::Int) = constraint_junction_flow_balance_ne_ls(gm, gm.cnw, i)

" constraints on flow across short pipes "
function constraint_on_off_short_pipe_flow_direction{T}(gm::GenericGasModel{T}, n::Int, k)
    pipe = ref(gm,n,:connection,k)    
    
    i  = pipe["f_junction"]
    j  = pipe["t_junction"]
    mf = gm.ref[:nw][n][:max_flow]
    yp = haskey(pipe, "yp") ? pipe["yp"] : nothing
    yn = haskey(pipe, "yn") ? pipe["yn"] : nothing 
    
    constraint_on_off_short_pipe_flow_direction(gm, n, k, i, j, mf; yp=yp, yn=yn)                
end
constraint_on_off_short_pipe_flow_direction(gm::GenericGasModel, k::Int) = constraint_on_off_short_pipe_flow_direction(gm, gm.cnw, k)

" constraints on pressure drop across pipes "
function constraint_short_pipe_pressure_drop{T}(gm::GenericGasModel{T}, n::Int, k)
    pipe = ref(gm,n,:connection,k)  
    i = pipe["f_junction"]
    j = pipe["t_junction"]
  
    constraint_short_pipe_pressure_drop(gm, n, k, i, j)  
end
constraint_short_pipe_pressure_drop(gm::GenericGasModel, k::Int) = constraint_short_pipe_pressure_drop(gm, gm.cnw, k)

" constraints on flow across valves "
function constraint_on_off_valve_flow_direction{T}(gm::GenericGasModel{T}, n::Int, k)
    valve = ref(gm,n,:connection,k)  
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = gm.ref[:nw][n][:max_flow]
      
    yp = haskey(valve, "yp") ? valve["yp"] : nothing
    yn = haskey(valve, "yn") ? valve["yn"] : nothing  
    
    constraint_on_off_valve_flow_direction(gm, n, k, i, j, mf; yp=yp, yn=yn)  
end
constraint_on_off_valve_flow_direction(gm::GenericGasModel, k::Int) = constraint_on_off_valve_flow_direction(gm, gm.cnw, k)

" constraints on pressure drop across valves "
function constraint_on_off_valve_pressure_drop{T}(gm::GenericGasModel{T}, n::Int, k)
    valve = ref(gm,n,:connection,k)  
    i = valve["f_junction"]
    j = valve["t_junction"]
  
    j_pmax = gm.ref[:nw][n][:junction][j]["pmax"]
    i_pmax = gm.ref[:nw][n][:junction][i]["pmax"]    
    
    constraint_on_off_valve_pressure_drop(gm, n, k, i, j, i_pmax, j_pmax)                                  
end
constraint_on_off_valve_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_valve_pressure_drop(gm, gm.cnw, k)

" constraints on flow across control valves "
function constraint_on_off_control_valve_flow_direction{T}(gm::GenericGasModel{T}, n::Int, k)
    valve = ref(gm,n,:connection,k)  
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = gm.ref[:nw][n][:max_flow]
      
    yp = haskey(valve, "yp") ? valve["yp"] : nothing
    yn = haskey(valve, "yn") ? valve["yn"] : nothing  
    
    constraint_on_off_control_valve_flow_direction(gm, n, k, i, j, mf; yp=yp, yn=yn)  
end
constraint_on_off_control_valve_flow_direction(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_flow_direction(gm, gm.cnw, k)

" constraints on pressure drop across control valves "
function constraint_on_off_control_valve_pressure_drop{T}(gm::GenericGasModel{T}, n::Int, k)
    valve = ref(gm,n,:connection,k)  
    i = valve["f_junction"]
    j = valve["t_junction"]
        
    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]
      
    j_pmax = gm.ref[:nw][n][:junction][j]["pmax"]  
    i_pmax = gm.ref[:nw][n][:junction][i]["pmax"]  
      
    yp = haskey(valve, "yp") ? valve["yp"] : nothing
    yn = haskey(valve, "yn") ? valve["yn"] : nothing  
      
    constraint_on_off_control_valve_pressure_drop(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax; yp=yp, yn=yn)                     
end
constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_pressure_drop(gm, gm.cnw, k)

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow{T}(gm::GenericGasModel{T}, n::Int, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection]))) 

    constraint_source_flow(gm, n, i, f_branches, t_branches)  
end
constraint_source_flow(gm::GenericGasModel, i::Int) = constraint_source_flow(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne{T}(gm::GenericGasModel{T}, n::Int, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection]))) 

    f_branches_ne = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:ne_connection])))
    t_branches_ne = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:ne_connection]))) 
    
    constraint_source_flow_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne)  
end
constraint_source_flow_ne(gm::GenericGasModel, i::Int) = constraint_source_flow_ne(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow{T}(gm::GenericGasModel{T}, n::Int, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection]))) 

    constraint_sink_flow(gm, n, i, f_branches, t_branches)  
end
constraint_sink_flow(gm::GenericGasModel, i::Int) = constraint_sink_flow(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne{T}(gm::GenericGasModel{T}, n::Int, i)
    f_branches = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection]))) 
    f_branches_ne = collect(keys(filter( (a,connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:ne_connection])))
    t_branches_ne = collect(keys(filter( (a,connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:ne_connection]))) 
    
    constraint_sink_flow_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne)          
end
constraint_sink_flow_ne(gm::GenericGasModel, i::Int) = constraint_sink_flow_ne(gm, gm.cnw, i)

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow{T}(gm::GenericGasModel{T}, n::Int, idx)
    first = nothing
    last = nothing
    
    for i in gm.ref[:nw][n][:junction_connections][idx]
        connection = gm.ref[:nw][n][:connection][i]
        if connection["f_junction"] == idx
            other = connection["t_junction"]
        else
            other = connection["f_junction"]
        end
        
        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end
            last = other    
        end      
    end
    
    yp_first = filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == first, gm.ref[:nw][n][:junction_connections][idx])
    yn_first = filter(i -> gm.ref[:nw][n][:connection][i]["t_junction"] == first, gm.ref[:nw][n][:junction_connections][idx])
    yp_last  = filter(i -> gm.ref[:nw][n][:connection][i]["t_junction"] == last,  gm.ref[:nw][n][:junction_connections][idx])
    yn_last  = filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == last,  gm.ref[:nw][n][:junction_connections][idx])
    
    constraint_conserve_flow(gm, n, idx, yp_first, yn_first, yp_last, yn_last)              
end
constraint_conserve_flow(gm::GenericGasModel, i::Int) = constraint_conserve_flow(gm, gm.cnw, i)

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow_ne{T}(gm::GenericGasModel{T}, n::Int, idx)
    first = nothing
    last = nothing
    
    for i in gm.ref[:nw][n][:junction_connections][idx] 
        connection = gm.ref[:nw][n][:connection][i]
        if connection["f_junction"] == idx
            other = connection["t_junction"]
        else
            other = connection["f_junction"]
        end
        
        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end          
            last = other    
        end      
    end
    
    for i in gm.ref[:nw][n][:junction_ne_connections][idx] 
        connection = gm.ref[:nw][n][:ne_connection][i]
        if connection["f_junction"] == idx
            other = connection["t_junction"]
        else
            other = connection["f_junction"]
        end
        
        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end          
            last = other    
        end      
    end
          
    yp_first = [filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == first, gm.ref[:nw][n][:junction_connections][idx]); filter(i -> gm.ref[:nw][n][:ne_connection][i]["f_junction"] == first, gm.ref[:nw][n][:junction_ne_connections][idx])]
    yn_first = [filter(i -> gm.ref[:nw][n][:connection][i]["t_junction"] == first, gm.ref[:nw][n][:junction_connections][idx]); filter(i -> gm.ref[:nw][n][:ne_connection][i]["t_junction"] == first, gm.ref[:nw][n][:junction_ne_connections][idx])]
    yp_last  = [filter(i -> gm.ref[:nw][n][:connection][i]["t_junction"] == last,  gm.ref[:nw][n][:junction_connections][idx]); filter(i -> gm.ref[:nw][n][:ne_connection][i]["t_junction"] == last,  gm.ref[:nw][n][:junction_ne_connections][idx])]
    yn_last  = [filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == last,  gm.ref[:nw][n][:junction_connections][idx]); filter(i -> gm.ref[:nw][n][:ne_connection][i]["f_junction"] == last,  gm.ref[:nw][n][:junction_ne_connections][idx])]

    constraint_conserve_flow_ne(gm, n, idx, yp_first, yn_first, yp_last, yn_last)  
      
end
constraint_conserve_flow_ne(gm::GenericGasModel, i::Int) = constraint_conserve_flow_ne(gm, gm.cnw, i)

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow{T}(gm::GenericGasModel{T}, n::Int, idx)
    connection = ref(gm,n,:connection,idx)
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])
    
    f_connections = filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == connection["f_junction"], gm.ref[:nw][n][:parallel_connections][(i,j)])
    t_connections = filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] != connection["f_junction"], gm.ref[:nw][n][:parallel_connections][(i,j)])

    if length(gm.ref[:nw][n][:parallel_connections][(i,j)]) <= 1
        return nothing
    end  
      
    constraint_parallel_flow(gm, n, idx, i, j, f_connections, t_connections)        
end
constraint_parallel_flow(gm::GenericGasModel, i::Int) = constraint_parallel_flow(gm, gm.cnw, i)

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne{T}(gm::GenericGasModel{T}, n::Int, idx)    
    connection = haskey(gm.ref[:nw][n][:connection], idx) ? gm.ref[:nw][n][:connection][idx] : gm.ref[:nw][n][:ne_connection][idx] 
      
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])
      
    if length(gm.ref[:nw][n][:all_parallel_connections][(i,j)]) <= 1
        return nothing
    end    
              
    f_connections = filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == connection["f_junction"], intersect(gm.ref[:nw][n][:all_parallel_connections][(i,j)], gm.ref[:nw][n][:parallel_connections][(i,j)]))
    t_connections = filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] != connection["f_junction"], intersect(gm.ref[:nw][n][:all_parallel_connections][(i,j)], gm.ref[:nw][n][:parallel_connections][(i,j)]))
    f_connections_ne = filter(i -> gm.ref[:nw][n][:ne_connection][i]["f_junction"] == connection["f_junction"], setdiff(gm.ref[:nw][n][:all_parallel_connections][(i,j)], gm.ref[:nw][n][:parallel_connections][(i,j)]))
    t_connections_ne = filter(i -> gm.ref[:nw][n][:ne_connection][i]["f_junction"] != connection["f_junction"], setdiff(gm.ref[:nw][n][:all_parallel_connections][(i,j)], gm.ref[:nw][n][:parallel_connections][(i,j)]))
        
    constraint_parallel_flow_ne(gm, n, idx, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne)  
end
constraint_parallel_flow_ne(gm::GenericGasModel, i::Int) = constraint_parallel_flow_ne(gm, gm.cnw, i)

"Weymouth equation with discrete direction variables "
function constraint_weymouth{T}(gm::GenericGasModel{T}, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:connection,k)
    i = pipe["f_junction"]
    j = pipe["t_junction"]
  
    mf = gm.ref[:nw][n][:max_flow]
    w = pipe["type"] == "pipe" ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)  

    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]
      
    yp = haskey(pipe, "yp") ? pipe["yp"] : nothing
    yn = haskey(pipe, "yn") ? pipe["yn"] : nothing       
       
    constraint_weymouth(gm, n, k, i, j, mf, w, pd_min, pd_max; yp=yp, yn=yn)              
end
constraint_weymouth(gm::GenericGasModel, k::Int) = constraint_weymouth(gm, gm.cnw, k)

" on/off constraints on flow across pipes for expansion variables "
function constraint_on_off_pipe_flow_ne{T}(gm::GenericGasModel{T}, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = gm.ref[:nw][n][:ne_connection][k]
    mf = gm.ref[:nw][n][:max_flow]
    pd_max = pipe["pd_max"]  
    pd_min = pipe["pd_min"]  
    w = pipe["type"] == "pipe" ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe) 
    
    constraint_on_off_pipe_flow_ne(gm, n, k, w, mf, pd_min, pd_max)  
end
constraint_on_off_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_flow_ne(gm, gm.cnw, k)

" on/off constraints on flow across compressors for expansion variables "
function constraint_on_off_compressor_flow_ne{T}(gm::GenericGasModel{T},  n::Int, k)
    compressor = gm.ref[:nw][n][:ne_connection][k]
    mf = gm.ref[:nw][n][:max_flow]    
    constraint_on_off_compressor_flow_ne(gm, n, k, mf)  
end
constraint_on_off_compressor_flow_ne(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_flow_ne(gm, gm.cnw, k::Int)

" This function ensures at most one pipe in parallel is selected "
function constraint_exclusive_new_pipes{T}(gm::GenericGasModel{T},  n::Int, i, j)  
    parallel = collect(filter( connection -> in(connection, collect(keys(gm.ref[:nw][n][:ne_pipe]))), gm.ref[:nw][n][:all_parallel_connections][(i,j)] ))      
    constraint_exclusive_new_pipes(gm,  n, i, j, parallel)  
end
constraint_exclusive_new_pipes(gm::GenericGasModel, i::Int, j::Int) = constraint_exclusive_new_pipes(gm, gm.cnw, i, j)

" Weymouth equation with discrete direction variables for MINLP "
function constraint_weymouth_ne{T}(gm::GenericGasModel{T},  n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = gm.ref[:nw][n][:ne_connection][k]
            
    i = pipe["f_junction"]
    j = pipe["t_junction"]
  
    mf = gm.ref[:nw][n][:max_flow]
    w = pipe["type"] == "pipe" ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)  

    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]
    yp = haskey(pipe, "yp") ? pipe["yp"] : nothing
    yn = haskey(pipe, "yn") ? pipe["yn"] : nothing         
         
    constraint_weymouth_ne(gm, n, k, i, j, w, mf, pd_min, pd_max; yp=yp, yn=yn)            
end
constraint_weymouth_ne(gm::GenericGasModel, k::Int) = constraint_weymouth_ne(gm, gm.cnw, k)

"compressor rations have on off for direction and expansion"
function constraint_new_compressor_ratios_ne{T}(gm::GenericGasModel{T},  n::Int, k)
    compressor = gm.ref[:nw][n][:ne_connection][k]
      
    i = compressor["f_junction"]
    j = compressor["t_junction"]
      
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    p_maxj = j["pmax"]
    p_maxi = i["pmax"]
    p_minj = j["pmin"]
    p_mini = i["pmin"]
    
    constraint_new_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, p_mini, p_maxi, p_minj, p_maxj)  
end
constraint_new_compressor_ratios_ne(gm::GenericGasModel, i::Int) = constraint_new_compressor_ratios_ne(gm, gm.cnw, i)
