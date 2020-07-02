# Define MISOCP implementations of Gas Models

"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_pressure_difference(gm, nw; bounded=bounded, report=report)
    variable_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_connection_direction(gm, nw; report=report)
end


"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_pressure_difference_ne(gm, nw; bounded=bounded, report=report)
    variable_mass_flow_ne(gm, nw; bounded=bounded, report=report)
    variable_connection_direction_ne(gm, nw; report=report)
end


"Variables needed for modeling pipe difference in the lifted MISOCP space"
function variable_pipe_pressure_difference(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    l_pipe = gm.var[:nw][nw][:l_pipe] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:pipe])],
        base_name="$(nw)_l_pipe",
        start=comp_start_value(gm.ref[:nw][nw][:pipe], i, "l_start", 0)
    )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(l_pipe[i], 0.0)
            JuMP.set_upper_bound(l_pipe[i], max(abs(ref(gm, nw, :pipe, i)["pd_sqr_min"]), abs(ref(gm, nw, :pipe, i)["pd_sqr_max"])))
        end
    end

    report && _IM.sol_component_value(gm, nw, :pipe, :l, ids(gm, nw, :pipe), l_pipe)
end

""
function variable_resistor_pressure_difference(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    l_resistor = gm.var[:nw][nw][:l_resistor] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:resistor])],
        base_name="$(nw)_l_resistor",
        start=comp_start_value(gm.ref[:nw][nw][:resistor], i, "l_start", 0)
    )

    if bounded
        for (i, resistor) in ref(gm, nw, :resistor)
            JuMP.set_lower_bound(l_resistor[i], 0.0)
            JuMP.set_upper_bound(l_resistor[i], max(abs(ref(gm, nw, :resistor, i)["pd_sqr_min"]), abs(ref(gm, nw, :resistor, i)["pd_sqr_max"])))
        end
    end

    report && _IM.sol_component_value(gm, nw, :resistor, :l, ids(gm, nw, :resistor), l_resistor)
end

""
function variable_pressure_difference(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_pipe_pressure_difference(gm, nw; bounded=bounded, report=report)
    variable_resistor_pressure_difference(gm, nw; bounded=bounded, report=report)
end


""
function variable_pressure_difference_ne(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    max_flow = ref(gm, nw, :max_mass_flow)

    l_ne_pipe = gm.var[:nw][nw][:l_ne_pipe] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:ne_pipe])],
        base_name="$(nw)_l_ne_pipe",
        start=comp_start_value(gm.ref[:nw][nw][:ne_pipe], i, "l_start", 0)
    )

    if bounded
        for (i, ne_pipe) in ref(gm, nw, :ne_pipe)
            pd_abs_max = max(abs(ref(gm, nw, :ne_pipe, i)["pd_sqr_min_off"]), abs(ref(gm, nw, :ne_pipe, i)["pd_sqr_max_off"]))
            ub = min(pd_abs_max, inv(ref(gm, nw, :ne_pipe, i)["resistance"]) * max_flow^2)
            JuMP.set_lower_bound(l_ne_pipe[i], 0.0)
            JuMP.set_upper_bound(l_ne_pipe[i], ub)
        end
    end

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :l, ids(gm, nw, :ne_pipe), l_ne_pipe)
end


"Weymouth equation for a pipe"
function constraint_pipe_weymouth(gm::AbstractMISOCPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y  = var(gm, n, :y_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    l  = var(gm, n, :l_pipe, k)
    f  = var(gm, n, :f_pipe, k)


    # constraints weymouth1 - weymouth4 are designed to enforce constraint l == abs(pi-pj)
    # constraints weymouth1 and weymouth2 make sure that l >= max(pi-pj,pj-pi) (one is always <=0)

    # weymouth3
    # when y = 1, 0 <= l <= pd_max and -pd_max <= pj - pi <= 0
    # we have l <= pj - pi + 2 * pd_max. Since pj - pi is negative up to -pd_max, if we add at least pd_max,
    # then the rhs is guarenteed to be >= 0. If we add another pd_max, we increase the rhs to be >= pd_max,
    # the upperbound on l and the constraint is deactived
    # when y = 0 we have  l <= pi - pj, activated the constraint and making l == pj - pi because of weymouth1

    # weymouth4
    # when y = 0, 0 <= l <= -pd_min and pd_min <= pi - pj <= 0
    # we have l <= pi - pj - 2*pd_min. Since pi - pj is negative up to pd_min, if we add at least -pd_min,
    # then the rhs is guarenteed to be >= 0. If we add another -pd_min, we increase the rhs to be >= -pd_min,
    # the upperbound on l and the constraint is deactived
    # when y = 1 we have  l <= pi - pj, activating the constraint and making l == pi - pj because of weymouth2

    # weymouth6
    # when y = 1, f is >= 0 and we have w*l <= f_max * f, which keeps l below the line between (0,0) and (f_max,f_max^2)
    # when y = 0, f_min <= f <= 0 and 0 <= w*l <= f_min^2. We have w*l <= f_max * f + abs(f_min*f_max) + f_min^2.
    # Since abs(f_min*f_max) >= abs(f_max,f), this makes the rhs >= 0. Since w*l <= f_min^2, adding another f_min^2
    # deactives the constraint

    # weymouth7
    # when y = 0, f <= 0, f_min is <= 0 and we have w*l <= f_min * f, which keeps l below the line between (0,0) and (-f_min,f_min^2)
    # when y = 1, -f_max <= f <= 0 and 0 <= w*l <= f_max^2. We have w*l <= f_min * f + abs(f_min*f_max) + f_max^2.
    # Since abs(f_min*f_max) >= abs(f_min,f), this makes the rhs >= 0. Since w*l <= f_max^2, adding another f_max^2
    # deactives the constraint

   _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, l >= pj - pi))
   _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, l >= pi - pj))
   _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
   _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
   _add_constraint!(gm, n, :weymouth5, k, JuMP.@constraint(gm.model, w*l >= f^2))

   _add_constraint!(gm, n, :weymouth6, k, JuMP.@constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2)))
   _add_constraint!(gm, n, :weymouth7, k, JuMP.@constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2)))
end


"Weymouth equation for a pipe"
function constraint_resistor_weymouth(gm::AbstractMISOCPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_resistor, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    l  = var(gm, n, :l_resistor, k)
    f  = var(gm, n, :f_resistor, k)

    # constraints weymouth1 - weymouth4 are designed to enforce constraint l == abs(pi-pj)
    # constraints weymouth1 and weymouth2 make sure that l >= max(pi-pj,pj-pi) (one is always <=0)

    # weymouth3
    # when y = 1, 0 <= l <= pd_max and -pd_max <= pj - pi <= 0
    # we have l <= pj - pi + 2 * pd_max. Since pj - pi is negative up to -pd_max, if we add at least pd_max,
    # then the rhs is guarenteed to be >= 0. If we add another pd_max, we increase the rhs to be >= pd_max,
    # the upperbound on l and the constraint is deactived
    # when y = 0 we have  l <= pi - pj, activated the constraint and making l == pj - pi because of weymouth1

    # weymouth4
    # when y = 0, 0 <= l <= -pd_min and pd_min <= pi - pj <= 0
    # we have l <= pi - pj - 2*pd_min. Since pi - pj is negative up to pd_min, if we add at least -pd_min,
    # then the rhs is guarenteed to be >= 0. If we add another -pd_min, we increase the rhs to be >= -pd_min,
    # the upperbound on l and the constraint is deactived
    # when y = 1 we have  l <= pi - pj, activating the constraint and making l == pi - pj because of weymouth2

    # weymouth6
    # when y = 1, f is >= 0 and we have w*l <= f_max * f, which keeps l below the line between (0,0) and (f_max,f_max^2)
    # when y = 0, f_min <= f <= 0 and 0 <= w*l <= f_min^2. We have w*l <= f_max * f + abs(f_min*f_max) + f_min^2.
    # Since abs(f_min*f_max) >= abs(f_max,f), this makes the rhs >= 0. Since w*l <= f_min^2, adding another f_min^2
    # deactives the constraint

    # weymouth7
    # when y = 0, f <= 0, f_min is <= 0 and we have w*l <= f_min * f, which keeps l below the line between (0,0) and (-f_min,f_min^2)
    # when y = 1, -f_max <= f <= 0 and 0 <= w*l <= f_max^2. We have w*l <= f_min * f + abs(f_min*f_max) + f_max^2.
    # Since abs(f_min*f_max) >= abs(f_min,f), this makes the rhs >= 0. Since w*l <= f_max^2, adding another f_max^2
    # deactives the constraint

   _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, l >= pj - pi))
   _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, l >= pi - pj))
   _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
   _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
   _add_constraint!(gm, n, :weymouth5, k, JuMP.@constraint(gm.model, l >= f^2/w))

   _add_constraint!(gm, n, :weymouth6, k, JuMP.@constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2)))
   _add_constraint!(gm, n, :weymouth7, k, JuMP.@constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2)))
end


"Weymouth equation for an expansion pipe"
function constraint_pipe_weymouth_ne(gm::AbstractMISOCPModel, n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    y  = var(gm, n, :y_ne_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zp = var(gm, n, :zp, k)
    l  = var(gm, n, :l_ne_pipe, k)
    f  = var(gm, n, :f_ne_pipe, k)

    pd_M = max(abs(pd_min),abs(pd_max))

    # weymouth1-4 same as constraint_pipe_weymouth and make l = abs(pi-pj)

    # weymount6
    # when zp = 1, constraint is active and the same as constraint_pipe_weymouth
    # when zp = 0, f = 0. So we have w*l <= (1-y) * (abs(f_min*f_max) + f_min^2) +  w * pd_M.
    # Since the first term is nonnegative, all we need to is add in the largest value of w*l,
    # which is w * max(abs(pd_min),abs(pd_max))

    # weymount7
    # when zp = 1, constraint is active and the same as constraint_pipe_weymouth
    # when zp = 0, f = 0. So we have w*l <= y * (abs(f_min*f_max) + f_max^2) +  w * pd_M.
    # Since the first term is nonnegative, all we need to is add in the largest value of w*l,
    # which is w * max(abs(pd_min),abs(pd_max))

    _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, l >= pj - pi))
    _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@constraint(gm.model, l >= pi - pj))
    _add_constraint!(gm, n, :weymouth_ne3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
    _add_constraint!(gm, n, :weymouth_ne4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
    _add_constraint!(gm, n, :weymouth_ne5, k, JuMP.@constraint(gm.model, zp*w*l >= f^2))

    _add_constraint!(gm, n, :weymouth_ne6, k, JuMP.@constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2) + (1-zp) * w * pd_M))
    _add_constraint!(gm, n, :weymouth_ne7, k, JuMP.@constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2) + (1-zp) * w * pd_M))
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractMISOCPModel, n::Int, k, i, j)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r     = var(gm, n, :rsqr, k)

    _IM.relaxation_product(gm.model, pi, r, pj)
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractMISOCPModel, n::Int, k, power_max, work)
end
