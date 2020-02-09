function _ref_add_core_old!(nw_refs::Dict)
    for (nw,ref) in nw_refs
        # filter turned off stuff
        ref[:junction]      =                               Dict(x for x in ref[:junction]      if  !haskey(x.second,"status") || x.second["status"] == 1)
        ref[:consumer]      =                               Dict(x for x in ref[:consumer]      if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["ql_junc"]    in keys(ref[:junction]))
        ref[:producer]      =                               Dict(x for x in ref[:producer]      if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["qg_junc"]    in keys(ref[:junction]))
        ref[:pipe]          = haskey(ref, :pipe)          ? Dict(x for x in ref[:pipe]          if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:short_pipe]    = haskey(ref, :short_pipe)    ? Dict(x for x in ref[:short_pipe]    if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:compressor]    = haskey(ref, :compressor)    ? Dict(x for x in ref[:compressor]    if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:valve]         = haskey(ref, :valve)         ? Dict(x for x in ref[:valve]         if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:control_valve] = haskey(ref, :control_valve) ? Dict(x for x in ref[:control_valve] if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:resistor]      = haskey(ref, :resistor)      ? Dict(x for x in ref[:resistor]      if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_pipe]       = haskey(ref, :ne_pipe)       ? Dict(x for x in ref[:ne_pipe]       if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_compressor] = haskey(ref, :ne_compressor) ? Dict(x for x in ref[:ne_compressor] if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()

        # compute the maximum flow
        max_mass_flow = _calc_max_mass_flow(ref)
        ref[:max_mass_flow] = max_mass_flow

        # create references to directed and undirected edges
        ref[:directed_pipe]          = Dict(x for x in ref[:pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_short_pipe]    = Dict(x for x in ref[:short_pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_compressor]    = Dict(x for x in ref[:compressor] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_valve]         = Dict(x for x in ref[:valve] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_control_valve] = Dict(x for x in ref[:control_valve] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_resistor]      = Dict(x for x in ref[:resistor] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_ne_pipe]       = Dict(x for x in ref[:ne_pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_ne_compressor] = Dict(x for x in ref[:ne_compressor] if haskey(x.second, "directed") && x.second["directed"] != 0)

        ref[:undirected_pipe]          = Dict(x for x in ref[:pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_short_pipe]    = Dict(x for x in ref[:short_pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_compressor]    = Dict(x for x in ref[:compressor] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_valve]         = Dict(x for x in ref[:valve] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_control_valve] = Dict(x for x in ref[:control_valve] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_resistor]      = Dict(x for x in ref[:resistor] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_ne_pipe]       = Dict(x for x in ref[:ne_pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_ne_compressor] = Dict(x for x in ref[:ne_compressor] if !haskey(x.second, "directed") || x.second["directed"] == 0)

        ref[:dispatch_consumer]        = Dict(x for x in ref[:consumer] if (x.second["dispatchable"] == 1))
        ref[:dispatch_producer]        = Dict(x for x in ref[:producer] if (x.second["dispatchable"] == 1))

        ref[:parallel_pipes] = Dict()
        for (idx, connection) in ref[:pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_pipes][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_compressors] = Dict()
        for (idx, connection) in ref[:compressor]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_compressors][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_resistors] = Dict()
        for (idx, connection) in ref[:resistor]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_resistors][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_short_pipes] = Dict()
        for (idx, connection) in ref[:short_pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_short_pipes][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_valves] = Dict()
        for (idx, connection) in ref[:valve]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_valves][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_control_valves] = Dict()
        for (idx, connection) in ref[:control_valve]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_control_valves][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_ne_pipes] = Dict()
        for (idx, connection) in ref[:ne_pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_ne_pipes][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_ne_compressors] = Dict()
        for (idx, connection) in ref[:ne_compressor]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_ne_compressors][(min(i,j), max(i,j))] = []
        end

        ref[:t_pipes]                 = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_pipes]                 = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_compressors]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_compressors]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_resistors]             = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_resistors]             = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_short_pipes]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_short_pipes]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_valves]                = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_valves]                = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_control_valves]        = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_control_valves]        = Dict(i => [] for (i,junction) in ref[:junction])

        ref[:t_ne_pipes]              = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_ne_pipes]              = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_ne_compressors]        = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_ne_compressors]        = Dict(i => [] for (i,junction) in ref[:junction])

        junction_consumers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_dispatchable_consumers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_nondispatchable_consumers = Dict([(i, []) for (i,junction) in ref[:junction]])
        for (i,consumer) in ref[:consumer]
            push!(junction_consumers[consumer["ql_junc"]], i)
            if (consumer["dispatchable"] == 1)
                push!(junction_dispatchable_consumers[consumer["ql_junc"]], i)
            else
                push!(junction_nondispatchable_consumers[consumer["ql_junc"]], i)
            end
        end
        ref[:junction_consumers] = junction_consumers
        ref[:junction_dispatchable_consumers] = junction_dispatchable_consumers
        ref[:junction_nondispatchable_consumers] = junction_nondispatchable_consumers

        junction_producers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_dispatchable_producers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_nondispatchable_producers = Dict([(i, []) for (i,junction) in ref[:junction]])
        for (i,producer) in ref[:producer]
            push!(junction_producers[producer["qg_junc"]], i)
            if (producer["dispatchable"] == 1)
                push!(junction_dispatchable_producers[producer["qg_junc"]], i)
            else
                push!(junction_nondispatchable_producers[producer["qg_junc"]], i)
            end
        end
        ref[:junction_producers] = junction_producers
        ref[:junction_dispatchable_producers] = junction_dispatchable_producers
        ref[:junction_nondispatchable_producers] = junction_nondispatchable_producers

        ref_degree!(ref)
        ref_degree_ne!(ref)

        ref[:pipe_ref]           = Dict()
        ref[:ne_pipe_ref]        = Dict()
        ref[:compressor_ref]     = Dict()
        ref[:ne_compressor_ref]  = Dict()
        ref[:junction_ref]       = Dict()
        ref[:short_pipe_ref]     = Dict()
        ref[:resistor_ref]       = Dict()
        ref[:valve_ref]          = Dict()
        ref[:control_valve_ref]  = Dict()

        for (idx,pipe) in ref[:pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:pipe_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:pipe_ref][idx][:pd_min] = pd_min
            ref[:pipe_ref][idx][:pd_max] = pd_max
            ref[:pipe_ref][idx][:w] = _calc_pipe_resistance_thorley(ref, pipe)
            ref[:pipe_ref][idx][:f_min] = _calc_pipe_fmin(ref, idx)
            ref[:pipe_ref][idx][:f_max] = _calc_pipe_fmax(ref, idx)

            push!(ref[:f_pipes][i], idx)
            push!(ref[:t_pipes][j], idx)
            push!(ref[:parallel_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,pipe) in ref[:ne_pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:ne_pipe_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:ne_pipe_ref][idx][:pd_min] = pd_min
            ref[:ne_pipe_ref][idx][:pd_max] = pd_max
            ref[:ne_pipe_ref][idx][:w] = _calc_pipe_resistance_thorley(ref, pipe)
            ref[:ne_pipe_ref][idx][:f_min] = _calc_ne_pipe_fmin(ref, idx)
            ref[:ne_pipe_ref][idx][:f_max] = _calc_ne_pipe_fmax(ref, idx)
            push!(ref[:f_ne_pipes][i], idx)
            push!(ref[:t_ne_pipes][j], idx)
            push!(ref[:parallel_ne_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,compressor) in ref[:compressor]
            i = compressor["f_junction"]
            j = compressor["t_junction"]
            ref[:compressor_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, compressor["f_junction"], compressor["t_junction"])
            ref[:compressor_ref][idx][:pd_min] = pd_min
            ref[:compressor_ref][idx][:pd_max] = pd_max
            ref[:compressor_ref][idx][:f_min] = _calc_compressor_fmin(ref, idx)
            ref[:compressor_ref][idx][:f_max] = _calc_compressor_fmax(ref, idx)
            push!(ref[:f_compressors][i], idx)
            push!(ref[:t_compressors][j], idx)
            push!(ref[:parallel_compressors][(min(i,j), max(i,j))], idx)
        end

        for (idx,compressor) in ref[:ne_compressor]
            i = compressor["f_junction"]
            j = compressor["t_junction"]
            ref[:ne_compressor_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, compressor["f_junction"], compressor["t_junction"])
            ref[:ne_compressor_ref][idx][:pd_min] = pd_min
            ref[:ne_compressor_ref][idx][:pd_max] = pd_max
            ref[:ne_compressor_ref][idx][:f_min] = _calc_ne_compressor_fmin(ref, idx)
            ref[:ne_compressor_ref][idx][:f_max] = _calc_ne_compressor_fmax(ref, idx)
            push!(ref[:f_ne_compressors][i], idx)
            push!(ref[:t_ne_compressors][j], idx)
            push!(ref[:parallel_ne_compressors][(min(i,j), max(i,j))], idx)
        end

        for (idx,pipe) in ref[:short_pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:short_pipe_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:short_pipe_ref][idx][:pd_min] = pd_min
            ref[:short_pipe_ref][idx][:pd_max] = pd_max
            ref[:short_pipe_ref][idx][:f_min] = _calc_short_pipe_fmin(ref, idx)
            ref[:short_pipe_ref][idx][:f_max] = _calc_short_pipe_fmax(ref, idx)
            push!(ref[:f_short_pipes][i], idx)
            push!(ref[:t_short_pipes][j], idx)
            push!(ref[:parallel_short_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,resistor) in ref[:resistor]
            i = resistor["f_junction"]
            j = resistor["t_junction"]
            ref[:resistor_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, resistor["f_junction"], resistor["t_junction"])
            ref[:resistor_ref][idx][:pd_min] = pd_min
            ref[:resistor_ref][idx][:pd_max] = pd_max
            ref[:resistor_ref][idx][:w] = _calc_resistor_resistance_simple(ref, resistor)
            ref[:resistor_ref][idx][:f_min] = _calc_resistor_fmin(ref, idx)
            ref[:resistor_ref][idx][:f_max] = _calc_resistor_fmax(ref, idx)
            push!(ref[:f_resistors][i], idx)
            push!(ref[:t_resistors][j], idx)
            push!(ref[:parallel_resistors][(min(i,j), max(i,j))], idx)
        end

        for (idx,valve) in ref[:valve]
            i = valve["f_junction"]
            j = valve["t_junction"]
            ref[:valve_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, valve["f_junction"], valve["t_junction"])
            ref[:valve_ref][idx][:pd_min] = pd_min
            ref[:valve_ref][idx][:pd_max] = pd_max
            ref[:valve_ref][idx][:f_min] = _calc_valve_fmin(ref, idx)
            ref[:valve_ref][idx][:f_max] = _calc_valve_fmax(ref, idx)
            push!(ref[:f_valves][i], idx)
            push!(ref[:t_valves][j], idx)
            push!(ref[:parallel_valves][(min(i,j), max(i,j))], idx)
        end

        for (idx,valve) in ref[:control_valve]
            i = valve["f_junction"]
            j = valve["t_junction"]
            ref[:control_valve_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, valve["f_junction"], valve["t_junction"])
            ref[:control_valve_ref][idx][:pd_min] = pd_min
            ref[:control_valve_ref][idx][:pd_max] = pd_max
            ref[:control_valve_ref][idx][:f_min] = _calc_control_valve_fmin(ref, idx)
            ref[:control_valve_ref][idx][:f_max] = _calc_control_valve_fmax(ref, idx)
            push!(ref[:f_control_valves][i], idx)
            push!(ref[:t_control_valves][j], idx)
            push!(ref[:parallel_control_valves][(min(i,j), max(i,j))], idx)
        end
    end
end

"Add reference information for the degree of junction with expansion edges"
function ref_degree_ne!(ref::Dict{Symbol,Any})
    ref[:degree_ne] = Dict()
    for (i,junction) in ref[:junction]
        ref[:degree_ne][i] = 0
    end

    connections = Set()
    for (i,j) in keys(ref[:parallel_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_compressors]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_resistors]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_short_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_valves]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_control_valves]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_ne_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_ne_compressors]) push!(connections, (i,j)) end

    for (i,j) in connections
        ref[:degree_ne][i] = ref[:degree_ne][i] + 1
        ref[:degree_ne][j] = ref[:degree_ne][j] + 1
    end
end
