"""
Residual bound computation for Inner Approximation.

The residual vector r(Δx, Δu) represents nonlinear terms in the linearized equations:
    J⋆Δx = R⋆Δu + r(Δx, Δu)

For gas networks:
- Weymouth: γₑ(Δfₑ) = ωₑ(Δfₑ)²
- Compressor: ηc(Δα, Δπᵢ) = ΔαΔπᵢ
- Mass balance: 0 (linear)

These bounds are FUNCTIONS of the state/input bounds ℓ_x, ℓ_u.
"""


#=============================================================================
    RESIDUAL BOUND FUNCTIONS
=============================================================================#

"""
    compute_weymouth_residual_bounds(ℓ_f_minus, ℓ_f_plus, w, f_star,
                                      reversal_allowed=false)

Compute bounds on Weymouth residual: γₑ(Δfₑ) = ωₑ(Δfₑ)²

Arguments:
- ℓ_f_minus: lower bound on flow deviation (ℓ_f^-)
- ℓ_f_plus: upper bound on flow deviation (ℓ_f^+)
- w: reciprocal resistance (1/ω)
- f_star: fixed point flow value
- reversal_allowed: whether flow reversal is permitted

Returns: (r_minus, r_plus) bounds on residual
"""
function compute_weymouth_residual_bounds(
    ℓ_f_minus::Float64,
    ℓ_f_plus::Float64,
    w::Float64,
    f_star::Float64,
    reversal_allowed::Bool=false
)
    # Resistance ω = 1/w
    ω = 1.0 / w

    if !reversal_allowed
        if f_star > 0
            # Positive flow without reversal: residual is always positive
            # γₑ = ω·(Δf)² ∈ [0, ω·max(|Δf|²)]
            max_delta_f_sqr = max(ℓ_f_minus^2, ℓ_f_plus^2)
            return (0.0, ω * max_delta_f_sqr)
        else
            # Negative flow without reversal: residual is always negative
            max_delta_f_sqr = max(ℓ_f_minus^2, ℓ_f_plus^2)
            return (-ω * max_delta_f_sqr, 0.0)
        end
    else
        # With flow reversal: use full bilinear bounds
        # TODO: Implement Section 1.4.2 bounds from research document
        error("Flow reversal bounds not yet implemented")
    end
end


"""
    compute_compressor_residual_bounds(ℓ_α_minus, ℓ_α_plus,
                                        ℓ_π_minus, ℓ_π_plus)

Compute bounds on compressor residual: ηc(Δα, Δπᵢ) = Δα·Δπᵢ (bilinear)

Uses McCormick envelope: evaluate at 4 corners of rectangle and take min/max.

Arguments:
- ℓ_α_minus, ℓ_α_plus: bounds on compression ratio deviation
- ℓ_π_minus, ℓ_π_plus: bounds on inlet pressure deviation

Returns: (r_minus, r_plus) bounds on residual
"""
function compute_compressor_residual_bounds(
    ℓ_α_minus::Float64,
    ℓ_α_plus::Float64,
    ℓ_π_minus::Float64,
    ℓ_π_plus::Float64
)
    # Bilinear term: Δα·Δπ
    # Evaluate at 4 corners of [ℓ_α^-, ℓ_α^+] × [ℓ_π^-, ℓ_π^+]
    corners = [
        ℓ_α_minus * ℓ_π_minus,
        ℓ_α_minus * ℓ_π_plus,
        ℓ_α_plus * ℓ_π_minus,
        ℓ_α_plus * ℓ_π_plus
    ]

    return (minimum(corners), maximum(corners))
end


"""
    assemble_residual_bounds(gm, n, state_map, ℓ_x, ℓ_u)

Assemble full residual bound vectors r^- and r^+ as functions of ℓ_x and ℓ_u.

Row order matches Jacobian:
- Weymouth equations (one per pipe)
- Compressor equations (one per compressor)
- Mass balance equations (one per non-slack junction) - always zero

Returns: (r_minus, r_plus) as vectors of length n_states
"""
function assemble_residual_bounds(
    gm::AbstractGasModel,
    n::Int,
    state_map::Dict,
    input_map::Dict,
    ℓ_x::Matrix{Float64},  # (n_states × 2): [ℓ^-, ℓ^+]
    ℓ_u::Matrix{Float64}   # (n_inputs × 2): [ℓ^-, ℓ^+]
)
    n_states = state_map[:dim]
    r_minus = zeros(n_states)
    r_plus = zeros(n_states)

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

        # Get flow bounds from ℓ_x
        flow_idx = state_map[:pipe_flow][k]
        ℓ_f_minus = ℓ_x[flow_idx, 1]  # ℓ^-
        ℓ_f_plus = ℓ_x[flow_idx, 2]   # ℓ^+

        r_minus[row], r_plus[row] = compute_weymouth_residual_bounds(
            ℓ_f_minus, ℓ_f_plus, w, f_star, false
        )
        row += 1
    end

    # Compressor residuals: ηc(Δα, Δπᵢ) = Δα·Δπᵢ
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        comp = ref(gm, n, :compressor, k)
        i = comp["fr_junction"]

        # Get ratio bounds from ℓ_u
        if haskey(input_map[:compressor_ratio], k)
            ratio_idx = input_map[:compressor_ratio][k]
            ℓ_α_minus = ℓ_u[ratio_idx, 1]
            ℓ_α_plus = ℓ_u[ratio_idx, 2]
        else
            # No control on this compressor
            ℓ_α_minus = ℓ_α_plus = 0.0
        end

        # Get inlet pressure bounds from ℓ_x (if not slack)
        pi_i_idx = get_state_index(state_map, :junction_psqr, i)
        if !isnothing(pi_i_idx)
            ℓ_π_minus = ℓ_x[pi_i_idx, 1]
            ℓ_π_plus = ℓ_x[pi_i_idx, 2]
        else
            # Inlet is slack: Δπᵢ = 0, so residual = 0
            ℓ_π_minus = ℓ_π_plus = 0.0
        end

        r_minus[row], r_plus[row] = compute_compressor_residual_bounds(
            ℓ_α_minus, ℓ_α_plus, ℓ_π_minus, ℓ_π_plus
        )
        row += 1
    end

    # Mass balance residuals: always zero (linear equations)
    for k in sort(collect(keys(ref(gm, n, :junction))))
        junction = ref(gm, n, :junction, k)
        junction["junction_type"] == 1 && continue

        r_minus[row] = 0.0
        r_plus[row] = 0.0
        row += 1
    end

    return r_minus, r_plus
end


"""
    compute_residual_contribution(N_pos, N_neg, r_minus, r_plus)

Compute the residual contribution to self-mapping: N·r(Δx, Δu) where N = J⋆^{-1}.

Using decomposition N = N^+ - N^-:
    Lower bound: N·r^- = N^+·r^- - N^-·r^+
    Upper bound: N·r^+ = N^+·r^+ - N^-·r^-

Returns: (τ_minus, τ_plus) as vectors
"""
function compute_residual_contribution(
    N_pos::Matrix{Float64},  # N^+ from decomposition
    N_neg::Matrix{Float64},  # N^- from decomposition
    r_minus::Vector{Float64},
    r_plus::Vector{Float64}
)
    # Upper bound: τ^+ = N^+·r^+ - N^-·r^-
    τ_plus = N_pos * r_plus - N_neg * r_minus

    # Lower bound: τ^- = N^+·r^- - N^-·r^+
    τ_minus = N_pos * r_minus - N_neg * r_plus

    return τ_minus, τ_plus
end
