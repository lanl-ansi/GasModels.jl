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
    # NOTE: α ≡ r² (ratio-squared), so πⱼ = α·πᵢ is linear in α
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        comp = ref(gm, n, :compressor, k)
        i, j = comp["fr_junction"], comp["to_junction"]

        fp_comp = _ia_fixed_point(gm, n)["compressor"][string(k)]
        a_sqr_star = haskey(fp_comp, "rsqr") ? fp_comp["rsqr"] : fp_comp["r"]^2

        pi_j_idx = get_state_index(state_map, :junction_psqr, j)
        !isnothing(pi_j_idx) && (J[row, pi_j_idx] = 1.0)
        pi_i_idx = get_state_index(state_map, :junction_psqr, i)
        !isnothing(pi_i_idx) && (J[row, pi_i_idx] = -a_sqr_star)
        row += 1
    end

    # Mass balance: AΔf = BΔd
    # Now includes mass balance at SLACK junctions to determine slack receipts/deliveries/transfers
    for k in sort(collect(keys(ref(gm, n, :junction))))
        junction = ref(gm, n, :junction, k)
        is_slack = (junction["junction_type"] == 1)

        # Flows entering/leaving - using (inflow - outflow) form to match case-6 example
        # This gives: f_entering - f_leaving = receipts - deliveries - transfers
        # Or equivalently: f_entering - f_leaving = -deliveries - transfers (if no receipts)
        for pipe_id in ref(gm, n, :pipes_to, k)
            J[row, state_map[:pipe_flow][pipe_id]] = 1.0  # Flow entering junction
        end
        for pipe_id in ref(gm, n, :pipes_fr, k)
            J[row, state_map[:pipe_flow][pipe_id]] = -1.0  # Flow leaving junction
        end
        for comp_id in ref(gm, n, :compressors_to, k)
            J[row, state_map[:compressor_flow][comp_id]] = 1.0  # Flow entering junction
        end
        for comp_id in ref(gm, n, :compressors_fr, k)
            J[row, state_map[:compressor_flow][comp_id]] = -1.0  # Flow leaving junction
        end

        # At slack junctions, receipts/deliveries/transfers are STATE variables (in J, not R)
        # At non-slack junctions, they are INPUT variables (in R, not J)
        #
        # Physical mass balance: (flows in) + (receipts) = (flows out) + (deliveries) + (transfers)
        # Rearranging: f_in - f_out + f_g - f_d - f_t = 0
        # For non-slack junctions, move dispatchables to RHS: f_in - f_out = -f_g + f_d + f_t
        if is_slack
            for receipt_id in ref(gm, n, :dispatchable_receipts_in_junction, k)
                receipt_idx = get_state_index(state_map, :slack_receipt, receipt_id)
                !isnothing(receipt_idx) && (J[row, receipt_idx] = 1.0)  # Receipts on LHS with +
            end
            for delivery_id in ref(gm, n, :dispatchable_deliveries_in_junction, k)
                delivery_idx = get_state_index(state_map, :slack_delivery, delivery_id)
                !isnothing(delivery_idx) && (J[row, delivery_idx] = -1.0)  # Deliveries on LHS with -
            end
            for transfer_id in ref(gm, n, :dispatchable_transfers_in_junction, k)
                transfer_idx = get_state_index(state_map, :slack_transfer, transfer_id)
                !isnothing(transfer_idx) && (J[row, transfer_idx] = -1.0)  # Transfers on LHS with -
            end
        end

        row += 1
    end

    return J
end


"""
Assemble input matrix R⋆ = -J_u

Input order: [compressor ratios, receipts, deliveries, transfers]
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
    # From linearization of πⱼ = α·πᵢ where α ≡ r²: Δπⱼ = α*Δπᵢ + πᵢ*Δα
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
    # IMPORTANT: Must have a row for EVERY junction to match J matrix row ordering
    # For slack junctions: R[row, :] = 0 (receipts/deliveries/transfers are states, not inputs)
    # For non-slack junctions: R[row, input_cols] = coefficients (they are inputs)
    for k in sort(collect(keys(ref(gm, n, :junction))))
        junction = ref(gm, n, :junction, k)
        is_slack = (junction["junction_type"] == 1)

        if !is_slack
            # At non-slack junctions, move receipts/deliveries/transfers to RHS
            # From: f_in - f_out + f_g - f_d - f_t = 0
            # To:   f_in - f_out = -f_g + f_d + f_t
            # Convention: R_star = -∂g/∂u, so on RHS: receipts get -1, deliveries/transfers get +1
            for receipt_id in ref(gm, n, :dispatchable_receipts_in_junction, k)
                haskey(input_map[:receipt], receipt_id) &&
                    (R[row, input_map[:receipt][receipt_id]] = -1.0)
            end
            for delivery_id in ref(gm, n, :dispatchable_deliveries_in_junction, k)
                haskey(input_map[:delivery], delivery_id) &&
                    (R[row, input_map[:delivery][delivery_id]] = 1.0)
            end
            for transfer_id in ref(gm, n, :dispatchable_transfers_in_junction, k)
                haskey(input_map[:transfer], transfer_id) &&
                    (R[row, input_map[:transfer][transfer_id]] = 1.0)
            end
        end
        # For slack junctions: R[row, :] remains all zeros (already initialized by spzeros)

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

    # Step 4: Compute transformation matrices
    # M = J⋆^{-1}R⋆ (input-to-state mapping)
    # N = J⋆^{-1} (residual-to-state mapping)
    M = J_inv * Matrix(R)
    N = J_inv
    @info "M = J⋆^{-1}R⋆ computed: $(size(M))"
    @info "N = J⋆^{-1} computed: $(size(N))"

    # Step 5: Decompose M = M_pos - M_neg
    M_pos, M_neg = decompose_matrix_positive_negative(M)
    @info "M = M^+ - M^- decomposed"

    # Step 6: Decompose N = N_pos - N_neg
    N_pos, N_neg = decompose_matrix_positive_negative(N)
    @info "N = N^+ - N^- decomposed"

    return (
        M_pos = M_pos,
        M_neg = M_neg,
        N_pos = N_pos,
        N_neg = N_neg,
        state_map = state_map,
        input_map = input_map,
        J_star = J_dense,
        R_star = Matrix(R),
        M = M,
        N = N
    )
end
