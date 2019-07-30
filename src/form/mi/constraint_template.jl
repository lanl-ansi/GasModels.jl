
########################################################################################################
# Constraints used to model flow across pipe_resistance
########################################################################################################
" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    constraint_on_off_pressure_drop(gm, n, k, i, j, pd_min, pd_max)
end
constraint_on_off_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop(gm, gm.cnw, k)

" constraint on flow across a directed pipe "
function constraint_on_off_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple) where T <: AbstractMIForms
    pipe = ref(gm,n,:connection,k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    mf             = ref(gm,n,:max_mass_flow)
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = haskey(ref(gm,n,:pipe),k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    yp             = pipe["yp"]
    yn             = pipe["yn"]

    constraint_on_off_pipe_flow_directed(gm, n, k, i, j, mf, pd_min, pd_max, w, yp, yn)
end
constraint_on_off_pipe_flow_directed(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_flow_directed(gm, gm.cnw, k)


#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    pipe = ref(gm, n, :ne_connection, k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]

    constraint_on_off_pressure_drop_ne(gm, n, k, i, j, pd_min, pd_max)
end
constraint_on_off_pressure_drop_ne(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop_ne(gm, gm.cnw, k)

" constraints on flow across an expansion pipe that is undirected "
function constraint_on_off_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple) where T <: AbstractMIForms
    pipe = ref(gm,n,:ne_connection, k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    mf             = ref(gm,n,:max_mass_flow)
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = haskey(ref(gm,n,:ne_pipe),k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)

    constraint_on_off_pipe_flow_ne(gm, n, k, i, j, mf, pd_min, pd_max, w)
end
constraint_on_off_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_flow_ne(gm, gm.cnw, k)

" constraints on flow across an expansion pipe that is directed "
function constraint_pipe_flow_ne_one_way(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:ne_connection, k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]

    constraint_pipe_flow_ne_one_way(gm, n, k, i, j, yp, yn)
end
constraint_pipe_flow_ne_one_way(gm::GenericGasModel, k::Int) = constraint_pipe_flow_ne_one_way(gm, gm.cnw, k)


#" constraints on flow across an expansion pipe that is directed "
#function constraint_on_off_pipe_flow_ne_directed(gm::GenericGasModel{T}, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple) where T <: AbstractMIForms
#    pipe = ref(gm,n,:ne_connection, k)

#    i              = pipe["f_junction"]
#    j              = pipe["t_junction"]
#    mf             = ref(gm,n,:max_mass_flow)
#    pd_max         = pipe["pd_max"]
#    pd_min         = pipe["pd_min"]
#    w              = haskey(ref(gm,n,:ne_pipe),k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
#    yp             = pipe["yp"]
#    yn             = pipe["yn"]

#    constraint_on_off_pipe_flow_ne_directed(gm, n, k, i, j, mf, pd_min, pd_max, w, yp, yn)
#end
#constraint_on_off_pipe_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_flow_ne_directed(gm, gm.cnw, k)

#" constraints on pressure drop across pipes where some edges are directed"
#function constraint_on_off_pressure_drop_directed(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
#    pipe           = ref(gm, n, :connection, k)
#    i              = pipe["f_junction"]
#    j              = pipe["t_junction"]
#    pd_min         = pipe["pd_min"]
#    pd_max         = pipe["pd_max"]
#    yp             = pipe["yp"]
#    yn             = pipe["yn"]
#    constraint_on_off_pressure_drop_directed(gm, n, k, i, j, pd_min, pd_max, yp, yn)
#end
#constraint_on_off_pressure_drop_directed(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop_directed(gm, gm.cnw, k)

######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

" constraints on flow across an undirected compressor "
function constraint_on_off_compressor_flow(gm::GenericGasModel{T}, n::Int, k)  where T <: AbstractMIForms
    compressor = ref(gm, n, :connection, k)

    i        = compressor["f_junction"]
    j        = compressor["t_junction"]
    mf       = ref(gm,n,:max_mass_flow)

    constraint_on_off_compressor_flow(gm, n, k, i, j, mf)
end
constraint_on_off_compressor_flow(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_flow(gm, gm.cnw, k)

" constraints on flow across a directed compressor "
function constraint_compressor_flow_one_way(gm::GenericGasModel{T}, n::Int, k)  where T <: AbstractMIForms
    compressor = ref(gm, n, :connection, k)

    i        = compressor["f_junction"]
    j        = compressor["t_junction"]
#    mf       = ref(gm,n,:max_mass_flow)
    yp       = compressor["yp"]
    yn       = compressor["yn"]

    constraint_compressor_flow_one_way(gm, n, k, i, j, yp, yn)
end
constraint_compressor_flow_one_way(gm::GenericGasModel, k::Int) = constraint_compressor_flow_one_way(gm, gm.cnw, k)

" enforces pressure changes bounds that obey compression ratios for an undirected compressor "
function constraint_on_off_compressor_ratios(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    compressor     = ref(gm,n,:connection,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    j_pmin         = ref(gm,n,:junction,j)["pmin"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmin         = ref(gm,n,:junction,i)["pmin"]

    constraint_on_off_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin)
end
constraint_on_off_compressor_ratios(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_ratios(gm, gm.cnw, k)


" constraints on flow across an undirected compressor "
function constraint_on_off_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    compressor     = ref(gm,n,:ne_connection,k)

    i        = compressor["f_junction"]
    j        = compressor["t_junction"]
    mf       = ref(gm,n,:max_mass_flow)

    constraint_on_off_compressor_flow_ne(gm, n, k, i, j, mf)
end
constraint_on_off_compressor_flow_ne(gm::GenericGasModel, i::Int) = constraint_on_off_compressor_flow_ne(gm, gm.cnw, i)



" constraints on pressure drop across an undirected compressor "
function constraint_on_off_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    compressor = ref(gm,n,:ne_connection, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]

    constraint_on_off_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, j_pmax, i_pmax)
end
constraint_on_off_compressor_ratios_ne(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_ratios_ne(gm, gm.cnw, k)


" constraints on flow across an undirected valve "
function constraint_on_off_valve_flow(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = ref(gm,n,:max_mass_flow)

    constraint_on_off_valve_flow(gm, n, k, i, j, mf)
end
constraint_on_off_valve_flow(gm::GenericGasModel, k::Int) = constraint_on_off_valve_flow(gm, gm.cnw, k)

" constraints on flow across a directed valve "
function constraint_on_off_valve_flow_directed(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = ref(gm,n,:max_mass_flow)

    yp = valve["yp"]
    yn = valve["yn"]

    constraint_on_off_valve_flow_directed(gm, n, k, i, j, mf, yp, yn)
end
constraint_on_off_valve_flow_directed(gm::GenericGasModel, k::Int) = constraint_on_off_valve_flow_directed(gm, gm.cnw, k)

" constraints on flow across an undirected control valve "
function constraint_on_off_control_valve_flow(gm::GenericGasModel{T}, n::Int, k)  where T <: AbstractMIForms
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = ref(gm,n,:max_mass_flow)

    constraint_on_off_control_valve_flow(gm, n, k, i, j, mf)
end
constraint_on_off_control_valve_flow(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_flow(gm, gm.cnw, k)

" constraints on flow across a directed control valve "
function constraint_on_off_control_valve_flow_directed(gm::GenericGasModel{T}, n::Int, k)  where T <: AbstractMIForms
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = ref(gm,n,:max_mass_flow)

    yp = valve["yp"]
    yn = valve["yn"]

    constraint_on_off_control_valve_flow_directed(gm, n, k, i, j, mf, yp, yn)
end
constraint_on_off_control_valve_flow_directed(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_flow_directed(gm, gm.cnw, k)

######################################################
# Flow Constraints for control valves
#######################################################

" constraints on pressure drop across control valves that are undirected "
function constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]

    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]

    j_pmax = ref(gm,n,:junction,j)["pmax"]
    i_pmax = ref(gm,n,:junction,i)["pmax"]

    constraint_on_off_control_valve_pressure_drop(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax)
end
constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_pressure_drop(gm, gm.cnw, k)

" constraints on pressure drop across control valves that are directed "
function constraint_on_off_control_valve_pressure_drop_directed(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]

    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]

    j_pmax = ref(gm,n,:junction,j)["pmax"]
    i_pmax = ref(gm,n,:junction,i)["pmax"]

    yp = valve["yp"]
    yn = valve["yn"]

    constraint_on_off_control_valve_pressure_drop_directed(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, yp, yn)
end
constraint_on_off_control_valve_pressure_drop_directed(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_pressure_drop_directed(gm, gm.cnw, k)
