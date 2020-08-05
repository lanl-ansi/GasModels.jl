# Define LRDWP implementations of Gas Models


"Variables needed for modeling flow in LRDWP models"
function variable_flow(gm::AbstractLRDWPModel, n::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow(gm, n; bounded=bounded, report=report)
    variable_connection_direction(gm, n; report=report)
end


"Variables needed for modeling flow in LRDWP models"
function variable_flow_ne(gm::AbstractLRDWPModel, n::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow_ne(gm, n; bounded=bounded, report=report)
    variable_connection_direction_ne(gm, n; report=report)
end

######################################################################################################
## Constraints
######################################################################################################

"Constraint: Weymouth equation--not applicable for LRDWP models"
function constraint_pipe_weymouth(gm::AbstractLRDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in crdwp.jl
end


"Constraint: Weymouth equation--not applicable for LRDWP models"
function constraint_resistor_weymouth(gm::AbstractLRDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in crdwp.jl
end


"Constraint: Weymouth equation"
function constraint_pipe_weymouth_ne(gm::AbstractLRDWPModel,  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in crdwp.jl
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractLRDWPModel, n::Int, k, i, j)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r     = var(gm, n, :rsqr, k)

    _IM.relaxation_product(gm.model, pi, r, pj)
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value_ne(gm::AbstractLRDWPModel, n::Int, k, i, j)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r     = var(gm, n, :rsqr_ne, k)

    _IM.relaxation_product(gm.model, pi, r, pj)
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractLRDWPModel, n::Int, k, power_max, m, work)
    #TODO - lrdwp relaxation
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractLRDWPModel, n::Int, k, power_max, m, work)
    #TODO - lrdwp relaxation
end
