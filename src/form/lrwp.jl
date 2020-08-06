# Define LRWP implementations of Gas Models

function get_compressor_y_lrwp(gm::AbstractWPModel, n::Int, k)
    if !haskey(gm.var[:nw][n],:y_compressor_lrwp)
        gm.var[:nw][n][:y_compressor_lrwp] = Dict()
    end

    if !haskey(gm.var[:nw][n][:y_compressor_lrwp],k)
        gm.var[:nw][n][:y_compressor_lrwp][k] = JuMP.@variable(gm.model, binary=true)
    end

    return gm.var[:nw][n][:y_compressor_lrwp][k]
end

function get_ne_compressor_y_lrwp(gm::AbstractWPModel, n::Int, k)
    if !haskey(gm.var[:nw][n],:y_ne_compressor_lrwp)
        gm.var[:nw][n][:y_ne_compressor_lrwp] = Dict()
    end

    if !haskey(gm.var[:nw][n][:y_ne_compressor_lrwp],k)
        gm.var[:nw][n][:y_ne_compressor_lrwp][k] = JuMP.@variable(gm.model, binary=true)
    end

    return gm.var[:nw][n][:y_ne_compressor_lrwp][k]
end

######################################################################################################
## Constraints
######################################################################################################

"Constraint: Weymouth equation--not applicable for LRWP models"
function constraint_pipe_weymouth(gm::AbstractLRWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in wp.jl
end


"Constraint: Weymouth equation--not applicable for LRWP models"
function constraint_resistor_weymouth(gm::AbstractLRWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in wp.jl
end

"Constraint: Constraints which define pressure drop across a loss resistor"
function constraint_loss_resistor_pressure(gm::AbstractLRWPModel, n::Int, k::Int, i::Int, j::Int, pd::Float64)
end


"Constraint: Compressor ratio constraints on pressure differentials--not applicable for LRWP models"
function constraint_compressor_ratios(gm::AbstractLRWPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_compressor, k)

    # compression in both directions
    if type == 0
        if (min_ratio <= 1.0 && max_ratio >= 1)
            pk   = JuMP.@variable(gm.model, upper_bound=max(JuMP.upper_bound(pi),JuMP.upper_bound(pj)), lower_bound=min(JuMP.lower_bound(pi),JuMP.lower_bound(pj)))
            pik  = JuMP.@variable(gm.model, upper_bound=JuMP.upper_bound(pi)-JuMP.lower_bound(pk), lower_bound=JuMP.lower_bound(pi)-JuMP.upper_bound(pk))
            pjk  = JuMP.@variable(gm.model, upper_bound=JuMP.upper_bound(pj)-JuMP.lower_bound(pk), lower_bound=JuMP.lower_bound(pj)-JuMP.upper_bound(pk))
            fpik = JuMP.@variable(gm.model)
            fpjk = JuMP.@variable(gm.model)

            _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pk - max_ratio^2*pi <= 0))
            _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pk <= 0))
            _add_constraint!(gm, n, :compressor_ratios3, k, JuMP.@constraint(gm.model, fpik <= 0))
            _add_constraint!(gm, n, :compressor_ratios4, k, JuMP.@constraint(gm.model, pk - max_ratio^2*pj <= 0))
            _add_constraint!(gm, n, :compressor_ratios5, k, JuMP.@constraint(gm.model, min_ratio^2*pj - pk <= 0))
            _add_constraint!(gm, n, :compressor_ratios6, k, JuMP.@constraint(gm.model, -fpjk <= 0))
            _add_constraint!(gm, n, :compressor_ratios7, k, JuMP.@constraint(gm.model, pjk == pj - pk))
            _add_constraint!(gm, n, :compressor_ratios8, k, JuMP.@constraint(gm.model, pik == pi - pk))
            _IM.relaxation_product(gm.model, f, pik, fpik)
            _IM.relaxation_product(gm.model, f, pjk, fpjk)

        # There is a disjunction, so we have to use a binary variable for this one
        else
            y = get_compressor_y_lrwp(gm,n,k)
            _add_constraint!(gm, n, :on_off_compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-y)*(j_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-y)*(min_ratio^2*i_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios3, k, JuMP.@constraint(gm.model, pi - max_ratio^2*pj <= y*(i_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios4, k, JuMP.@constraint(gm.model, min_ratio^2*pj - pi <= y*(min_ratio^2*j_pmax^2)))
        end
    # compression when flow is from i to j.  No flow in reverse, so nothing to model in that direction
    elseif type == 1
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= 0))
        _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= 0))
    # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio = 1
    else # type 2
        if min_ratio == 1
            pij  = JuMP.@variable(gm.model, upper_bound=JuMP.upper_bound(pi)-JuMP.lower_bound(pj), lower_bound=JuMP.lower_bound(pi)-JuMP.upper_bound(pj))
            fpij = JuMP.@variable(gm.model)

            _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= 0))
            _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= 0))
            _add_constraint!(gm, n, :compressor_ratios3, k, JuMP.@constraint(gm.model, fpij <= 0))
            _add_constraint!(gm, n, :compressor_ratios4, k, JuMP.@constraint(gm.model, pij == pi - pj))
            _IM.relaxation_product(gm.model, f, pij, fpij)
        # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio != 1. This is a disjunctive model
        else
            y = get_compressor_y_lrwp(gm,n,k)
            _add_constraint!(gm, n, :on_off_compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-y)*(j_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-y)*(i_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios3, k, JuMP.@constraint(gm.model, pi - pj <= y*(i_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios4, k, JuMP.@constraint(gm.model, pj - pi <= y*(j_pmax^2)))
        end
    end
end


"constraints on pressure drop across control valves--not applicable for LRWP models"
function constraint_on_off_regulator_pressure(gm::AbstractLRWPModel, n::Int, k, i, j, min_ratio, max_ratio, f_min, i_pmin, i_pmax, j_pmin, j_pmax)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    v  = var(gm, n, :v_regulator, k)
    f  = var(gm, n, :f_regulator, k)

    if max_ratio == 1
        pij  = JuMP.@variable(gm.model, upper_bound=JuMP.upper_bound(pi)-JuMP.lower_bound(pj), lower_bound=JuMP.lower_bound(pi)-JuMP.upper_bound(pj))
        fpij = JuMP.@variable(gm.model)

        _add_constraint!(gm, n, :regulator_pressure_drop1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
        _add_constraint!(gm, n, :regulator_pressure_drop3, k, JuMP.@constraint(gm.model, fpij >= 0))
        _add_constraint!(gm, n, :regulator_pressure_drop4, k, JuMP.@constraint(gm.model, pij == pi - pj))
        _IM.relaxation_product(gm.model, f, pij, fpij)
    elseif f_min >= 0
        _add_constraint!(gm, n, :regulator_pressure_drop1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
    else
        # There condition implies a disjunction when flow is reversed
        y = JuMP.@variable(gm.model, binary = true)
        _add_constraint!(gm, n, :regulator_pressure_drop1, k, JuMP.@constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-y-v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop2, k, JuMP.@constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-y-v)*i_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop3, k, JuMP.@constraint(gm.model,  pj - pi <= (1 + y - v)*j_pmax^2))
        _add_constraint!(gm, n, :regulator_pressure_drop4, k, JuMP.@constraint(gm.model,  pi - pj <= (1 + y - v)*i_pmax^2))
    end
end


"Constraint: Weymouth equation"
function constraint_pipe_weymouth_ne(gm::AbstractLRWPModel,  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
        #TODO Linear convex hull equations in wp.jl
end


"Constraint: compressor ratios on a new compressor"
function constraint_compressor_ratios_ne(gm::AbstractLRWPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zc = var(gm, n, :zc, k)
    f  = var(gm, n, :f_ne_compressor, k)

    MR = max(i_pmax^2,j_pmax^2) / min(i_pmin^2,j_pmin^2)

    # compression in both directions
    if type == 0
        if (min_ratio <= 1.0 && max_ratio >= 1)
            k_pmax = max(i_pmax, j_pmax)
            k_pmin = min(i_pmin, j_pmin)
            pk     = JuMP.@variable(gm.model, upper_bound=k_pmax, lower_bound=k_pmin)
            pik    = JuMP.@variable(gm.model, upper_bound=JuMP.upper_bound(pi)-JuMP.lower_bound(pk), lower_bound=JuMP.lower_bound(pi)-JuMP.upper_bound(pk))
            pjk    = JuMP.@variable(gm.model, upper_bound=JuMP.upper_bound(pj)-JuMP.lower_bound(pk), lower_bound=JuMP.lower_bound(pj)-JuMP.upper_bound(pk))
            fpik   = JuMP.@variable(gm.model)
            fpjk   = JuMP.@variable(gm.model)

            _add_constraint!(gm, n, :compressor_ratios_ne1, k, JuMP.@constraint(gm.model, pk - max_ratio^2*pi <= (1-zc)*k_pmax^2))
            _add_constraint!(gm, n, :compressor_ratios_ne2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pk <= (1-zc)*i_pmax^2*min_ratio^2))
            _add_constraint!(gm, n, :compressor_ratios_ne3, k, JuMP.@constraint(gm.model, fpik <= 0)) # zc = 0 implies f = 0 so always true then
            _add_constraint!(gm, n, :compressor_ratios_ne4, k, JuMP.@constraint(gm.model, pk - max_ratio^2*pj <= (1-zc)*k_pmax^2))
            _add_constraint!(gm, n, :compressor_ratios_ne5, k, JuMP.@constraint(gm.model, min_ratio^2*pj - pk <= (1-zc)*j_pmax^2*min_ratio^2))
            _add_constraint!(gm, n, :compressor_ratios_ne6, k, JuMP.@constraint(gm.model, -fpjk <= 0))  # zc = 0 implies f = 0 so always true then
            _add_constraint!(gm, n, :compressor_ratios_ne7, k, JuMP.@constraint(gm.model, pjk == pj - pk))
            _add_constraint!(gm, n, :compressor_ratios_ne8, k, JuMP.@constraint(gm.model, pik == pi - pk))
            _IM.relaxation_product(gm.model, f, pik, fpik)
            _IM.relaxation_product(gm.model, f, pjk, fpjk)
        # There is a disjunction, so we have to use a binary variable for this one
        else
            y = get_ne_compressor_y_lrwp(gm,n,k)
            _add_constraint!(gm, n, :on_off_compressor_ratios_ne1, k, JuMP.@constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-y-zc)*j_pmax^2))
            _add_constraint!(gm, n, :on_off_compressor_ratios_ne2, k, JuMP.@constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-y-zc)*(min_ratio^2*i_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios_ne3, k, JuMP.@constraint(gm.model,  pi - (max_ratio^2*pj) <= (1+y-zc)*i_pmax^2))
            _add_constraint!(gm, n, :on_off_compressor_ratios_ne4, k, JuMP.@constraint(gm.model,  (min_ratio^2*pj) - pi <= (1+y-zc)*(min_ratio^2*j_pmax^2)))
        end
    # compression when flow is from i to j.  No flow in reverse, so nothing to model in that direction
    elseif type == 1
        _add_constraint!(gm, n, :on_off_compressor_ratios_ne1, k, JuMP.@constraint(gm.model,  pj - (max_ratio^2*pi) <= (1-zc)*j_pmax^2))
        _add_constraint!(gm, n, :on_off_compressor_ratios_ne2, k, JuMP.@constraint(gm.model,  (min_ratio^2*pi) - pj <= (1-zc)*i_pmax^2*min_ratio^2))
    # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio = 1
    else # type 2
        if min_ratio == 1
            pij  = JuMP.@variable(gm.model, upper_bound=JuMP.upper_bound(pi)-JuMP.lower_bound(pj), lower_bound=JuMP.lower_bound(pi)-JuMP.upper_bound(pj))
            fpij = JuMP.@variable(gm.model)

            _add_constraint!(gm, n, :compressor_ratios_ne1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-zc)*j_pmax^2))
            _add_constraint!(gm, n, :compressor_ratios_ne2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-zc)*(min_ratio*i_pmax^2)))
            # z_c = 0 implies f = 0 (constraint_compressor_ne), so 0 <= 1. So constraint is off
            # z_c = 1 implies f * (pi - pj) <= 0, which is the constraint we want when the edge is actve
            _add_constraint!(gm, n, :compressor_ratios_ne3, k, JuMP.@constraint(gm.model, fpij <= (1-zc)))
            _add_constraint!(gm, n, :compressor_ratios_ne4, k, JuMP.@constraint(gm.model, pij == pi - pj))
            _IM.relaxation_product(gm.model, f, pij, fpij)
        # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio != 1. This is a disjunctive model
        else
            y = get_ne_compressor_y_lrwp(gm,n,k)
            _add_constraint!(gm, n, :on_off_compressor_ratios_ne1, k, JuMP.@constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-y-zc)*j_pmax^2))
            _add_constraint!(gm, n, :on_off_compressor_ratios_ne2, k, JuMP.@constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-y-zc)*(min_ratio^2*i_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios3, k, JuMP.@constraint(gm.model, pi - pj <= (1+y-zc)*(i_pmax^2)))
            _add_constraint!(gm, n, :on_off_compressor_ratios4, k, JuMP.@constraint(gm.model, pj - pi <= (1+y-zc)*(j_pmax^2)))
        end
    end
end

"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractLRWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, max_ratio)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r     = var(gm, n, :rsqr, k)

    if type == 0
        y   = get_compressor_y_wp(gm, n, k)
        rpi = JuMP.@variable(gm.model)
        rpj = JuMP.@variable(gm.model)

        _IM.relaxation_product(gm.model, pi, r, rpi)
        _IM.relaxation_product(gm.model, pj, r, rpj)
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, rpi <= pj + (1-y) * i_pmax*max_ratio))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, rpi >= pj - (1-y) * j_pmax))
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, rpj <= pi +  y * j_pmax*max_ratio))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, rpj >= pi -  y * i_pmax))    else
    end
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value_ne(gm::AbstractLRWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, max_ratio)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r     = var(gm, n, :rsqr_ne, k)

    if type == 0
        y   = get_ne_compressor_y_wp(gm, n, k)
        rpi = JuMP.@variable(gm.model)
        rpj = JuMP.@variable(gm.model)

        _IM.relaxation_product(gm.model, pi, r, rpi)
        _IM.relaxation_product(gm.model, pj, r, rpj)
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, rpi <= pj + (1-y) * i_pmax*max_ratio))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, rpi >= pj - (1-y) * j_pmax))
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, rpj <= pi +  y * j_pmax*max_ratio))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, rpj >= pi -  y * i_pmax))
    else
        _IM.relaxation_product(gm.model, pi, r, pj)
    end
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractLRWPModel, n::Int, k, power_max, m, work)
    #TODO Linear convex hull equations in wp.jl
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractLRWPModel, n::Int, k, power_max, m, work)
    #TODO Linear convex hull equations in wp.jl
end
