# Define LRDWP implementations of Gas Models


"Variables needed for modeling flow in LRDWP models"
function variable_flow(gm::AbstractLRDWPModel, n::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_mass_flow(gm, n; bounded = bounded, report = report)
    variable_connection_direction(gm, n; report = report)
end


"Variables needed for modeling flow in LRDWP models"
function variable_flow_ne(gm::AbstractLRDWPModel, n::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_mass_flow_ne(gm, n; bounded = bounded, report = report)
    variable_connection_direction_ne(gm, n; report = report)
end

"Variable Set: Define variables needed for modeling flow across storage"
function variable_storage(gm::AbstractLRDWPModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    variable_storage_mass_flow(gm,nw,bounded=bounded,report=report)
end


######################################################################################################
## Constraints
######################################################################################################

"Constraint: Weymouth equation--not applicable for LRDWP models"
function constraint_pipe_weymouth(gm::AbstractLRDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in crdwp.jl
end


"Constraint: Darcy-Weisbach equation--not applicable for LRDWP models"
function constraint_resistor_darcy_weisbach(gm::AbstractLRDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in crdwp.jl
end


"Constraint: Define pressures across a resistor"
function constraint_resistor_pressure(gm::AbstractLRDWPModel, n::Int, k::Int, i::Int, j::Int, pd_min::Float64, pd_max::Float64)
end


"Constraint: Constraints which define pressure drop across a loss resistor"
function constraint_loss_resistor_pressure(gm::AbstractLRDWPModel, n::Int, k::Int, i::Int, j::Int, pd::Float64) end


"Constraint: Weymouth equation"
function constraint_pipe_weymouth_ne(gm::AbstractLRDWPModel, n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in crdwp.jl
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractLRDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, max_ratio)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    r = var(gm, n, :rsqr, k)
    y = var(gm, n, :y_compressor, k)

    if type == 0
        rpi = JuMP.@variable(gm.model)
        rpj = JuMP.@variable(gm.model)

        _IM.relaxation_product(gm.model, pi, r, rpi)
        _IM.relaxation_product(gm.model, pj, r, rpj)
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@constraint(gm.model, rpi <= pj + (1 - y) * i_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@constraint(gm.model, rpi >= pj - (1 - y) * j_pmax^2))
        _add_constraint!(gm, n, :compressor_ratio_value3, k, JuMP.@constraint(gm.model, rpj <= pi + y * j_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value4, k, JuMP.@constraint(gm.model, rpj >= pi - y * i_pmax^2))
    else
        _IM.relaxation_product(gm.model, pi, r, pj)
    end
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value_ne(gm::AbstractLRDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, max_ratio)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    r = var(gm, n, :rsqr_ne, k)
    y = var(gm, n, :y_ne_compressor, k)
    z = var(gm, n, :zc, k)

    if type == 0
        rpi = JuMP.@variable(gm.model)
        rpj = JuMP.@variable(gm.model)

        _IM.relaxation_product(gm.model, pi, r, rpi)
        _IM.relaxation_product(gm.model, pj, r, rpj)
        _add_constraint!(gm, n, :compressor_ratio_value_ne1, k, JuMP.@constraint(gm.model, rpi <= pj + (2 - y - z) * i_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value_ne2, k, JuMP.@constraint(gm.model, rpi >= pj - (2 - y - z) * j_pmax^2))
        _add_constraint!(gm, n, :compressor_ratio_value_ne3, k, JuMP.@constraint(gm.model, rpj <= pi + (1 + y - z) * j_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value_ne4, k, JuMP.@constraint(gm.model, rpj >= pi - (1 + y - z) * i_pmax^2))
    else
        rpi = JuMP.@variable(gm.model)
        _IM.relaxation_product(gm.model, pi, r, rpi)
        _add_constraint!(gm, n, :compressor_ratio_value_ne1, k, JuMP.@constraint(gm.model, rpi <= pj + (1 - z) * i_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value_ne2, k, JuMP.@constraint(gm.model, rpi >= pj - (1 - z) * j_pmax^2))
    end
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractLRDWPModel, n::Int, k, power_max, m, work)
    #TODO - lrdwp relaxation
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractLRDWPModel, n::Int, k, power_max, m, work)
    #TODO - lrdwp relaxation
end
