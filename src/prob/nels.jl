# Definitions for running a pipe expansion problem to maximize load

"entry point into running the gas flow expansion planning with load shedding"
function solve_nels(file, model_type, optimizer; kwargs...)
    return run_model(
        file,
        model_type,
        optimizer,
        build_nels;
        ref_extensions = [ref_add_ne!],
        solution_processors = [
            sol_psqr_to_p!,
            sol_compressor_p_to_r!,
            sol_regulator_p_to_r!,
            sol_ne_compressor_p_to_r!,
        ],
        kwargs...,
    )
end


"construct the gas flow expansion problem to maximize load"
function build_nels(gm::AbstractGasModel)
    nws = haskey(gm.setting, "config") ? get(gm.setting["config"], "networks", [nw_id_default]) : [nw_id_default]

    for nw in nws
        bounded_compressors = Dict(
            x for x in ref(gm, :compressor, nw=nw) if
            _calc_is_compressor_energy_bounded(
                get_specific_heat_capacity_ratio(gm.data),
                get_gas_specific_gravity(gm.data),
                get_temperature(gm.data),
                x.second
         )
        )

        bounded_compressors_ne = Dict(
            x for x in ref(gm, :ne_compressor, nw=nw) if
            _calc_is_compressor_energy_bounded(
                get_specific_heat_capacity_ratio(gm.data),
                get_gas_specific_gravity(gm.data),
                get_temperature(gm.data),
                x.second
         )
     )

        variable_flow(gm, nw)
        variable_pressure(gm, nw)
        variable_pressure_sqr(gm, nw)
        variable_on_off_operation(gm, nw)
        variable_load_mass_flow(gm, nw)
        variable_production_mass_flow(gm, nw)
        variable_transfer_mass_flow(gm, nw)
        variable_compressor_ratio_sqr(gm, nw; compressors = bounded_compressors)
        variable_compressor_ratio_sqr_ne(gm, nw; compressors = bounded_compressors_ne)
        variable_storage(gm, nw)
        variable_form_specific(gm, nw)

        # expansion variables
        variable_pipe_ne(gm, nw)
        variable_compressor_ne(gm, nw)
        variable_flow_ne(gm, nw)
            
        for (i, junction) in ref(gm, :junction; nw=nw)
            constraint_mass_flow_balance_ne(gm, i; n=nw)

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
            constraint_resistor_mass_flow(gm, i; n=nw)
            constraint_resistor_darcy_weisbach(gm, i; n=nw)
        end

        for i in ids(gm, :loss_resistor; nw=nw)
            constraint_loss_resistor_pressure(gm, i; n=nw)
            constraint_loss_resistor_mass_flow(gm, i; n=nw)
        end

        for i in ids(gm, :ne_pipe; nw=nw)
            constraint_pipe_pressure_ne(gm, i; n=nw)
            constraint_pipe_ne(gm, i; n=nw)
            constraint_pipe_mass_flow_ne(gm, i; n=nw)
            constraint_pipe_weymouth_ne(gm, i; n=nw)
        end

        for i in ids(gm, :short_pipe; nw=nw)
            constraint_short_pipe_pressure(gm, i; n=nw)
            constraint_short_pipe_mass_flow(gm, i; n=nw)
        end

        for i in ids(gm, :compressor; nw=nw)
            constraint_compressor_ratios(gm, i; n=nw)
            constraint_compressor_mass_flow(gm, i; n=nw)
        end

        for i in keys(bounded_compressors)
            constraint_compressor_ratio_value(gm, i; n=nw)
            constraint_compressor_energy(gm, i; n=nw)
        end

        for i in ids(gm, :ne_compressor; nw=nw)
            constraint_compressor_ratios_ne(gm, i; n=nw)
            constraint_compressor_ne(gm, i; n=nw)
            constraint_compressor_mass_flow_ne(gm, i; n=nw)
        end

        for i in keys(bounded_compressors_ne)
            constraint_compressor_ratio_value_ne(gm, i; n=nw)
            constraint_compressor_energy_ne(gm, i; n=nw)
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

    # expansion cost objective
    objective_max_load(gm, nws)
end
