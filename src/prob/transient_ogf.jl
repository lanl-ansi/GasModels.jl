"entry point for the transient optimal gas flow model"
function run_transient_ogf(data, model_type, optimizer; kwargs...)
    data_it = _IM.ismultiinfrastructure(data) ? data["it"]["ng"] : data
    @assert _IM.ismultinetwork(data_it) == true

    return run_model(
        data,
        model_type,
        optimizer,
        build_transient_ogf;
        ref_extensions = [ref_add_transient!],
        kwargs...,
    )
end

"Builds the transient optimal gas flow Nonlinear problem"
function build_transient_ogf(gm::AbstractGasModel)
    time_points = sort(collect(nw_ids(gm)))
    start_t = time_points[1]
    end_t = time_points[end]
    num_well_discretizations = 4

    # variables for first n-1 time points
    for n in time_points[1:end]
        if n != end_t
            # nodal density variables
            variable_density(gm, n)

            # compressor variables
            variable_compressor_flow(gm, n)
            variable_c_ratio(gm, n)
            variable_compressor_power(gm, n)

            # pipe variables
            variable_pipe_flux_avg(gm, n)
            variable_pipe_flux_neg(gm, n)
            variable_pipe_flux_fr(gm, n)
            variable_pipe_flux_to(gm, n)

            # injection withdrawal variables
            variable_injection(gm, n)
            variable_withdrawal(gm, n)
            variable_transfer_flow(gm, n)
        end

        # storage variables
        variable_storage_flow(gm, n)
        variable_storage_c_ratio(gm, n)
        variable_reservoir_density(gm, n)
        variable_well_density(gm, n, num_discretizations = num_well_discretizations)
        variable_well_flux_avg(gm, n, num_discretizations = num_well_discretizations)
        variable_well_flux_neg(gm, n, num_discretizations = num_well_discretizations)
        variable_well_flux_fr(gm, n, num_discretizations = num_well_discretizations)
        variable_well_flux_to(gm, n, num_discretizations = num_well_discretizations)

        if n != end_t
            expression_net_nodal_injection(gm, n)
            expression_net_nodal_edge_out_flow(gm, n)
        end
    end

    for n in time_points[1:end-1]
        prev = n - 1
        (n == start_t) && (prev = time_points[end-1])
        expression_density_derivative(gm, n, prev)
        expression_compressor_power(gm, n)
    end

    # enforcing time-periodicity without adding additional variables
    var(gm, end_t)[:density] = var(gm, start_t, :density)
    var(gm, end_t)[:compressor_flow] = var(gm, start_t, :compressor_flow)
    var(gm, end_t)[:pipe_flux_avg] = var(gm, start_t, :pipe_flux_avg)
    var(gm, end_t)[:pipe_flux_neg] = var(gm, start_t, :pipe_flux_neg)
    var(gm, end_t)[:pipe_flux_fr] = var(gm, start_t, :pipe_flux_fr)
    var(gm, end_t)[:pipe_flux_to] = var(gm, start_t, :pipe_flux_to)
    var(gm, end_t)[:pipe_flow_avg] = var(gm, start_t, :pipe_flow_avg)
    var(gm, end_t)[:pipe_flow_neg] = var(gm, start_t, :pipe_flow_neg)
    var(gm, end_t)[:pipe_flow_fr] = var(gm, start_t, :pipe_flow_fr)
    var(gm, end_t)[:pipe_flow_to] = var(gm, start_t, :pipe_flow_to)
    var(gm, end_t)[:compressor_ratio] = var(gm, start_t, :compressor_ratio)
    var(gm, end_t)[:compressor_power_var] = var(gm, start_t, :compressor_power_var)
    var(gm, end_t)[:injection] = var(gm, start_t, :injection)
    var(gm, end_t)[:withdrawal] = var(gm, start_t, :withdrawal)
    var(gm, end_t)[:transfer_effective] = var(gm, start_t, :transfer_effective)
    var(gm, end_t)[:transfer_injection] = var(gm, start_t, :transfer_injection)
    var(gm, end_t)[:transfer_withdrawal] = var(gm, start_t, :transfer_withdrawal)
    var(gm, end_t)[:net_nodal_injection] = var(gm, start_t, :net_nodal_injection)
    var(gm, end_t)[:net_nodal_edge_out_flow] = var(gm, start_t, :net_nodal_edge_out_flow)

    # derivative expressions for the storage 
    for n in time_points[1:end]
        (n == end_t) && (continue)
        next = n + 1
        expression_well_density_derivative(
            gm,
            n,
            next,
            num_discretizations = num_well_discretizations,
        )
        expression_reservoir_density_derivative(gm, n, next)
    end


    for i in ids(gm, start_t, :storage)
        constraint_initial_condition_reservoir(gm, i, start_t)
    end

    for n in time_points[1:end]
        if n != end_t
            for i in ids(gm, n, :slack_junctions)
                constraint_slack_junction_density(gm, i, n)
            end

            for i in ids(gm, n, :junction)
                constraint_nodal_balance(gm, i, n)
            end

            for i in ids(gm, n, :compressor)
                constraint_compressor_physics(gm, i, n)
                constraint_compressor_power(gm, i, n)
            end

            for i in ids(gm, n, :pipe)
                constraint_pipe_mass_balance(gm, i, n)
                constraint_pipe_momentum_balance(gm, i, n)
            end

        end

        for i in ids(gm, n, :storage)
            constraint_storage_compressor_regulator(gm, i, n)
            constraint_storage_well_momentum_balance(
                gm,
                i,
                n,
                num_discretizations = num_well_discretizations,
            )
            if n != end_t
                constraint_storage_well_mass_balance(
                    gm,
                    i,
                    n,
                    num_discretizations = num_well_discretizations,
                )
            end
            constraint_storage_well_nodal_balance(
                gm,
                i,
                n,
                num_discretizations = num_well_discretizations,
            )
            constraint_storage_bottom_hole_reservoir_density(
                gm,
                i,
                n,
                num_discretizations = num_well_discretizations,
            )
            if n != end_t
                constraint_storage_reservoir_physics(gm, i, n)
            end
        end
    end

    econ_weight = gm.ref[:it][:ng][:economic_weighting]

    if econ_weight == 1.0
        objective_min_transient_load_shed(gm, time_points)
    elseif econ_weight == 0.0
        objective_min_transient_compressor_power(gm, time_points)
    else
        objective_min_transient_economic_costs(gm, time_points)
    end
end
