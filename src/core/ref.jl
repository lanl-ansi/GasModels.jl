
function ref_add_ne!(gm::AbstractGasModel)
    _ref_add_ne!(gm.ref[:nw]; base_length=gm.ref[:base_length], base_pressure=gm.ref[:base_pressure], base_flow=gm.ref[:base_flow], sound_speed=gm.ref[:sound_speed])
end


function _ref_add_ne!(nw_refs::Dict; base_length=5000.0, base_pressure=1.0, base_flow=1.0/371.6643, sound_speed=371.6643)
    for (nw, ref) in nw_refs
        ref[:ne_pipe]       = haskey(ref, :ne_pipe) ? Dict(x for x in ref[:ne_pipe] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_compressor] = haskey(ref, :ne_compressor) ? Dict(x for x in ref[:ne_compressor] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()

        ref[:directed_ne_pipe]       = Dict(x for x in ref[:ne_pipe] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] == 0)
        ref[:undirected_ne_pipe]       = Dict(x for x in ref[:ne_pipe] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] != 0)

        # compressor types
        # default allows compression with uncompressed flow reversals
        ref[:default_ne_compressor] = Dict(x for x in ref[:ne_compressor] if haskey(x.second, "directionality") && x.second["directionality"] == 2)
        ref[:bidirectional_ne_compressor] = Dict(x for x in ref[:ne_compressor] if haskey(x.second, "directionality") && x.second["directionality"] == 0)
        ref[:unidirectional_ne_compressor] = Dict(x for x in ref[:ne_compressor] if haskey(x.second, "directionality") && x.second["directionality"] == 1)

        ref[:parallel_ne_pipes] = Dict()
        ref[:parallel_ne_compressors] = Dict()

        _add_parallel_edges!(ref[:parallel_ne_pipes], ref[:ne_pipe])
        _add_parallel_edges!(ref[:parallel_ne_compressors], ref[:ne_compressor])

        ref[:ne_pipes_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:ne_pipes_to] = Dict(i => [] for (i,junction) in ref[:junction])

        ref[:ne_compressors_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:ne_compressors_to] = Dict(i => [] for (i,junction) in ref[:junction])

        _add_edges_to_junction_map!(ref[:ne_pipes_fr], ref[:ne_pipes_to], ref[:ne_pipe])
        _add_edges_to_junction_map!(ref[:ne_compressors_fr], ref[:ne_compressors_to], ref[:ne_compressor])

        ref_degree_ne!(ref)

        for (idx, pipe) in ref[:ne_pipe]
            i = pipe["fr_junction"]
            j = pipe["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            pipe["pd_min"] = pd_min
            pipe["pd_max"] = pd_max
            pipe["resistance"] = _calc_pipe_resistance(pipe, base_length, base_pressure, base_flow, sound_speed)
            pipe["flow_min"] = _calc_pipe_flow_min(ref, pipe)
            pipe["flow_max"] = _calc_pipe_flow_max(ref, pipe)
        end

        for (idx,compressor) in ref[:ne_compressor]
            i = compressor["fr_junction"]
            j = compressor["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            compressor["pd_min"] = pd_min
            compressor["pd_max"] = pd_max
            compressor["resistance"] = _calc_pipe_resistance(compressor, base_length, base_pressure, base_flow, sound_speed)
            compressor["flow_min"] = _calc_pipe_flow_min(ref, compressor)
            compressor["flow_max"] = _calc_pipe_flow_max(ref, compressor)
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
    for (i,j) in keys(ref[:parallel_regulators]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_ne_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_ne_compressors]) push!(connections, (i,j)) end

    for (i,j) in connections
        ref[:degree_ne][i] = ref[:degree_ne][i] + 1
        ref[:degree_ne][j] = ref[:degree_ne][j] + 1
    end
end
