"""
Constraint generation for Inner Approximation optimization.

Uses matrix-based self-mapping with M and N decompositions:
    Δx = M·Δu + N·r(Δx, Δu)

where M = M^+ - M^- and N = N^+ - N^-.

Self-mapping sufficient conditions:
    ℓ_x^+ ≥ M^+·ℓ_u^+ + M^-·ℓ_u^- + N^+·r^+ - N^-·r^-
    ℓ_x^- ≥ M^+·ℓ_u^- + M^-·ℓ_u^+ - N^+·r^- + N^-·r^+
"""


"""
    build_ia_model(gm, n; optimizer=nothing, reversal_allowed=false)

Build the Inner Approximation optimization model.

Creates a JuMP model with:
- Decision variables: ℓ_x^+, ℓ_x^-, ℓ_u^+, ℓ_u^-
- Auxiliary variables: r^+, r^- (residual bounds)
- Self-mapping constraints (matrix-based)
- Physical feasibility constraints
- Objective: maximize polytope volume

# Arguments
- `gm::AbstractGasModel`: Gas model with fixed point attached
- `n::Int`: Network ID (default: 0)
- `optimizer`: JuMP optimizer (optional)
- `reversal_allowed::Bool`: Allow flow direction changes (default: false)
  * false: Tighter one-sided residual bounds, flow stays on same side of zero
  * true: Symmetric residual bounds, allows flow reversals

Returns: JuMP model
"""
function build_ia_model(
    gm::AbstractGasModel,
    n::Int=nw_id_default;
    optimizer=nothing,
    reversal_allowed::Bool=false
)
    @info "Building IA optimization model"

    # Compute coefficient matrices
    matrices = compute_ia_coefficient_matrices(gm, n)
    M_pos = matrices.M_pos
    M_neg = matrices.M_neg
    N_pos = matrices.N_pos
    N_neg = matrices.N_neg
    state_map = matrices.state_map
    input_map = matrices.input_map

    n_states = state_map[:dim]
    n_inputs = input_map[:dim]

    # Create JuMP model
    model = isnothing(optimizer) ? JuMP.Model() : JuMP.Model(optimizer)

    # Decision variables: state bounds
    JuMP.@variable(model, ℓ_x_plus[1:n_states] >= 0)
    JuMP.@variable(model, ℓ_x_minus[1:n_states] >= 0)

    # Decision variables: input bounds
    JuMP.@variable(model, ℓ_u_plus[1:n_inputs] >= 0)
    JuMP.@variable(model, ℓ_u_minus[1:n_inputs] >= 0)

    # Auxiliary variables: residual bounds
    JuMP.@variable(model, r_plus[1:n_states])
    JuMP.@variable(model, r_minus[1:n_states])

    @info "Variables created: $(n_states) states, $(n_inputs) inputs"

    # Add residual bound constraints
    _add_residual_bound_constraints!(
        model, gm, n, state_map, input_map,
        ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus,
        r_plus, r_minus;
        reversal_allowed=reversal_allowed
    )

    # Add self-mapping constraints
    _add_self_mapping_constraints!(
        model, M_pos, M_neg, N_pos, N_neg,
        ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus,
        r_plus, r_minus
    )

    # Add physical feasibility constraints
    _add_physical_bounds_constraints!(
        model, gm, n, state_map, input_map,
        ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus;
        reversal_allowed=reversal_allowed
    )

    # Add objective: maximize polytope volume
    _add_ia_objective!(
        model, n_states, n_inputs,
        ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus
    )

    @info "Model construction complete"
    return model
end


"""
Add residual bound constraints: r^- ≤ r(Δx, Δu) ≤ r^+

Uses two inequalities for max operations (as user requested).
"""
function _add_residual_bound_constraints!(
    model, gm, n, state_map, input_map,
    ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus,
    r_plus, r_minus;
    reversal_allowed::Bool=false
)
    @info "Adding residual bound constraints (reversal_allowed=$reversal_allowed)"
    row = 1

    # Weymouth residuals: γₑ(Δfₑ) = ωₑ(Δfₑ)²

    for k in sort(collect(keys(ref(gm, n, :pipe))))
        pipe = ref(gm, n, :pipe, k)
        f_star = _ia_fp_value(gm, n, :pipe, k, "f")
        w = _calc_pipe_resistance(
            pipe,
            gm.ref[:it][gm_it_sym][:base_length],
            gm.ref[:it][gm_it_sym][:base_pressure],
            gm.ref[:it][gm_it_sym][:base_flow],
            gm.ref[:it][gm_it_sym][:sound_speed]
        )
        ω = 1.0 / w

        flow_idx = state_map[:pipe_flow][k]

        if !reversal_allowed
            # Flow stays on same side of zero (enforced by physical bounds)
            if f_star > 0
                # Positive flow: r ∈ [0, ω·max(ℓ_f^-, ℓ_f^+)²]
                JuMP.@constraint(model, r_minus[row] == 0.0)
                # r^+ ≥ ω·(ℓ_f^-)² and r^+ ≥ ω·(ℓ_f^+)²
                JuMP.@constraint(model, r_plus[row] >= ω * ℓ_x_minus[flow_idx]^2)
                JuMP.@constraint(model, r_plus[row] >= ω * ℓ_x_plus[flow_idx]^2)
            else
                # Negative flow: r ∈ [-ω·max(ℓ_f^-, ℓ_f^+)², 0]
                JuMP.@constraint(model, r_plus[row] == 0.0)
                # -r^- ≥ ω·(ℓ_f^-)² and -r^- ≥ ω·(ℓ_f^+)²
                JuMP.@constraint(model, -r_minus[row] >= ω * ℓ_x_minus[flow_idx]^2)
                JuMP.@constraint(model, -r_minus[row] >= ω * ℓ_x_plus[flow_idx]^2)
            end
        else
            # Flow reversal allowed: use conservative symmetric bounds
            # Generic bound: r ∈ [-ω·max(ℓ²), +ω·max(ℓ²)]
            # This is conservative but valid for any flow direction
            # TODO: Implement tighter bounds from Section 1.4.2 of research document
            max_delta_f_sqr = max(ℓ_x_minus[flow_idx]^2, ℓ_x_plus[flow_idx]^2)
            max_residual = ω * max_delta_f_sqr

            JuMP.@constraint(model, r_minus[row] <= max_residual)
            JuMP.@constraint(model, r_plus[row] >= max_residual)
            JuMP.@constraint(model, -r_minus[row] <= max_residual)
            JuMP.@constraint(model, -r_plus[row] >= -max_residual)
        end
        row += 1
    end

    # Compressor residuals: ηc(Δα, Δπᵢ) = Δα·Δπᵢ (bilinear)
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        comp = ref(gm, n, :compressor, k)
        i = comp["fr_junction"]

        # Get ratio bounds
        if haskey(input_map[:compressor_ratio], k)
            ratio_idx = input_map[:compressor_ratio][k]
            ℓ_α_minus = ℓ_u_minus[ratio_idx]
            ℓ_α_plus = ℓ_u_plus[ratio_idx]
        else
            # No control: Δα = 0, residual = 0
            JuMP.@constraint(model, r_minus[row] == 0.0)
            JuMP.@constraint(model, r_plus[row] == 0.0)
            row += 1
            continue
        end

        # Get inlet pressure bounds
        pi_i_idx = get_state_index(state_map, :junction_psqr, i)
        if !isnothing(pi_i_idx)
            ℓ_π_minus = ℓ_x_minus[pi_i_idx]
            ℓ_π_plus = ℓ_x_plus[pi_i_idx]
        else
            # Inlet is slack: Δπᵢ = 0, residual = 0
            JuMP.@constraint(model, r_minus[row] == 0.0)
            JuMP.@constraint(model, r_plus[row] == 0.0)
            row += 1
            continue
        end

        # McCormick envelope: evaluate at 4 corners
        # r ∈ [min(corners), max(corners)]
        # Use constraints instead of evaluating corners directly

        # Lower bound: r^- ≤ all 4 corners
        JuMP.@constraint(model, r_minus[row] <= -ℓ_α_minus * (-ℓ_π_minus))
        JuMP.@constraint(model, r_minus[row] <= -ℓ_α_minus * ℓ_π_plus)
        JuMP.@constraint(model, r_minus[row] <= ℓ_α_plus * (-ℓ_π_minus))
        JuMP.@constraint(model, r_minus[row] <= ℓ_α_plus * ℓ_π_plus)

        # Upper bound: r^+ ≥ all 4 corners
        JuMP.@constraint(model, r_plus[row] >= -ℓ_α_minus * (-ℓ_π_minus))
        JuMP.@constraint(model, r_plus[row] >= -ℓ_α_minus * ℓ_π_plus)
        JuMP.@constraint(model, r_plus[row] >= ℓ_α_plus * (-ℓ_π_minus))
        JuMP.@constraint(model, r_plus[row] >= ℓ_α_plus * ℓ_π_plus)

        row += 1
    end

    # Mass balance residuals: always zero (linear equation, no approximation)
    # This applies to ALL junctions (both slack and non-slack)
    for k in sort(collect(keys(ref(gm, n, :junction))))
        JuMP.@constraint(model, r_minus[row] == 0.0)
        JuMP.@constraint(model, r_plus[row] == 0.0)
        row += 1
    end

    @info "Residual bound constraints added"
end


"""
Add self-mapping constraints using M and N matrices.

Upper bound: ℓ_x^+ ≥ M^+·ℓ_u^+ + M^-·ℓ_u^- + N^+·r^+ - N^-·r^-
Lower bound: ℓ_x^- ≥ M^+·ℓ_u^- + M^-·ℓ_u^+ - N^+·r^- + N^-·r^+
"""
function _add_self_mapping_constraints!(
    model, M_pos, M_neg, N_pos, N_neg,
    ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus,
    r_plus, r_minus
)
    @info "Adding self-mapping constraints"

    n_states = size(M_pos, 1)

    # Upper bound: ℓ_x^+ ≥ M^+·ℓ_u^+ + M^-·ℓ_u^- + N^+·r^+ - N^-·r^-
    for i in 1:n_states
        JuMP.@constraint(
            model,
            ℓ_x_plus[i] >=
                sum(M_pos[i, j] * ℓ_u_plus[j] for j in 1:length(ℓ_u_plus)) +
                sum(M_neg[i, j] * ℓ_u_minus[j] for j in 1:length(ℓ_u_minus)) +
                sum(N_pos[i, k] * r_plus[k] for k in 1:n_states) -
                sum(N_neg[i, k] * r_minus[k] for k in 1:n_states)
        )
    end

    # Lower bound: ℓ_x^- ≥ M^+·ℓ_u^- + M^-·ℓ_u^+ - N^+·r^- + N^-·r^+
    for i in 1:n_states
        JuMP.@constraint(
            model,
            ℓ_x_minus[i] >=
                sum(M_pos[i, j] * ℓ_u_minus[j] for j in 1:length(ℓ_u_minus)) +
                sum(M_neg[i, j] * ℓ_u_plus[j] for j in 1:length(ℓ_u_plus)) -
                sum(N_pos[i, k] * r_minus[k] for k in 1:n_states) +
                sum(N_neg[i, k] * r_plus[k] for k in 1:n_states)
        )
    end

    @info "Self-mapping constraints added"
end


"""
Add physical feasibility constraints.

Ensures state/input bounds respect physical limits:
- Pressure: within allowed range
- Flow: within capacity limits
- Compressor ratio: within operational bounds

# Arguments
- `reversal_allowed::Bool`: If false (default), adds constraints to keep flow
  on same side of zero. If true, allows flow direction changes.
"""
function _add_physical_bounds_constraints!(
    model, gm, n, state_map, input_map,
    ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus;
    reversal_allowed::Bool=false
)
    @info "Adding physical feasibility constraints (reversal_allowed=$reversal_allowed)"

    # Pipe flow bounds

    for k in sort(collect(keys(ref(gm, n, :pipe))))
        pipe = ref(gm, n, :pipe, k)
        f_star = _ia_fp_value(gm, n, :pipe, k, "f")
        flow_idx = state_map[:pipe_flow][k]

        # Physical limits from data
        f_min = pipe["flow_min"]
        f_max = pipe["flow_max"]

        if !reversal_allowed
            # No flow reversal: additional constraints to keep flow on same side of zero
            if f_star > 0
                # Flow must stay non-negative
                JuMP.@constraint(model, f_star - ℓ_x_minus[flow_idx] >= 0.0)
                # Upper bound from data
                JuMP.@constraint(model, f_star + ℓ_x_plus[flow_idx] <= f_max)
            elseif f_star < 0
                # Flow must stay non-positive
                JuMP.@constraint(model, f_star + ℓ_x_plus[flow_idx] <= 0.0)
                # Lower bound from data
                JuMP.@constraint(model, f_star - ℓ_x_minus[flow_idx] >= f_min)
            else
                # f_star = 0: This is ambiguous, for now just use data bounds
                # TODO: Handle f_star = 0 case properly when reversal_allowed is implemented
                JuMP.@constraint(model, f_star - ℓ_x_minus[flow_idx] >= f_min)
                JuMP.@constraint(model, f_star + ℓ_x_plus[flow_idx] <= f_max)
            end
        else
            # Flow reversal allowed: just use data bounds
            JuMP.@constraint(model, f_star - ℓ_x_minus[flow_idx] >= f_min)
            JuMP.@constraint(model, f_star + ℓ_x_plus[flow_idx] <= f_max)
        end
    end

    # Compressor flow bounds
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        comp = ref(gm, n, :compressor, k)
        f_star = _ia_fp_value(gm, n, :compressor, k, "f")
        flow_idx = state_map[:compressor_flow][k]

        f_min = comp["flow_min"]
        f_max = comp["flow_max"]

        JuMP.@constraint(model, f_star - ℓ_x_minus[flow_idx] >= f_min)
        JuMP.@constraint(model, f_star + ℓ_x_plus[flow_idx] <= f_max)
    end

    # Junction pressure bounds
    for k in sort(collect(keys(ref(gm, n, :junction))))
        junction = ref(gm, n, :junction, k)
        junction["junction_type"] == 1 && continue  # Skip slack

        pi_idx = state_map[:junction_psqr][k]
        pi_star = _ia_fp_value(gm, n, :junction, k, "psqr")

        p_min = junction["p_min"]
        p_max = junction["p_max"]
        pi_min = p_min^2
        pi_max = p_max^2

        JuMP.@constraint(model, pi_star - ℓ_x_minus[pi_idx] >= pi_min)
        JuMP.@constraint(model, pi_star + ℓ_x_plus[pi_idx] <= pi_max)
    end

    # Compressor ratio bounds
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        comp = ref(gm, n, :compressor, k)
        haskey(input_map[:compressor_ratio], k) || continue

        ratio_idx = input_map[:compressor_ratio][k]

        # Get α* (r²)
        fp_comp = _ia_fixed_point(gm, n)["compressor"][string(k)]
        α_star = haskey(fp_comp, "rsqr") ? fp_comp["rsqr"] : fp_comp["r"]^2

        # Ratio limits
        c_ratio_min = comp["c_ratio_min"]
        c_ratio_max = comp["c_ratio_max"]
        α_min = c_ratio_min^2
        α_max = c_ratio_max^2

        JuMP.@constraint(model, α_star - ℓ_u_minus[ratio_idx] >= α_min)
        JuMP.@constraint(model, α_star + ℓ_u_plus[ratio_idx] <= α_max)
    end

    # Receipt bounds
    for k in sort(collect(keys(ref(gm, n, :receipt))))
        haskey(input_map[:receipt], k) || continue
        receipt = ref(gm, n, :receipt, k)
        receipt_idx = input_map[:receipt][k]

        fg_star = _ia_fp_value(gm, n, :receipt, k, "fg")
        fg_min = receipt["injection_min"]
        fg_max = receipt["injection_max"]

        JuMP.@constraint(model, fg_star - ℓ_u_minus[receipt_idx] >= fg_min)
        JuMP.@constraint(model, fg_star + ℓ_u_plus[receipt_idx] <= fg_max)
    end

    # Transfer bounds (non-slack only, slack transfers are handled as state variables)
    for k in sort(collect(keys(ref(gm, n, :transfer))))
        haskey(input_map[:transfer], k) || continue
        transfer = ref(gm, n, :transfer, k)
        transfer_idx = input_map[:transfer][k]

        ft_star = _ia_fp_value(gm, n, :transfer, k, "ft")
        ft_min = transfer["withdrawal_min"]
        ft_max = transfer["withdrawal_max"]

        JuMP.@constraint(model, ft_star - ℓ_u_minus[transfer_idx] >= ft_min)
        JuMP.@constraint(model, ft_star + ℓ_u_plus[transfer_idx] <= ft_max)
    end

    # Slack receipt bounds (state variables, not inputs)
    for (k, receipt_idx) in state_map[:slack_receipt]
        receipt = ref(gm, n, :receipt, k)
        fg_star = _ia_fp_value(gm, n, :receipt, k, "fg")
        fg_min = receipt["injection_min"]
        fg_max = receipt["injection_max"]

        JuMP.@constraint(model, fg_star - ℓ_x_minus[receipt_idx] >= fg_min)
        JuMP.@constraint(model, fg_star + ℓ_x_plus[receipt_idx] <= fg_max)
    end

    # Slack delivery bounds (state variables, not inputs)
    for (k, delivery_idx) in state_map[:slack_delivery]
        delivery = ref(gm, n, :delivery, k)
        fd_star = _ia_fp_value(gm, n, :delivery, k, "fd")
        fd_min = delivery["withdrawal_min"]
        fd_max = delivery["withdrawal_max"]

        JuMP.@constraint(model, fd_star - ℓ_x_minus[delivery_idx] >= fd_min)
        JuMP.@constraint(model, fd_star + ℓ_x_plus[delivery_idx] <= fd_max)
    end

    # Slack transfer bounds (state variables, not inputs)
    for (k, transfer_idx) in state_map[:slack_transfer]
        transfer = ref(gm, n, :transfer, k)
        ft_star = _ia_fp_value(gm, n, :transfer, k, "ft")
        ft_min = transfer["withdrawal_min"]
        ft_max = transfer["withdrawal_max"]

        JuMP.@constraint(model, ft_star - ℓ_x_minus[transfer_idx] >= ft_min)
        JuMP.@constraint(model, ft_star + ℓ_x_plus[transfer_idx] <= ft_max)
    end

    @info "Physical feasibility constraints added"
end


"""
Add objective: maximize polytope volume.

Uses product of half-widths: ∏(ℓ_x^+ + ℓ_x^-) × ∏(ℓ_u^+ + ℓ_u^-)

For numerical stability, maximize sum of logs instead:
    max Σ log(ℓ_x^+ + ℓ_x^-) + Σ log(ℓ_u^+ + ℓ_u^-)
"""
function _add_ia_objective!(
    model, n_states, n_inputs,
    ℓ_x_plus, ℓ_x_minus, ℓ_u_plus, ℓ_u_minus
)
    @info "Adding objective function"

    # Maximize only input variable bounds (compressor ratios and dispatchable injections/withdrawals)
    # State variables (pressures, flows) are determined by physics once inputs are fixed
    # Maximizing state bounds can lead to inconsistent corners violating implicit coupling constraints
    JuMP.@objective(
        model,
        JuMP.MOI.MAX_SENSE,
        sum(ℓ_u_plus[j] + ℓ_u_minus[j] for j in 1:n_inputs)
    )

    @info "Objective function added (input variables only)"
end
