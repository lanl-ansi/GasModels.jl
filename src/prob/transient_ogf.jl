"entry point for the transient ogf model"
function run_transient_ogf(data, model_type, optimizer; kwargs...)
    @assert _IM.ismultinetwork(data) == true
    return run_model(
        data,
        model_type,
        optimizer,
        build_transient_ogf;
        ref_extensions = [ref_add_transient!],
        kwargs...,
    )
end

""
function build_transient_ogf(gm::AbstractGasModel)
    time_points = sort(collect(nw_ids(gm)))
    start_t = time_points[1]
    end_t = time_points[end]

    # variables for first n-1 time points
    for n in time_points[1:end-1]
        variable_density(gm, n)
        variable_compressor_flow(gm, n)
        variable_pipe_flux(gm, n)
        variable_c_ratio(gm, n)
        variable_injection(gm, n)
        variable_withdrawal(gm, n)
        variable_transfer_flow(gm, n)
    end

    # enforcing time-periodicity without adding additional variables
    var(gm, end_t)[:density] = var(gm, time_points[start_t], :density)
    var(gm, end_t)[:compressor_flow] = var(gm, time_points[start_t], :compressor_flow)
    var(gm, end_t)[:pipe_flux] = var(gm, time_points[start_t], :pipe_flux)
    var(gm, end_t)[:compressor_ratio] = var(gm, time_points[start_t], :compressor_ratio)
    var(gm, end_t)[:injection] = var(gm, time_points[start_t], :injection)
    var(gm, end_t)[:withdrawal] = var(gm, time_points[start_t], :withdrawal)
    var(gm, end_t)[:transfer_effective] = var(gm, time_points[start_t], :transfer_effective)
    var(gm, end_t)[:transfer_injection] = var(gm, time_points[start_t], :transfer_injection)
    var(gm, end_t)[:transfer_withdrawal] =
        var(gm, time_points[start_t], :transfer_withdrawal)


    for n in time_points 
        prev = n-1 
        (n == start_t) && (prev = time_points[end-1])
        expression_density_derivative(gm, n, prev)
        expression_net_nodal_injection(gm, n)
        expression_net_nodal_edge_out_flow(gm, n)
        expression_non_slack_affine_derivative(gm, n)
        expression_compressor_power(gm, n)
    end 

    for n in time_points[1:end-1]
        for i in ids(gm, n, :slack_junctions)
            constraint_slack_node_density(gm, i, n)
        end 
        # constraint_slack_nodal_density(gm, n)
        # constraint_pipe_physics(gm, n)
        # constraint_compressor_physics(gm, n)
        # constraint_compressor_power(gm, n)
        # constraint_transfer_separation(gm, n)
        # constraint_slack_junction_mass_balance(gm, n)
        # constraint_non_slack_junction_mass_balance(gm, n)
    end 

    # objective_transient(gm)

    # constraints
    for n in time_points[1:end-1]

        # pipe physics
        for (i, pipe) in ref(gm, n, :pipe)
            p_fr = var(gm, n, :density, pipe["fr_junction"])
            p_to = var(gm, n, :density, pipe["to_junction"])
            f = var(gm, n, :pipe_flux, i)
            resistance =
                pipe["friction_factor"] * gm.ref[:base_length] * pipe["length"] /
                pipe["diameter"]
            JuMP.@NLconstraint(gm.model, p_fr^2 - p_to^2 - resistance * f * abs(f) == 0)

        end

        # compressor physics
        for (i, compressor) in ref(gm, n, :compressor)
            p_fr = var(gm, n, :density, compressor["fr_junction"])
            p_to = var(gm, n, :density, compressor["to_junction"])
            alpha = var(gm, n, :compressor_ratio, i)
            f = var(gm, n, :compressor_flow, i)
            JuMP.@constraint(gm.model, p_to == alpha * p_fr)
            JuMP.@constraint(gm.model, f * (p_fr - p_to) <= 0)
        end

        # compressor power constraint
        for (i, compressor) in ref(gm, n, :compressor)
            JuMP.@NLconstraint(
                gm.model,
                var(gm, n, :compressor_power)[i] <= compressor["power_max"]
            )
        end

        # transfer separation 
        for (i, transfer) in ref(gm, n, :dispatchable_transfer)
            s = var(gm, n, :transfer_injection)[i]
            d = var(gm, n, :transfer_withdrawal)[i]
            t = var(gm, n, :transfer_effective)[i]
            JuMP.@constraint(gm.model, t == d - s)
        end

        # mass balance constraints for slack junctions 
        con(gm, n)[:slack_junctions_mass_balance] = JuMP.@constraint(
            gm.model,
            [i in keys(ref(gm, n, :slack_junctions))],
            var(gm, n, :net_nodal_injection)[i] == var(gm, n, :net_nodal_edge_out_flow)[i]
        )

        # mass balance constraints for non-slack junctions 
        con(gm, n)[:non_slack_junctions_mass_balance] = JuMP.@constraint(
            gm.model,
            [i in ref(gm, n, :non_slack_junction_ids)],
            var(gm, n, :non_slack_derivative)[i] +
            4 * (var(gm, n, :net_nodal_edge_out_flow)[i] - var(gm, n, :net_nodal_injection)[i]) ==
            0.0
        )

    end

    # objective (load shed objective added for now)
    m = (gm.ref[:specific_heat_capacity_ratio] - 1) / gm.ref[:specific_heat_capacity_ratio]
    W = 286.76 * gm.ref[:temperature] / gm.ref[:gas_specific_gravity] / m
    econ_weight = gm.ref[:economic_weighting]
    load_shed_expressions = []
    compressor_power_expressions = []
    for n in time_points
        for (i, receipt) in ref(gm, n, :dispatchable_receipt)
            push!(
                load_shed_expressions,
                JuMP.@NLexpression(
                    gm.model,
                    receipt["offer_price"] * var(gm, n, :injection)[i]
                )
            )
        end
        for (i, delivery) in ref(gm, n, :dispatchable_delivery)
            push!(
                load_shed_expressions,
                JuMP.@NLexpression(
                    gm.model,
                    -delivery["bid_price"] * var(gm, n, :withdrawal)[i]
                )
            )
        end
        for (i, transfer) in ref(gm, n, :dispatchable_transfer)
            push!(
                load_shed_expressions,
                JuMP.@NLexpression(
                    gm.model,
                    transfer["offer_price"] * var(gm, n, :transfer_injection)[i] -
                    transfer["bid_price"] * var(gm, n, :transfer_withdrawal)[i]
                )
            )
        end
        for (i, compressor) in ref(gm, n, :compressor)
            push!(compressor_power_expressions, var(gm, n, :compressor_power)[i])
        end
    end
    JuMP.@NLobjective(
        gm.model,
        Min,
        econ_weight *
        sum(load_shed_expressions[i] for i = 1:length(load_shed_expressions)) +
        (1 - econ_weight) *
        sum(compressor_power_expressions[i] for i = 1:length(compressor_power_expressions))
    )

end

""
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
            pipe["resistance"] =
                pipe["friction_factor"] * pipe["length"] * ref[:base_length] /
                pipe["diameter"]
            fr_junction = nw_ref[:junction][pipe["fr_junction"]]
            to_junction = nw_ref[:junction][pipe["fr_junction"]]
            fr_p_min = fr_junction["p_min"]
            fr_p_max = fr_junction["p_max"]
            to_p_min = to_junction["p_min"]
            to_p_max = to_junction["p_max"]
            pipe["flux_min"] = -sqrt((to_p_max^2 - fr_p_min^2) / pipe["resistance"])
            pipe["flux_max"] = sqrt((fr_p_max^2 - to_p_min^2) / pipe["resistance"])
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
            Memento.error(
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
