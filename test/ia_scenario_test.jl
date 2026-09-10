"""
Scenario runner for Inner Approximation (IA) flexibility analysis.

For each scenario defined in `SCENARIOS` below, this script:
  1. Mutates a fresh copy of the case-6 data (e.g. caps a receipt's injection,
     or rescales junction pressure minimums) and re-solves the OGF fixed
     point at that new operating point ("fp" data). A scenario may also use a
     *different* data dict ("box" data) to define the physical bounds the IA
     box is built against -- e.g. the "receipt_cap30_fixedpt_fullbox"
     scenario operates at the capped-30 fixed point but certifies flexibility
     against the network's original (uncapped) physical bounds.
  2. Builds TWO IA models at that fixed point via `GasModels.build_ia_model`:
       - "real"        : full nonconvex residual bounds (Weymouth + bilinear
                          curvature), via `linear_only=false`
       - "linear-only" : residuals pinned to zero (pure LP self-mapping),
                          via `linear_only=true`
     Both use the same small ε-weighted secondary objective (`ε_secondary`)
     so that "don't-care" states/inputs (free at zero cost to the primary
     transfer/delivery objective) are pushed out to their true achievable
     extent instead of being left at an arbitrary interior value. See the
     `_add_ia_objective!` docstring in src/prob/ia_constraints.jl for the
     caveat that this secondary term is itself a summed objective and can
     redistribute flexibility arbitrarily among items that tie in that sum.
  3. Solves both with SCIP (project convention: Ipopt for OGF fixed-point
     solves, SCIP for all IA flexibility solves).
  4. Plots receipt flexibility (slack injection), pipe flow states,
     compressor flow states, pressure states (junctions), transfer
     flexibility, and compressor-ratio flexibility -- each showing
     [physical range] > [linear-only box] > [real/certified box] > fixed
     point -- saved as PNGs under
     `~/Documents/Github/JuliaProjects/NG-IA/plots/` (outside this repo).
  5. Prints a transfer-flexibility summary table to stdout, and writes all
     flexibility tables (flow/pressure states, transfer/ratio inputs, and the
     transfer-flexibility summary) to a per-scenario text file under
     `~/Documents/Github/JuliaProjects/NG-IA/summaries/`.

Add new scenarios by appending a `(name, mutate_fp!, mutate_box!)` triple to
`SCENARIOS`, where each `mutate!(data)` edits a freshly-parsed matgas `data`
Dict in place (before the OGF is solved / before the box's physical bounds
are read). Use the same function for both when the scenario should operate
and be certified against the same (mutated) data.

Run from GasModels.jl directory (needs SCIP and Plots available in the
active Julia environment, in addition to GasModels/JuMP/Ipopt):
    julia test/ia_scenario_test.jl
"""

using GasModels, JuMP, Ipopt, SCIP, Plots
gr()

const CASE6_FILE = joinpath(@__DIR__, "data", "matgas", "case-6.m")
const OUTDIR = joinpath(homedir(), "Documents", "Github", "JuliaProjects", "NG-IA", "plots")
const SUMMARYDIR = joinpath(homedir(), "Documents", "Github", "JuliaProjects", "NG-IA", "summaries")
mkpath(OUTDIR)
mkpath(SUMMARYDIR)

const π_SCALE = 200.0
const ε_SECONDARY = 1e-6
const ACCEPTABLE_STATUSES = (MOI.LOCALLY_SOLVED, MOI.OPTIMAL, MOI.ALMOST_LOCALLY_SOLVED, MOI.ALMOST_OPTIMAL)

# ---------------------------------------------------------------------------
# Scenario definitions
# ---------------------------------------------------------------------------

"No-op mutator: base case, no changes to case-6 data."
function scenario_base!(data)
end

"""
Returns a mutator that caps Receipt 1's injection at `cap` kg/s (its own new
operating bound) and uses that same value as its nominal, so the OGF
re-solves at the new equilibrium this cap forces rather than the old (much
higher) capacity.
"""
function scenario_receipt_cap(cap::Real)
    return function (data)
        GasModels.make_si_units!(data)
        data["receipt"]["1"]["injection_max"] = float(cap)
        data["receipt"]["1"]["injection_nominal"] = float(cap)
        GasModels.make_per_unit!(data)
    end
end

"""
Returns a mutator that rescales every junction's minimum pressure by `scale`
(e.g. 0.5 loosens the minimum-pressure requirement, 1.2 tightens it).
"""
function scenario_pmin_scale(scale::Real)
    return function (data)
        GasModels.make_si_units!(data)
        for k in 1:length(data["junction"])
            data["junction"][string(k)]["p_min"] *= scale
        end
        GasModels.make_per_unit!(data)
    end
end

# Each entry: (name, mutate_fp!, mutate_box!)
#   mutate_fp!  -- edits the data used to solve the OGF fixed point
#   mutate_box! -- edits the data whose physical bounds define the IA box
# Use the same function for both unless the scenario intentionally mixes them.
SCENARIOS = [
    ("base", scenario_base!, scenario_base!),
    ("receipt_cap30", scenario_receipt_cap(30), scenario_receipt_cap(30)),
    ("receipt_cap100", scenario_receipt_cap(100), scenario_receipt_cap(100)),
    ("receipt_cap30_fixedpt_fullbox", scenario_receipt_cap(30), scenario_base!),
    ("pmin_x0.5", scenario_pmin_scale(0.5), scenario_pmin_scale(0.5)),
    ("pmin_x1.2", scenario_pmin_scale(1.2), scenario_pmin_scale(1.2)),
    ("base_fixedpt_pmin_x0.5_box", scenario_base!, scenario_pmin_scale(0.5)),
]

# ---------------------------------------------------------------------------
# Plotting helpers
# ---------------------------------------------------------------------------

"""
Three-layer floating bar chart for a list of
(label, phys_min, phys_max, lin_lo, lin_hi, real_lo, real_hi, fixed) rows:
gray = physical range, orange = linear-only box, blue = real/certified box,
red diamond = OGF fixed point.

Margins are set explicitly (left_margin especially) so the rotated y-axis
title is never clipped by the figure canvas edge.
"""
function floating_bar_plot(rows; title="", ylabel="")
    n = length(rows)
    p = plot(title=title, ylabel=ylabel, xticks=(1:n, [r[1] for r in rows]),
             legend=:outertopright, size=(1080, 600),
             titlefontsize=14, guidefontsize=12, tickfontsize=11,
             left_margin=14Plots.mm, bottom_margin=8Plots.mm,
             top_margin=6Plots.mm, right_margin=4Plots.mm)
    for (i, (label, pmin, pmax, llo, lhi, blo, bhi, fixed)) in enumerate(rows)
        plot!(p, Shape([i-0.34, i+0.34, i+0.34, i-0.34], [pmin, pmin, pmax, pmax]),
              fillcolor=:gray88, linecolor=:gray60, label=(i == 1 ? "Physical range" : ""))
        if lhi > llo + 1e-6
            plot!(p, Shape([i-0.22, i+0.22, i+0.22, i-0.22], [llo, llo, lhi, lhi]),
                  fillcolor=:orange, fillalpha=0.5, linecolor=:darkorange,
                  label=(i == 1 ? "Linear-only box (ε-pen.)" : ""))
        else
            plot!(p, [i-0.22, i+0.22], [llo, llo], linecolor=:darkorange, linewidth=3,
                  label=(i == 1 ? "Linear-only box (≈0 width)" : ""))
        end
        if bhi > blo + 1e-6
            plot!(p, Shape([i-0.12, i+0.12, i+0.12, i-0.12], [blo, blo, bhi, bhi]),
                  fillcolor=:steelblue, linecolor=:steelblue,
                  label=(i == 1 ? "Certified box (real, ε-pen.)" : ""))
        else
            plot!(p, [i-0.12, i+0.12], [blo, blo], linecolor=:steelblue, linewidth=3,
                  label=(i == 1 ? "Certified box (≈0 width)" : ""))
        end
        scatter!(p, [i], [fixed], markershape=:diamond, markercolor=:red, markersize=6,
                 label=(i == 1 ? "Fixed point (OGF)" : ""))
    end
    return p
end

"Formats a single (label, phys_min, phys_max, lin_lo, lin_hi, real_lo, real_hi, fixed) row as one line of text."
function format_row(row)
    lbl, pmin, pmax, llo, lhi, blo, bhi, fixed = row
    lw = lhi - llo
    bw = bhi - blo
    note = bw < lw - 1e-6 ? "(real narrower)" : (bw > lw + 1e-6 ? "(real WIDER)" : "(equal)")
    return "$lbl: phys=[$(round(pmin,digits=3)),$(round(pmax,digits=3))] " *
           "linear-only=[$(round(llo,digits=3)),$(round(lhi,digits=3))] " *
           "real=[$(round(blo,digits=3)),$(round(bhi,digits=3))] " *
           "fixed=$(round(fixed,digits=3))  $note"
end

"Prints (and, if `io` given, also writes) a labeled block of formatted rows."
function print_rows(rows, label; io=nothing)
    println("  --- $label ---")
    for r in rows
        println("    " * format_row(r))
    end
    if io !== nothing
        println(io, "  --- $label ---")
        for r in rows
            println(io, "    " * format_row(r))
        end
    end
end

# ---------------------------------------------------------------------------
# Run one scenario end-to-end
# ---------------------------------------------------------------------------
function run_scenario(name, mutate_fp!, mutate_box!)
    println("="^90)
    println("SCENARIO: $name")
    println("="^90)

    # [1/5] Fixed point at the mutated operating point (Ipopt, per convention)
    println("[1/5] Solving OGF fixed point...")
    data_fp = GasModels.parse_file(CASE6_FILE)
    mutate_fp!(data_fp)
    result = solve_ogf(data_fp, WPGasModel, Ipopt.Optimizer)
    println("  OGF status = $(result["termination_status"])")
    fp_solution = result["solution"]

    # gm (and thus all physical bounds used by the IA box) is instantiated
    # against the "box" data, which may differ from the fixed-point data.
    data_box = GasModels.parse_file(CASE6_FILE)
    mutate_box!(data_box)
    gm = GasModels.instantiate_model(data_box, GasModels.WPGasModel, GasModels.build_ogf)
    gm.ext[:fixed_point] = fp_solution
    GasModels._prepare_ia_fixed_point!(gm)

    # [2/5] Real (nonconvex residual bounds) IA model -- SCIP, per convention
    println("[2/5] Building + solving real IA model (SCIP)...")
    real_model = GasModels.build_ia_model(
        gm, 0; π_scale=π_SCALE, linear_only=false, ε_secondary=ε_SECONDARY
    )
    set_optimizer(real_model, SCIP.Optimizer)
    optimize!(real_model)
    real_status = termination_status(real_model)
    println("  real IA status = $real_status")
    if !(real_status in ACCEPTABLE_STATUSES)
        println("  ✗ Real IA model did not solve to a usable solution -- skipping this scenario.")
        println("    (This can happen when the fixed point itself violates the box's own")
        println("     physical bounds, e.g. a relaxed-fp/tightened-box mismatch.)")
        println()
        return nothing
    end
    real_sol = GasModels.extract_ia_solution(gm, real_model, 0, π_scale=π_SCALE)

    # [3/5] Linear-only (residual = 0) IA model -- SCIP, per convention
    println("[3/5] Building + solving linear-only IA model (SCIP)...")
    lin_model = GasModels.build_ia_model(
        gm, 0; π_scale=π_SCALE, linear_only=true, ε_secondary=ε_SECONDARY
    )
    set_optimizer(lin_model, SCIP.Optimizer)
    optimize!(lin_model)
    lin_status = termination_status(lin_model)
    println("  linear-only IA status = $lin_status")
    if !(lin_status in ACCEPTABLE_STATUSES)
        println("  ✗ Linear-only IA model did not solve to a usable solution -- skipping this scenario.")
        println()
        return nothing
    end
    lin_sol = GasModels.extract_ia_solution(gm, lin_model, 0, π_scale=π_SCALE)

    # [4/5] Physical bounds in SI units (for state plots; input plots use the
    # physical_min/physical_max already carried in input_bounds) -- taken
    # from the "box" data, consistent with what gm/build_ia_model used.
    d_si = GasModels.parse_file(CASE6_FILE)
    mutate_box!(d_si)
    GasModels.make_si_units!(d_si)

    println("[4/5] Building flexibility tables + plots...")

    summary_path = joinpath(SUMMARYDIR, "$(name)_summary.txt")
    io = open(summary_path, "w")
    println(io, "="^90)
    println(io, "SCENARIO: $name")
    println(io, "="^90)
    println(io, "OGF status = $(result["termination_status"])")
    println(io, "real IA status = $real_status")
    println(io, "linear-only IA status = $lin_status")
    println(io)

    # --- Receipt flexibility (slack receipt injection, kg/s) ---
    receipt_rows = []
    for (k, _) in sort(collect(real_sol[:state_map][:slack_receipt]))
        d = d_si["receipt"][string(k)]
        br = real_sol[:state_bounds][(:slack_receipt, k)]
        bl = lin_sol[:state_bounds][(:slack_receipt, k)]
        push!(receipt_rows, ("Rcpt$k", d["injection_min"], d["injection_max"],
              bl.actual_lower, bl.actual_upper, br.actual_lower, br.actual_upper, br.fixed_point))
    end
    print_rows(receipt_rows, "Receipt flexibility"; io=io)
    p_receipt = floating_bar_plot(receipt_rows, title="Receipt flexibility — $name (case-6)", ylabel="Injection (kg/s)")
    savefig(p_receipt, joinpath(OUTDIR, "$(name)_states_receipt.png"))
    println("  saved $(joinpath(OUTDIR, "$(name)_states_receipt.png"))")

    # --- Pipe flow states (kg/s) ---
    pipe_flow_rows = []
    for k in sort(collect(keys(ref(gm, 0, :pipe))))
        d = d_si["pipe"][string(k)]
        br = real_sol[:state_bounds][(:pipe_flow, k)]
        bl = lin_sol[:state_bounds][(:pipe_flow, k)]
        push!(pipe_flow_rows, ("p$k", d["flow_min"], d["flow_max"],
              bl.actual_lower, bl.actual_upper, br.actual_lower, br.actual_upper, br.fixed_point))
    end
    print_rows(pipe_flow_rows, "Pipe flow states"; io=io)
    p_pipe_flow = floating_bar_plot(pipe_flow_rows, title="Pipe flow states — $name (case-6)", ylabel="Flow (kg/s)")
    savefig(p_pipe_flow, joinpath(OUTDIR, "$(name)_states_pipe_flow.png"))
    println("  saved $(joinpath(OUTDIR, "$(name)_states_pipe_flow.png"))")

    # --- Compressor flow states (kg/s) ---
    compressor_flow_rows = []
    for k in sort(collect(keys(ref(gm, 0, :compressor))))
        d = d_si["compressor"][string(k)]
        br = real_sol[:state_bounds][(:compressor_flow, k)]
        bl = lin_sol[:state_bounds][(:compressor_flow, k)]
        push!(compressor_flow_rows, ("c$k", d["flow_min"], d["flow_max"],
              bl.actual_lower, bl.actual_upper, br.actual_lower, br.actual_upper, br.fixed_point))
    end
    print_rows(compressor_flow_rows, "Compressor flow states"; io=io)
    p_compressor_flow = floating_bar_plot(compressor_flow_rows, title="Compressor flow states — $name (case-6)", ylabel="Flow (kg/s)")
    savefig(p_compressor_flow, joinpath(OUTDIR, "$(name)_states_compressor_flow.png"))
    println("  saved $(joinpath(OUTDIR, "$(name)_states_compressor_flow.png"))")

    # --- Pressure states: non-slack junctions (MPa) ---
    pressure_rows = []
    for (k, _) in sort(collect(real_sol[:state_map][:junction_psqr]))
        d = d_si["junction"][string(k)]
        br = real_sol[:state_bounds][(:junction_psqr, k)]
        bl = lin_sol[:state_bounds][(:junction_psqr, k)]
        push!(pressure_rows, ("J$k", d["p_min"]/1e6, d["p_max"]/1e6,
              bl.actual_lower/1e6, bl.actual_upper/1e6, br.actual_lower/1e6, br.actual_upper/1e6, br.fixed_point/1e6))
    end
    print_rows(pressure_rows, "Pressure states"; io=io)
    p_press = floating_bar_plot(pressure_rows, title="Junction pressures — $name (case-6)", ylabel="Pressure (MPa)")
    savefig(p_press, joinpath(OUTDIR, "$(name)_states_pressure.png"))
    println("  saved $(joinpath(OUTDIR, "$(name)_states_pressure.png"))")

    # --- Inputs: transfers (kg/s) ---
    transfer_rows = []
    for (k, _) in sort(collect(real_sol[:input_map][:transfer]))
        br = real_sol[:input_bounds][(:transfer, k)]
        bl = lin_sol[:input_bounds][(:transfer, k)]
        push!(transfer_rows, ("T$k", br.physical_min, br.physical_max,
              bl.actual_lower, bl.actual_upper, br.actual_lower, br.actual_upper, br.fixed_point))
    end
    print_rows(transfer_rows, "Transfers"; io=io)
    p_transfer = floating_bar_plot(transfer_rows, title="Transfer flexibility — $name (case-6)", ylabel="Transfer flow (kg/s)")
    savefig(p_transfer, joinpath(OUTDIR, "$(name)_inputs_transfer.png"))
    println("  saved $(joinpath(OUTDIR, "$(name)_inputs_transfer.png"))")

    # --- Inputs: compressor ratios ---
    ratio_rows = []
    for (k, _) in sort(collect(real_sol[:input_map][:compressor_ratio]))
        br = real_sol[:input_bounds][(:compressor_ratio, k)]
        bl = lin_sol[:input_bounds][(:compressor_ratio, k)]
        push!(ratio_rows, ("r$k", br.physical_min, br.physical_max,
              bl.actual_lower, bl.actual_upper, br.actual_lower, br.actual_upper, br.fixed_point))
    end
    print_rows(ratio_rows, "Compressor ratios"; io=io)
    p_ratio = floating_bar_plot(ratio_rows, title="Compressor ratio flexibility — $name (case-6)", ylabel="Compressor ratio")
    savefig(p_ratio, joinpath(OUTDIR, "$(name)_inputs_ratio.png"))
    println("  saved $(joinpath(OUTDIR, "$(name)_inputs_ratio.png"))")

    # [5/5] Transfer flexibility summary
    println("[5/5] Transfer flexibility summary (kg/s):")
    println(io, "[5/5] Transfer flexibility summary (kg/s):")
    for r in transfer_rows
        lbl, _, _, llo, lhi, blo, bhi, fixed = r
        line = "  $lbl: fixed=$(round(fixed,digits=4))  real=[$(round(blo,digits=4)),$(round(bhi,digits=4))]  " *
               "width=$(round(bhi-blo,digits=4))  linear-only width=$(round(lhi-llo,digits=4))"
        println(line)
        println(io, line)
    end
    println()
    close(io)
    println("  saved $summary_path")

    return (real=real_sol, linear=lin_sol, transfer_rows=transfer_rows)
end

# ---------------------------------------------------------------------------
# Run all scenarios
# ---------------------------------------------------------------------------
println("="^90)
println("INNER APPROXIMATION - SCENARIO SWEEP")
println("Plots -> $OUTDIR")
println("Summaries -> $SUMMARYDIR")
println("="^90)

results = Dict()
for (name, mutate_fp!, mutate_box!) in SCENARIOS
    results[name] = run_scenario(name, mutate_fp!, mutate_box!)
end

println("="^90)
ok = [n for (n, _, _) in SCENARIOS if results[n] !== nothing]
skipped = [n for (n, _, _) in SCENARIOS if results[n] === nothing]
println("✓ Scenarios completed: $(join(ok, ", "))")
isempty(skipped) || println("✗ Scenarios skipped (solve failed): $(join(skipped, ", "))")
println("="^90)
