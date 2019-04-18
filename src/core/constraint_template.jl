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
function constraint_on_off_pressure_drop(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    constraint_on_off_pressure_drop(gm, n, k, i, j, pd_min, pd_max)
end
constraint_on_off_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop(gm, gm.cnw, k)

" constraints on pressure drop across pipes where some edges are directed"
function constraint_on_off_pressure_drop_directed(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]

    constraint_on_off_pressure_drop_directed(gm, n, k, i, j, pd_min, pd_max, yp, yn)
end
constraint_on_off_pressure_drop_directed(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop_directed(gm, gm.cnw, k)

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm, n, :ne_connection, k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]

    constraint_on_off_pressure_drop_ne(gm, n, k, i, j, pd_min, pd_max)
end
constraint_on_off_pressure_drop_ne(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop_ne(gm, gm.cnw, k)

" constraints on pressure drop across pipes "
function constraint_on_off_pressure_drop_ne_directed(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm, n, :ne_connection, k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_min         = pipe["pd_min"]
    pd_max         = pipe["pd_max"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]

    constraint_on_off_pressure_drop_ne_directed(gm, n, k, i, j, pd_min, pd_max, yp, yn)
end
constraint_on_off_pressure_drop_ne_directed(gm::GenericGasModel, k::Int) = constraint_on_off_pressure_drop_ne_directed(gm, gm.cnw, k)

" standard mass flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance(gm::GenericGasModel, n::Int, i)
    junction   = ref(gm,n,:junction,i)
    consumer   = ref(gm,n,:consumer)
    producer   = ref(gm,n,:producer)
    consumers  = ref(gm,n,:junction_consumers,i)
    producers  = ref(gm,n,:junction_producers,i)
    f_branches = ref(gm,n,:f_connections,i)
    t_branches = ref(gm,n,:t_connections,i)

    fg         = length(producers) > 0 ? sum(calc_fg(gm.data,producer[j]) for j in producers) : 0
    fl         = length(consumers) > 0 ? sum(calc_fl(gm.data,consumer[j]) for j in consumers) : 0
    constraint_junction_mass_flow_balance(gm, n, i, f_branches, t_branches, fg, fl)
end
constraint_junction_mass_flow_balance(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance(gm, gm.cnw, i)

" standard mass flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, n::Int, i)
    junction      = ref(gm,n,:junction,i)
    consumer      = ref(gm,n,:consumer)
    producer      = ref(gm,n,:producer)
    consumers     = ref(gm,n,:junction_consumers,i)
    producers     = ref(gm,n,:junction_producers,i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

    fg         = length(producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in producers) : 0
    fl         = length(consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in consumers) : 0

    constraint_junction_mass_flow_balance_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fg, fl)
end
constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ne(gm, gm.cnw, i)

" standard mass flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, n::Int, i)
    junction      = ref(gm,n,:junction,i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    consumer      = ref(gm,n,:consumer)
    producer      = ref(gm,n,:producer)
    consumers     = ref(gm,n,:junction_consumers,i)
    producers     = ref(gm,n,:junction_producers,i)
    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0

    constraint_junction_mass_flow_balance_ls(gm, n, i, f_branches, t_branches, fl, fg, dispatch_consumers, dispatch_producers)
end
constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ls(gm, gm.cnw, i)

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, n::Int, i)
    junction      = ref(gm,n,:junction,i)
    consumer      = ref(gm,n,:consumer)
    producer      = ref(gm,n,:producer)
    consumers     = ref(gm,n,:junction_consumers,i)
    producers     = ref(gm,n,:junction_producers,i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

#    flfirm  = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer[j]) for j in consumers) : 0

#    v_consumers   = filter(j -> consumer[j]["qlmax"] != 0 || consumer[j]["qlmin"] != 0, consumers)
    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg  = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl  = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0


    constraint_junction_mass_flow_balance_ne_ls(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fl, fg, dispatch_consumers, dispatch_producers)
end
constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ne_ls(gm, gm.cnw, i)

" constraints on pressure drop across pipes "
function constraint_short_pipe_pressure_drop(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm,n,:connection,k)
    i = pipe["f_junction"]
    j = pipe["t_junction"]

    constraint_short_pipe_pressure_drop(gm, n, k, i, j)
end
constraint_short_pipe_pressure_drop(gm::GenericGasModel, k::Int) = constraint_short_pipe_pressure_drop(gm, gm.cnw, k)

" constraints on pressure drop across valves "
function constraint_on_off_valve_pressure_drop(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]

    j_pmax = gm.ref[:nw][n][:junction][j]["pmax"]
    i_pmax = gm.ref[:nw][n][:junction][i]["pmax"]

    constraint_on_off_valve_pressure_drop(gm, n, k, i, j, i_pmax, j_pmax)
end
constraint_on_off_valve_pressure_drop(gm::GenericGasModel, k::Int) = constraint_on_off_valve_pressure_drop(gm, gm.cnw, k)

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

"Weymouth equation with discrete direction variables "
function constraint_weymouth(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:connection,k)
    i = pipe["f_junction"]
    j = pipe["t_junction"]

    mf = gm.ref[:nw][n][:max_mass_flow]
    w = haskey(gm.ref[:nw][n][:pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)

    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    constraint_weymouth(gm, n, k, i, j, mf, w, pd_min, pd_max)
end
constraint_weymouth(gm::GenericGasModel, k::Int) = constraint_weymouth(gm, gm.cnw, k)

"Weymouth equation with discrete direction variables "
function constraint_weymouth_directed(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:connection,k)
    i = pipe["f_junction"]
    j = pipe["t_junction"]

    mf = gm.ref[:nw][n][:max_mass_flow]
    w = haskey(gm.ref[:nw][n][:pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)

    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]

    yp = pipe["yp"]
    yn = pipe["yn"]

    constraint_weymouth_directed(gm, n, k, i, j, mf, w, pd_min, pd_max, yp, yn)
end
constraint_weymouth_directed(gm::GenericGasModel, k::Int) = constraint_weymouth_directed(gm, gm.cnw, k)

" on/off constraints on flow across pipes for expansion variables "
function constraint_on_off_pipe_ne(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = gm.ref[:nw][n][:ne_connection][k]
    mf = gm.ref[:nw][n][:max_mass_flow]
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    w = haskey(gm.ref[:nw][n][:ne_pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)

    constraint_on_off_pipe_ne(gm, n, k, w, mf, pd_min, pd_max)
end
constraint_on_off_pipe_ne(gm::GenericGasModel, k::Int) = constraint_on_off_pipe_ne(gm, gm.cnw, k)

" on/off constraints on flow across compressors for expansion variables "
function constraint_on_off_compressor_ne(gm::GenericGasModel,  n::Int, k)
    compressor = gm.ref[:nw][n][:ne_connection][k]
    mf = gm.ref[:nw][n][:max_mass_flow]
    constraint_on_off_compressor_ne(gm, n, k, mf)
end
constraint_on_off_compressor_ne(gm::GenericGasModel, k::Int) = constraint_on_off_compressor_ne(gm, gm.cnw, k::Int)

" This function ensures at most one pipe in parallel is selected "
function constraint_exclusive_new_pipes(gm::GenericGasModel,  n::Int, i, j)
    parallel = ref(gm,n,:parallel_ne_pipes, (i,j))
    constraint_exclusive_new_pipes(gm, n, i, j, parallel)
end
constraint_exclusive_new_pipes(gm::GenericGasModel, i::Int, j::Int) = constraint_exclusive_new_pipes(gm, gm.cnw, i, j)

" Weymouth equation for undirected expansion pipes "
function constraint_weymouth_ne(gm::GenericGasModel,  n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = gm.ref[:nw][n][:ne_connection][k]

    i = pipe["f_junction"]
    j = pipe["t_junction"]

    mf = gm.ref[:nw][n][:max_mass_flow]
    w  = haskey(gm.ref[:nw][n][:ne_pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)

    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]

    constraint_weymouth_ne(gm, n, k, i, j, w, mf, pd_min, pd_max)
end
constraint_weymouth_ne(gm::GenericGasModel, k::Int) = constraint_weymouth_ne(gm, gm.cnw, k)

" Weymouth equation directed expansion pipes "
function constraint_weymouth_ne_directed(gm::GenericGasModel,  n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = gm.ref[:nw][n][:ne_connection][k]

    i = pipe["f_junction"]
    j = pipe["t_junction"]

    mf = gm.ref[:nw][n][:max_mass_flow]
    w  = haskey(gm.ref[:nw][n][:ne_pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)

    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    yp = pipe["yp"]
    yn = pipe["yn"]

    constraint_weymouth_ne_directed(gm, n, k, i, j, w, mf, pd_min, pd_max, yp, yn)
end
constraint_weymouth_ne_directed(gm::GenericGasModel, k::Int) = constraint_weymouth_ne_directed(gm, gm.cnw, k)

"compressor rations have on off for direction and expansion"
function constraint_new_compressor_ratios_ne(gm::GenericGasModel,  n::Int, k)
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
