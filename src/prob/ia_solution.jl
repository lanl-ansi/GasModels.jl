"""
Solution extraction and display for Inner Approximation.

Converts per-unit bounds to SI units for human-readable output.
"""


"""
    extract_ia_solution(gm, model)

Extract IA solution from optimization model and convert to SI units.

Returns a Dict with:
- state_bounds: Dict mapping state indices to (lower, upper) in SI units
- input_bounds: Dict mapping input indices to (lower, upper) in SI units
- state_map: State index mapping
- input_map: Input index mapping
- objective_value: Objective function value
"""
function extract_ia_solution(gm::AbstractGasModel, model, n::Int=nw_id_default)
    # Get index maps from model (should be stored during build)
    matrices = compute_ia_coefficient_matrices(gm, n)
    state_map = matrices.state_map
    input_map = matrices.input_map

    # Extract solution values
    ℓ_x_plus = JuMP.value.(model[:ℓ_x_plus])
    ℓ_x_minus = JuMP.value.(model[:ℓ_x_minus])
    ℓ_u_plus = JuMP.value.(model[:ℓ_u_plus])
    ℓ_u_minus = JuMP.value.(model[:ℓ_u_minus])

    # Get base values for conversion
    base_flow = gm.ref[:it][gm_it_sym][:base_flow]  # kg/s
    base_pressure = gm.ref[:it][gm_it_sym][:base_pressure]  # Pa

    # Convert state bounds to SI units
    state_bounds = Dict()

    # Pipe flows (convert from per-unit to kg/s)
    for (k, idx) in state_map[:pipe_flow]
        state_bounds[(:pipe_flow, k)] = (
            lower = -ℓ_x_minus[idx] * base_flow,
            upper = ℓ_x_plus[idx] * base_flow,
            unit = "kg/s"
        )
    end

    # Compressor flows (convert from per-unit to kg/s)
    for (k, idx) in state_map[:compressor_flow]
        state_bounds[(:compressor_flow, k)] = (
            lower = -ℓ_x_minus[idx] * base_flow,
            upper = ℓ_x_plus[idx] * base_flow,
            unit = "kg/s"
        )
    end

    # Junction pressures (convert from per-unit Δπ to ΔP in Pa)
    # Note: π = p², so for small deviations: Δπ ≈ 2p*·Δp
    # More precisely: Δp = (sqrt(π* + Δπ) - sqrt(π*)) ≈ Δπ/(2*sqrt(π*))
    for (k, idx) in state_map[:junction_psqr]
        π_star = _ia_fp_value(gm, n, :junction, k, "psqr")
        p_star = sqrt(π_star) * base_pressure  # p* in Pa

        # Deviation in π (per-unit)
        Δπ_minus_pu = ℓ_x_minus[idx]
        Δπ_plus_pu = ℓ_x_plus[idx]

        # Convert to pressure deviation (Pa)
        # Δp ≈ Δπ · base_pressure² / (2·p*)
        Δp_minus = Δπ_minus_pu * base_pressure^2 / (2 * p_star)
        Δp_plus = Δπ_plus_pu * base_pressure^2 / (2 * p_star)

        state_bounds[(:junction_psqr, k)] = (
            lower = -Δp_minus,
            upper = Δp_plus,
            unit = "Pa"
        )
    end

    # Convert input bounds to SI units
    input_bounds = Dict()

    # Compressor ratios (convert Δα to Δr)
    # Note: α = r², so for small deviations: Δα ≈ 2r*·Δr, thus Δr ≈ Δα/(2r*)
    for (k, idx) in input_map[:compressor_ratio]
        fp_comp = _ia_fixed_point(gm, n)["compressor"][string(k)]
        α_star = haskey(fp_comp, "rsqr") ? fp_comp["rsqr"] : fp_comp["r"]^2
        r_star = sqrt(α_star)

        # Deviation in α (per-unit, dimensionless)
        Δα_minus = ℓ_u_minus[idx]
        Δα_plus = ℓ_u_plus[idx]

        # Convert to ratio deviation: Δr ≈ Δα / (2·r*)
        Δr_minus = Δα_minus / (2 * r_star)
        Δr_plus = Δα_plus / (2 * r_star)

        input_bounds[(:compressor_ratio, k)] = (
            lower = -Δr_minus,
            upper = Δr_plus,
            unit = "dimensionless"
        )
    end

    # Receipts (deviation bounds in kg/s)
    for (k, idx) in input_map[:receipt]
        input_bounds[(:receipt, k)] = (
            lower = -ℓ_u_minus[idx] * base_flow,
            upper = ℓ_u_plus[idx] * base_flow,
            unit = "kg/s"
        )
    end

    # Transfers (deviation bounds in kg/s)
    for (k, idx) in input_map[:transfer]
        input_bounds[(:transfer, k)] = (
            lower = -ℓ_u_minus[idx] * base_flow,
            upper = ℓ_u_plus[idx] * base_flow,
            unit = "kg/s"
        )
    end

    return Dict(
        :state_bounds => state_bounds,
        :input_bounds => input_bounds,
        :state_map => state_map,
        :input_map => input_map,
        :objective_value => JuMP.objective_value(model)
    )
end


"""
    print_ia_solution(solution; max_items=5)

Print IA solution in human-readable format with SI units.

Displays **deviation bounds** (Δx and Δu) in SI units, representing
how much each variable can deviate from its fixed-point value.
"""
function print_ia_solution(solution; max_items=5)
    println("\n" * "="^80)
    println("INNER APPROXIMATION SOLUTION - DEVIATION BOUNDS (SI UNITS)")
    println("="^80)
    println("\nNote: All bounds show deviations (Δx, Δu) from fixed-point values.")
    println("      Actual values: x ∈ [x* + lower, x* + upper]")

    println("\nObjective value: $(Printf.@sprintf("%.6f", solution[:objective_value]))")

    # State bounds
    println("\n--- STATE BOUNDS ---")

    state_bounds = solution[:state_bounds]

    # Pipe flows
    pipe_flows = sort([k for k in keys(state_bounds) if k[1] == :pipe_flow])
    if !isempty(pipe_flows)
        println("\nPipe flows:")
        for (i, key) in enumerate(pipe_flows)
            i > max_items && (println("  ... ($(length(pipe_flows) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Pipe $k: [$(Printf.@sprintf("%9.3f", b.lower)), $(Printf.@sprintf("%9.3f", b.upper))] $(b.unit)")
        end
    end

    # Compressor flows
    comp_flows = sort([k for k in keys(state_bounds) if k[1] == :compressor_flow])
    if !isempty(comp_flows)
        println("\nCompressor flows:")
        for (i, key) in enumerate(comp_flows)
            i > max_items && (println("  ... ($(length(comp_flows) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Comp $k: [$(Printf.@sprintf("%9.3f", b.lower)), $(Printf.@sprintf("%9.3f", b.upper))] $(b.unit)")
        end
    end

    # Junction pressures
    junc_pressures = sort([k for k in keys(state_bounds) if k[1] == :junction_psqr])
    if !isempty(junc_pressures)
        println("\nJunction pressures:")
        for (i, key) in enumerate(junc_pressures)
            i > max_items && (println("  ... ($(length(junc_pressures) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            # Convert Pa to bar for display
            p_min_bar = b.lower / 1e5
            p_max_bar = b.upper / 1e5
            println("  Junction $k: [$(Printf.@sprintf("%7.3f", p_min_bar)), $(Printf.@sprintf("%7.3f", p_max_bar))] bar")
        end
    end

    # Input bounds
    println("\n--- INPUT BOUNDS ---")

    input_bounds = solution[:input_bounds]

    # Compressor ratios
    comp_ratios = sort([k for k in keys(input_bounds) if k[1] == :compressor_ratio])
    if !isempty(comp_ratios)
        println("\nCompressor ratios:")
        for (i, key) in enumerate(comp_ratios)
            i > max_items && (println("  ... ($(length(comp_ratios) - max_items) more)"); break)
            b = input_bounds[key]
            k = key[2]
            println("  Comp $k: [$(Printf.@sprintf("%6.4f", b.lower)), $(Printf.@sprintf("%6.4f", b.upper))] $(b.unit)")
        end
    end

    # Receipts
    receipts = sort([k for k in keys(input_bounds) if k[1] == :receipt])
    if !isempty(receipts)
        println("\nReceipts:")
        for (i, key) in enumerate(receipts)
            i > max_items && (println("  ... ($(length(receipts) - max_items) more)"); break)
            b = input_bounds[key]
            k = key[2]
            println("  Receipt $k: [$(Printf.@sprintf("%9.3f", b.lower)), $(Printf.@sprintf("%9.3f", b.upper))] $(b.unit)")
        end
    end

    # Transfers
    transfers = sort([k for k in keys(input_bounds) if k[1] == :transfer])
    if !isempty(transfers)
        println("\nTransfers:")
        for (i, key) in enumerate(transfers)
            i > max_items && (println("  ... ($(length(transfers) - max_items) more)"); break)
            b = input_bounds[key]
            k = key[2]
            println("  Transfer $k: [$(Printf.@sprintf("%9.3f", b.lower)), $(Printf.@sprintf("%9.3f", b.upper))] $(b.unit)")
        end
    end

    println("\n" * "="^80)
end
