# Define DWP implementations of Gas Models

"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractDWPModel, n::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_mass_flow(gm, n; bounded = bounded, report = report)
    variable_connection_direction(gm, n; report = report)
end


"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::AbstractDWPModel, n::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_mass_flow_ne(gm, n; bounded = bounded, report = report)
    variable_connection_direction_ne(gm, n; report = report)
end


"Variable Set: Define variables needed for modeling flow across storage"
function variable_storage(gm::AbstractDWPModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    variable_storage_mass_flow(gm,nw,bounded=bounded,report=report)
end

"Weymouth equation with discrete direction variables

Constraint 1:

This constraint should be active when flow goes from i to j. Pressure needs to decrease from i to j. y = 1 models this condition
When y = 1, this constraint becomes w*(pi - pj) >= f^2, which is only true when pi >= pj
When y = 0, we have w*(pi - pj) >= f^2 - f_min^2 + w*pd_min. By definition, w*(pi - pj) <= 0.  The lower bound on w*(pi - pj) is
w*pd_min. Since flow is reversed in this situation, f^2 is bounded by f_min^2. Thus f^2 - f_min^2 only further decreases the rhs.
Thus, this constraint is always true (inactive when y = 0)

Constraint 2:

When y = 1, w(pi - pj) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth1
# When y = 0, w(pi - pj) <= 0, making this constraint always true (inactive when y = 0)

Constraint 3:

This constraint should be active when flow goes from j to i. Pressure needs to decrease from j to i. y = 0 models this condition
# When y = 0, this constraint becomes w*(pj - pi) >= f^2, which is only true when pj >= pi
# When y = 1, we have w*(pj - pi) >= f^2 - f_max^2 - w*pd_max. By definition, w*(pj - pi) <= 0.  The lower bound on w*(pi - pj) is
# -w*pd_max (sign flip on pi amnd pj). Since flow is forward in this situation, f^2 is bounded by f_max^2. Thus f^2 - f_max^2 only further decreases the rhs.
# Thus, this constraint is always true (inactive when y = 1)

Constraint 4:

# When y = 0, w(pj - pi) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth3
# When y = 1, w(pj - pi) <= 0, making this constraint always true (inactive when y = 1)
# note the sign flip between pi and pj
"
function constraint_pipe_weymouth(gm::AbstractDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f = var(gm, n, :f_pipe, k)

    if w == 0.0
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, pi - pj == 0.0))
    else
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w * (pi - pj) >= f^2 - (1 - y) * (f_min^2 - w * pd_min)))
        _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w * (pi - pj) <= f^2))
        _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w * (pj - pi) >= f^2 - y * (f_max^2 + w * pd_max)))
        _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w * (pj - pi) <= f^2))
    end
end


"Weymouth equation for resistors

Constraint 1:

This constraint should be active when flow goes from i to j. Pressure needs to decrease from i to j. y = 1 models this condition
When y = 1, this constraint becomes w*(pi - pj) >= f^2, which is only true when pi >= pj
When y = 0, we have w*(pi - pj) >= f^2 - f_min^2 + w*pd_min. By definition, w*(pi - pj) <= 0.  The lower bound on w*(pi - pj) is
w*pd_min. Since flow is reversed in this situation, f^2 is bounded by f_min^2. Thus f^2 - f_min^2 only further decreases the rhs.
Thus, this constraint is always true (inactive when y = 0)

Constraint 2:

When y = 1, w(pi - pj) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth1
When y = 0, w(pi - pj) <= 0, making this constraint always true (inactive when y = 0)

Constraint 3:

This constraint should be active when flow goes from j to i. Pressure needs to decrease from j to i. y = 0 models this condition
When y = 0, this constraint becomes w*(pj - pi) >= f^2, which is only true when pj >= pi
When y = 1, we have w*(pj - pi) >= f^2 - f_max^2 - w*pd_max. By definition, w*(pj - pi) <= 0.  The lower bound on w*(pi - pj) is
-w*pd_max (sign flip on pi amnd pj). Since flow is forward in this situation, f^2 is bounded by f_max^2. Thus f^2 - f_max^2 only further decreases the rhs.
Thus, this constraint is always true (inactive when y = 1)

Constraint 4:

When y = 0, w(pj - pi) >= 0 this constraint needs to be active, so should be upper bounded by f^2 to get equality when combined with weymouth3
When y = 1, w(pj - pi) <= 0, making this constraint always true (inactive when y = 1)
note the sign flip between pi and pj
"
function constraint_resistor_darcy_weisbach(gm::AbstractDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    f, y = var(gm, n, :f_resistor, k), var(gm, n, :y_resistor, k)
    p_i, p_j = var(gm, n, :p, i), var(gm, n, :p, j)

    _add_constraint!(gm, n, :darcy_weisbach_1, k, JuMP.@constraint(gm.model, (1.0/w)*(p_i - p_j) >= f^2 - (1.0 - y) * (f_min^2-(1.0/w)*pd_min)))
    _add_constraint!(gm, n, :darcy_weisbach_2, k, JuMP.@constraint(gm.model, (1.0/w)*(p_i - p_j) <= f^2))
    _add_constraint!(gm, n, :darcy_weisbach_3, k, JuMP.@constraint(gm.model, (1.0/w)*(p_j - p_i) >= f^2 - y * (f_max^2+(1.0/w)*pd_max)))
    _add_constraint!(gm, n, :darcy_weisbach_4, k, JuMP.@constraint(gm.model, (1.0/w)*(p_j - p_i) <= f^2))
end


"Constraint: Define pressures across a resistor"
function constraint_resistor_pressure(gm::AbstractDWPModel, n::Int, k::Int, i::Int, j::Int, pd_min::Float64, pd_max::Float64)
    p_i, p_j = var(gm, n, :p, i), var(gm, n, :p, j)
    p_i_sqr, p_j_sqr = var(gm, n, :psqr, i), var(gm, n, :psqr, j)
    y = var(gm, n, :y_resistor, k)

    c_1 = JuMP.@constraint(gm.model, p_i^2 == p_i_sqr)
    _add_constraint!(gm, n, :pressure_drop_1, k, c_1)
    c_2 = JuMP.@constraint(gm.model, p_j^2 == p_j_sqr)
    _add_constraint!(gm, n, :pressure_drop_2, k, c_2)
    c_3 = JuMP.@constraint(gm.model, (1.0 - y) * pd_min <= p_i - p_j)
    _add_constraint!(gm, n, :on_off_pressure_drop_1, k, c_3)
    c_4 = JuMP.@constraint(gm.model, p_i - p_j <= y * pd_max)
    _add_constraint!(gm, n, :on_off_pressure_drop_2, k, c_4)
end


"Weymouth equation for an expansion pipe

Constraint 1:

When zp = 1, this constraint reduces to constraint weymouth1 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
When zp = 0, we want this constraint to be in active AND any y value should be valid.  In this case, since f^2 = 0 (there is no flow) the constraint becomes
w*(pi - pj) >= -(1-y) * (f_min^2 - w*pd_min) - abs(w*pd_min). When y = 1, we have w*(pi - pj) >= -abs(w*pd_min). Since pd_min is the lower bound on pi - pj,
this is always true.  When y = 0, we have w*(pi - pj) >= -f_min^2 + w*pd_min - abs(w*pd_min). Which is always true. w*pd_min is the lower bound on w*pi - pj
and the other two terms just drive the lower bound further down.

Constraint 2:

When zp = 1, this constraint reduces to constraint weymouth2 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
When zp = 0, we have w*(pi - pj) <= f^2 + w*pd_max.  Since w*pd_max is the upper bound on w*(pi-pj), this is always true.

Constraint 3:

When zp = 1, this constraint reduces to constraint weymouth3 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
When zp = 0, we want this constraint to be in active AND any y value should be valid.  In this case, since f^2 = 0 (there is no flow) the constraint becomes
w*(pj - pi) >= - y * (f_max^2 + w*pd_max) - abs(w*pd_max). When y = 0, we have w*(pj - pi) >= -abs(w*pd_max). Since -pd_max is the lower bound on pj - pi
note reversal of pressure sign, this is always true.  When y = 1, we have w*(pj - pi) >= -f_max^2 - w*pd_max - abs(w*pd_max). Which is always true.
-w*pd_max is the lower bound on w*(pj - pi) (note the sign flip). The other two terms just drive the lower bound further down.

Constraint 4:

# When zp = 1, this constraint reduces to constraint weymouth4 in constraint_pipe_weymouth, which is what we want (i.e. an active constraint)
# When zp = 0, we have (pj - pi) <= f^2 - w*pd_min).  Since -w*pd_min is the upper bound on w*(pj-pi)--the pi and pj are flipped, this is always true.
"
function constraint_pipe_weymouth_ne(gm::AbstractDWPModel, n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    y = var(gm, n, :y_ne_pipe, k)

    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zp = var(gm, n, :zp, k)
    f = var(gm, n, :f_ne_pipe, k)

    if w == 0.0
        _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, pi - pj <= (1 - zp) * pd_max))
        _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@constraint(gm.model, pi - pj >= (1 - zp) * pd_min))
    else
        _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, w * (pi - pj) >= f^2 - (1 - y) * (f_min^2 - w * pd_min) - (1 - zp) * abs(w * pd_min)))
        _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@constraint(gm.model, w * (pi - pj) <= f^2 + (1 - zp) * w * pd_max))
        _add_constraint!(gm, n, :weymouth_ne3, k, JuMP.@constraint(gm.model, w * (pj - pi) >= f^2 - y * (f_max^2 + w * pd_max) - (1 - zp) * abs(w * pd_max)))
        _add_constraint!(gm, n, :weymouth_ne4, k, JuMP.@constraint(gm.model, w * (pj - pi) <= f^2 - (1 - zp) * w * pd_min))
    end
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, min_ratio, max_ratio)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    r = var(gm, n, :rsqr, k)
    y = var(gm, n, :y_compressor, k)

    if type == 0
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@constraint(gm.model, r * pi <= pj + (1 - y) * i_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@constraint(gm.model, r * pi >= pj - (1 - y) * j_pmax^2))
        _add_constraint!(gm, n, :compressor_ratio_value3, k, JuMP.@constraint(gm.model, r * pj <= pi + y * j_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value4, k, JuMP.@constraint(gm.model, r * pj >= pi - y * i_pmax^2))
    else
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@constraint(gm.model, r * pi <= pj))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@constraint(gm.model, r * pi >= pj))
    end
end


"Constraint: Constraints which define pressure drop across a loss resistor"
function constraint_loss_resistor_pressure(gm::AbstractDWPModel, n::Int, k::Int, i::Int, j::Int, pd::Float64)
    f = var(gm, n, :f_loss_resistor, k)
    y = var(gm, n, :y_loss_resistor, k)
    p_i, p_j = var(gm, n, :p, i), var(gm, n, :p, j)
    p_i_sqr, p_j_sqr = var(gm, n, :psqr, i), var(gm, n, :psqr, j)

    c_1 = JuMP.@constraint(gm.model, (2.0 * y - 1.0) * pd == p_i - p_j)
    _add_constraint!(gm, n, :pressure_drop_1, k, c_1)
    c_2 = JuMP.@constraint(gm.model, p_i^2 == p_i_sqr)
    _add_constraint!(gm, n, :pressure_drop_2, k, c_2)
    c_3 = JuMP.@constraint(gm.model, p_j^2 == p_j_sqr)
    _add_constraint!(gm, n, :pressure_drop_3, k, c_3)
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value_ne(gm::AbstractDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, min_ratio, max_ratio)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    r = var(gm, n, :rsqr_ne, k)
    y = var(gm, n, :y_ne_compressor, k)
    z = var(gm, n, :zc, k)

    if type == 0
        _add_constraint!(gm, n, :compressor_ratio_value_ne1, k, JuMP.@constraint(gm.model, r * pi <= pj + (2 - y - z) * i_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value_ne2, k, JuMP.@constraint(gm.model, r * pi >= pj - (2 - y - z) * j_pmax^2))
        _add_constraint!(gm, n, :compressor_ratio_value_ne3, k, JuMP.@constraint(gm.model, r * pj <= pi + (1 + y - z) * j_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value_ne4, k, JuMP.@constraint(gm.model, r * pj >= pi - (1 + y - z) * i_pmax^2))
    else
        _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@constraint(gm.model, r * pi <= pj + (1 - z) * i_pmax^2 * max_ratio^2))
        _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@constraint(gm.model, r * pi >= pj - (1 - z) * j_pmax^2))
    end
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractDWPModel, n::Int, k::Int, power_max, m, work, flow_max, ratio_max)
    r = var(gm, n, :rsqr, k)
    f = var(gm, n, :f_compressor, k)
    y = var(gm, n, :y_compressor, k)

    M = abs(flow_max) * abs(ratio_max^2^m - 1) # working in the space of r^2

    _add_constraint!(gm, n, :compressor_energy, k, JuMP.@NLconstraint(gm.model, f * (r^m - 1)  <= power_max / work + ((1-y) * M)))
    _add_constraint!(gm, n, :compressor_energy, k, JuMP.@NLconstraint(gm.model, -f * (r^m - 1) <= power_max / work + (y * M) ))
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractDWPModel, n::Int, k, power_max, m, work, flow_max, ratio_max)
    r = var(gm, n, :rsqr_ne, k)
    f = var(gm, n, :f_ne_compressor, k)
    y = var(gm, n, :y_ne_compressor, k)

    M = abs(flow_max) * abs(ratio_max^2^m - 1) # working in the space of r^2

    # f is zero when the compressor is not built, so constraint is always true then
    _add_constraint!(gm, n, :ne_compressor_energy, k, JuMP.@NLconstraint(gm.model, f * (r^m - 1)  <= power_max / work + ((1-y) * M)))
    _add_constraint!(gm, n, :ne_compressor_energy, k, JuMP.@NLconstraint(gm.model, -f * (r^m - 1) <= power_max / work + (y * M) ))
end
