
function ref_add_ne!(refs::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    _ref_add_ne!(refs[:nw], refs[:base_length], refs[:base_pressure], refs[:base_flow], refs[:sound_speed])
end


function _ref_add_ne!(nw_refs::Dict{Int,<:Any}, base_length, base_pressure, base_flow, sound_speed)
    for (nw, ref) in nw_refs
        ref[:ne_pipe]       = haskey(ref, :ne_pipe) ? Dict(x for x in ref[:ne_pipe] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_compressor] = haskey(ref, :ne_compressor) ? Dict(x for x in ref[:ne_compressor] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()

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
    for (i,j) in keys(ref[:parallel_loss_resistors]) push!(connections, (i,j)) end
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

"adds the additional data into the ref that is required to used to formulate the transient formulation"
function ref_add_transient!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    if _IM.ismultinetwork(data)
        nws_data = data["nw"]
    else
        nws_data = Dict("0" => data)
    end

    for (n, nw_data) in nws_data
        nw_id = parse(Int, n)
        nw_ref = ref[:nw][nw_id]

        for (i, pipe) in nw_ref[:pipe]
            resistance =  _calc_pipe_resistance_rho_phi_space(pipe, ref[:base_length])
            fr_junction = nw_ref[:junction][pipe["fr_junction"]]
            to_junction = nw_ref[:junction][pipe["fr_junction"]]
            fr_p_min = fr_junction["p_min"]
            fr_p_max = fr_junction["p_max"]
            to_p_min = to_junction["p_min"]
            to_p_max = to_junction["p_max"]
            pipe["flux_min"] = -sqrt((to_p_max^2 - fr_p_min^2) / resistance)
            pipe["flux_max"] = sqrt((fr_p_max^2 - to_p_min^2) / resistance)
        end

        for (i, pipe) in get(nw_ref, :original_pipe, [])
            pipe["area"] = pi * pipe["diameter"] * pipe["diameter"] / 4.0
        end
        arcs_from = [
            (i, pipe["fr_junction"], pipe["to_junction"], false)
            for (i, pipe) in nw_ref[:pipe]
        ]
        append!(
            arcs_from,
            [
                (i, compressor["fr_junction"], compressor["to_junction"], true)
                for (i, compressor) in nw_ref[:compressor]
            ],
        )

        nw_ref[:non_slack_neighbor_junction_ids] = Dict(
            i => []
            for (i, junction) in nw_ref[:junction] if junction["junction_type"] == 0
        )
        for (i, fr_junction, to_junction, is_compressor) in arcs_from
            is_f_slack = (nw_ref[:junction][fr_junction]["junction_type"] == 1)
            is_t_slack = (nw_ref[:junction][to_junction]["junction_type"] == 1)
            if !is_f_slack && !is_t_slack
                push!(nw_ref[:non_slack_neighbor_junction_ids][fr_junction], to_junction)
                push!(nw_ref[:non_slack_neighbor_junction_ids][to_junction], fr_junction)
            end
        end

        nw_ref[:neighbor_edge_info] =
            Dict(i => Dict{Any,Any}() for i in keys(nw_ref[:junction]))
        for (i, fr_junction, to_junction, is_compressor) in arcs_from
            nw_ref[:neighbor_edge_info][fr_junction][to_junction] = Dict()
            nw_ref[:neighbor_edge_info][to_junction][fr_junction] = Dict()
            from_dict = Dict("id" => i, "is_compressor" => is_compressor)

            to_dict = Dict("id" => i, "is_compressor" => is_compressor)

            nw_ref[:neighbor_edge_info][fr_junction][to_junction] = from_dict
            nw_ref[:neighbor_edge_info][to_junction][fr_junction] = to_dict
        end

        slack_junctions = Dict()
        non_slack_junction_ids = []
        for (k, v) in nw_ref[:junction]
            (v["junction_type"] == 1) && (slack_junctions[k] = v)
            (v["junction_type"] == 0) && (push!(non_slack_junction_ids, k))
        end

        if length(slack_junctions) == 0
            Memento.warn(
                _LOGGER,
                "No slack junctions found in the data - add a slack junction",
            )
        end

        if length(slack_junctions) > 1
            Memento.warn(_LOGGER, "multiple slack junctions, $(keys(slack_junctions))")
        end

        nw_ref[:slack_junctions] = slack_junctions
        nw_ref[:non_slack_junction_ids] = non_slack_junction_ids
    end

end
