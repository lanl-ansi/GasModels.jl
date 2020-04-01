"fixing slack node density value"
function constraint_slack_junction_density(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    fixed_density::Float64,
)
    rho = var(gm, nw, :density, slack_junction_id)
    con(gm, nw, :slack_junction_density)[slack_junction_id] =
        JuMP.@constraint(gm.model, rho == fixed_density)
end

"slack junction mass balance"
function constraint_slack_junction_mass_balance(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    net_injection,
    net_edge_out_flow,
)
    con(gm, nw, :slack_junction_mass_balance)[slack_junction_id] =
        JuMP.@constraint(gm.model, net_injection == net_edge_out_flow)
end

"non-slack junction mass balance"
function constraint_slack_junction_mass_balance(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    derivative,
    net_injection,
    net_edge_out_flow,
)
    con(gm, nw, :non_slack_junction_mass_balance)[slack_junction_id] = JuMP.@constraint(
        gm.model,
        derivative + 4.0 * (net_edge_out_flow - net_injection) == 0
    )
end

"pipe physics ideal gas assumption"
function constraint_pipe_physics_ideal(
    gm::AbstractGasModel,
    nw::Int,
    pipe_id::Int,
    fr_junction::Int,
    to_junction::Int,
    resistance::Float64,
)
    p_fr = var(gm, nw, :density, fr_junction)
    p_to = var(gm, nw, :density, to_junction)
    f = var(gm, nw, :pipe_flux, i)
    con(gm, nw, :pipe_physics_ideal)[pipe_id] =
        JuMP.@NLconstraint(gm.model, p_fr^2 - p_to^2 - resistance * f * abs(f) == 0)
end
