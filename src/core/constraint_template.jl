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
function constraint_on_off_pressure_drop{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm, n, :connection, pipe_idx)

    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
      
    constraint_on_off_pressure_drop(gm, n, pipe_idx, i_junction_idx, j_junction_idx, pd_min, pd_max)        
end
constraint_on_off_pressure_drop(gm::GenericGasModel, i::Int) = constraint_on_off_pressure_drop(gm, gm.cnw, i)

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_fixed_direction{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm, n, :connection, pipe_idx) 
   
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]

    yp     = pipe["yp"]
    yn     = pipe["yn"]
    pd_min = pipe["pd_min"]
    pd_max = pipe["pd_max"]
    
    constraint_on_off_pressure_drop_fixed_direction(gm, n, pipe_idx, i_junction_idx, j_junction_idx, yp, yn, pd_min, pd_max)            
end
constraint_on_off_pressure_drop_fixed_direction(gm::GenericGasModel, i::Int) = constraint_on_off_pressure_drop_fixed_direction(gm, gm.cnw, i)

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm, n, :ne_connection, pipe_idx) 
    
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
   
    constraint_on_off_pressure_drop_ne(gm, n, pipe_idx, i_junction_idx, j_junction_idx, pd_min, pd_max)        
end
constraint_on_off_pressure_drop_ne(gm::GenericGasModel, i::Int) = constraint_on_off_pressure_drop_ne(gm, gm.cnw, i)

" constraints on pressure drop across pipes when the direction is fixed "
function constraint_on_off_pressure_drop_ne_fixed_direction{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm, n, :ne_connection, pipe_idx) 
  
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    
    constraint_on_off_pressure_drop_ne_fixed_direction(gm, n, pipe_idx, i_junction_idx, j_junction_idx, yp, yn, pd_min, pd_max)  
end
constraint_on_off_pressure_drop_ne_fixed_direction(gm::GenericGasModel, i::Int) = constraint_on_off_pressure_drop_ne_fixed_direction(gm, gm.cnw, i)

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm,n,:connection,pipe_idx)
    
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]    
    max_flow       = gm.ref[:nw][n][:max_flow]
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = pipe["resistance"] 
    
    constraint_on_off_pipe_flow_direction(gm, n, pipe_idx, i_junction_idx, j_junction_idx, max_flow, pd_max, pd_min, w)  
end
constraint_on_off_pipe_flow_direction(gm::GenericGasModel, i::Int) = constraint_on_off_pipe_flow_direction(gm, gm.cnw, i)

" constraints on flow across pipes where the directions are fixed "
function constraint_on_off_pipe_flow_direction_fixed_direction{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm, n, :connection, pipe_idx)

    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
    max_flow       = gm.ref[:nw][n][:max_flow]
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = pipe["resistance"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]
        
    constraint_on_off_pipe_flow_direction_fixed_direction(gm, n, pipe_idx, i_junction_idx, j_junction_idx, max_flow, pd_max, pd_min, w, yp, yn)  
end
constraint_on_off_pipe_flow_direction_fixed_direction(gm::GenericGasModel, i::Int) = constraint_on_off_pipe_flow_direction_fixed_direction(gm, gm.cnw, i)

" constraints on flow across pipes "
function constraint_on_off_pipe_flow_direction_ne{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm,n,:ne_connection, pipe_idx) 
     
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
    max_flow       = gm.ref[:nw][n][:max_flow]
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = pipe["resistance"]  

    constraint_on_off_pipe_flow_direction_ne(gm, n, pipe_idx, i_junction_idx, j_junction_idx, max_flow, pd_max, pd_min, w) 
end
constraint_on_off_pipe_flow_direction_ne(gm::GenericGasModel, i::Int) = constraint_on_off_pipe_flow_direction_ne(gm, gm.cnw, i)

" constraints on flow across pipes when directions are fixed "
function constraint_on_off_pipe_flow_direction_ne_fixed_direction{T}(gm::GenericGasModel{T}, n::Int, pipe_idx)
    pipe = ref(gm, n, :ne_connection, pipe_idx)
        
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
    max_flow       = gm.ref[:nw][n][:max_flow]
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = pipe["resistance"]      
    yp             = pipe["yp"]
    yn             = pipe["yn"]

    constraint_on_off_pipe_flow_direction_ne_fixed_direction(gm::GenericGasModel, n, pipe_idx, i_junction_idx, j_junction_idx, max_flow, pd_max, pd_min, w, yp, yn)  
end
constraint_on_off_pipe_flow_direction_ne_fixed_direction(gm::GenericGasModel, i::Int) = constraint_on_off_pipe_flow_direction_ne_fixed_direction(gm, gm.cnw, i)

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction{T}(gm::GenericGasModel{T}, n::Int, c_idx)
    compressor = ref(gm, n, :connection, c_idx)
  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
    max_flow       = gm.ref[:nw][n][:max_flow]  

    constraint_on_off_compressor_flow_direction(gm, n, c_idx, i_junction_idx, j_junction_idx, max_flow)  
end 
constraint_on_off_compressor_flow_direction(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_flow_direction(gm, gm.cnw, i)

" constraints on flow across compressors when directions are constants "
function constraint_on_off_compressor_flow_direction_fixed_direction{T}(gm::GenericGasModel{T}, n::Int, c_idx)
    compressor = ref(gm, n, :connection, c_idx)
  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
    yp             = compressor["yp"]
    yn             = compressor["yn"]
    max_flow       = gm.ref[:nw][n][:max_flow]
    
    constraint_on_off_compressor_flow_direction_fixed_direction(gm, n, c_idx, i_junction_idx, j_junction_idx, yp, yn, max_flow)  
end
constraint_on_off_compressor_flow_direction_fixed_direction(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_flow_direction_fixed_direction(gm, gm.cnw, i)

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_direction_ne{T}(gm::GenericGasModel{T}, n::Int, c_idx)
    compressor     = ref(gm,n,:ne_connection,c_idx)  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
    max_flow       = gm.ref[:nw][n][:max_flow]  
    
    constraint_on_off_compressor_flow_direction_ne(gm, n, c_idx, i_junction_idx, j_junction_idx, max_flow)  
end 
constraint_on_off_compressor_flow_direction_ne(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_flow_direction_ne(gm, gm.cnw, i)

" constraints on flow across compressors when the directions are constants "
function constraint_on_off_compressor_flow_direction_ne_fixed_direction{T}(gm::GenericGasModel{T}, n::Int, c_idx)
    compressor = ref(gm,n,:ne_connection,c_idx)
      
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
    yp             = compressor["yp"]
    yn             = compressor["yn"]

    constraint_on_off_compressor_flow_direction_ne_fixed_direction(gm::GenericGasModel, n, c_idx, i_junction_idx, j_junction_idx, yp, yn)        
end 
constraint_on_off_compressor_flow_direction_ne_fixed_direction(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_flow_direction_ne_fixed_direction(gm, gm.cnw, i)

" enforces pressure changes bounds that obey compression ratios "
function constraint_on_off_compressor_ratios{T}(gm::GenericGasModel{T}, n::Int, c_idx)
    compressor     = ref(gm,n,:connection,c_idx)
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = gm.ref[:nw][n][:junction][j_junction_idx]["pmax"]  
    j_pmin         = gm.ref[:nw][n][:junction][j_junction_idx]["pmin"]  
    i_pmax         = gm.ref[:nw][n][:junction][i_junction_idx]["pmax"]  
    i_pmin         = gm.ref[:nw][n][:junction][i_junction_idx]["pmin"]  
    
    constraint_on_off_compressor_ratios(gm, n, c_idx, i_junction_idx, j_junction_idx, max_ratio, min_ratio, j_pmax, j_pmin, i_pmax, i_pmin)             
end
constraint_on_off_compressor_ratios(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_ratios(gm, gm.cnw, i)

" constraints on pressure drop across control valves "
function constraint_on_off_compressor_ratios_ne{T}(gm::GenericGasModel{T}, n::Int, c_idx)
    compressor = ref(gm,n,:ne_connection,c_idx)  
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = gm.ref[:nw][n][:junction][j_junction_idx]["pmax"]  
    i_pmax         = gm.ref[:nw][n][:junction][i_junction_idx]["pmax"]  
            
    constraint_on_off_compressor_ratios_ne(gm, n, c_idx, i_junction_idx, j_junction_idx, max_ratio, min_ratio, j_pmax, i_pmax)          
end
constraint_on_off_compressor_ratios_ne(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_ratios_ne(gm, gm.cnw, i)

" on/off constraint for compressors when the flow direction is constant "
function constraint_on_off_compressor_ratios_fixed_direction{T}(gm::GenericGasModel{T}, n::Int, c_idx)
    compressor = ref(gm,n,:connection,c_idx)
    i_junction_idx = compressor["f_junction"]
    j_junction_idx = compressor["t_junction"]
    yp             = compressor["yp"]
    yn             = compressor["yn"]    
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = gm.ref[:nw][n][:junction][j_junction_idx]["pmax"]  
    j_pmin         = gm.ref[:nw][n][:junction][j_junction_idx]["pmin"]  
    i_pmax         = gm.ref[:nw][n][:junction][i_junction_idx]["pmax"]  
    i_pmin         = gm.ref[:nw][n][:junction][i_junction_idx]["pmin"]  
    
    constraint_on_off_compressor_ratios_fixed_direction(gm, n, c_idx, i_junction_idx, j_junction_idx, yp, yn, max_ratio, min_ratio, j_pmax, j_pmin, i_pmax, i_pmin)          
end
constraint_on_off_compressor_ratios_fixed_direction(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_ratios_fixed_direction(gm, gm.cnw, i)

" standard flow balance equation where demand and production is fixed "
function constraint_junction_flow_balance{T}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    junction_branches = gm.ref[:nw][n][:junction_connections][i]
    
    f_branches = collect(keys(filter( (a, connection) -> connection["f_junction"] == i, gm.ref[:nw][n][:connection])))
    t_branches = collect(keys(filter( (a, connection) -> connection["t_junction"] == i, gm.ref[:nw][n][:connection])))
    qgfirm     = junction["qgfirm"]
    qlfirm     = junction["qlfirm"]
      
    constraint_junction_flow_balance(gm, n, i, f_branches, t_branches, qgfirm, qlfirm)  
end
constraint_junction_flow_balance(gm::GenericGasModel, i::Int) = constraint_junction_flow_balance(gm, gm.cnw, i)
