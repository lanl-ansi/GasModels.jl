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
#    yp             = haskey(pipe, "yp") ? pipe["yp"] : nothing
#    yn             = haskey(pipe, "yn") ? pipe["yn"] : nothing

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
    junction = ref(gm,n,:junction,i)
    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)

    junction_branches = gm.ref[:nw][n][:junction_connections][i]

    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))
    fgfirm     = length(producers) > 0 ? sum(calc_fgfirm(gm.data,producer) for (j, producer) in producers) : 0
    flfirm     = length(consumers) > 0 ? sum(calc_flfirm(gm.data,consumer) for (j, consumer) in consumers) : 0

    constraint_junction_mass_flow_balance(gm, n, i, f_branches, t_branches, fgfirm, flfirm)
end
constraint_junction_mass_flow_balance(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance(gm, gm.cnw, i)

" standard mass flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, n::Int, i)
    junction = ref(gm,n,:junction,i)
    junction_branches = gm.ref[:nw][n][:junction_connections][i]
    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)

    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))

    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

    fgfirm     = length(producers) > 0 ? sum(calc_fgfirm(gm.data, producer) for (j, producer) in producers) : 0
    flfirm     = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer) for (j, consumer) in consumers) : 0

    constraint_junction_mass_flow_balance_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fgfirm, flfirm)
end
constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ne(gm, gm.cnw, i)

" standard mass flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, n::Int, i)
    junction = ref(gm,n,:junction,i)
    junction_branches = gm.ref[:nw][n][:junction_connections][i]

    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))

    # collect the firm load numbers
    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)
    fgfirm  = length(producers) > 0 ? sum(calc_fgfirm(gm.data, producer) for (j, producer) in producers) : 0
    flfirm  = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer) for (j, consumer) in consumers) : 0

    # collect the possible consumer and producer indices
    v_consumers = collect(keys(Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i && (x.second["qlmax"] != 0 || x.second["qlmin"]) != 0)))
    v_producers = collect(keys(Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i && (x.second["qgmax"] != 0 || x.second["qgmin"]) != 0)))

    constraint_junction_mass_flow_balance_ls(gm, n, i, f_branches, t_branches, flfirm, fgfirm, v_consumers, v_producers)
end
constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ls(gm, gm.cnw, i)

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, n::Int, i)
    junction = ref(gm,n,:junction,i)
    junction_branches = gm.ref[:nw][n][:junction_connections][i]

    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))

    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

    # collect the firm load numbers
    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)
    fgfirm  = length(producers) > 0 ? sum(calc_fgfirm(gm.data, producer) for (j, producer) in producers) : 0
    flfirm  = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer) for (j, consumer) in consumers) : 0

    # collect the possible consumer and producer indices
    v_consumers = collect(keys(Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i && (x.second["qlmax"] != 0 || x.second["qlmin"]) != 0)))
    v_producers = collect(keys(Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i && (x.second["qgmax"] != 0 || x.second["qgmin"]) != 0)))

    constraint_junction_mass_flow_balance_ne_ls(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, flfirm, fgfirm, v_consumers, v_producers)
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

" constraints on flow across control valves "
function constraint_on_off_control_valve_flow_direction(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    i = valve["f_junction"]
    j = valve["t_junction"]
    mf = gm.ref[:nw][n][:max_mass_flow]

    yp = haskey(valve, "yp") ? valve["yp"] : nothing
    yn = haskey(valve, "yn") ? valve["yn"] : nothing

    constraint_on_off_control_valve_flow_direction(gm, n, k, i, j, mf; yp=yp, yn=yn)
end
constraint_on_off_control_valve_flow_direction(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_flow_direction(gm, gm.cnw, k)

" constraints on pressure drop across control valves "
function constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel, n::Int, k)
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
function constraint_source_flow(gm::GenericGasModel, n::Int, i)
    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))

    constraint_source_flow(gm, n, i, f_branches, t_branches)
end
constraint_source_flow(gm::GenericGasModel, i::Int) = constraint_source_flow(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne(gm::GenericGasModel, n::Int, i)
    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))

    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

    constraint_source_flow_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
end
constraint_source_flow_ne(gm::GenericGasModel, i::Int) = constraint_source_flow_ne(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow(gm::GenericGasModel, n::Int, i)
    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))

    constraint_sink_flow(gm, n, i, f_branches, t_branches)
end
constraint_sink_flow(gm::GenericGasModel, i::Int) = constraint_sink_flow(gm, gm.cnw, i)

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne(gm::GenericGasModel, n::Int, i)
    f_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["f_junction"] == i)))
    t_branches = collect(keys(Dict(x for x in gm.ref[:nw][n][:connection] if x.second["t_junction"] == i)))

    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

    constraint_sink_flow_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne)
end
constraint_sink_flow_ne(gm::GenericGasModel, i::Int) = constraint_sink_flow_ne(gm, gm.cnw, i)

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::GenericGasModel, n::Int, idx)
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
                error(LOGGER, string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
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
function constraint_conserve_flow_ne(gm::GenericGasModel, n::Int, idx)
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
                error(LOGGER, string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
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
                error(LOGGER, string("Error: adding a degree 2 constraint to a node with degree > 2: Junction ", idx))
            end
            last = other
        end
    end

    yp_first = [
        filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == first, gm.ref[:nw][n][:junction_connections][idx]);
        filter(i -> gm.ref[:nw][n][:ne_connection][i]["f_junction"] == first, gm.ref[:nw][n][:junction_ne_connections][idx])
    ]
    yn_first = [
        filter(i -> gm.ref[:nw][n][:connection][i]["t_junction"] == first, gm.ref[:nw][n][:junction_connections][idx]);
        filter(i -> gm.ref[:nw][n][:ne_connection][i]["t_junction"] == first, gm.ref[:nw][n][:junction_ne_connections][idx])
    ]
    yp_last = [
        filter(i -> gm.ref[:nw][n][:connection][i]["t_junction"] == last,  gm.ref[:nw][n][:junction_connections][idx]);
        filter(i -> gm.ref[:nw][n][:ne_connection][i]["t_junction"] == last,  gm.ref[:nw][n][:junction_ne_connections][idx])
    ]
    yn_last = [
        filter(i -> gm.ref[:nw][n][:connection][i]["f_junction"] == last,  gm.ref[:nw][n][:junction_connections][idx]);
        filter(i -> gm.ref[:nw][n][:ne_connection][i]["f_junction"] == last,  gm.ref[:nw][n][:junction_ne_connections][idx])
    ]

    constraint_conserve_flow_ne(gm, n, idx, yp_first, yn_first, yp_last, yn_last)
end
constraint_conserve_flow_ne(gm::GenericGasModel, i::Int) = constraint_conserve_flow_ne(gm, gm.cnw, i)

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow(gm::GenericGasModel, n::Int, idx)
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
function constraint_parallel_flow_ne(gm::GenericGasModel, n::Int, idx)
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
function constraint_weymouth(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:connection,k)
    i = pipe["f_junction"]
    j = pipe["t_junction"]

    mf = gm.ref[:nw][n][:max_mass_flow]
    w = haskey(gm.ref[:nw][n][:pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)

    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]

#    yp = haskey(pipe, "yp") ? pipe["yp"] : nothing
#    yn = haskey(pipe, "yn") ? pipe["yn"] : nothing

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
    parallel = collect(filter( connection -> in(connection, collect(keys(gm.ref[:nw][n][:ne_pipe]))), gm.ref[:nw][n][:all_parallel_connections][(i,j)] ))
    constraint_exclusive_new_pipes(gm,  n, i, j, parallel)
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
