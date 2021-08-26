# Definitions for running a pipe expansion problem

"entry point into running the gas flow feasability problem"
function run_ne(file, model_type, optimizer; kwargs...)
    return run_model(
        file,
        model_type,
        optimizer,
        build_ne;
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


"construct the gas flow feasbility problem"
function build_ne(gm::AbstractGasModel)
    bounded_compressors = Dict(
        x for x in ref(gm, :compressor) if
        _calc_is_compressor_energy_bounded(
            get_specific_heat_capacity_ratio(gm.data),
            get_gas_specific_gravity(gm.data),
            get_temperature(gm.data),
            x.second
        )
    )

    bounded_compressors_ne = Dict(
        x for x in ref(gm, :ne_compressor) if
        _calc_is_compressor_energy_bounded(
            get_specific_heat_capacity_ratio(gm.data),
            get_gas_specific_gravity(gm.data),
            get_temperature(gm.data),
            x.second
        )
    )

    variable_pressure(gm)
    variable_pressure_sqr(gm)
    variable_flow(gm)
    variable_flow_ne(gm)
    variable_on_off_operation(gm)
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)
    variable_compressor_ratio_sqr(gm; compressors = bounded_compressors)
    variable_compressor_ratio_sqr_ne(gm; compressors = bounded_compressors_ne)
    variable_storage(gm)

    # expansion cost objective
    objective_min_ne_cost(gm)

    for (i, junction) in ref(gm, :junction)
        constraint_mass_flow_balance_ne(gm, i)
        if (junction["junction_type"] == 1)
            constraint_pressure(gm, i)
        end
    end

    for i in ids(gm, :pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm, i)
        constraint_pipe_weymouth(gm, i)
    end

    for i in ids(gm, :resistor)
        constraint_resistor_pressure(gm, i)
        constraint_resistor_mass_flow(gm,i)
        constraint_resistor_darcy_weisbach(gm,i)
    end

    for i in ids(gm, :loss_resistor)
        constraint_loss_resistor_pressure(gm, i)
        constraint_loss_resistor_mass_flow(gm, i)
    end

    for i in ids(gm, :ne_pipe)
        constraint_pipe_pressure_ne(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_pipe_weymouth_ne(gm, i)
        constraint_pipe_mass_flow_ne(gm, i)
    end

    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_mass_flow(gm, i)
        constraint_compressor_ratios(gm, i)
    end

    for i in keys(bounded_compressors)
        constraint_compressor_ratio_value(gm, i)
        constraint_compressor_energy(gm, i)
    end

    for i in ids(gm, :ne_compressor)
        constraint_compressor_ratios_ne(gm, i)
        constraint_compressor_ne(gm, i)
        constraint_compressor_mass_flow_ne(gm, i)
    end

    for i in keys(bounded_compressors_ne)
        constraint_compressor_ratio_value_ne(gm, i)
        constraint_compressor_energy_ne(gm, i)
    end

    for i in ids(gm, :valve)
        constraint_on_off_valve_mass_flow(gm, i)
        constraint_on_off_valve_pressure(gm, i)
    end

    for i in ids(gm, :regulator)
        constraint_on_off_regulator_mass_flow(gm, i)
        constraint_on_off_regulator_pressure(gm, i)
    end

end
