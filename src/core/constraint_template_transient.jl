"Template: fixing slack node density value"
function constraint_slack_junction_density(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    fixed_density = ref(gm, nw, :slack_junctions, i)["p_nominal"]
    constraint_slack_junction_density(gm, nw, i, fixed_density)
end

"Template: slack junction mass balance"
function constraint_slack_junction_mass_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw,
)
    net_injection = var(gm, nw, :net_nodal_injection)[i]
    net_edge_out_flow = var(gm, nw, :net_nodal_edge_out_flow)[i]
    constraint_slack_junction_mass_balance(gm, nw, i, net_injection, net_edge_out_flow)
end

"Template: non-slack junction mass balance"
function constraint_non_slack_junction_mass_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw,
)
    derivative = var(gm, nw, :non_slack_derivative)[i]
    net_injection = var(gm, nw, :net_nodal_injection)[i]
    net_edge_out_flow = var(gm, nw, :net_nodal_edge_out_flow)[i]
    constraint_non_slack_junction_mass_balance(
        gm,
        nw,
        i,
        derivative,
        net_injection,
        net_edge_out_flow,
    )
end

"Template: pipe physics with ideal gas assumption"
function constraint_pipe_physics_ideal(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    pipe = ref(gm, nw, :pipe, i)
    fr_junction = pipe["fr_junction"]
    to_junction = pipe["to_junction"]
    resistance =
        pipe["friction_factor"] * gm.ref[:base_length] * pipe["length"] / pipe["diameter"]
    constraint_pipe_physics_ideal(gm, nw, i, fr_junction, to_junction, resistance)
end

"Template: compressor physics"
function constraint_compressor_physics(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    compressor = ref(gm, nw, :compressor, i)
    fr_junction = compressor["fr_junction"]
    to_junction = compressor["to_junction"]
    constraint_compressor_physics(gm, nw, i, fr_junction, to_junction)
end

"Template: compressor power"
function constraint_compressor_power(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    compressor_power = var(gm, nw, :compressor_power)[i]
    power_max = ref(gm, nw, :compressor, i)["power_max"]
    constraint_compressor_power(gm, nw, i, compressor_power, power_max)
end
