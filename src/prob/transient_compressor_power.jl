"entry point for the transient model with compressor power objective"
function run_transient_compressor_power(data, model_type, optimizer; kwargs...)
    @assert InfrastructureModels.ismultinetwork(data) == true 
    return run_model(data, model_type, optimizer, build_transient_compressor_power; ref_extensions=[ref_add_transient!], multinetwork=true, kwargs...)
end

""
function build_transient_compressor_power(pm::AbstractGasModel)
    
end

""
function ref_add_transient!(pm::AbstractGasModel)
    if InfrastructureModels.ismultinetwork(pm.data)
        nws_data = pm.data["nw"]
    else
        nws_data = Dict("0" => pm.data)
    end

    for (n, nw_data) in nws_data
        nw_id = parse(Int, n)
        nw_ref = ref(pm, nw_id)

        arcs_from = [(i, pipe["fr_junction"], pipe["to_junction"], false) for (i, pipe) in nw_ref[:pipe]]
        append!(arcs_from, [(i, compressor["fr_junction"], compressor["to_junction"], true) for (i, compressor) in nw_ref[:compressor]])

        nw_ref[:non_slack_neighbors] = Dict(i => [] for (i, junction) in nw_ref[:junction] if junction["junction_type"] == 0)
        for (i, fr_junction, to_junction, is_compressor) in arcs_from
            is_f_slack = (nw_ref[:junction][fr_junction]["junction_type"] == 1)
            is_t_slack = (nw_ref[:junction][to_junction]["junction_type"] == 1)
            if !is_f_slack && !is_t_slack 
                push!(nw_ref[:non_slack_neighbors][fr_junction], to_junction)
                push!(nw_ref[:non_slack_neighbors][to_junction], fr_junction)
            end 
        end 

        nw_ref[:neighbors] = Dict(i => Dict{Any,Any}() for i in keys(nw_ref[:junction]))
        for (i, f_junction, t_junction, is_compressor) in arcs_from
            nw_ref[:neighbors][f_junction][t_junction] = Dict() 
            nw_ref[:neighbors][t_junction][f_junction] = Dict() 
            from_dict = Dict(
                "id" => i, 
                "is_compressor" => is_compressor
            )

            to_dict = Dict(
                "id" => i, 
                "is_compressor" => is_compressor 
            )

            nw_ref[:neighbors][f_junction][t_junction] = from_dict
            nw_ref[:neighbors][t_junction][f_junction] = to_dict
        end 

        slack_junctions = Dict()
        non_slack_junction_ids = []
        for (k, v) in nw_ref[:junction]
            (v["junction_type"] == 1) && (slack_junctions[k] = v)
            (v["junction_type"] == 0) && (push!(non_slack_junction_ids, k))
        end 

        if length(slack_junctions) == 0
            Memento.error(_LOGGER, "No slack junctions found in the data - add a slack junction")
        end

        if length(slack_junctions) > 1
            Memento.warn(_LOGGER, "multiple slack junctions, $(keys(slack_junctions))")
        end

        nw_ref[:slack_junctions] = slack_junctions
        nw_ref[:non_slack_junction_ids] = non_slack_junction_ids
    end
    
end

