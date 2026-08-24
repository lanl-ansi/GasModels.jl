"""
Solution extraction and display for Inner Approximation.

Converts per-unit bounds to SI units for human-readable output.
"""


"""
    extract_ia_solution(gm, model, n; π_scale=1.0)

Extract IA solution from optimization model and convert to SI units.

# Arguments
- `gm::AbstractGasModel`: Gas model
- `model`: JuMP model with solved IA optimization
- `n::Int`: Network ID (default: 0)
- `π_scale::Float64`: Pressure scaling factor used in optimization (default: 1.0)

Returns a Dict with:
- state_bounds: Dict mapping state indices to (lower, upper) in SI units
- input_bounds: Dict mapping input indices to (lower, upper) in SI units
- state_map: State index mapping
- input_map: Input index mapping
- objective_value: Objective function value
"""
function extract_ia_solution(gm::AbstractGasModel, model, n::Int=nw_id_default; π_scale::Float64=1.0)
    # Get index maps from model (should be stored during build)
    matrices = compute_ia_coefficient_matrices(gm, n, π_scale=π_scale)
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

    # Note: Slack receipts/deliveries/transfers are STATE variables, not inputs
    # They will be extracted here in the state_bounds section

    # Pipe flows (convert from per-unit to kg/s)
    for (k, idx) in state_map[:pipe_flow]
        f_star = _ia_fp_value(gm, n, :pipe, k, "f") * base_flow
        Δf_lower = -ℓ_x_minus[idx] * base_flow
        Δf_upper = ℓ_x_plus[idx] * base_flow

        state_bounds[(:pipe_flow, k)] = (
            deviation_lower = Δf_lower,
            deviation_upper = Δf_upper,
            actual_lower = f_star + Δf_lower,
            actual_upper = f_star + Δf_upper,
            fixed_point = f_star,
            unit = "kg/s"
        )
    end

    # Compressor flows (convert from per-unit to kg/s)
    for (k, idx) in state_map[:compressor_flow]
        f_star = _ia_fp_value(gm, n, :compressor, k, "f") * base_flow
        Δf_lower = -ℓ_x_minus[idx] * base_flow
        Δf_upper = ℓ_x_plus[idx] * base_flow

        state_bounds[(:compressor_flow, k)] = (
            deviation_lower = Δf_lower,
            deviation_upper = Δf_upper,
            actual_lower = f_star + Δf_lower,
            actual_upper = f_star + Δf_upper,
            fixed_point = f_star,
            unit = "kg/s"
        )
    end

    # Junction pressures (convert from π = p² to p)
    # Exact approach: convert to SI, apply bounds, take sqrt, compute deviation
    # Account for pressure scaling
    π_scale = get(state_map, :π_scale, 1.0)

    for (k, idx) in state_map[:junction_psqr]
        π_star_pu = _ia_fp_value(gm, n, :junction, k, "psqr")

        # Convert to SI
        π_star_SI = π_star_pu * base_pressure^2

        # Apply deviation bounds (scaled back) to get π range in SI
        π_min_SI = π_star_SI - ℓ_x_minus[idx] * π_scale * base_pressure^2
        π_max_SI = π_star_SI + ℓ_x_plus[idx] * π_scale * base_pressure^2

        # Take sqrt to get p range
        p_star_SI = sqrt(π_star_SI)
        p_min_SI = sqrt(max(0.0, π_min_SI))  # Protect against negative
        p_max_SI = sqrt(max(0.0, π_max_SI))

        # Compute deviation from p*
        Δp_lower = p_min_SI - p_star_SI
        Δp_upper = p_max_SI - p_star_SI

        state_bounds[(:junction_psqr, k)] = (
            deviation_lower = Δp_lower,
            deviation_upper = Δp_upper,
            actual_lower = p_min_SI,
            actual_upper = p_max_SI,
            fixed_point = p_star_SI,
            unit = "Pa"
        )
    end

    # Slack receipts (state variables at slack junctions)
    for (k, idx) in state_map[:slack_receipt]
        fg_star = _ia_fp_value(gm, n, :receipt, k, "fg") * base_flow
        Δfg_lower = -ℓ_x_minus[idx] * base_flow
        Δfg_upper = ℓ_x_plus[idx] * base_flow

        state_bounds[(:slack_receipt, k)] = (
            deviation_lower = Δfg_lower,
            deviation_upper = Δfg_upper,
            actual_lower = fg_star + Δfg_lower,
            actual_upper = fg_star + Δfg_upper,
            fixed_point = fg_star,
            unit = "kg/s"
        )
    end

    # Slack deliveries (state variables at slack junctions)
    for (k, idx) in state_map[:slack_delivery]
        fd_star = _ia_fp_value(gm, n, :delivery, k, "fd") * base_flow
        Δfd_lower = -ℓ_x_minus[idx] * base_flow
        Δfd_upper = ℓ_x_plus[idx] * base_flow

        state_bounds[(:slack_delivery, k)] = (
            deviation_lower = Δfd_lower,
            deviation_upper = Δfd_upper,
            actual_lower = fd_star + Δfd_lower,
            actual_upper = fd_star + Δfd_upper,
            fixed_point = fd_star,
            unit = "kg/s"
        )
    end

    # Slack transfers (state variables at slack junctions)
    for (k, idx) in state_map[:slack_transfer]
        ft_star = _ia_fp_value(gm, n, :transfer, k, "ft") * base_flow
        Δft_lower = -ℓ_x_minus[idx] * base_flow
        Δft_upper = ℓ_x_plus[idx] * base_flow

        state_bounds[(:slack_transfer, k)] = (
            deviation_lower = Δft_lower,
            deviation_upper = Δft_upper,
            actual_lower = ft_star + Δft_lower,
            actual_upper = ft_star + Δft_upper,
            fixed_point = ft_star,
            unit = "kg/s"
        )
    end

    # Convert input bounds to SI units
    input_bounds = Dict()

    # Compressor ratios (convert from α = r² to r)
    # Exact approach: apply bounds to α, take sqrt, compute deviation
    for (k, idx) in input_map[:compressor_ratio]
        fp_comp = _ia_fixed_point(gm, n)["compressor"][string(k)]
        α_star = haskey(fp_comp, "rsqr") ? fp_comp["rsqr"] : fp_comp["r"]^2

        # Apply deviation bounds to get α range
        α_min = α_star - ℓ_u_minus[idx]
        α_max = α_star + ℓ_u_plus[idx]

        # Take sqrt to get r range
        r_star = sqrt(α_star)
        r_min = sqrt(max(0.0, α_min))  # Protect against negative
        r_max = sqrt(max(0.0, α_max))

        # Compute deviation from r*
        Δr_lower = r_min - r_star
        Δr_upper = r_max - r_star

        input_bounds[(:compressor_ratio, k)] = (
            deviation_lower = Δr_lower,
            deviation_upper = Δr_upper,
            actual_lower = r_min,
            actual_upper = r_max,
            fixed_point = r_star,
            unit = "dimensionless"
        )
    end

    # Receipts (deviation bounds in kg/s)
    for (k, idx) in input_map[:receipt]
        fg_star = _ia_fp_value(gm, n, :receipt, k, "fg") * base_flow
        Δfg_lower = -ℓ_u_minus[idx] * base_flow
        Δfg_upper = ℓ_u_plus[idx] * base_flow

        input_bounds[(:receipt, k)] = (
            deviation_lower = Δfg_lower,
            deviation_upper = Δfg_upper,
            actual_lower = fg_star + Δfg_lower,
            actual_upper = fg_star + Δfg_upper,
            fixed_point = fg_star,
            unit = "kg/s"
        )
    end

    # Transfers (deviation bounds in kg/s)
    for (k, idx) in input_map[:transfer]
        ft_star = _ia_fp_value(gm, n, :transfer, k, "ft") * base_flow
        Δft_lower = -ℓ_u_minus[idx] * base_flow
        Δft_upper = ℓ_u_plus[idx] * base_flow

        input_bounds[(:transfer, k)] = (
            deviation_lower = Δft_lower,
            deviation_upper = Δft_upper,
            actual_lower = ft_star + Δft_lower,
            actual_upper = ft_star + Δft_upper,
            fixed_point = ft_star,
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
    println("INNER APPROXIMATION SOLUTION (SI UNITS)")
    println("="^80)
    println("\nShows:")
    println("  1. Fixed point (x*): Nominal operating point")
    println("  2. Deviation bounds (Δx): How much variables can deviate from x*")
    println("  3. Actual range: Physical bounds [x* + Δx_lower, x* + Δx_upper]")

    println("\nObjective value: $(Printf.@sprintf("%.6f", solution[:objective_value]))")

    # State bounds
    println("\n" * "="^80)
    println("STATE VARIABLES")
    println("="^80)

    state_bounds = solution[:state_bounds]

    # Pipe flows
    pipe_flows = sort([k for k in keys(state_bounds) if k[1] == :pipe_flow])
    if !isempty(pipe_flows)
        println("\n--- PIPE FLOWS ---")
        for (i, key) in enumerate(pipe_flows)
            i > max_items && (println("  ... ($(length(pipe_flows) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Pipe $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.3f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.3f", b.deviation_lower)), $(Printf.@sprintf("%9.3f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.3f", b.actual_lower)), $(Printf.@sprintf("%9.3f", b.actual_upper))] $(b.unit)")
        end
    end

    # Compressor flows
    comp_flows = sort([k for k in keys(state_bounds) if k[1] == :compressor_flow])
    if !isempty(comp_flows)
        println("\n--- COMPRESSOR FLOWS ---")
        for (i, key) in enumerate(comp_flows)
            i > max_items && (println("  ... ($(length(comp_flows) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Comp $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.3f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.3f", b.deviation_lower)), $(Printf.@sprintf("%9.3f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.3f", b.actual_lower)), $(Printf.@sprintf("%9.3f", b.actual_upper))] $(b.unit)")
        end
    end

    # Junction pressures
    junc_pressures = sort([k for k in keys(state_bounds) if k[1] == :junction_psqr])
    if !isempty(junc_pressures)
        println("\n--- JUNCTION PRESSURES ---")
        for (i, key) in enumerate(junc_pressures)
            i > max_items && (println("  ... ($(length(junc_pressures) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Junction $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.0f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.0f", b.deviation_lower)), $(Printf.@sprintf("%9.0f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.0f", b.actual_lower)), $(Printf.@sprintf("%9.0f", b.actual_upper))] $(b.unit)")
        end
    end

    # Slack receipts (state variables at slack junctions)
    slack_receipts = sort([k for k in keys(state_bounds) if k[1] == :slack_receipt])
    if !isempty(slack_receipts)
        println("\n--- SLACK RECEIPTS (at slack junctions) ---")
        for (i, key) in enumerate(slack_receipts)
            i > max_items && (println("  ... ($(length(slack_receipts) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Receipt $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.3f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.3f", b.deviation_lower)), $(Printf.@sprintf("%9.3f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.3f", b.actual_lower)), $(Printf.@sprintf("%9.3f", b.actual_upper))] $(b.unit)")
        end
    end

    # Slack deliveries (state variables at slack junctions)
    slack_deliveries = sort([k for k in keys(state_bounds) if k[1] == :slack_delivery])
    if !isempty(slack_deliveries)
        println("\n--- SLACK DELIVERIES (at slack junctions) ---")
        for (i, key) in enumerate(slack_deliveries)
            i > max_items && (println("  ... ($(length(slack_deliveries) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Delivery $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.3f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.3f", b.deviation_lower)), $(Printf.@sprintf("%9.3f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.3f", b.actual_lower)), $(Printf.@sprintf("%9.3f", b.actual_upper))] $(b.unit)")
        end
    end

    # Slack transfers (state variables at slack junctions)
    slack_transfers = sort([k for k in keys(state_bounds) if k[1] == :slack_transfer])
    if !isempty(slack_transfers)
        println("\n--- SLACK TRANSFERS (at slack junctions) ---")
        for (i, key) in enumerate(slack_transfers)
            i > max_items && (println("  ... ($(length(slack_transfers) - max_items) more)"); break)
            b = state_bounds[key]
            k = key[2]
            println("  Transfer $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.3f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.3f", b.deviation_lower)), $(Printf.@sprintf("%9.3f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.3f", b.actual_lower)), $(Printf.@sprintf("%9.3f", b.actual_upper))] $(b.unit)")
        end
    end

    # Input bounds
    println("\n" * "="^80)
    println("INPUT VARIABLES")
    println("="^80)

    input_bounds = solution[:input_bounds]

    # Compressor ratios
    comp_ratios = sort([k for k in keys(input_bounds) if k[1] == :compressor_ratio])
    if !isempty(comp_ratios)
        println("\n--- COMPRESSOR RATIOS ---")
        for (i, key) in enumerate(comp_ratios)
            i > max_items && (println("  ... ($(length(comp_ratios) - max_items) more)"); break)
            b = input_bounds[key]
            k = key[2]
            println("  Comp $k:")
            println("    Fixed point: $(Printf.@sprintf("%6.4f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%6.4f", b.deviation_lower)), $(Printf.@sprintf("%6.4f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%6.4f", b.actual_lower)), $(Printf.@sprintf("%6.4f", b.actual_upper))] $(b.unit)")
        end
    end

    # Receipts
    receipts = sort([k for k in keys(input_bounds) if k[1] == :receipt])
    if !isempty(receipts)
        println("\n--- RECEIPTS ---")
        for (i, key) in enumerate(receipts)
            i > max_items && (println("  ... ($(length(receipts) - max_items) more)"); break)
            b = input_bounds[key]
            k = key[2]
            println("  Receipt $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.3f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.3f", b.deviation_lower)), $(Printf.@sprintf("%9.3f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.3f", b.actual_lower)), $(Printf.@sprintf("%9.3f", b.actual_upper))] $(b.unit)")
        end
    end

    # Transfers
    transfers = sort([k for k in keys(input_bounds) if k[1] == :transfer])
    if !isempty(transfers)
        println("\n--- TRANSFERS ---")
        for (i, key) in enumerate(transfers)
            i > max_items && (println("  ... ($(length(transfers) - max_items) more)"); break)
            b = input_bounds[key]
            k = key[2]
            println("  Transfer $k:")
            println("    Fixed point: $(Printf.@sprintf("%9.3f", b.fixed_point)) $(b.unit)")
            println("    Deviation:   [$(Printf.@sprintf("%9.3f", b.deviation_lower)), $(Printf.@sprintf("%9.3f", b.deviation_upper))] $(b.unit)")
            println("    Actual range:[$(Printf.@sprintf("%9.3f", b.actual_lower)), $(Printf.@sprintf("%9.3f", b.actual_upper))] $(b.unit)")
        end
    end

    println("\n" * "="^80)
end
