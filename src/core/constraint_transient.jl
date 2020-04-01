function constraint_slack_node_density(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    fixed_density::Float64,
)
    rho = var(gm, nw, :density, slack_junction_id)
    con(gm, nw, :slack_density)[slack_junction_id] =
        JuMP.@constraint(gm.model, rho == fixed_density)
end
