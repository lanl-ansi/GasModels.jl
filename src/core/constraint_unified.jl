"Constraint: standard flow balance equation where demand and production are variables"
function constraint_junction_flow_balance(gm::AbstractGasModel, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, fl_constant, fg_constant, deliveries, receipts, transfers, storages, flmin, flmax, fgmin, fgmax)
    f_pipe = var(gm, n, :f_pipe)
    f_compressor = var(gm, n, :f_compressor)
    fg = var(gm, n, :injection_receipt)
    fl = var(gm, n, :withdrawal_delivery)
    ft = var(gm, n, :withdrawal_transfer)
    fs = var(gm, n, :withdrawal_storage)

    cstr_mfb = _add_constraint!(gm, n, :junction_mass_flow_balance, i, JuMP.@constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in receipts) - sum(fl[a] for a in deliveries) - sum(ft[a] for a in transfers) - sum(fs[a] for a in storages) ==
                                                                            sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                            sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) 
                                                                        ))
    if _IM.report_duals(gm)
        sol(gm, n)[:junction][i][:lam_junction_mfb] = cstr_mfb
    end
end

"Constraint: pin potential to a specific value "
function constraint_slack_potential(gm::AbstractGasModel, n::Int, i, val)
    potential = var(gm, n, :potential, i)
    _add_constraint!(gm, n, :slack_potential, i, JuMP.@constraint(gm.model, potential == val))
end

"Weymouth equation with absolute value"
function constraint_pipe_physics(gm::AbstractWPModel, n::Int, k, i, j, resistance)
    potential_i = var(gm, n, :potential, i)
    potential_j = var(gm, n, :potential, j)
    f = var(gm, n, :f_pipe, k)
    _add_constraint!(gm, n, :pipe_physics, k, JuMP.@constraint(gm.model, (potential_j - potential_i) == resistance * f * abs(f)))
end

"enforces potential changes bounds that obey compression ratios"
function constraint_compressor_physics_unified(gm::AbstractWPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
    potential_i = var(gm, n, :potential, i)
    potential_j = var(gm, n, :potential, j)
    f = var(gm, n, :f_compressor, k)
    g = x -> 0.9 * x^2 + 0.1 * x^3

    # compression in both directions
    if type == 0
        potential_k = var(gm, n, :potential_compressor, k)
        _add_constraint!(gm, n, :compressor_ratios_forward_lb, k, JuMP.@constraint(gm.model, potential_k >= potential_i))
        _add_constraint!(gm, n, :compressor_ratios_forward_ub, k, JuMP.@constraint(gm.model, potential_k <= g(max_ratio) * potential_i))
        _add_constraint!(gm, n, :compressor_ratios_backward_lb, k, JuMP.@constraint(gm.model, potential_k >= potential_j))
        _add_constraint!(gm, n, :compressor_ratios_backward_ub, k, JuMP.@constraint(gm.model, potential_k <= g(max_ratio) * potential_j))
        _add_constraint!(gm, n, :compressor_ratios_forward_flow, k, JuMP.@constraint(gm.model, f * (potential_k - potential_i) >= 0))
        _add_constraint!(gm, n, :compressor_ratios_backward_flow, k, JuMP.@constraint(gm.model, f * (potential_j - potential_k) <= 0))
        # compression when flow is from i to j.  No flow in reverse, so nothing to model in that direction
    elseif type == 1
        _add_constraint!(gm, n, :compressor_ratios_lb, k, JuMP.@constraint(gm.model, potential_j >= potential_i))
        _add_constraint!(gm, n, :compressor_ratios_ub, k, JuMP.@constraint(gm.model, potential_j <= g(max_ratio) * potential_i))
        # compression when flow is from i to j.  no compression when flow is from j to i. min_ratio = 1
    else # type 2
        _add_constraint!(gm, n, :compressor_ratios_lb, k, JuMP.@constraint(gm.model, potential_j >= potential_i))
        _add_constraint!(gm, n, :compressor_ratios_ub, k, JuMP.@constraint(gm.model, potential_j <= g(max_ratio) * potential_i))
        _add_constraint!(gm, n, :compressor_ratios_direction, k, JuMP.@constraint(gm.model, f * (potential_j - potential_i) >= 0))
    end
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_power_unified(gm::AbstractWPModel, n::Int, i, j, k, power_max, mul_constant, exponent, type)
    potential_i = var(gm, n, :potential, i)
    potential_j = var(gm, n, :potential, j)
    f = var(gm, n, :f_compressor, k)
    # drawing a secant between 1 and 1.4 and moving it up to 1.2 to make it an inner approxation of (r^exponent -1)
    g = x -> x^(0.5 * exponent) - 1 # potential space
    slope = (g(1.96) - g(1)) / (1.96 - 1)
    unshifted_secant = x -> slope * (x - 1)
    shift = g(1.44) - unshifted_secant(1.44)
    m = round(slope; digits=6)
    delta = round(shift; digits=6)

    if type == 0 
        potential_k = var(gm, n, :potential_compressor, k)
        _add_constraint!(gm, n, :compressor_power_forward, k, 
            JuMP.@constraint(gm.model, mul_constant * f * (m * (potential_k - potential_i) + delta * potential_i) <= power_max * potential_i))
        _add_constraint!(gm, n, :compressor_power_backward, k, 
            JuMP.@constraint(gm.model, mul_constant * f * (m * (potential_k - potential_j) + delta * potential_j) <= power_max * potential_j))
    else 
        _add_constraint!(gm, n, :compressor_power_backward, k, 
            JuMP.@constraint(gm.model, mul_constant * f * (m * (potential_j - potential_i) + delta * potential_i) <= power_max * potential_i))
    end 
end