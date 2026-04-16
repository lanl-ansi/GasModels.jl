# Define LRDWP implementations of Gas Models
function variable_form_specific(gm::AbstractLRDWPModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    # pipe f^2 relaxation
    f_square_l_pipe = var(gm, nw)[:f_square_l_pipe] = JuMP.@variable(gm.model,
        [i in ids(gm, nw, :pipe)],
        base_name="$(nw)_f_square_l")
    report && sol_component_value(gm, nw, :pipe, :f_square_l, ids(gm, nw, :pipe), f_square_l_pipe)

    # resistor f^2 relaxation
    f_square_l_resistor = var(gm, nw)[:f_square_l_resistor] = JuMP.@variable(gm.model,
        [i in ids(gm, nw, :resistor)],
        base_name="$(nw)_f_square_l")
    report && sol_component_value(gm, nw, :resistor, :f_square_l, ids(gm, nw, :resistor), f_square_l_resistor)

end

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
    pipe = ref(gm, n, :pipe, k)
    y = var(gm, n, :y_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f = var(gm, n, :f_pipe, k)
    f2_l = var(gm, n, :f_square_l_pipe, k)

    if w == 0.0
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, pi - pj == 0.0))
    elseif f_min == f_max
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w * (pi - pj) == f_min*abs(f_min)))
    else
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w * (pi - pj) >= f2_l - (1 - y) * (f_min^2 - w * pd_min)))
        _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w * (pi - pj) <= f2_l))
        _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w * (pj - pi) >= f2_l - y * (f_max^2 + w * pd_max)))
        _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w * (pj - pi) <= f2_l))

        #univariate relaxdation for f^2
        partition = get_flow_partition(pipe, f_min, f_max)
        construct_univariate_relaxation!(gm.model, a -> a^2, f, f2_l, partition, true)
    end
end

"Constraint: Pressure drop for inclined pipe"
function constraint_inclined_pipe_pressure_drop(gm::AbstractLRDWPModel, n::Int, k, i, j, r_1, r_2, f_min, f_max, inc_pd_min, inc_pd_max)
    pipe = ref(gm, n, :pipe, k)
    y = var(gm, n, :y_pipe, k)
    pii = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f = var(gm, n, :f_pipe, k)
    f2_l = var(gm, n, :f_square_l_pipe, k)

    inc_pi = exp(r_2)* pii
    w = 1/(r_1 * (1 - exp(r_2)))

    if w == 0.0
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, (inc_pi - pj) == 0.0))
    elseif f_min == f_max
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w * (inc_pi - pj) == f_min*abs(f_min)))
    else
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w * (inc_pi - pj) >= f2_l - (1 - y) * (f_min^2 - w * pd_min)))
        _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w * (inc_pi - pj) <= f2_l))
        _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w * (pj - inc_pi) >= f2_l - y * (f_max^2 + w * pd_max)))
        _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w * (pj - inc_pi) <= f2_l))

        #univariate relaxdation for f^2
        partition = get_flow_partition(pipe, f_min, f_max)
        construct_univariate_relaxation!(gm.model, a -> a^2, f, f2_l, partition, true)
    end

end


"Constraint: Darcy-Weisbach equation--not applicable for LRDWP models"
function constraint_resistor_darcy_weisbach(gm::AbstractLRDWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    resistor = ref(gm, n, :resistor, k)
    f, y = var(gm, n, :f_resistor, k), var(gm, n, :y_resistor, k)
    p_i, p_j = var(gm, n, :p, i), var(gm, n, :p, j)
    f2_l = var(gm, n, :f_square_l_resistor, k)

    if w == 0.0
        _add_constraint!(gm, n, :darcy_weisbach1, k, JuMP.@constraint(gm.model, (p_i - p_j) == 0.0))
    elseif f_min == f_max
        _add_constraint!(gm, n, :darcy_weisbach1, k, JuMP.@constraint(gm.model, w * (p_i - p_j) == f_min*abs(f_min)))
    else
        _add_constraint!(gm, n, :darcy_weisbach_1, k, JuMP.@constraint(gm.model, (1.0/w)*(p_i - p_j) >= f2_l - (1.0 - y) * (f_min^2-(1.0/w)*pd_min)))
        _add_constraint!(gm, n, :darcy_weisbach_2, k, JuMP.@constraint(gm.model, (1.0/w)*(p_i - p_j) <= f2_l))
        _add_constraint!(gm, n, :darcy_weisbach_3, k, JuMP.@constraint(gm.model, (1.0/w)*(p_j - p_i) >= f2_l - y * (f_max^2+(1.0/w)*pd_max)))
        _add_constraint!(gm, n, :darcy_weisbach_4, k, JuMP.@constraint(gm.model, (1.0/w)*(p_j - p_i) <= f2_l))

        # f2_l incorporates the univariate relaxation for f^2
        partition = get_flow_partition(resistor, f_min, f_max)
        construct_univariate_relaxation!(gm.model, a -> a^2, f, f2_l, partition, true)
    end

end


"Constraint: Define pressures across a resistor"
function constraint_resistor_pressure(gm::AbstractLRDWPModel, n::Int, k::Int, i::Int, j::Int, pd_min::Float64, pd_max::Float64)
end


"Constraint: Constraints which define pressure drop across a loss resistor"
function constraint_loss_resistor_pressure(gm::AbstractLRDWPModel, n::Int, k::Int, i::Int, j::Int, pd::Float64) end


"Constraint: Weymouth equation"
function constraint_pipe_weymouth_ne(gm::AbstractLRDWPModel, n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    pipe = ref(gm, n, :ne_pipe, k)
    y = var(gm, n, :y_ne_pipe, k)

    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zp = var(gm, n, :zp, k)
    f = var(gm, n, :f_ne_pipe, k)

    f2_l = JuMP.@variable(gm.model)

    @assert f_min != f_max "Expansion modeling does not support this case yet"
    if w == 0.0
        _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, pi - pj <= (1 - zp) * pd_max))
        _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@constraint(gm.model, pi - pj >= (1 - zp) * pd_min))
    else
        _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, w * (pi - pj) >= f2_l - (1 - y) * (f_min^2 - w * pd_min) - (1 - zp) * abs(w * pd_min)))
        _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@constraint(gm.model, w * (pi - pj) <= f2_l + (1 - zp) * w * pd_max))
        _add_constraint!(gm, n, :weymouth_ne3, k, JuMP.@constraint(gm.model, w * (pj - pi) >= f2_l - y * (f_max^2 + w * pd_max) - (1 - zp) * abs(w * pd_max)))
        _add_constraint!(gm, n, :weymouth_ne4, k, JuMP.@constraint(gm.model, w * (pj - pi) <= f2_l - (1 - zp) * w * pd_min))

        # f2_l incorporates the univariate relaxation for f*(abs(f))
        partition = get_flow_partition(pipe, f_min, f_max)

        f2_max = (max(abs(f_min), abs(f_max)))^2
        _add_constraint!(gm, n, :weymouth_ne3, k, JuMP.@constraint(gm.model, f2_l <= zp * f2_max))
        _add_constraint!(gm, n, :weymouth_ne4, k, JuMP.@constraint(gm.model, f2_l >= 0))

        construct_univariate_relaxation!(gm.model, a -> a*(abs(a)), f, f2_l, partition, true)
    
    end


end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractLRDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, min_ratio, max_ratio)
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
function constraint_compressor_ratio_value_ne(gm::AbstractLRDWPModel, n::Int, k, i, j, type, i_pmax, j_pmax, min_ratio, max_ratio)
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
function constraint_compressor_energy(gm::AbstractLRDWPModel, n::Int, k, power_max, m, work, flow_max, ratio_max)
    r = var(gm, n, :rsqr, k)
    f = var(gm, n, :f_compressor, k)

    r_pow_m = JuMP.@variable(gm.model)
    f_r_pow_m = JuMP.@variable(gm.model)

    min_ratio = ref(gm, n, :compressor, k)["c_ratio_min"]
    max_ratio = ref(gm, n, :compressor, k)["c_ratio_max"]
    JuMP.set_lower_bound(r_pow_m, min_ratio^(2*m) - 1)
    JuMP.set_upper_bound(r_pow_m, max_ratio^(2*m) - 1)

    if min_ratio == max_ratio
        _add_constraint!(gm, n, :compressor_energy_1, k, JuMP.@constraint(gm.model, f*(min_ratio^m - 1) <= power_max / work))
        _add_constraint!(gm, n, :compressor_energy_2, k, JuMP.@constraint(gm.model, -f*(min_ratio^m - 1) <= power_max / work))
    else
        partition = [min_ratio^2,max_ratio^2];
        construct_univariate_relaxation!(gm.model, a -> (a^m)-1, r, r_pow_m, partition, false)
        _IM.relaxation_product(gm.model, f, r_pow_m, f_r_pow_m)

        _add_constraint!(gm, n, :compressor_energy_1, k, JuMP.@constraint(gm.model, f_r_pow_m <= power_max / work))
        _add_constraint!(gm, n, :compressor_energy_2, k, JuMP.@constraint(gm.model, -f_r_pow_m <= power_max / work))

        _add_constraint!(gm, n, :compressor_energy, k, JuMP.@constraint(gm.model, abs(f) * (r^m - 1) <= power_max / work))
    end
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractLRDWPModel, n::Int, k, power_max, m, work, flow_max, ratio_max)
        r = var(gm, n, :rsqr, k)
        f = var(gm, n, :f_compressor, k)

        r_pow_m = JuMP.@variable(gm.model)
        f_r_pow_m = JuMP.@variable(gm.model)

        min_ratio = ref(gm, n, :compressor, k)["c_ratio_min"]
        max_ratio = ref(gm, n, :compressor, k)["c_ratio_max"]
        JuMP.set_lower_bound(r_pow_m, min_ratio^(2*m) - 1)
        JuMP.set_upper_bound(r_pow_m, max_ratio^(2*m) - 1)

        if min_ratio == max_ratio
            _add_constraint!(gm, n, :compressor_energy_1, k, JuMP.@constraint(gm.model, f*(min_ratio^m - 1) <= power_max / work))
            _add_constraint!(gm, n, :compressor_energy_2, k, JuMP.@constraint(gm.model, -f*(min_ratio^m - 1) <= power_max / work))
        else
            partition = [min_ratio^2,max_ratio^2];
            construct_univariate_relaxation!(gm.model, a -> (a^m)-1, r, r_pow_m, partition, false)
            _IM.relaxation_product(gm.model, f, r_pow_m, f_r_pow_m)

            _add_constraint!(gm, n, :compressor_energy_1, k, JuMP.@constraint(gm.model, f_r_pow_m <= power_max / work))
            _add_constraint!(gm, n, :compressor_energy_2, k, JuMP.@constraint(gm.model, -f_r_pow_m <= power_max / work))

            _add_constraint!(gm, n, :compressor_energy, k, JuMP.@constraint(gm.model, abs(f) * (r^m - 1) <= power_max / work))
        end
end
