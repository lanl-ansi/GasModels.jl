"entry point for the transient model with compressor power objective"
function run_transient_compressor_power(data, model_type, optimizer; kwargs...)
    @assert InfrastructureModels.ismultinetwork(data) == true 
    return run_model(data, model_type, optimizer, build_transient_compressor_power; ref_extensions=[ref_add_transient!], multinetwork=true, kwargs...)
end

""
function build_transient_compressor_power(gm::AbstractGasModel)
    time_points = sort(collect(nw_ids(gm)))
    for n in time_points
        gm.var[:nw][n][:density] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :junction))], 
            base_name="$(n)_rho", 
            lower_bound=ref(gm, n, :junction, i, "p_min"), 
            upper_bound=ref(gm, n, :junction, i, "p_max")
        )
        gm.var[:nw][n][:pressure] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :junction))], 
            base_name="$(n)_p", 
            lower_bound=ref(gm, n, :junction, i, "p_min"), 
            upper_bound=ref(gm, n, :junction, i, "p_max")
        )
        gm.var[:nw][n][:compressor_flow] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :compressor))], 
            base_name="$(n)_f_compressor", 
            lower_bound=-ref(gm, n, :max_mass_flow), 
            upper_bound=ref(gm, n, :max_mass_flow)
        )
        gm.var[:nw][n][:pipe_flux] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :pipe))], 
            base_name="$(n)_phi_pipe", 
            lower_bound=-ref(gm, n, :max_mass_flow)/ref(gm, n, :pipe, i, "area"), 
            upper_bound=ref(gm, n, :max_mass_flow)/ref(gm, n, :pipe, i, "area")
        )
        gm.var[:nw][n][:compressor_ratio] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :compressor))], 
            base_name="$(n)_c_ratio", 
            lower_bound=ref(gm, n, :compressor, i, "c_ratio_min"), 
            upper_bound=ref(gm, n, :compressor, i, "c_ratio_min")
        )
        gm.var[:nw][n][:injection] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :receipt))], 
            base_name="$(n)_injection", 
            lower_bound=ref(gm, n, :receipt, i, "injection_min"), 
            upper_bound=ref(gm, n, :receipt, i, "injection_max")
        )
        gm.var[:nw][n][:withdrawal] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :delivery))], 
            base_name="$(n)_withdrawal", 
            lower_bound=ref(gm, n, :receipt, i, "withdrwal_min"), 
            upper_bound=ref(gm, n, :receipt, i, "withdrawal_max")
        )
        gm.var[:nw][n][:transfer_injection] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :transfer))],
            base_name="$(n)_transfer_injection", 
            lower_bound=0.0,
            upper_bound=-ref(gm, n, :transfer, i, "withdrawal_min")
        )
        gm.var[:nw][n][:transfer_withdrawal] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :transfer))],
            base_name="$(n)_transfer_withdrawal", 
            lower_bound=0.0,
            upper_bound=ref(gm, n, :transfer, i, "withdrawal_max")
        )
        
    end 
end

""
function ref_add_transient!(gm::AbstractGasModel)
    if InfrastructureModels.ismultinetwork(gm.data)
        nws_data = gm.data["nw"]
    else
        nws_data = Dict("0" => gm.data)
    end

    for (n, nw_data) in nws_data
        nw_id = parse(Int, n)
        nw_ref = ref(gm, nw_id)

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

