# Define CRDWP implementations of Gas Models

"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractCRDWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_pressure_difference(gm, nw; bounded = bounded, report = report)
    variable_mass_flow(gm, nw; bounded = bounded, report = report)
    variable_connection_direction(gm, nw; report = report)
end


"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::AbstractCRDWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_pressure_difference_ne(gm, nw; bounded = bounded, report = report)
    variable_mass_flow_ne(gm, nw; bounded = bounded, report = report)
    variable_connection_direction_ne(gm, nw; report = report)
end

"Variable Set: Define variables needed for modeling flow across storage"
function variable_storage(gm::AbstractCRDWPModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    variable_storage_mass_flow(gm,nw,bounded=bounded,report=report)
    variable_storage_pressure_difference(gm, nw; bounded = bounded, report = report)
    variable_storage_direction(gm,nw,report=report)
end

"Variables needed for modeling pipe difference in the lifted CRDWP space"
function variable_pipe_pressure_difference(gm::AbstractCRDWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    l_pipe = var(gm, nw)[:l_pipe] = JuMP.@variable(
            gm.model,
            [k in ids(gm, nw, :pipe)],
            base_name = "$(nw)_l_pipe",
            start = comp_start_value(ref(gm, nw, :pipe), k, "l_start", 0)
        )

    if bounded
        for (k, pipe) in ref(gm, nw, :pipe)
            i = pipe["fr_junction"]
            j = pipe["to_junction"]
            pd_min, pd_max = _calc_pipe_pd_bounds_sqr(pipe, ref(gm, nw, :junction, i), ref(gm, nw, :junction, j))

            JuMP.set_lower_bound(l_pipe[k], 0.0)
            JuMP.set_upper_bound(l_pipe[k], max(abs(pd_min), abs(pd_max)))
        end
    end

    report && sol_component_value(gm, nw, :pipe, :l, ids(gm, nw, :pipe), l_pipe)
end

""
function variable_resistor_pressure_difference(gm::AbstractCRDWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    l_resistor = var(gm, nw)[:l_resistor] = JuMP.@variable(
            gm.model,
            [k in ids(gm, nw, :resistor)],
            base_name = "$(nw)_l_resistor",
            start = comp_start_value(ref(gm, nw, :resistor), k, "l_start", 0)
        )

    if bounded
        for (k, resistor) in ref(gm, nw, :resistor)
            i                = resistor["fr_junction"]
            j                = resistor["to_junction"]
            pd_min, pd_max   = _calc_resistor_pd_bounds(resistor, ref(gm, nw, :junction, i), ref(gm, nw, :junction, j))
            JuMP.set_lower_bound(l_resistor[k], 0.0)
            JuMP.set_upper_bound(l_resistor[k], max(abs(pd_min), abs(pd_max)))
        end
    end

    report &&
        sol_component_value(gm, nw, :resistor, :l, ids(gm, nw, :resistor), l_resistor)
end

""
function variable_pressure_difference(gm::AbstractCRDWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_pipe_pressure_difference(gm, nw; bounded = bounded, report = report)
    variable_resistor_pressure_difference(gm, nw; bounded = bounded, report = report)
end


""
function variable_pressure_difference_ne(gm::AbstractCRDWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    max_flow = ref(gm, nw, :max_mass_flow)

    l_ne_pipe = var(gm, nw)[:l_ne_pipe] = JuMP.@variable(
            gm.model,
            [k in keys(ref(gm, nw, :ne_pipe))],
            base_name = "$(nw)_l_ne_pipe",
            start = comp_start_value(ref(gm, nw, :ne_pipe), k, "l_start", 0)
        )

    if bounded
        for (k, ne_pipe) in ref(gm, nw, :ne_pipe)
            pd_min_on, pd_max_on, pd_min_off, pd_max_off = _calc_ne_pipe_pd_bounds_sqr(ne_pipe, ref(gm, nw, :junction, ne_pipe["fr_junction"]), ref(gm, nw, :junction, ne_pipe["to_junction"]))
            pd_abs_max = max(abs(pd_min_off), abs(pd_max_off))
            JuMP.set_lower_bound(l_ne_pipe[k], 0.0)
            JuMP.set_upper_bound(l_ne_pipe[k], pd_abs_max)
        end
    end

    report &&
        sol_component_value(gm, nw, :ne_pipe, :l, ids(gm, nw, :ne_pipe), l_ne_pipe)
end

"Variables needed for modeling storage pressure difference in the lifted CRDWP space"
function variable_storage_pressure_difference(gm::AbstractCRDWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    l_storage = var(gm, nw)[:l_storage] = JuMP.@variable(
            gm.model,
            [k in ids(gm, nw, :storage)],
            base_name = "$(nw)_l_storage",
            start = comp_start_value(ref(gm, nw, :storage), k, "l_storage", 0)
        )

    if bounded
        for (k, storage) in ref(gm, nw, :storage)
            j      = storage["junction_id"]
            pi     = storage["initial_pressure"]^2
            j_pmin = ref(gm, nw, :junction)[j]["p_min"]^2
            j_pmax = ref(gm, nw, :junction)[j]["p_max"]^2
            pd_max = pi - j_pmin
            pd_min = -(j_pmax-pi)

            JuMP.set_lower_bound(l_storage[k], 0.0)
            JuMP.set_upper_bound(l_storage[k], max(abs(pd_min), abs(pd_max)))
        end
    end

    report && sol_component_value(gm, nw, :storage, :l_storage, ids(gm, nw, :storage), l_storage)
end

"Weymouth equation for a pipe"
function constraint_pipe_weymouth(gm::AbstractCRDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    l = var(gm, n, :l_pipe, k)
    f = var(gm, n, :f_pipe, k)

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
    _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max * (2 * y)))
    _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min * (2 * y - 2)))
    _add_constraint!(gm, n, :weymouth5, k, JuMP.@constraint(gm.model, w * l >= f^2))

    _add_constraint!(gm, n, :weymouth6, k, JuMP.@constraint(gm.model, w * l <= f_max * f + (1 - y) * (abs(f_min * f_max) + f_min^2)))
    _add_constraint!(gm, n, :weymouth7, k, JuMP.@constraint(gm.model, w * l <= f_min * f + y * (abs(f_min * f_max) + f_max^2)))
end


"Weymouth equation for a pipe"
function constraint_resistor_darcy_weisbach(gm::AbstractCRDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    f, y = var(gm, n, :f_resistor, k), var(gm, n, :y_resistor, k)
    p_i, p_j = var(gm, n, :p, i), var(gm, n, :p, j)
    l = var(gm, n, :l_resistor, k)

   _add_constraint!(gm, n, :darcy_weisbach_1, k, JuMP.@constraint(gm.model, l >= p_j - p_i))
   _add_constraint!(gm, n, :darcy_weisbach_2, k, JuMP.@constraint(gm.model, l >= p_i - p_j))
   _add_constraint!(gm, n, :darcy_weisbach_3, k, JuMP.@constraint(gm.model, l <= p_j - p_i + pd_max*(2.0 * y)))
   _add_constraint!(gm, n, :darcy_weisbach_4, k, JuMP.@constraint(gm.model, l <= p_i - p_j + pd_min*(2.0 * y - 2.0)))
   _add_constraint!(gm, n, :darcy_weisbach_5, k, JuMP.@constraint(gm.model, (1.0/w)*l >= f^2))
   _add_constraint!(gm, n, :darcy_weisbach_6, k, JuMP.@constraint(gm.model, (1.0/w)*l <= f_max * f + (1.0 - y) * (abs(f_min*f_max) + f_min^2)))
   _add_constraint!(gm, n, :darcy_weisbach_7, k, JuMP.@constraint(gm.model, (1.0/w)*l <= f_min * f + y * (abs(f_min*f_max) + f_max^2)))
end


"Constraint: Define pressures across a resistor"
function constraint_resistor_pressure(gm::AbstractCRDWPModel, n::Int, k::Int, i::Int, j::Int, pd_min::Float64, pd_max::Float64)
    p_i, p_j = var(gm, n, :p, i), var(gm, n, :p, j)
    p_i_sqr, p_j_sqr = var(gm, n, :psqr, i), var(gm, n, :psqr, j)
    y = var(gm, n, :y_resistor, k)

    c_1 = JuMP.@constraint(gm.model, p_i^2 <= p_i_sqr)
    _add_constraint!(gm, n, :pressure_drop_1, k, c_1)
    c_2 = JuMP.@constraint(gm.model, p_j^2 <= p_j_sqr)
    _add_constraint!(gm, n, :pressure_drop_2, k, c_2)
    c_3 = JuMP.@constraint(gm.model, (1.0 - y) * pd_min <= p_i - p_j)
    _add_constraint!(gm, n, :on_off_pressure_drop_1, k, c_3)
    c_4 = JuMP.@constraint(gm.model, p_i - p_j <= y * pd_max)
    _add_constraint!(gm, n, :on_off_pressure_drop_2, k, c_4)
end


"Weymouth equation for an expansion pipe"
function constraint_pipe_weymouth_ne(gm::AbstractCRDWPModel, n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    y = var(gm, n, :y_ne_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zp = var(gm, n, :zp, k)
    l = var(gm, n, :l_ne_pipe, k)
    f = var(gm, n, :f_ne_pipe, k)

    pd_M = max(abs(pd_min), abs(pd_max))

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
    _add_constraint!(gm, n, :weymouth_ne3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max * (2 * y)))
    _add_constraint!(gm, n, :weymouth_ne4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min * (2 * y - 2)))
    _add_constraint!(gm, n, :weymouth_ne5, k, JuMP.@constraint(gm.model, zp * w * l >= f^2))

    _add_constraint!(gm, n, :weymouth_ne6, k, JuMP.@constraint(gm.model, w * l <= f_max * f + (1 - y) * (abs(f_min * f_max) + f_min^2) + (1 - zp) * w * pd_M))
    _add_constraint!(gm, n, :weymouth_ne7, k, JuMP.@constraint(gm.model, w * l <= f_min * f + y * (abs(f_min * f_max) + f_max^2) + (1 - zp) * w * pd_M))
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractCRDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, max_ratio)
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


"Constraint: Constraints which define pressure drop across a loss resistor"
function constraint_loss_resistor_pressure(gm::AbstractCRDWPModel, n::Int, k::Int, i::Int, j::Int, pd::Float64)
    f = var(gm, n, :f_loss_resistor, k)
    y = var(gm, n, :y_loss_resistor, k)
    p_i, p_j = var(gm, n, :p, i), var(gm, n, :p, j)
    p_i_sqr, p_j_sqr = var(gm, n, :psqr, i), var(gm, n, :psqr, j)

    c_1 = JuMP.@constraint(gm.model, (2.0 * y - 1.0) * pd == p_i - p_j)
    _add_constraint!(gm, n, :pressure_drop_1, k, c_1)
    c_2 = JuMP.@constraint(gm.model, p_i^2 <= p_i_sqr)
    _add_constraint!(gm, n, :pressure_drop_2, k, c_2)
    c_3 = JuMP.@constraint(gm.model, p_j^2 <= p_j_sqr)
    _add_constraint!(gm, n, :pressure_drop_3, k, c_3)
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value_ne(gm::AbstractCRDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, max_ratio)
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
function constraint_compressor_energy(gm::AbstractCRDWPModel, n::Int, k, power_max, m, work)
    #TODO - convex relaxation
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractCRDWPModel, n::Int, k, power_max, m, work) end

"Enforces pressure changes bounds that obey (de)compression ratios depending on direction of flow for a well.
k is the well head
j is the compressor
i is the well bottom
"
function constraint_well_compressor_ratios(gm::AbstractCRDWPModel, n::Int, i, k, min_ratio, max_ratio, initial_pressure, k_pmin, k_pmax, w, j_pmin, j_pmax, f_min, f_max)
    pi     = initial_pressure^2
    i_pmax = initial_pressure^2
    pk     = var(gm, n, :psqr, k)
    pj     = var(gm, n, :well_intermediate_pressure, i)
    fs     = var(gm, n, :well_head_flow, i)
    y      = var(gm, n, :y_storage, i)
    l      = var(gm, n, :l_storage, i)
    pd_max = pi - j_pmin^2
    pd_min = -(j_pmax^2-pi)

    if (min_ratio == 1.0/max_ratio)
        _add_constraint!(gm, n, :well_compressor_ratio1, i, JuMP.@constraint(gm.model, pk <= max_ratio^2 * pj))
        _add_constraint!(gm, n, :well_compressor_ratio2, i, JuMP.@constraint(gm.model, min_ratio^2 * pj <= pk))
    else
        _add_constraint!(gm, n, :well_compressor_ratios1, i, JuMP.@constraint(gm.model, pk - max_ratio^2 * pj <= (1 - y) * (k_pmax^2)))
        _add_constraint!(gm, n, :well_compressor_ratios2, i, JuMP.@constraint(gm.model, min_ratio^2 * pj - pk <= (1 - y) * (min_ratio^2 * j_pmax^2)))
        _add_constraint!(gm, n, :well_compressor_ratios3, i, JuMP.@constraint(gm.model, pj - max_ratio^2 * pk <= y * (j_pmax^2)))
        _add_constraint!(gm, n, :well_compressor_ratios4, i, JuMP.@constraint(gm.model, min_ratio^2 * pk - pj <= y * (min_ratio^2 * k_pmax^2)))
    end

    _add_constraint!(gm, n, :well_compressor_ratios10, i, JuMP.@constraint(gm.model, l >= pj - pi))
    _add_constraint!(gm, n, :well_compressor_ratios11, i, JuMP.@constraint(gm.model, l >= pi - pj))
    _add_constraint!(gm, n, :well_compressor_ratios12, i, JuMP.@constraint(gm.model, l <= pj - pi + pd_max * (2 * y)))
    _add_constraint!(gm, n, :well_compressor_ratios13, i, JuMP.@constraint(gm.model, l <= pi - pj + pd_min * (2 * y - 2)))
    _add_constraint!(gm, n, :well_compressor_ratios14, i, JuMP.@constraint(gm.model, w * l >= fs^2))

    _add_constraint!(gm, n, :well_compressor_ratios15, i, JuMP.@constraint(gm.model, w * l <= f_max * fs + (1 - y) * (abs(f_min * f_max) + f_min^2)))
    _add_constraint!(gm, n, :well_compressor_ratios16, i, JuMP.@constraint(gm.model, w * l <= f_min * fs + y * (abs(f_min * f_max) + f_max^2)))
end
