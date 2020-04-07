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
        prev = n - 1
        (n == start_t) && (prev = time_points[end-1])
        expression_density_derivative(gm, n, prev)
        expression_net_nodal_injection(gm, n)
        expression_net_nodal_edge_out_flow(gm, n)
        expression_non_slack_affine_derivative(gm, n)
        expression_compressor_power(gm, n)
    end

    for n in time_points[1:end-1]
        for i in ids(gm, n, :slack_junctions)
            constraint_slack_junction_density(gm, i, n)
            constraint_slack_junction_mass_balance(gm, i, n)
        end

        for i in ref(gm, n, :non_slack_junction_ids)
            constraint_non_slack_junction_mass_balance(gm, i, n)
        end

        for i in ids(gm, n, :pipe)
            constraint_pipe_physics_ideal(gm, i, n)
        end

        for i in ids(gm, n, :compressor)
            constraint_compressor_physics(gm, i, n)
            constraint_compressor_power(gm, i, n)
        end

        for i in ids(gm, n, :dispatchable_transfer)
            constraint_transfer_separation(gm, i, n)
        end
    end

    econ_weight = gm.ref[:economic_weighting]
    if econ_weight == 1.0
        objective_min_transient_load_shed(gm, time_points)
    elseif econ_weight == 0.0 
        objective_min_transient_compressor_power(gm, time_points)
    else 
        objective_min_transient_economic_costs(gm, time_points)
    end
end

