"fixing slack node density value"
function constraint_slack_junction_density(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    fixed_density::Float64,
)
    rho = var(gm, nw, :density, slack_junction_id)
    _add_constraint!(gm, nw, :slack_junction_density, slack_junction_id,
        JuMP.@constraint(gm.model, rho == fixed_density)
    )
end

"slack junction mass balance"
function constraint_slack_junction_mass_balance(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    net_injection,
    net_edge_out_flow,
)
    _add_constraint!(gm, nw, :slack_junction_mass_balance, slack_junction_id,
        JuMP.@constraint(gm.model, net_injection == net_edge_out_flow)
    )
end

"non-slack junction mass balance"
function constraint_non_slack_junction_mass_balance(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    derivative,
    net_injection,
    net_edge_out_flow,
)
    _add_constraint!(gm, nw, :non_slack_junction_mass_balance, slack_junction_id,
    JuMP.@constraint(
        gm.model,
        derivative + 4.0 * (net_edge_out_flow - net_injection) == 0
    ))
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
    f = var(gm, nw, :pipe_flux, pipe_id)
    _add_constraint!(gm, nw, :pipe_physics_ideal, pipe_id,
        JuMP.@NLconstraint(gm.model, p_fr^2 - p_to^2 - resistance * f * abs(f) == 0)
    )
end

"constraint transfer"
function constraint_transfer_separation(
    gm::AbstractGasModel,
    transfer_id::Int,
    nw::Int = gm.cnw,
)
    s = var(gm, nw, :transfer_injection)[transfer_id]
    d = var(gm, nw, :transfer_withdrawal)[transfer_id]
    t = var(gm, nw, :transfer_effective)[transfer_id]

    _add_constraint!(gm, nw, :effective_transfer_withdrawal, transfer_id,
        JuMP.@constraint(gm.model, t == d - s)
    )
end

"compressor physics"
function constraint_compressor_physics(
    gm::AbstractGasModel,
    nw::Int,
    compressor_id::Int,
    fr_junction::Int,
    to_junction::Int,
)
    p_fr = var(gm, nw, :density, fr_junction)
    p_to = var(gm, nw, :density, to_junction)
    alpha = var(gm, nw, :compressor_ratio, compressor_id)
    f = var(gm, nw, :compressor_flow, compressor_id)
    _add_constraint!(gm, nw, :compressor_physics_boost, compressor_id,
        JuMP.@constraint(gm.model, p_to == alpha * p_fr)
    )
    _add_constraint!(gm, nw, :compressor_physics_flow, compressor_id, 
        JuMP.@constraint(gm.model, f * (p_fr - p_to) <= 0)
    )
end

"compressor power"
function constraint_compressor_power(
    gm::AbstractGasModel,
    nw::Int,
    compressor_id::Int,
    compressor_power,
    power_max::Float64,
)
    _add_constraint!(gm, nw, :compressor_power, compressor_id,
        JuMP.@NLconstraint(gm.model, compressor_power <= power_max)
    )
end
