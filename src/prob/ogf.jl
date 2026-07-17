# Definitions for running an optimal gas flow (ogf)

"entry point into running the ogf problem"
function solve_ogf(file, model_type::DataType, optimizer; kwargs...)
    solution_processors = [
        sol_psqr_to_p!,
        sol_compressor_p_to_r!,
        sol_regulator_p_to_r!,
    ]

    return run_model(
        file,
        model_type,
        optimizer,
        build_ogf;
        solution_processors = solution_processors,
        kwargs...,
    )
end


"Helper function to run a version of the OGF problem which uses nominal values as bounds on gas consumption and production rather than
the physical engineering bounds on consumption and production. This allows the seperatation of engineering limits from a specific proposed
usage scenario"
function solve_ogf_nominal(file, model_type::DataType, optimizer; kwargs...)
    solution_processors = [
        sol_psqr_to_p!,
        sol_compressor_p_to_r!,
        sol_regulator_p_to_r!,
    ]

    return run_model(
        file,
        model_type,
        optimizer,
        build_ogf;
        ref_extensions = [ref_nominal_flow_as_capacity!],
        solution_processors = solution_processors,
        kwargs...,
    )
end

""
function solve_soc_ogf(file, optimizer; kwargs...)
    return solve_ogf(file, CRDWPGasModel, optimizer; kwargs...)
end


""
function solve_dwp_ogf(file, optimizer; kwargs...)
    return solve_ogf(file, DWPGasModel, optimizer; kwargs...)
end

"construct the ogf problem for specific networks in ref"
function build_ogf(gm::AbstractGasModel)
    nws = haskey(gm.setting, "config") ? get(gm.setting["config"], "networks", [nw_id_default]) : [nw_id_default]

    for nw in nws
        bounded_compressors = Dict(
            x for x in ref(gm, :compressor; nw=nw) if
            _calc_is_compressor_energy_bounded(
                get_specific_heat_capacity_ratio(gm.data),
                get_gas_specific_gravity(gm.data),
                get_temperature(gm.data),
                x.second
            )
        )

        variable_pressure(gm, nw)
        variable_pressure_sqr(gm, nw)
        variable_flow(gm, nw)
        variable_on_off_operation(gm, nw)
        variable_load_mass_flow(gm, nw)
        variable_production_mass_flow(gm, nw)
        variable_transfer_mass_flow(gm, nw)
        variable_compressor_ratio_sqr(gm, nw)
        variable_storage(gm, nw)
        variable_form_specific(gm, nw)

        for (i, junction) in ref(gm, :junction; nw=nw)
            constraint_mass_flow_balance(gm, i; n=nw)

            if (junction["junction_type"] == 1)
                constraint_pressure(gm, i; n=nw)
            end
        end

        for i in ids(gm, :pipe; nw=nw)
            constraint_pipe_pressure(gm, i; n=nw)
            constraint_pipe_mass_flow(gm, i; n=nw)
            constraint_pipe_weymouth(gm, i; n=nw)
        end

        for i in ids(gm, :resistor; nw=nw)
            constraint_resistor_pressure(gm, i; n=nw)
            constraint_resistor_mass_flow(gm,i; n=nw)
            constraint_resistor_darcy_weisbach(gm,i; n=nw)
        end

        for i in ids(gm, :loss_resistor; nw=nw)
            constraint_loss_resistor_pressure(gm, i; n=nw)
            constraint_loss_resistor_mass_flow(gm, i; n=nw)
        end

        for i in ids(gm, :short_pipe; nw=nw)
            constraint_short_pipe_pressure(gm, i; n=nw)
            constraint_short_pipe_mass_flow(gm, i; n=nw)
        end

        for i in ids(gm, :compressor; nw=nw)
            constraint_compressor_ratios(gm, i; n=nw)
            constraint_compressor_mass_flow(gm, i; n=nw)
            constraint_compressor_ratio_value(gm, i; n=nw)
        end

        for i in keys(bounded_compressors)
            constraint_compressor_energy(gm, i; n=nw)
        end

        for i in ids(gm, :valve; nw=nw)
            constraint_on_off_valve_mass_flow(gm, i; n=nw)
            constraint_on_off_valve_pressure(gm, i; n=nw)
        end

        for i in ids(gm, :regulator; nw=nw)
            constraint_on_off_regulator_mass_flow(gm, i; n=nw)
            constraint_on_off_regulator_pressure(gm, i; n=nw)
        end
    end

    objective_min_economic_costs(gm, nws)
end

