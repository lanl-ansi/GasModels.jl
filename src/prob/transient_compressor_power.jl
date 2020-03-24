"entry point for the transient model with compressor power objective"
function run_transient_compressor_power(data, model_type, optimizer; kwargs...)
    @assert InfrastructureModels.ismultinetwork(data) == true 
    return run_model(data, model_type, optimizer, build_transient_compressor_power; ref_extensions=[ref_add_transient!], multinetwork=true, kwargs...)
end

""
function build_transient_compressor_power(gm::AbstractGasModel)
    time_points = sort(collect(nw_ids(gm)))

    for n in time_points
        if (n == time_points[end])
            # enforcing time-periodicity without adding additional variables (is esp. good for Ipopt)
            var(gm, n)[:density] = var(gm, time_points[1], :density)
            var(gm, n)[:pressure] = var(gm, time_points[1], :pressure)
            var(gm, n)[:compressor_flow] = var(gm, time_points[1], :compressor_flow)
            var(gm, n)[:pipe_flow] = var(gm, time_points[1], :pipe_flow)
            var(gm, n)[:compressor_ratio] = var(gm, time_points[1], :compressor_ratio)
            var(gm, n)[:injection] = var(gm, time_points[1], :injection)
            var(gm, n)[:withdrawal] = var(gm, time_points[1], :withdrawal)
            var(gm, n)[:transfer_injection] = var(gm, time_points[1], :transfer_injection)
            var(gm, n)[:transfer_withdrawal] = var(gm, time_points[1], :transfer_withdrawal)
        end 
        var(gm, n)[:density] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :junction))], 
            base_name="$(n)_rho", 
            lower_bound=ref(gm, n, :junction, i, "p_min"), 
            upper_bound=ref(gm, n, :junction, i, "p_max")
        )
        var(gm, n)[:pressure] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :junction))], 
            base_name="$(n)_p", 
            lower_bound=ref(gm, n, :junction, i, "p_min"), 
            upper_bound=ref(gm, n, :junction, i, "p_max")
        )
        var(gm, n)[:compressor_flow] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :compressor))], 
            base_name="$(n)_f_compressor", 
            lower_bound=-ref(gm, n, :max_mass_flow), 
            upper_bound=ref(gm, n, :max_mass_flow)
        )
        var(gm, n)[:pipe_flow] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :pipe))], 
            base_name="$(n)_f_pipe", 
            lower_bound=-ref(gm, n, :max_mass_flow), 
            upper_bound=ref(gm, n, :max_mass_flow)
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
            lower_bound=ref(gm, n, :receipt, i, "withdrwal_min"), 
            upper_bound=ref(gm, n, :receipt, i, "withdrawal_max")
        )
        var(gm, n)[:transfer_effective] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_transfer))],
            base_name="$(n)_transfer_withdrawal", 
            lower_bound=ref(gm, n, :transfer, i, "withdrawal_min"),
            upper_bound=-ref(gm, n, :transfer, i, "withdrawal_max")
        )
        var(gm, n)[:transfer_injection] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_transfer))],
            base_name="$(n)_transfer_injection", 
            lower_bound=0.0,
            upper_bound=-ref(gm, n, :transfer, i, "withdrawal_min")
        )
        var(gm, n)[:transfer_withdrawal] = JuMP.@variable(gm.model, [i in keys(ref(gm, n, :dispatchable_transfer))],
            base_name="$(n)_transfer_withdrawal", 
            lower_bound=0.0,
            upper_bound=ref(gm, n, :transfer, i, "withdrawal_max")
        )
    end 

    # density derivative expressions 
    for n in time_points[1:end-1] 

        var(gm, n)[:density_derivative] = Dict{Int, Any}()
        if (n == 1)
            prev = time_points[end-1]
            for i in ref(gm, n, :non_slack_junction_ids)
                var(gm, n, :density_derivative)[i] = (var(gm, n, :density, i) - var(gm, prev, :density, i)) / gm.ref[:time_step]
            end
        else 
            for i in ref(gm, n, :non_slack_junction_ids)
                var(gm, n, :density_derivative)[i] = (var(gm, n, :density, i) - var(gm, n-1, :density, i)) / gm.ref[:time_step]
            end
        end 

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
            for j in ref(gm, n, :non_dispatchable_receipts_in_junction, i)
                var(gm, n, :total_injection)[i] += ref(gm, n, :receipt, j, "injection_nominal")
            end 
            for j in ref(gm, n, :non_dispatchable_transfers_in_junction, i)
                var(gm, n, :total_injection)[i] -= ref(gm, n, :transfer, j, "withdrawal_nominal") 
            end
            for j in ref(gm, n, :non_dispatchable_deliveries_in_junction, i)
                var(gm, n, :total_injection)[i] -= ref(gm, n, :delivery, j, "withdrawal_nominal") 
            end 
            for j in ref(gm, n, :pipes_fr, i)
                var(gm, n, :total_edge_out_flow)[i] += var(gm, n, :pipe_flow, j)
            end 
            for j in ref(gm, n, :compressors_fr, i)
                var(gm, n, :total_edge_out_flow)[i] += var(gm, n, :compressor_flow, j)
            end 
            for j in ref(gm, n, :pipes_to, i)
                var(gm, n, :total_edge_out_flow)[i] -= var(gm, n, :pipe_flow, j)
            end 
            for j in ref(gm, n, :compressors_to, i)
                var(gm, n, :total_edge_out_flow)[i] -= var(gm, n, :compressor_flow, j)
            end 
        end 

        (n == 1) && (continue)
        var(gm, n)[:non_slack_derivative] = Dict{Int,Any}()
        for i in ref(gm, n, :non_slack_junction_ids)
            var(gm, n, :non_slack_derivative)[i] = 0
            derivative_indices = ref(gm, n, :non_slack_neighbors, i)
            for j in derivative_indices
                pipe_info = ref(gm, n, :neighbors, j)[i]
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
            
            for (j, neighbor) in ref(gm, n, :neighbors, i)
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


    end 
    
    for n in time_points[1:end-1]
        # slack node density and pressure fixed to a certain value
        con(gm, n)[:slack_density] = JuMP.@constraint(gm.model, [i in keys(ref(gm, n, :slack_junctions))], 
            var(gm, n, :density)[i] == ref(gm, n, :slack_junctions, i)["p_nominal"]
        )
        con(gm, n)[:slack_pressure] = JuMP.@constraint(gm.model, [i in keys(ref(gm, n, :slack_junctions))], 
            var(gm, n, :pressure)[i] == ref(gm, n, :slack_junctions, i)["p_nominal"]
        )

        # pressure density relationship 
        con(gm, n)[:pressure_density_eq] = JuMP.@constraint(gm.model, [i in keys(ref(gm, n, :junction))], 
            var(gm, n, :pressure)[i] == var(gm, n, :density)[i]
        )
        
        # pipe physics
        for (i, pipe) in ref(gm, n, :pipe)
            p_fr = var(gm, n, :pressure, pipe["fr_junction"])
            p_to = var(gm, n, :pressure, pipe["to_junction"])
            f = var(gm, n, :pipe_flow, i)
            resistance = pipe["friction_factor"] * gm.ref[:base_length] * pipe["length"] / pipe["diameter"] / pipe["area"] / pipe["area"]
            JuMP.@NLconstraint(gm.model, p_fr^2 - p_to^2 - resistance * f * abs(f) == 0)
            
        end 
        
        # compressor physics
        for (i, compressor) in ref(gm, n, :compressor)
            p_fr = var(gm, n, :pressure, compressor["fr_junction"])
            p_to = var(gm, n, :pressure, compressor["to_junction"])
            alpha = var(gm, n, :compressor_ratio, i)
            f = var(gm, n, :compressor_flow, i)
            JuMP.@constraint(gm.model, p_to == alpha * p_fr)
            JuMP.@constraint(gm.model, f * (p_fr - p_to) <= 0)
        end 

        # compressor power constraint
        for (i, compressor) in ref(gm, n, :compressor)
            alpha = var(gm, n, :compressor_ratio, i)
            f = var(gm, n, :compressor_flow, i)
            m = (gm.ref[:specific_heat_capacity_ratio] - 1) / gm.ref[:specific_heat_capacity_ratio] 
            W = 286.76 * gm.ref[:temperature] / gm.ref[:gas_specific_gravity] / m
            JuMP.@NLconstraint(gm.model, W * f * (alpha^m - 1) <= compressor["power_max"])
        end 

        # transfer separation 
        for (i, transfer) in ref(gm, n, :dispatchable_transfer)
            JuMP.@variable(gm.model, var(gm, n, :transfer_injection, i) >= -var(gm, n, :transfer_effective, i))
            JuMP.@variable(gm.model, var(gm, n, :transfer_withdrawal, i) >= var(gm, n, :transfer_effective, i))
        end 

        # mass balance constraints for slack junctions 
        con(gm, n)[:slack_junctions_mass_balance] = JuMP.@constraint(gm.model, [i in keys(ref(gm, n, :slack_junctions))], 
            var(gm, n, :total_injection, i) == var(gm, n, :total_edge_out_flow, i)
        )

        # mass balance constraints for non-slack junctions 
        con(gm, n)[:non_slack_junctions_mass_balance] = JuMP.@constraint(gm.model, [i in ref(gm, n, :non_slack_junction_ids)],
            var(gm, n, :non_slack_derivative, i) + 4 * (var(gm, n, :total_edge_out_flow, i) - var(gm, n, :total_injection, i)) 
            == 0.0 
        )
        
    end 

    # objective (load shed objective added for now)
    m = (gm.ref[:specific_heat_capacity_ratio] - 1) / gm.ref[:specific_heat_capacity_ratio] 
    W = 286.76 * gm.ref[:temperature] / gm.ref[:gas_specific_gravity] / m
    econ_weight = gm.ref[:economic_weighting]
    load_shed_expression = 0
    compressor_power_expressions = []
    for n in time_points
        for (i, receipt) in ref(gm, n, :dispatchable_receipt)
            load_shed_expression += receipt["offer_price"] * var(gm, n, :injection, i)
        end 
        for (i, delivery) in ref(gm, n, :dispatchable_delivery)
            load_shed_expression -= delivery["bid_price"] * var(gm, n, :withdrawal, i)
        end 
        for (i, transfer) in ref(gm, n, :dispatchable_transfer)
            load_shed_expression += (transfer["offer_price"] * var(gm, n, :transfer_injection, i) - 
                transfer["bid_price"] * var(gm, n, :transfer_withdrawal, i)
            )
        end 
        for (i, compressor) in ref(gm, n, :compressor)
            alpha = var(gm, n, :compressor_ratio, i)
            f = var(gm, n, :compressor_flow, i)
            push!(compressor_power_expressions, W * f * (alpha^m - 1))
        end 
    end 
    @NLobjective(gm.model, Min, econ_weight * load_shed_expression + (1-econ_weight) * sum(compressor_power_expressions))

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

