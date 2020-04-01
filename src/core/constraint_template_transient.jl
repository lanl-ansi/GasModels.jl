"fixing slack node density value"
function constraint_slack_junction_density(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    if !haskey(gm.con[:nw][nw], :slack_junction_density)
        con(gm, nw)[:slack_junction_density] = Dict{Int,JuMP.ConstraintRef}()
    end
    fixed_density = ref(gm, nw, :slack_junctions, i)["p_nominal"]
    constraint_slack_junction_density(gm, nw, i, fixed_density)
end

"slack junction mass balance"
function constraint_slack_junction_mass_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw,
)
    if !haskey(gm.con[:nw][nw], :slack_junction_mass_balance)
        con(gm, nw)[:slack_junction_mass_balance] = Dict{Int,JuMP.ConstraintRef}()
    end
    net_injection = var(gm, nw, :net_nodal_injection)[i]
    net_edge_out_flow = var(gm, nw, :net_nodal_edge_out_flow)[i]
    constraint_slack_junction_mass_balance(gm, nw, i, net_injection, net_edge_out_flow)
end

"non-slack junction mass balance"
function constraint_non_slack_junction_mass_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw,
)
    if !haskey(gm.con[:nw][nw], :non_slack_junction_mass_balance)
        con(gm, nw)[:non_slack_junction_mass_balance] = Dict{Int,JuMP.ConstraintRef}()
    end
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

"pipe physics"
function constraint_pipe_physics_ideal(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    if !haskey(gm.con[:nw][nw], :pipe_physics_ideal)
        con(gm, nw)[:pipe_physics_ideal] = Dict{Int,JuMP.ConstraintRef}()
    end
    pipe = ref(gm, nw, :pipe, i)
    fr_junction = pipe["fr_junction"]
    to_junction = pipe["to_junction"]
    resistance =
        pipe["friction_factor"] * gm.ref[:base_length] * pipe["length"] / pipe["diameter"]
    constraint_pipe_physics_ideal(gm, nw, i, fr_junction, to_junction, resistance)
end
