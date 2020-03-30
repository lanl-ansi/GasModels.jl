"entry point for the transient ogf model"
function run_transient_ogf(data, model_type, optimizer; kwargs...)
    @assert _IM.ismultinetwork(data) == true 
    return run_model(data, model_type, optimizer, build_transient_ogf; ref_extensions=[ref_add_transient!], kwargs...)
end

""
function build_transient_ogf(gm::AbstractGasModel)
    time_points = sort(collect(nw_ids(gm)))
    start_t = time_points[1]
    end_t = time_points[end]

    # variables for first n-1 time points
    for n in time_points[1:end-1]
        variable_density(gm, n)
        
        var(gm, n)[:compressor_flow] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :compressor))], 
            base_name="$(n)_f_compressor", 
            lower_bound=-ref(gm, n, :max_mass_flow), 
            upper_bound=ref(gm, n, :max_mass_flow)
        )
        var(gm, n)[:pipe_flux] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :pipe))], 
            base_name="$(n)_f_pipe", 
            lower_bound=ref(gm, n, :pipe, i)["flux_min"], 
            upper_bound=ref(gm, n, :pipe, i)["flux_max"]
        )
        var(gm, n)[:compressor_ratio] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :compressor))], 
            base_name="$(n)_c_ratio", 
            lower_bound=ref(gm, n, :compressor, i, "c_ratio_min"), 
            upper_bound=ref(gm, n, :compressor, i, "c_ratio_max")
        )
        var(gm, n)[:injection] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_receipt))], 
            base_name="$(n)_injection", 
            lower_bound=ref(gm, n, :receipt, i, "injection_min"), 
            upper_bound=ref(gm, n, :receipt, i, "injection_max")
        )
        var(gm, n)[:withdrawal] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_delivery))], 
            base_name="$(n)_withdrawal", 
            lower_bound=ref(gm, n, :receipt, i, "withdrawal_min"), 
            upper_bound=ref(gm, n, :receipt, i, "withdrawal_max")
        )
        var(gm, n)[:transfer_effective] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_transfer))],
            base_name="$(n)_transfer_effective", 
            lower_bound=min(ref(gm, n, :transfer, i, "withdrawal_min"), 0.0),
            upper_bound=max(0.0, ref(gm, n, :transfer, i, "withdrawal_max"))
        )
        var(gm, n)[:transfer_injection] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_transfer))],
            base_name="$(n)_transfer_injection", 
            lower_bound=0.0,
            upper_bound=max(-ref(gm, n, :transfer, i, "withdrawal_min"), 0.0)
        )
        var(gm, n)[:transfer_withdrawal] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_transfer))],
            base_name="$(n)_transfer_withdrawal", 
            lower_bound=0.0,
            upper_bound=max(ref(gm, n, :transfer, i, "withdrawal_max"), 0.0)
        )
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
    var(gm, end_t)[:transfer_withdrawal] = var(gm, time_points[start_t], :transfer_withdrawal)


    # expressions 
    for n in time_points 
        # density derivatives for non slack nodes, for slack nodes density (pressure) is fixed
        var(gm, n)[:density_derivative] = Dict{Int, Any}()
        prev = n - 1
        (n == start_t) && (prev = time_points[end-1])
        for i in ref(gm, n, :non_slack_junction_ids)
            var(gm, n, :density_derivative)[i] = (var(gm, n, :density, i) - var(gm, prev, :density, i)) / gm.ref[:time_step]
        end 

        # total injection into a node and total edge flow out of a node 
        var(gm, n)[:total_injection] = Dict{Int, Any}()
        var(gm, n)[:total_edge_out_flow] = Dict{Int, Any}()
        for (i, junction) in ref(gm, n, :junction)
            var(gm, n, :total_injection)[i] = 0
            var(gm, n, :total_edge_out_flow)[i] = 0
            for j in ref(gm, n, :dispatchable_receipts_in_junction, i)
                var(gm, n, :total_injection)[i] += var(gm, n, :injection, j)
            end 
            for j in ref(gm, n, :dispatchable_transfers_in_junction, i)
                var(gm, n, :total_injection)[i] -= var(gm, n, :transfer_effective, j)
            end 
            for j in ref(gm, n, :dispatchable_deliveries_in_junction, i)
                var(gm, n, :total_injection)[i] -= var(gm, n, :withdrawal, j)
            end 
            for j in ref(gm, n, :nondispatchable_receipts_in_junction, i)
                var(gm, n, :total_injection)[i] += ref(gm, n, :receipt, j, "injection_nominal")
            end 
            for j in ref(gm, n, :nondispatchable_transfers_in_junction, i)
                var(gm, n, :total_injection)[i] -= ref(gm, n, :transfer, j, "withdrawal_nominal") 
            end
            for j in ref(gm, n, :nondispatchable_deliveries_in_junction, i)
                var(gm, n, :total_injection)[i] -= ref(gm, n, :delivery, j, "withdrawal_nominal") 
            end 
            for j in ref(gm, n, :pipes_fr, i)
                var(gm, n, :total_edge_out_flow)[i] += (var(gm, n, :pipe_flux, j) * 
                    ref(gm, n, :pipe, j)["area"]
                )
            end 
            for j in ref(gm, n, :compressors_fr, i)
                var(gm, n, :total_edge_out_flow)[i] += var(gm, n, :compressor_flow, j)
            end 
            for j in ref(gm, n, :pipes_to, i)
                var(gm, n, :total_edge_out_flow)[i] -= (var(gm, n, :pipe_flux, j) * 
                    ref(gm, n, :pipe, j)["area"]
                )
            end 
            for j in ref(gm, n, :compressors_to, i)
                var(gm, n, :total_edge_out_flow)[i] -= var(gm, n, :compressor_flow, j)
            end 
        end  

        # non-slack junction affine derivative expression 
        var(gm, n)[:non_slack_derivative] = Dict{Int,Any}()
        for i in ref(gm, n, :non_slack_junction_ids)
            var(gm, n, :non_slack_derivative)[i] = 0
            derivative_indices = ref(gm, n, :non_slack_neighbor_junction_ids, i)
            for j in derivative_indices
                pipe_info = ref(gm, n, :neighbor_edge_info, j)[i]
                id = pipe_info["id"]
                is_compressor = pipe_info["is_compressor"]
                pipe = is_compressor ? ref(gm, n, :compressor, id) : ref(gm, n, :pipe, id)
                x = pipe["length"] * pi * pipe["diameter"]^2 / 4.0
                if (is_compressor && pipe["fr_junction"] == j && pipe["to_junction"] == i)
                    var(gm, n, :non_slack_derivative)[i] += (x * var(gm, n, :compressor_ratio, id) * 
                        var(gm, n, :density_derivative, j))
                else 
                    var(gm, n, :non_slack_derivative)[i] += (x * var(gm, n, :density_derivative, j))
                end
            end
            
            for (j, neighbor) in ref(gm, n, :neighbor_edge_info, i)
                id = neighbor["id"]
                is_compressor = neighbor["is_compressor"]
                pipe = is_compressor ? ref(gm, n, :compressor, id) : ref(gm, n, :pipe, id)
                x = pipe["length"] * pi * pipe["diameter"]^2 / 4.0
                if (is_compressor && pipe["fr_junction"] == i && pipe["to_junction"] == j) 
                    var(gm, n, :non_slack_derivative)[i] += (x * var(gm, n, :compressor_ratio, id) * 
                        var(gm, n, :density_derivative, i))
                else 
                    var(gm, n, :non_slack_derivative)[i] += (x * var(gm, n, :density_derivative, i))
                end
            end 
        end 

        # compressor power expression 
        var(gm, n)[:compressor_power] = Dict{Int,Any}()
        for (i, compressor) in ref(gm, n, :compressor)
            alpha = var(gm, n, :compressor_ratio, i)
            f = var(gm, n, :compressor_flow, i)
            m = (gm.ref[:specific_heat_capacity_ratio] - 1) / gm.ref[:specific_heat_capacity_ratio] 
            W = 286.76 * gm.ref[:temperature] / gm.ref[:gas_specific_gravity] / m
            var(gm, n, :compressor_power)[i] = JuMP.@NLexpression(gm.model, W * f * (alpha^m - 1))
        end
    end 
    
    # constraints
    for n in time_points[1:end-1]
        # slack node density fixed to a certain value
        con(gm, n)[:slack_density] = JuMP.@constraint(gm.model, [i in keys(ref(gm, n, :slack_junctions))], 
            var(gm, n, :density)[i] == ref(gm, n, :slack_junctions, i)["p_nominal"]
        )
        
        # pipe physics
        for (i, pipe) in ref(gm, n, :pipe)
            p_fr = var(gm, n, :density, pipe["fr_junction"])
            p_to = var(gm, n, :density, pipe["to_junction"])
            f = var(gm, n, :pipe_flux, i)
            resistance = pipe["friction_factor"] * gm.ref[:base_length] * pipe["length"] / pipe["diameter"]
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
            JuMP.@NLconstraint(gm.model, var(gm, n, :compressor_power)[i] <= compressor["power_max"])
        end 

        # transfer separation 
        for (i, transfer) in ref(gm, n, :dispatchable_transfer)
            s = var(gm, n, :transfer_injection)[i]
            d = var(gm, n, :transfer_withdrawal)[i]
            t = var(gm, n, :transfer_effective)[i]
            JuMP.@constraint(gm.model, t == d - s)
        end 

        # mass balance constraints for slack junctions 
        con(gm, n)[:slack_junctions_mass_balance] = JuMP.@constraint(gm.model, [i in keys(ref(gm, n, :slack_junctions))], 
            var(gm, n, :total_injection)[i] == var(gm, n, :total_edge_out_flow)[i]
        )

        # mass balance constraints for non-slack junctions 
        con(gm, n)[:non_slack_junctions_mass_balance] = JuMP.@constraint(gm.model, [i in ref(gm, n, :non_slack_junction_ids)],
            var(gm, n, :non_slack_derivative)[i] + 4 * (var(gm, n, :total_edge_out_flow)[i] - var(gm, n, :total_injection)[i]) 
            == 0.0 
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
            push!(load_shed_expressions, JuMP.@NLexpression(gm.model, receipt["offer_price"] * var(gm, n, :injection)[i]))
        end 
        for (i, delivery) in ref(gm, n, :dispatchable_delivery)
            push!(load_shed_expressions,  JuMP.@NLexpression(gm.model, -delivery["bid_price"] * var(gm, n, :withdrawal)[i]))
        end 
        for (i, transfer) in ref(gm, n, :dispatchable_transfer)
            push!(load_shed_expressions, JuMP.@NLexpression(gm.model, transfer["offer_price"] * var(gm, n, :transfer_injection)[i] - 
                transfer["bid_price"] * var(gm, n, :transfer_withdrawal)[i])
            )
        end 
        for (i, compressor) in ref(gm, n, :compressor)
            push!(compressor_power_expressions, var(gm, n, :compressor_power)[i])
        end 
    end 
    JuMP.@NLobjective(gm.model, Min, econ_weight * sum(load_shed_expressions[i] for i in 1:length(load_shed_expressions)) + 
        (1-econ_weight) * sum(compressor_power_expressions[i] for i in 1:length(compressor_power_expressions))
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
            pipe["resistance"] = pipe["friction_factor"] * pipe["length"] * ref[:base_length] / pipe["diameter"];
            fr_junction = nw_ref[:junction][pipe["fr_junction"]]
            to_junction = nw_ref[:junction][pipe["fr_junction"]]
            fr_p_min = fr_junction["p_min"]
            fr_p_max = fr_junction["p_max"]
            to_p_min = to_junction["p_min"]
            to_p_max = to_junction["p_max"]
            pipe["flux_min"] = -sqrt((to_p_max^2 - fr_p_min^2)/pipe["resistance"])
            pipe["flux_max"] = sqrt((fr_p_max^2 - to_p_min^2)/pipe["resistance"])
        end 
        arcs_from = [(i, pipe["fr_junction"], pipe["to_junction"], false) for (i, pipe) in nw_ref[:pipe]]
        append!(arcs_from, [(i, compressor["fr_junction"], compressor["to_junction"], true) for (i, compressor) in nw_ref[:compressor]])

        nw_ref[:non_slack_neighbor_junction_ids] = Dict(i => [] for (i, junction) in nw_ref[:junction] if junction["junction_type"] == 0)
        for (i, fr_junction, to_junction, is_compressor) in arcs_from
            is_f_slack = (nw_ref[:junction][fr_junction]["junction_type"] == 1)
            is_t_slack = (nw_ref[:junction][to_junction]["junction_type"] == 1)
            if !is_f_slack && !is_t_slack 
                push!(nw_ref[:non_slack_neighbor_junction_ids][fr_junction], to_junction)
                push!(nw_ref[:non_slack_neighbor_junction_ids][to_junction], fr_junction)
            end 
        end 

        nw_ref[:neighbor_edge_info] = Dict(i => Dict{Any,Any}() for i in keys(nw_ref[:junction]))
        for (i, fr_junction, to_junction, is_compressor) in arcs_from
            nw_ref[:neighbor_edge_info][fr_junction][to_junction] = Dict() 
            nw_ref[:neighbor_edge_info][to_junction][fr_junction] = Dict() 
            from_dict = Dict(
                "id" => i, 
                "is_compressor" => is_compressor
            )

            to_dict = Dict(
                "id" => i, 
                "is_compressor" => is_compressor 
            )

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
            Memento.error(_LOGGER, "No slack junctions found in the data - add a slack junction")
        end

        if length(slack_junctions) > 1
            Memento.warn(_LOGGER, "multiple slack junctions, $(keys(slack_junctions))")
        end

        nw_ref[:slack_junctions] = slack_junctions
        nw_ref[:non_slack_junction_ids] = non_slack_junction_ids
    end
    
end

