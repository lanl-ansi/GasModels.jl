# *******************************************************
# Variables
# *******************************************************
"variables associated with storage flows"
function variable_storage_flow(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)

    f_s = var(gm, nw)[:storage_flow] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :storage)],
            base_name = "$(nw)_storage_flow"
        )
    f_bh = var(gm, nw)[:bottom_hole_flow] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :storage)],
            base_name = "$(nw)_storage_bottom_hole"
        )
    f_wh = var(gm, nw)[:well_head_flow] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :storage)],
            base_name = "$(nw)_storage_well_head"
        )

    if bounded
        for (i, storage) in ref(gm, nw, :storage)
            lb = min(-storage["flow_injection_rate_max"], 0.0)
            ub = max(storage["flow_withdrawal_rate_max"], 0.0)
            JuMP.set_lower_bound(f_s[i], lb)
            JuMP.set_upper_bound(f_s[i], ub)
            JuMP.set_lower_bound(f_bh[i], lb)
            JuMP.set_upper_bound(f_bh[i], ub)
            JuMP.set_lower_bound(f_wh[i], lb)
            JuMP.set_upper_bound(f_wh[i], ub)
        end
    end

    if report
        _IM.sol_component_value(
            gm,
            gm_it_sym,
            nw,
            :storage,
            :storage_flow,
            ids(gm, nw, :storage),
            f_s,
        )
        _IM.sol_component_value(
            gm,
            gm_it_sym,
            nw,
            :storage,
            :bottom_hole_flow,
            ids(gm, nw, :storage),
            f_bh,
        )
        _IM.sol_component_value(
            gm,
            gm_it_sym,
            nw,
            :storage,
            :withdrawal,
            ids(gm, nw, :storage),
            f_wh,
        )
        _IM.sol_component_value(
            gm,
            gm_it_sym,
            nw,
            :storage,
            :well_head_flow,
            ids(gm, nw, :storage),
            f_wh,
        )
    end
end


"variables associated with well compressor/regulator ratio"
function variable_storage_c_ratio(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    bounded::Bool = true,
    report::Bool = true,
)
    c_ratio_well = var(gm, nw)[:storage_compressor_ratio] = JuMP.@variable(
            gm.model,
            [i in ids(gm, nw, :storage)],
            base_name = "$(nw)_c_ratio_storage"
        )

    if bounded
        for (i, storage) in ref(gm, nw, :storage)
            JuMP.set_lower_bound(c_ratio_well[i], storage["reduction_factor_max"])
            JuMP.set_upper_bound(c_ratio_well[i], storage["c_ratio_max"])
        end
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :storage_compressor_ratio,
        ids(gm, nw, :storage),
        c_ratio_well,
    )
end

"variables associated with the nodal densities of the well"
function variable_well_density(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    num_discretizations::Int = 4,
    bounded::Bool = true,
    report::Bool = true,
)
    rho_well_nodes = var(gm, nw)[:well_density] = Dict{Int,Any}()
    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_density][i] = JuMP.@variable(
            gm.model,
            [j in 1:num_discretizations+1],
            base_name = "$(nw)_$(i)_nodal_density_well"
        )
    end

    for i in ids(gm, nw, :storage)
        for j = 1:num_discretizations+1
            JuMP.set_lower_bound(rho_well_nodes[i][j], 0)
        end
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_density,
        ids(gm, nw, :storage),
        rho_well_nodes,
    )

end

"variables associated with the average well fluxes for the storages"
function variable_well_flux_avg(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    num_discretizations::Int = nw_id_default,
    report::Bool = true,
)
    phi = var(gm, nw)[:well_flux_avg] = Dict{Int,Any}()
    flow = var(gm, nw)[:well_flow_avg] = Dict{Int,Any}()
    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flux_avg][i] = JuMP.@variable(
            gm.model,
            [j in 1:num_discretizations],
            base_name = "$(nw)_$(i)_flux_well_avg"
        )
    end

    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flow_avg][i] = JuMP.@expression(
            gm.model,
            [j in 1:num_discretizations],
            ref(gm, nw, :storage, i)["well_area"] * phi[i][j]
        )
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_flux_avg,
        ids(gm, nw, :storage),
        phi,
    )

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_flow_avg,
        ids(gm, nw, :storage),
        flow,
    )
end

"variables associated with the neg. well fluxes for the storages"
function variable_well_flux_neg(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    num_discretizations::Int = nw_id_default,
    report::Bool = true,
)
    phi = var(gm, nw)[:well_flux_neg] = Dict{Int,Any}()
    flow = var(gm, nw)[:well_flow_neg] = Dict{Int,Any}()
    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flux_neg][i] = JuMP.@variable(
            gm.model,
            [j in 1:num_discretizations],
            base_name = "$(nw)_$(i)_flux_well_neg"
        )
    end

    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flow_neg][i] = JuMP.@expression(
            gm.model,
            [j in 1:num_discretizations],
            ref(gm, nw, :storage, i)["well_area"] * phi[i][j]
        )
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_flux_neg,
        ids(gm, nw, :storage),
        phi,
    )

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_flow_neg,
        ids(gm, nw, :storage),
        flow,
    )
end

"variables associated with the (from) well fluxes for the storages"
function variable_well_flux_fr(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    num_discretizations::Int = nw_id_default,
    report::Bool = true,
)
    phi = var(gm, nw)[:well_flux_fr] = Dict{Int,Any}()
    flow = var(gm, nw)[:well_flow_fr] = Dict{Int,Any}()
    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flux_fr][i] = JuMP.@expression(
            gm.model,
            [j in 1:num_discretizations],
            var(gm, nw, :well_flux_avg, i)[j] - var(gm, nw, :well_flux_neg, i)[j]
        )
    end

    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flow_fr][i] = JuMP.@expression(
            gm.model,
            [j in 1:num_discretizations],
            ref(gm, nw, :storage, i)["well_area"] * phi[i][j]
        )
    end

    report &&
        sol_component_value(gm, nw, :storage, :well_flux_fr, ids(gm, nw, :storage), phi)

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_flow_fr,
        ids(gm, nw, :storage),
        flow,
    )
end

"variables associated with the (to) well fluxes for the storages"
function variable_well_flux_to(
    gm::AbstractGasModel,
    nw::Int = nw_id_default;
    num_discretizations::Int = nw_id_default,
    report::Bool = true,
)
    phi = var(gm, nw)[:well_flux_to] = Dict{Int,Any}()
    flow = var(gm, nw)[:well_flow_to] = Dict{Int,Any}()
    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flux_to][i] = JuMP.@expression(
            gm.model,
            [j in 1:num_discretizations],
            var(gm, nw, :well_flux_avg, i)[j] + var(gm, nw, :well_flux_neg, i)[j]
        )
    end

    for i in ids(gm, nw, :storage)
        var(gm, nw)[:well_flow_to][i] = JuMP.@expression(
            gm.model,
            [j in 1:num_discretizations],
            ref(gm, nw, :storage, i)["well_area"] * phi[i][j]
        )
    end

    report &&
        sol_component_value(gm, nw, :storage, :well_flux_to, ids(gm, nw, :storage), phi)

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_flow_to,
        ids(gm, nw, :storage),
        flow,
    )
end


# *******************************************************
# Expressions
# *******************************************************

"density derivative for well nodal densities"
function expression_well_density_derivative(
    gm::AbstractGasModel,
    nw::Int,
    nw_next::Int;
    num_discretizations::Int = 4,
    report::Bool = true,
)
    var(gm, nw)[:well_density_derivative] = Dict{Int,Any}()
    for storage_id in ids(gm, nw, :storage)
        var(gm, nw, :well_density_derivative)[storage_id] = Dict{Int,Any}()
        for j = 1:(num_discretizations+1)
            var(gm, nw, :well_density_derivative, storage_id)[j] = (
                    var(gm, nw_next, :well_density, storage_id)[j] -
                    var(gm, nw, :well_density, storage_id)[j]
             ) / gm.ref[:it][gm_it_sym][:time_step]
        end
    end

    report && sol_component_value(
        gm,
        nw,
        :storage,
        :well_density_derivative,
        ids(gm, nw, :storage),
        var(gm, nw)[:well_density_derivative],
    )
end
# *******************************************************
# Constraints
# *******************************************************

"Constraint: well compression/pressure-reduction"
function constraint_storage_compressor_regulator(gm::AbstractGasModel, nw::Int, storage_id::Int, junction_id::Int)
    rho_junction = var(gm, nw, :density, junction_id)
    rho_well_head = var(gm, nw, :well_density, storage_id)[1]
    alpha = var(gm, nw, :storage_compressor_ratio, storage_id)
    GasModels._add_constraint!(gm, nw, :well_compressor_regulator, storage_id, JuMP.@constraint(gm.model, rho_junction == alpha * rho_well_head))
end

"Constraint: well momentum balance"
function constraint_storage_well_momentum_balance(gm::AbstractGasModel, nw::Int, num_discretizations::Int, storage_id::Int, beta::Float64, resistance::Float64)
    for i = 1:num_discretizations
        rho_top = var(gm, nw, :well_density, storage_id)[i]
        rho_bottom = var(gm, nw, :well_density, storage_id)[i+1]
        phi_avg = var(gm, nw, :well_flux_avg, storage_id)[i]
        GasModels._add_constraint!(gm, nw, :well_ideal_momentum_balance, storage_id * 1000 + i, JuMP.@constraint(gm.model, exp(beta) * rho_bottom^2 - rho_top^2 == (-resistance * phi_avg * abs(phi_avg)) * (exp(beta) - 1) / beta))
    end
end

"Constraint: well mass balance"
function constraint_storage_well_mass_balance(gm::AbstractGasModel, nw::Int, num_discretizations::Int, storage_id::Int, L::Float64, is_end::Bool)
    for i = 1:num_discretizations
        rho_dot_top = var(gm, nw, :well_density_derivative, storage_id)[i]
        rho_dot_bottom = var(gm, nw, :well_density_derivative, storage_id)[i+1]
        phi_neg = var(gm, nw, :well_flux_neg, storage_id)[i]
        if is_end
            phi_neg = 0.5 * (var(gm, nw, :well_flux_neg, storage_id)[i] + var(gm, nw + 1, :well_flux_neg, storage_id)[i])
        end
        GasModels._add_constraint!(gm, nw, :well_ideal_mass_balance, storage_id * 1000 + i, JuMP.@constraint(gm.model, L * (rho_dot_top + rho_dot_bottom) + 4 * phi_neg == 0))
    end
end

"Constraint: storage well nodal balance"
function constraint_storage_well_nodal_balance(
    gm::AbstractGasModel, storage_id::Int, nw::Int = nw_id_default;
    num_discretizations::Int = 4, )

    f_s = var(gm, nw, :storage_flow, storage_id)
    f_wh = var(gm, nw, :well_head_flow, storage_id)
    f_bh = var(gm, nw, :bottom_hole_flow, storage_id)
    flow_from_wh = var(gm, nw, :well_flow_fr, storage_id)[1]
    flow_to_bh = var(gm, nw, :well_flow_to, storage_id)[num_discretizations]

    GasModels._add_constraint!(gm, nw, :wh_flow_balance, storage_id, JuMP.@constraint(gm.model, f_wh == flow_from_wh))

    GasModels._add_constraint!(gm, nw, :bh_flow_balance, storage_id, JuMP.@constraint(gm.model, f_bh == flow_to_bh))

    GasModels._add_constraint!(gm, nw, :storage_flow_balance, storage_id, JuMP.@constraint(gm.model, f_wh == -f_s))


    for i = 1:(num_discretizations-1)
        flux_to = var(gm, nw, :well_flux_to, storage_id)[i]
        flux_fr = var(gm, nw, :well_flux_fr, storage_id)[i+1]

        GasModels._add_constraint!(gm, nw, :well_nodal_balance, storage_id * 1000 + i, JuMP.@constraint(gm.model, flux_fr == flux_to))

    end
end

"Constraint: equivalence of bottom hole density and reservoir density"
function constraint_storage_bottom_hole_reservoir_density(
    gm::AbstractGasModel, storage_id::Int, nw::Int = nw_id_default;
    num_discretizations::Int = 4, )
    rho_bh = var(gm, nw, :well_density, storage_id)[num_discretizations+1]
    rho_reservoir = var(gm, nw, :reservoir_density, storage_id)

    GasModels._add_constraint!(gm, nw, :reservoir_and_well_density_equivalence, storage_id, JuMP.@constraint(gm.model, rho_bh == rho_reservoir))
end

"Constraint: reservoir physics"
function constraint_storage_reservoir_physics(
    gm::AbstractGasModel, storage_id::Int, nw::Int = nw_id_default;
    is_end::Bool = false, )
    volume = ref(gm, nw, :storage, storage_id)["reservoir_volume"]
    rho_dot = var(gm, nw, :reservoir_density_derivative, storage_id)
    f_bh = var(gm, nw, :bottom_hole_flow, storage_id)
    if is_end
        f_bh = 0.5 * (var(gm, nw, :bottom_hole_flow, storage_id) + var(gm, nw + 1, :bottom_hole_flow, storage_id))
    end

    GasModels._add_constraint!(gm, nw, :reservoir_physics, storage_id, JuMP.@constraint(gm.model, volume * rho_dot == f_bh))
end

"Constraint: time periodicity of well head flow"
function constraint_wh_flow_time_periodicity(gm::AbstractGasModel, storage_id::Int, nw_start::Int, nw_end::Int)
    f_wh_start = var(gm, nw_start, :well_head_flow, storage_id)
    f_wh_end = var(gm, nw_end, :well_head_flow, storage_id)
    GasModels._add_constraint!(gm, nw_start, :wh_flow_periodicity, storage_id, JuMP.@constraint(gm.model, f_wh_start == f_wh_end))
end
