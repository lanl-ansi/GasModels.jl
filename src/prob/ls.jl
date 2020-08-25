# Definitions for running a minimum load shed model

"entry point into running the gas flow feasability problem"
function run_ls(file, model_type, optimizer; kwargs...)
    return run_model(
        file,
        model_type,
        optimizer,
        build_ls;
        solution_processors = [
            sol_psqr_to_p!,
            sol_compressor_p_to_r!,
            sol_regulator_p_to_r!,
        ],
        kwargs...,
    )
end


"construct the gas flow feasbility problem"
function build_ls(gm::AbstractGasModel)
    bounded_compressors = Dict(
        x
        for
        x in ref(gm, :compressor) if
        _calc_is_compressor_energy_bounded(
            gm.data["specific_heat_capacity_ratio"],
            gm.data["gas_specific_gravity"],
            gm.data["temperature"],
            x.second,
        )
    )

    variable_pressure(gm)
    variable_flow(gm)
    variable_pressure_sqr(gm)
    variable_on_off_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)
    variable_compressor_ratio_sqr(gm; compressors = bounded_compressors)

    objective_max_load(gm)

    for i in ids(gm, :pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm, i)
        constraint_pipe_weymouth(gm, i)
    end

    for i in ids(gm, :resistor)
        constraint_resistor_pressure(gm, i)
        constraint_resistor_mass_flow(gm, i)
        constraint_resistor_weymouth(gm, i)
    end

    for i in ids(gm, :loss_resistor)
        constraint_loss_resistor_pressure(gm, i)
        constraint_loss_resistor_mass_flow(gm, i)
    end

    for (i, junction) in ref(gm, :junction)
        constraint_mass_flow_balance(gm, i)

        if (junction["junction_type"] == 1)
            constraint_pressure(gm, i)
        end
    end

    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_ratios(gm, i)
        constraint_compressor_mass_flow(gm, i)
    end

    for i in keys(bounded_compressors)
        constraint_compressor_ratio_value(gm, i)
        constraint_compressor_energy(gm, i)
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
