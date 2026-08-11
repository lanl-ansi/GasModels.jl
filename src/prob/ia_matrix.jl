"""
Matrix assembly and decomposition for Inner Approximation.

Correct approach (Research_Ideas-2.pdf):
1. Assemble J⋆ and R⋆ from perturbed equations
2. Invert J⋆
3. Compute PRODUCT: M = J⋆^{-1}R⋆
4. Decompose PRODUCT: M = M⁺ - M⁻
5. Use for constraint generation

Key: We decompose the PRODUCTS, not J⋆^{-1} itself!

Organization (bottom-up for Julia):
    [1] Utility functions (called by others)
    [2] Matrix assembly (called by main)
    [3] Main function - call this!
"""

# Note: LinearAlgebra and SparseArrays are imported at module level in GasModels.jl


#=============================================================================
    [1] UTILITY FUNCTIONS
=============================================================================#

"""
Decompose matrix into positive and negative parts: M = M⁺ - M⁻
"""
function decompose_matrix_positive_negative(M::AbstractMatrix)
    M_pos = max.(M, 0.0)
    M_neg = max.(-M, 0.0)
    @assert maximum(abs.(M - (M_pos - M_neg))) < 1e-10 "Decomposition error"
    return M_pos, M_neg
end


"""
Compute residual bounds for Weymouth equation.
γₑ(Δfₑ) = ωₑ(Δfₑ)² for f*>0 without reversal
"""
function compute_weymouth_residual_bounds(
    f_star::Float64,
    l_f_minus::Float64,
    l_f_plus::Float64,
    reversal_allowed::Bool
)
    if !reversal_allowed
        if f_star > 0
            return 0.0, max(l_f_minus^2, l_f_plus^2)
        else
            return -max(l_f_minus^2, l_f_plus^2), 0.0
        end
    else
        # TODO: Use Section 1.4.2 bounds for flow reversal
        return compute_weymouth_residual_bounds_with_reversal(
            f_star, l_f_minus, l_f_plus
        )
    end
end


#=============================================================================
    [2] MATRIX ASSEMBLY FUNCTIONS
=============================================================================#

"""
Assemble Jacobian J⋆ from linearized equations: J⋆Δx = R⋆Δu + r(Δx, Δu)

Row order: [Weymouth, Compressor boost, Mass balance]
Col order: [pipe flows, compressor flows, junction psqr]
"""
function assemble_ia_jacobian(gm::AbstractGasModel, n::Int=nw_id_default, state_map=nothing)
    if isnothing(state_map)
        state_map = build_ia_state_map(gm, n)
    end

    n_states = state_map[:dim]
    J = spzeros(n_states, n_states)
    row = 1

    # Weymouth: Δπᵢ - Δπⱼ - kₑΔfₑ = γₑ(Δfₑ) where kₑ = 2ωₑ|fₑ*|
    # NOTE: _calc_pipe_resistance returns w = 1/ω (reciprocal of resistance)
    for k in sort(collect(keys(ref(gm, n, :pipe))))
        pipe = ref(gm, n, :pipe, k)
        i, j = pipe["fr_junction"], pipe["to_junction"]

        f_star = _ia_fp_value(gm, n, :pipe, k, "f")
        w = _calc_pipe_resistance(pipe,
                                   gm.ref[:it][gm_it_sym][:base_length],
                                   gm.ref[:it][gm_it_sym][:base_pressure],
                                   gm.ref[:it][gm_it_sym][:base_flow],
                                   gm.ref[:it][gm_it_sym][:sound_speed])
        k_e = 2 * abs(f_star) / w  # k_e = 2ω|f*| = 2|f*|/w since w = 1/ω

        J[row, state_map[:pipe_flow][k]] = -k_e
        pi_i_idx = get_state_index(state_map, :junction_psqr, i)
        !isnothing(pi_i_idx) && (J[row, pi_i_idx] = 1.0)
        pi_j_idx = get_state_index(state_map, :junction_psqr, j)
        !isnothing(pi_j_idx) && (J[row, pi_j_idx] = -1.0)
        row += 1
    end

    # Compressor boost: Δπⱼ - α*Δπᵢ = πᵢ*Δα + ηc(Δα, Δπᵢ)
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        comp = ref(gm, n, :compressor, k)
        i, j = comp["fr_junction"], comp["to_junction"]

        fp_comp = _ia_fixed_point(gm, n)["compressor"][string(k)]
        a_star = haskey(fp_comp, "r") ? fp_comp["r"] : sqrt(fp_comp["rsqr"])

        pi_j_idx = get_state_index(state_map, :junction_psqr, j)
        !isnothing(pi_j_idx) && (J[row, pi_j_idx] = 1.0)
        pi_i_idx = get_state_index(state_map, :junction_psqr, i)
        !isnothing(pi_i_idx) && (J[row, pi_i_idx] = -a_star)
        row += 1
    end

    # Mass balance: AΔf = BΔd
    for k in sort(collect(keys(ref(gm, n, :junction))))
        junction = ref(gm, n, :junction, k)
        junction["junction_type"] == 1 && continue  # Skip slack

        for pipe_id in ref(gm, n, :pipes_fr, k)
            J[row, state_map[:pipe_flow][pipe_id]] = 1.0
        end
        for pipe_id in ref(gm, n, :pipes_to, k)
            J[row, state_map[:pipe_flow][pipe_id]] = -1.0
        end
        for comp_id in ref(gm, n, :compressors_fr, k)
            J[row, state_map[:compressor_flow][comp_id]] = 1.0
        end
        for comp_id in ref(gm, n, :compressors_to, k)
            J[row, state_map[:compressor_flow][comp_id]] = -1.0
        end
        row += 1
    end

    return J
end


"""
Assemble input matrix R⋆ = -J_u

Input order: [compressor ratios, receipts, deliveries, transfers, storage]
"""
function assemble_ia_input_matrix(gm::AbstractGasModel, n::Int=nw_id_default,
                                   state_map=nothing, input_map=nothing)
    if isnothing(state_map)
        state_map = build_ia_state_map(gm, n)
    end
    if isnothing(input_map)
        input_map = build_ia_input_map(gm, n)
    end

    n_states, n_inputs = state_map[:dim], input_map[:dim]
    R = spzeros(n_states, n_inputs)
    row = 1

    # Weymouth rows: all zeros
    for k in sort(collect(keys(ref(gm, n, :pipe))))
        row += 1
    end

    # Compressor rows: R⋆[row, α_col] = πᵢ*
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        comp = ref(gm, n, :compressor, k)
        i = comp["fr_junction"]
        pi_i_star = _ia_fp_value(gm, n, :junction, i, "psqr")

        if haskey(input_map[:compressor_ratio], k)
            R[row, input_map[:compressor_ratio][k]] = pi_i_star
        end
        row += 1
    end

    # Mass balance rows: input coefficients
    for k in sort(collect(keys(ref(gm, n, :junction))))
        junction = ref(gm, n, :junction, k)
        junction["junction_type"] == 1 && continue

        for receipt_id in ref(gm, n, :dispatchable_receipts_in_junction, k)
            haskey(input_map[:receipt], receipt_id) &&
                (R[row, input_map[:receipt][receipt_id]] = 1.0)
        end
        for delivery_id in ref(gm, n, :dispatchable_deliveries_in_junction, k)
            haskey(input_map[:delivery], delivery_id) &&
                (R[row, input_map[:delivery][delivery_id]] = -1.0)
        end
        for transfer_id in ref(gm, n, :dispatchable_transfers_in_junction, k)
            haskey(input_map[:transfer], transfer_id) &&
                (R[row, input_map[:transfer][transfer_id]] = -1.0)
        end
        for storage_id in ref(gm, n, :storages_in_junction, k)
            haskey(input_map[:storage], storage_id) &&
                (R[row, input_map[:storage][storage_id]] = -1.0)
        end
        row += 1
    end

    return R
end


#=============================================================================
    [3] MAIN FUNCTION - Call this!
=============================================================================#

"""
    compute_ia_coefficient_matrices(gm, n) → matrices

**MAIN ENTRY POINT** - Computes all coefficient matrices for IA.

The self-map: Δx = J⋆^{-1}R⋆·Δu + J⋆^{-1}r(Δx,Δu) = M·Δu + J⋆^{-1}r

Steps:
1. Build index maps
2. Assemble J⋆ and R⋆
3. Invert J⋆
4. Compute PRODUCT M = J⋆^{-1}R⋆
5. Decompose M = M⁺ - M⁻

Returns named tuple with M_pos, M_neg, J_inv, state_map, input_map, J, R
"""
function compute_ia_coefficient_matrices(gm::AbstractGasModel, n::Int=nw_id_default)
    @info "Computing IA coefficient matrices"

    # Step 1: Index maps
    state_map = build_ia_state_map(gm, n)
    input_map = build_ia_input_map(gm, n)
    @info "Dimensions: state=$(state_map[:dim]), input=$(input_map[:dim])"

    # Step 2: Assemble matrices
    J = assemble_ia_jacobian(gm, n, state_map)
    R = assemble_ia_input_matrix(gm, n, state_map, input_map)
    @info "J⋆: $(size(J)), nnz=$(nnz(J))  |  R⋆: $(size(R)), nnz=$(nnz(R))"

    # Step 3: Invert J⋆
    J_dense = Matrix(J)
    det_J = det(J_dense)
    @info "det(J⋆) = $(det_J)"
    abs(det_J) < 1e-10 && error("J⋆ is singular (det=$det_J)")

    J_inv = inv(J_dense)
    @info "J⋆^{-1} computed"

    # Step 4: Compute PRODUCT
    M = J_inv * Matrix(R)
    @info "M = J⋆^{-1}R⋆ computed: $(size(M))"

    # Step 5: Decompose PRODUCT
    M_pos, M_neg = decompose_matrix_positive_negative(M)
    @info "M = M⁺ - M⁻ decomposed"

    return (
        M_pos = M_pos,
        M_neg = M_neg,
        J_inv = J_inv,
        state_map = state_map,
        input_map = input_map,
        J = J_dense,
        R = Matrix(R)
    )
end
