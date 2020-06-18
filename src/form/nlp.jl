# This file contains implementations of functions for the nlp formulation

#############################################################################################################
## Constraints for modeling flow across a pipe
############################################################################################################

"Weymouth equation with absolute value"
function constraint_pipe_weymouth(gm::AbstractNLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_pipe, k)
    _add_constraint!(gm, n, :weymouth1, k, JuMP.@NLconstraint(gm.model, (pi - pj) <= (f * abs(f))/w))
    _add_constraint!(gm, n, :weymouth2, k, JuMP.@NLconstraint(gm.model, (pi - pj) >= (f * abs(f))/w))
end


"Weymouth equation with absolute value"
function constraint_resistor_weymouth(gm::AbstractNLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_resistor, k)
    _add_constraint!(gm, n, :weymouth1, k, JuMP.@NLconstraint(gm.model, (pi - pj) <= (f * abs(f))/w))
    _add_constraint!(gm, n, :weymouth2, k, JuMP.@NLconstraint(gm.model, (pi - pj) >= (f * abs(f))/w))
end


#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################


"Weymouth equation for an expansion pipe"
function constraint_pipe_weymouth_ne(gm::AbstractNLPModel,  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zp = var(gm, n, :zp, k)
    f  = var(gm, n, :f_ne_pipe, k)

    _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@NLconstraint(gm.model, w*(pi - pj) >= f * abs(f) + (1-zp) * w * pd_min))
    _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@NLconstraint(gm.model, w*(pi - pj) <= f * abs(f) + (1-zp) * w * pd_max))
end


######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

"enforces pressure changes bounds that obey compression ratios"
function constraint_compressor_ratios(gm::AbstractNLPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_compressor, k)

    # compression in both directions
    if type == 0
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, f * (pj - pi) >= 0))
        _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, max(pi/pj, pj/pi) <= max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratios3, k, JuMP.@constraint(gm.model, min_ratio^2 <= max(pi/pj, pj/pi)))
    # compression when flow is from i to j.  No flow in reverse, so nothing to model in that direction
    elseif type == 1
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= 0))
        _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= 0))
    # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio = 1
    elseif min_ratio == 1
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= 0))
        _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= 0))
        _add_constraint!(gm, n, :compressor_ratios3, k, JuMP.@constraint(gm.model, f*(pi - pj) <= 0))
    # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio != 1. This is a disjunctive model
    else
        if !haskey(gm.var[:nw][n],:y_compressor_nlp)
            gm.var[:nw][n][:y_compressor_nlp] = Dict()
        end
        y = gm.var[:nw][n][:y_compressor_nlp][k] = JuMP.@variable(gm.model,k,base_name="$(n)_y_nlp")
        _add_constraint!(gm, n, :on_off_compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-y)*(j_pmax^2)))
        _add_constraint!(gm, n, :on_off_compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-y)*(i_pmax^2)))
        _add_constraint!(gm, n, :on_off_compressor_ratios3, k, JuMP.@constraint(gm.model, pi - pj <= y*(i_pmax^2)))
        _add_constraint!(gm, n, :on_off_compressor_ratios4, k, JuMP.@constraint(gm.model, pj - pi <= y*(j_pmax^2)))
        _add_constraint!(gm, n, :on_off_compressor_ratios5, k, JuMP.@constraint(gm.model, y == y^2))
    end
end


"constraints on pressure drop across a compressor"
function constraint_compressor_ratios_ne(gm::AbstractNLPModel, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax, type)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zc = var(gm, n, :zc, k)
    f  = var(gm, n, :f_ne_compressor, k)

    M  = abs(max(i_pmax^2,j_pmax^2)) - abs(min(i_pmin^2,j_pmin^2))
    MR = max(i_pmax^2,j_pmax^2) / min(i_pmin^2,j_pmin^2)

    # compression in both directions
    if type == 0
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, f * (pj - pi) >= 0)) # f is 0 when zc = 0, so no big M needed here
        _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, max(pi/pj, pj/pi) <= max_ratio^2 + (1-zc)*MR))
        _add_constraint!(gm, n, :compressor_ratios3, k, JuMP.@constraint(gm.model, min_ratio^2 <= max(pi/pj, pj/pi) + (1-zc)*min_ratio^2))
    # compression when flow is from i to j.  No flow in reverse, so nothing to model in that direction
    elseif type == 1
        _add_constraint!(gm, n, :on_off_compressor_ratios_ne1, k, JuMP.@constraint(gm.model,  pj - (max_ratio^2*pi) <= (1-zc)*j_pmax^2))
        _add_constraint!(gm, n, :on_off_compressor_ratios_ne2, k, JuMP.@constraint(gm.model,  (min_ratio^2*pi) - pj <= (1-zc)*i_pmax^2*min_ratio^2))
    # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio = 1
    elseif min_ratio == 1
        _add_constraint!(gm, n, :compressor_ratios_ne1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-zc)*j_pmax^2))
        _add_constraint!(gm, n, :compressor_ratios_ne2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-zc)*(min_ratio*i_pmax^2)))
        _add_constraint!(gm, n, :compressor_ratios_ne3, k, JuMP.@constraint(gm.model, f * (pi - pj) <= (1-zc) * f_max * M))
    # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio != 1. This is a disjunctive model
    else
        if !haskey(gm.var[:nw][n],:y_compressor_nlp)
            gm.var[:nw][n][:y_compressor_nlp] = Dict()
        end
        y = gm.var[:nw][n][:y_compressor_nlp][k] = JuMP.@variable(gm.model,k,base_name="$(n)_y_nlp")
        _add_constraint!(gm, n, :on_off_compressor_ratios_ne1, k, JuMP.@constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-y-zc)*j_pmax^2))
        _add_constraint!(gm, n, :on_off_compressor_ratios_ne2, k, JuMP.@constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-y-zc)*(min_ratio^2*i_pmax^2)))
        _add_constraint!(gm, n, :on_off_compressor_ratios3, k, JuMP.@constraint(gm.model, pi - pj <= (1+y-zc)*(i_pmax^2)))
        _add_constraint!(gm, n, :on_off_compressor_ratios4, k, JuMP.@constraint(gm.model, pj - pi <= (1+y-zc)*(j_pmax^2)))
        _add_constraint!(gm, n, :on_off_compressor_ratios5, k, JuMP.@constraint(gm.model, y == y^2))
    end
end


##########################################################################################################
# Constraints on control valves
##########################################################################################################

"constraints on pressure drop across control valves"
function constraint_on_off_regulator_pressure(gm::AbstractNLPModel, n::Int, k, i, j, min_ratio, max_ratio, f_min, i_pmin, i_pmax, j_pmin, j_pmax)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    v  = var(gm, n, :v_regulator, k)
    f  = var(gm, n, :f_regulator, k)

    if max_ratio == 1
        _add_constraint!(gm, n, :regulator_pressure_drop1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
        _add_constraint!(gm, n, :regulator_pressure_drop3, k, JuMP.@constraint(gm.model, f * (pi - pj) >= 0))
    elseif f_min >= 0
        _add_constraint!(gm, n, :regulator_pressure_drop1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
    else
        # There condition implies a disjunction when flow is reversed
        if !haskey(gm.var[:nw][n],:y_regulator_nlp)
            gm.var[:nw][n][:y_regulator_nlp] = Dict()
        end
        y = gm.var[:nw][n][:y_regulator_nlp][k] = JuMP.@variable(gm.model,k,base_name="$(n)_y_nlp")
        _add_constraint!(gm, n, :regulator_pressure_drop1, k, JuMP.@constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-y-v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop2, k, JuMP.@constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-y-v)*i_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop3, k, JuMP.@constraint(gm.model,  pj - pi <= (1 + y - v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop4, k, JuMP.@constraint(gm.model,  pi - pj <= (1 + y - v)*i_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop5, k, JuMP.@constraint(gm.model,  y == y^2))
    end
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractNLPModel, n::Int, k, i, j)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r     = var(gm, n, :rsqr, k)
    _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, r * pi <= pj))
    _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, r * pi >= pj))
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractNLPModel, n::Int, k, power_max, m, work)
    r = var(gm, n, :rsqr, k)
    f = var(gm, n, :f_compressor, k)
    _add_constraint!(gm, n, :compressor_energy, k, JuMP.@NLconstraint(gm.model, f * (r^m - 1) <= power_max/work))
end
