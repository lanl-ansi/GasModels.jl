
#################################################################################################
# Constraints associated with pipes
#################################################################################################

" Constraint: Pressure drop across pipes with on/off direction variables"
function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    constraint_on_off_pressure_drop(gm, n, k, i, j, pd_min, pd_max)
end
constraint_on_off_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop(gm, gm.cnw, k)

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


" constraints on flow across an undirected control valve "
function constraint_on_off_control_valve_flow(gm::GenericGasModel{T}, n::Int, k)  where T <: AbstractMIForms
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = ref(gm,n,:max_mass_flow)

    constraint_on_off_control_valve_flow(gm, n, k, i, j, mf)
end
constraint_on_off_control_valve_flow(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_flow(gm, gm.cnw, k)


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
function constraint_control_valve_pressure_drop_one_way(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]

    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]

    j_pmax = ref(gm,n,:junction,j)["pmax"]
    i_pmax = ref(gm,n,:junction,i)["pmax"]

    yp = valve["yp"]
    yn = valve["yn"]

    constraint_control_valve_pressure_drop_one_way(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, yp, yn)
end
constraint_control_valve_pressure_drop_one_way(gm::GenericGasModel, k::Int) = constraint_control_valve_pressure_drop_one_way(gm, gm.cnw, k)

" constraint on flow across an undirected pipe "
function constraint_on_off_pipe_flow(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:connection,k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    mf             = ref(gm,n,:max_mass_flow)
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = haskey(ref(gm,n,:pipe),k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    constraint_on_off_pipe_flow(gm, n, k, i, j, mf, pd_min, pd_max, w)
end
constraint_on_off_pipe_flow(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_flow(gm, gm.cnw, k)

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow(gm::GenericGasModel, n::Int, i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)

    constraint_source_flow(gm, n, i, f_branches, t_branches)
end
constraint_source_flow(gm::GenericGasModel, i::Int) = constraint_source_flow(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne(gm::GenericGasModel, n::Int, i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    f_branches_ne    = ref(gm,n,:f_ne_connections,i)
    t_branches_ne    = ref(gm,n,:t_ne_connections,i)
    constraint_source_flow_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
end
constraint_source_flow_ne(gm::GenericGasModel, i::Int) = constraint_source_flow_ne(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow(gm::GenericGasModel, n::Int, i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    constraint_sink_flow(gm, n, i, f_branches, t_branches)
end
constraint_sink_flow(gm::GenericGasModel, i::Int) = constraint_sink_flow(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne(gm::GenericGasModel, n::Int, i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    f_branches_ne    = ref(gm,n,:f_ne_connections,i)
    t_branches_ne    = ref(gm,n,:t_ne_connections,i)
    constraint_sink_flow_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
end
constraint_sink_flow_ne(gm::GenericGasModel, i::Int) = constraint_sink_flow_ne(gm, gm.cnw, i)

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::GenericGasModel, n::Int, idx)
    connections = ref(gm,n,:connection)
    junction_connections = ref(gm,n,:junction_connections,idx)

    first = nothing
    last = nothing

    for i in junction_connections
        connection = connections[i]
        other = (connection["f_junction"] == idx) ? connection["t_junction"] :  connection["f_junction"]

        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(LOGGER, string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end
            last = other
        end
    end

    yp_first = filter(i -> connections[i]["f_junction"] == first, junction_connections)
    yn_first = filter(i -> connections[i]["t_junction"] == first, junction_connections)
    yp_last  = filter(i -> connections[i]["t_junction"] == last,  junction_connections)
    yn_last  = filter(i -> connections[i]["f_junction"] == last,  junction_connections)

    constraint_conserve_flow(gm, n, idx, yp_first, yn_first, yp_last, yn_last)
end
constraint_conserve_flow(gm::GenericGasModel, i::Int) = constraint_conserve_flow(gm, gm.cnw, i)

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow_ne(gm::GenericGasModel, n::Int, idx)
    connections = ref(gm,n,:connection)
    ne_connections = ref(gm,n,:ne_connection)
    junction_connections = ref(gm,n,:junction_connections,idx)
    junction_ne_connections = ref(gm,n,:junction_ne_connections,idx)

    first = nothing
    last = nothing

    for i in junction_connections
        connection = connections[i]
        other = (connection["f_junction"] == idx) ?  connection["t_junction"] : connection["f_junction"]

        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(LOGGER, string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end
            last = other
        end
    end

    for i in junction_ne_connections
        connection = ne_connections[i]
        other = (connection["f_junction"] == idx) ? connection["t_junction"] : connection["f_junction"]

        if first == nothing
            first = other
        elseif first != other
            if last != nothing && last != other
                error(LOGGER, string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end
            last = other
        end
    end

    yp_first = [
        filter(i -> connections[i]["f_junction"] == first, junction_connections);
        filter(i -> ne_connections[i]["f_junction"] == first, junction_ne_connections)
    ]
    yn_first = [
        filter(i -> connections[i]["t_junction"] == first, junction_connections);
        filter(i -> ne_connections[i]["t_junction"] == first, junction_ne_connections)
    ]
    yp_last = [
        filter(i -> connections[i]["t_junction"] == last, junction_connections);
        filter(i -> ne_connections[i]["t_junction"] == last, junction_ne_connections)
    ]
    yn_last = [
        filter(i -> connections[i]["f_junction"] == last, junction_connections);
        filter(i -> ne_connections[i]["f_junction"] == last, junction_ne_connections)
    ]

    constraint_conserve_flow_ne(gm, n, idx, yp_first, yn_first, yp_last, yn_last)
end
constraint_conserve_flow_ne(gm::GenericGasModel, i::Int) = constraint_conserve_flow_ne(gm, gm.cnw, i)

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow(gm::GenericGasModel, n::Int, idx)
    connection = ref(gm,n,:connection,idx)
    connections = ref(gm,n,:connection)

    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])

    parallel_connections = ref(gm,n,:parallel_connections,(i,j))

    f_connections = filter(i -> connections[i]["f_junction"] == connection["f_junction"], parallel_connections)
    t_connections = filter(i -> connections[i]["f_junction"] != connection["f_junction"], parallel_connections)

    if length(parallel_connections) <= 1
        return nothing
    end

    constraint_parallel_flow(gm, n, idx, i, j, f_connections, t_connections)
end
constraint_parallel_flow(gm::GenericGasModel, i::Int) = constraint_parallel_flow(gm, gm.cnw, i)

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne(gm::GenericGasModel, n::Int, idx)
    connection = haskey(ref(gm,n,:connection), idx) ? ref(gm,n,:connection)[idx] : ref(gm,n,:ne_connection)[idx]
    connections = ref(gm,n,:connection)
    ne_connections = ref(gm,n,:ne_connection)

    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])

    all_parallel_connections = ref(gm,n,:all_parallel_connections, (i,j))
    parallel_connections = ref(gm,n,:parallel_connections, (i,j))

    if length(all_parallel_connections) <= 1
        return nothing
    end

    f_connections = filter(i -> connections[i]["f_junction"] == connection["f_junction"], intersect(all_parallel_connections, parallel_connections))
    t_connections = filter(i -> connections[i]["f_junction"] != connection["f_junction"], intersect(all_parallel_connections, parallel_connections))
    f_connections_ne = filter(i -> ne_connections[i]["f_junction"] == connection["f_junction"], setdiff(all_parallel_connections, parallel_connections))
    t_connections_ne = filter(i -> ne_connections[i]["f_junction"] != connection["f_junction"], setdiff(all_parallel_connections, parallel_connections))

    constraint_parallel_flow_ne(gm, n, idx, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne)
end
constraint_parallel_flow_ne(gm::GenericGasModel, i::Int) = constraint_parallel_flow_ne(gm, gm.cnw, i)
