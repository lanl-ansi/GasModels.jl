# Define MINLP implementations of Gas Models

"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractMINLPModel, n::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow(gm, n; bounded=bounded, report=report)
    variable_connection_direction(gm, n; report=report)
end


"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::AbstractMINLPModel, n::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow_ne(gm, n; bounded=bounded, report=report)
    variable_connection_direction_ne(gm, n; report=report)
end


"Weymouth equation with discrete direction variables"
function constraint_pipe_weymouth(gm::AbstractMINLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_pipe, k)

    # Constraint weymouth1
    # This constraint should be active when flow goes from i to j. Pressure needs to decrease from i to j. y = 1 models this condition
    # When y = 1, this constraint becomes w*(pi - pj) >= f^2, which is only true when pi >= pj
    # When y = 0, we have w*(pi - pj) >= f^2 - f_min^2 + w*pd_min. By definition, w*(pi - pj) <= 0.  The lower bound on w*(pi - pj) is
    # w*pd_min. Since flow is reversed in this situation, f^2 is bounded by f_min^2. Thus f^2 - f_min^2 only further decreases the rhs.
    # Thus, this constraint is always true (inactive when y = 0)

    # Constraint weymouth2
    # When y = 1, w(pi - pj) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth1
    # When y = 0, w(pi - pj) <= 0, making this constraint always true (inactive when y = 0)

    # Constraint weymouth3
    # This constraint should be active when flow goes from j to i. Pressure needs to decrease from j to i. y = 0 models this condition
    # When y = 0, this constraint becomes w*(pj - pi) >= f^2, which is only true when pj >= pi
    # When y = 1, we have w*(pj - pi) >= f^2 - f_max^2 - w*pd_max. By definition, w*(pj - pi) <= 0.  The lower bound on w*(pi - pj) is
    # -w*pd_max (sign flip on pi amnd pj). Since flow is forward in this situation, f^2 is bounded by f_max^2. Thus f^2 - f_max^2 only further decreases the rhs.
    # Thus, this constraint is always true (inactive when y = 1)

    # Constraint weymouth4
    # When y = 0, w(pj - pi) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth3
    # When y = 1, w(pj - pi) <= 0, making this constraint always true (inactive when y = 1)
    # note the sign flip between pi and pj


    _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w*(pi - pj) >= f^2 - (1-y) * (f_min^2 - w*pd_min)))
    _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w*(pi - pj) <= f^2))
    _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w*(pj - pi) >= f^2 - y * (f_max^2 + w*pd_max)))
    _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w*(pj - pi) <= f^2))
end


"Weymouth equation with discrete direction variables"
function constraint_resistor_weymouth(gm::AbstractMINLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_resistor, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_resistor, k)

    # Constraint weymouth1
    # This constraint should be active when flow goes from i to j. Pressure needs to decrease from i to j. y = 1 models this condition
    # When y = 1, this constraint becomes w*(pi - pj) >= f^2, which is only true when pi >= pj
    # When y = 0, we have w*(pi - pj) >= f^2 - f_min^2 + w*pd_min. By definition, w*(pi - pj) <= 0.  The lower bound on w*(pi - pj) is
    # w*pd_min. Since flow is reversed in this situation, f^2 is bounded by f_min^2. Thus f^2 - f_min^2 only further decreases the rhs.
    # Thus, this constraint is always true (inactive when y = 0)

    # Constraint weymouth2
    # When y = 1, w(pi - pj) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth1
    # When y = 0, w(pi - pj) <= 0, making this constraint always true (inactive when y = 0)

    # Constraint weymouth3
    # This constraint should be active when flow goes from j to i. Pressure needs to decrease from j to i. y = 0 models this condition
    # When y = 0, this constraint becomes w*(pj - pi) >= f^2, which is only true when pj >= pi
    # When y = 1, we have w*(pj - pi) >= f^2 - f_max^2 - w*pd_max. By definition, w*(pj - pi) <= 0.  The lower bound on w*(pi - pj) is
    # -w*pd_max (sign flip on pi amnd pj). Since flow is forward in this situation, f^2 is bounded by f_max^2. Thus f^2 - f_max^2 only further decreases the rhs.
    # Thus, this constraint is always true (inactive when y = 1)

    # Constraint weymouth4
    # When y = 0, w(pj - pi) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth3
    # When y = 1, w(pj - pi) <= 0, making this constraint always true (inactive when y = 1)
    # note the sign flip between pi and pj


    _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w*(pi - pj) >= f^2 - (1-y) * (f_min^2 - w*pd_min)))
    _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w*(pi - pj) <= f^2))
    _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w*(pj - pi) >= f^2 - y * (f_max^2 + w*pd_max)))
    _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w*(pj - pi) <= f^2))
end


"Weymouth equation for an expansion pipe"
function constraint_pipe_weymouth_ne(gm::AbstractMINLPModel,  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    y = var(gm, n, :y_ne_pipe, k)

    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zp = var(gm, n, :zp, k)
    f  = var(gm, n, :f_ne_pipe, k)

    # Constraint weymouth1
    # When zp = 1, this constraint reduces to constraint weymouth1 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
    # When zp = 0, we want this constraint to be in active AND any y value should be valid.  In this case, since f^2 = 0 (there is no flow) the constraint becomes
    # w*(pi - pj) >= -(1-y) * (f_min^2 - w*pd_min) - abs(w*pd_min). When y = 1, we have w*(pi - pj) >= -abs(w*pd_min). Since pd_min is the lower bound on pi - pj,
    # this is always true.  When y = 0, we have w*(pi - pj) >= -f_min^2 + w*pd_min - abs(w*pd_min). Which is always true. w*pd_min is the lower bound on w*pi - pj
    # and the other two terms just drive the lower bound further down.

    # Constraint weymouth2
    # When zp = 1, this constraint reduces to constraint weymouth2 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
    # When zp = 0, we have w*(pi - pj) <= f^2 + w*pd_max.  Since w*pd_max is the upper bound on w*(pi-pj), this is always true.

    # Constraint weymouth3
    # When zp = 1, this constraint reduces to constraint weymouth3 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
    # When zp = 0, we want this constraint to be in active AND any y value should be valid.  In this case, since f^2 = 0 (there is no flow) the constraint becomes
    # w*(pj - pi) >= - y * (f_max^2 + w*pd_max) - abs(w*pd_max). When y = 0, we have w*(pj - pi) >= -abs(w*pd_max). Since -pd_max is the lower bound on pj - pi
    # note reversal of pressure sign, this is always true.  When y = 1, we have w*(pj - pi) >= -f_max^2 - w*pd_max - abs(w*pd_max). Which is always true.
    # -w*pd_max is the lower bound on w*(pj - pi) (note the sign flip). The other two terms just drive the lower bound further down.

    # Constraint weymouth4
    # When zp = 1, this constraint reduces to constraint weymouth4 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
    # When zp = 0, we have (pj - pi) <= f^2 - w*pd_min).  Since -w*pd_min is the upper bound on w*(pj-pi)--the pi and pj are flipped, this is always true.


    _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w*(pi - pj) >= f^2 - (1-y) * (f_min^2 - w*pd_min) - (1-zp)*abs(w*pd_min) ))
    _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w*(pi - pj) <= f^2 + (1-zp)*w*pd_max))
    _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w*(pj - pi) >= f^2 - y * (f_max^2 + w*pd_max) - (1-zp)*abs(w*pd_max) ))
    _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w*(pj - pi) <= f^2 - (1-zp)*w*pd_min))
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractMINLPModel, n::Int, k, i, j)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r = var(gm, n, :rsqr, k)
    _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, r^2 * pi <= pj))
    _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, r^2 * pi >= pj))
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value_ne(gm::AbstractMINLPModel, n::Int, k, i, j)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r = var(gm, n, :rsqr_ne, k)
    _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, r^2 * pi <= pj))
    _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, r^2 * pi >= pj))
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractMINLPModel, n::Int, k::Int, power_max, m, work)
    r = var(gm, n, :rsqr, k)
    f = var(gm, n, :f_compressor, k)
    _add_constraint!(gm, n, :compressor_energy, k, JuMP.@NLconstraint(gm.model, f * (r^m - 1) <= power_max/work))
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractMINLPModel, n::Int, k, power_max, m, work)
    r = var(gm, n, :rsqr_ne, k)
    f = var(gm, n, :f_ne_compressor, k)
    # f is zero when the compressor is not built, so constraint is always true then
    _add_constraint!(gm, n, :compressor_energy, k, JuMP.@NLconstraint(gm.model, f * (r^m - 1) <= power_max/work))
end
