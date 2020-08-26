"Constraint: fixing slack node density value"
function constraint_slack_junction_density(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    fixed_density::Float64,
)
    rho = var(gm, nw, :density, slack_junction_id)
    _add_constraint!(
        gm,
        nw,
        :slack_junction_density,
        slack_junction_id,
        JuMP.@constraint(gm.model, rho == fixed_density)
    )
end

"Constraint: slack junction mass balance"
function constraint_slack_junction_mass_balance(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    net_injection,
    net_edge_out_flow,
)
    _add_constraint!(
        gm,
        nw,
        :slack_junction_mass_balance,
        slack_junction_id,
        JuMP.@constraint(gm.model, net_injection == net_edge_out_flow)
    )
end

"Constraint: non-slack junction mass balance"
function constraint_non_slack_junction_mass_balance(
    gm::AbstractGasModel,
    nw::Int,
    slack_junction_id::Int,
    derivative,
    net_injection,
    net_edge_out_flow,
)
    _add_constraint!(
        gm,
        nw,
        :non_slack_junction_mass_balance,
        slack_junction_id,
        JuMP.@constraint(
            gm.model,
            derivative + 4.0 * (net_edge_out_flow - net_injection) == 0
        )
    )
end

"Constraint: pipe physics with an ideal gas assumption"
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
    _add_constraint!(
        gm,
        nw,
        :pipe_physics_ideal,
        pipe_id,
        JuMP.@NLconstraint(gm.model, p_fr^2 - p_to^2 - resistance * f * abs(f) == 0)
    )
end

"Constraint: aggregate withdrawal at transfer points computation"
function constraint_transfer_separation(
    gm::AbstractGasModel,
    transfer_id::Int,
    nw::Int = gm.cnw,
)
    s = var(gm, nw, :transfer_injection)[transfer_id]
    d = var(gm, nw, :transfer_withdrawal)[transfer_id]
    t = var(gm, nw, :transfer_effective)[transfer_id]

    _add_constraint!(
        gm,
        nw,
        :effective_transfer_withdrawal,
        transfer_id,
        JuMP.@constraint(gm.model, t == d - s)
    )
end

"Constraint: compressor physics"
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
    _add_constraint!(
        gm,
        nw,
        :compressor_physics_boost,
        compressor_id,
        JuMP.@constraint(gm.model, p_to == alpha * p_fr)
    )
    _add_constraint!(
        gm,
        nw,
        :compressor_physics_flow,
        compressor_id,
        JuMP.@constraint(gm.model, f * (p_fr - p_to) <= 0)
    )
end

"Constraint: compressor power"
function constraint_compressor_power(
    gm::AbstractGasModel,
    nw::Int,
    compressor_id::Int,
    compressor_power,
    power_max::Float64,
)
    _add_constraint!(
        gm,
        nw,
        :compressor_power,
        compressor_id,
        JuMP.@NLconstraint(gm.model, compressor_power <= power_max)
    )
end

"Constraint: storage effective flow" 
function constraint_storage_well_head_to_eff_flow(gm::AbstractGasModel, storage_id::Int, nw::Int = gm.cnw)
    f_eff = var(gm, nw, :storage_effective, storage_id)
    f_wh = var(gm, nw, :well_head, storage_id)
    _add_constraint!(
        gm, 
        nw, 
        :storage_effective_flow_balance,
        storage_id,
        JuMP.@constraint(gm.model, f_eff == f_wh)
    )
end 

"Constraint: well compression/pressure-reduction"
function constraint_storage_compressor_regulator(
    gm::AbstractGasModel,
    nw::Int,
    storage_id::Int,
    junction_id::Int,
)
    rho_junction = var(gm, nw, :density, junction_id)
    rho_well_head = var(gm, nw, :well_density, storage_id)[1]
    alpha = var(gm, nw, :storage_compressor_ratio, storage_id)
    GasModels._add_constraint!(
    gm,
    nw,
    :well_compressor_regulator,
    storage_id,
    JuMP.@constraint(gm.model, rho_junction == alpha * rho_well_head)
    )
end

"Constraint: well momentum balance"
function constraint_storage_well_momentum_balance(
    gm::AbstractGasModel, 
    nw::Int, 
    num_discretizations::Int, 
    storage_id::Int, 
    beta::Float64, 
    resistance::Float64, 
)
    for i in 1:num_discretizations
        rho_top = var(gm, nw, :well_density, storage_id)[i]
        rho_bottom = var(gm, nw, :well_density, storage_id)[i+1]
        phi_avg = var(gm, nw, :well_flux_avg, storage_id)[i]
        GasModels._add_constraint!(
            gm, 
            nw, 
            :well_ideal_momentum_balance,
            storage_id * 1000 + i,
            JuMP.@NLconstraint(gm.model, exp(beta) * rho_top^2 - rho_bottom^2 == (-resistance * phi_avg * abs(phi_avg)) * (exp(beta) - 1) / beta)
        )
    end 
end

"Constraint: well mass balance"
function constraint_storage_well_mass_balance(
    gm::AbstractGasModel, 
    nw::Int, 
    num_discretizations::Int, 
    storage_id::Int, 
    length::Float64 
)
    for i in 1:num_discretizations
        rho_dot_top = var(gm, nw, :well_density_derivative, storage_id)[i]
        rho_dot_bottom = var(gm, nw, :well_density_derivative, storage_id)[i+1]
        phi_neg = var(gm, nw, :well_flux_neg, storage_id)[i]
        GasModels._add_constraint!(
            gm, 
            nw, 
            :well_ideal_mass_balance, 
            storage_id * 1000 + i, 
            JuMP.@constraint(gm.model, length * (rho_dot_top + rho_dot_bottom) = -4 * phi_neg)
        )
    end 
end

"Constraint: storage well nodal balance"
function constraint_storage_well_nodal_balance(gm::AbstractGasModel, storage_id::Int, nw::Int = gm.cnw; 
    num_discretizations::Int = 4)
    
    for i in 1:(num_discretizations-1)
        phi_top_well_avg = var(gm, nw, :well_flux_avg, storage_id)[i]
        phi_top_well_neg = var(gm, nw, :well_flux_neg, storage_id)[i]
        phi_bottom_well_avg = var(gm, nw, :well_flux_avg, storage_id)[i+1]
        phi_bottom_well_neg = var(gm, nw, :well_flux_neg, storage_id)[i+1]

        GasModels._add_constraint!(
            gm,
            nw,
            :well_nodal_balance,
            storage_id* 1000 + i,
            JuMP.@constraint(gm.model, phi_top_well_avg - phi_top_well_neg == phi_bottom_well_avg + phi_bottom_well_neg)
            )

    end
end 