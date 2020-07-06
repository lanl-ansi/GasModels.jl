# Definitions for running a pipe expansion problem

"entry point into running the gas flow feasability problem"
function run_ne(file, model_type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, build_ne; ref_extensions=[ref_add_ne!], solution_processors=[sol_psqr_to_p!, sol_compressor_p_to_r!, sol_regulator_p_to_r!, sol_ne_compressor_p_to_r!], kwargs...)
end


"construct the gas flow feasbility problem"
function build_ne(gm::AbstractGasModel)
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

    # expansion cost objective
    objective_min_ne_cost(gm)

    for i in ids(gm, :junction)
        constraint_mass_flow_balance_ne(gm, i)
    end

    for i in ids(gm,:pipe)
        constraint_pipe_pressure(gm, i)
        constraint_pipe_mass_flow(gm,i)
        constraint_pipe_weymouth(gm,i)
    end

    for i in ids(gm,:resistor)
        constraint_resistor_pressure(gm, i)
        constraint_resistor_mass_flow(gm,i)
        constraint_resistor_weymouth(gm,i)
    end

    for i in ids(gm, :loss_resistor)
        constraint_loss_resistor_pressure(gm, i)
        constraint_loss_resistor_mass_flow(gm, i)
    end

    for i in ids(gm,:ne_pipe)
        constraint_pipe_pressure_ne(gm, i)
        constraint_pipe_ne(gm, i)
        constraint_pipe_weymouth_ne(gm, i)
        constraint_pipe_mass_flow_ne(gm,i)
    end

    for i in ids(gm, :short_pipe)
        constraint_short_pipe_pressure(gm, i)
        constraint_short_pipe_mass_flow(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_mass_flow(gm, i)
        constraint_compressor_ratios(gm, i)
    end

    for i in ids(gm, :ne_compressor)
        constraint_compressor_ratios_ne(gm, i)
        constraint_compressor_ne(gm, i)
        constraint_compressor_mass_flow_ne(gm, i)
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
