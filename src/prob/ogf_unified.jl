# Definitions for running an optimal gas flow (ogf)

"entry point into running the ogf problem"
function solve_ogf_unified(file, model_type, optimizer; kwargs...)

    return run_model(
        file,
        model_type,
        optimizer,
        build_ogf;
        kwargs...,
    )
end


"construct the ogf problem"
function build_ogf_unified(gm::AbstractGasModel)

    variable_potential(gm) 
    variable_flow_unified(gm)
    variable_receipt(gm) 
    variable_delivery(gm)
    variable_transfer(gm)
    variable_storage_unified(gm)

    objective_min_economic_costs(gm)

    for (i, junction) in ref(gm, :junction)
        constraint_junction_flow_balance(gm, i)

        if (junction["junction_type"] == 1)
            constraint_slack_potential(gm, i)
        end
    end

    for i in ids(gm, :pipe)
        constraint_pipe_physics(gm, i)
    end

    for i in ids(gm, :compressor)
        constraint_compressor_physics(gm, i)
        constraint_compressor_power(gm, i)
    end
end