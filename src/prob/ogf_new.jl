# Definitions for running the new optimal gas flow (ogf) (with a proxy compressor power term in the objective)

"entry point into running the new ogf problem"
function run_nw_ogf(file, model_type, optimizer; kwargs...)
    return run_model(
        file,
        model_type,
        optimizer,
        build_new_ogf;
        solution_processors = [
            sol_psqr_to_p!,
            sol_compressor_p_to_r!,
            sol_regulator_p_to_r!,
        ],
        kwargs...,
    )
end


""
function run_soc_new_ogf(file, optimizer; kwargs...)
    return run_new_ogf(file, CRDWPGasModel, optimizer; kwargs...)
end


""
function run_dwp_new_ogf(file, optimizer; kwargs...)
    return run_new_ogf(file, DWPGasModel, optimizer; kwargs...)
end


"construct the new ogf problem"
function build_new_ogf(gm::AbstractGasModel)
    bounded_compressors = Dict(
        x for x in ref(gm, :compressor) if
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
    variable_on_off_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
    variable_transfer_mass_flow(gm)
    variable_compressor_ratio_sqr(gm)
    variable_storage(gm)
    variable_form_specific(gm)

    objective_min_new_economic_costs(gm)

    for (i, junction) in ref(gm, :junction)
        constraint_mass_flow_balance(gm, i)

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

    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_ratios(gm, i)
        constraint_compressor_mass_flow(gm, i)
        constraint_compressor_ratio_value(gm, i)
    end

    for i in keys(bounded_compressors)
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
