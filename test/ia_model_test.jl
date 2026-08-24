"""
Test script for Inner Approximation model construction and solving.

This demonstrates the full IA workflow:
1. Load network data
2. Load fixed point solution
3. Compute coefficient matrices (M, N decompositions)
4. Build optimization model
5. (Optional) Solve with nonlinear optimizer

Run from GasModels.jl directory:
    julia --project=. test/ia_model_test.jl
"""

using GasModels, JSON, JuMP, Ipopt

println("="^80)
println("INNER APPROXIMATION - MODEL TEST")
println("="^80)

# Load network data
println("\n[1/5] Loading network data...")
case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")

data = GasModels.parse_file(case6_file)
fp_solution = JSON.parsefile(fp_file)

# Instantiate gas model
println("[2/5] Instantiating gas model...")
gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
gm.ext[:fixed_point] = fp_solution
GasModels._prepare_ia_fixed_point!(gm)

# Compute and display matrices
# Set π_scale here: 1.0 = no scaling, 200.0 = improved conditioning
π_scale = 1.0
println("[3/5] Computing IA matrices (π_scale = $π_scale)...")
matrices = GasModels.compute_ia_coefficient_matrices(gm, 0, π_scale=π_scale)

println("\n" * "="^80)
println("COEFFICIENT MATRICES (PER-UNIT)")
println("="^80)

println("\nJ (Jacobian) matrix ($(size(matrices.J_star))):")
display(matrices.J_star)

println("\n\nR (Input) matrix ($(size(matrices.R_star))):")
display(matrices.R_star)

println("\n\nM = J⁻¹·R matrix ($(size(matrices.M))):")
display(matrices.M)

println("\n\nN = J⁻¹ matrix ($(size(matrices.N))):")
display(matrices.N)

println("\n\nState map:")
for (key, val) in matrices.state_map
    key == :dim && continue
    if !isempty(val)
        println("  $key: $(length(val)) variables")
    end
end

println("\nInput map:")
for (key, val) in matrices.input_map
    key == :dim && continue
    if !isempty(val)
        println("  $key: $(length(val)) variables")
    end
end

# Build IA optimization model
println("\n[4/5] Building IA optimization model...")
model = GasModels.build_ia_model(gm, 0, π_scale=π_scale)

# Model statistics
println("\n" * "="^80)
println("MODEL STATISTICS")
println("="^80)
println("  Variables: ", num_variables(model))
println("  Constraints: ", sum(num_constraints(model, F, S) for (F, S) in list_of_constraint_types(model)))
println("\n  Constraint breakdown:")
for (F, S) in list_of_constraint_types(model)
    count = num_constraints(model, F, S)
    println("    $F-in-$S: $count")
end

# Solve with Ipopt
println("\n" * "="^80)
println("SOLVING")
println("="^80)
set_optimizer(model, Ipopt.Optimizer)
set_optimizer_attribute(model, "print_level", 3)
optimize!(model)

if termination_status(model) in [MOI.LOCALLY_SOLVED, MOI.OPTIMAL]
    println("\n✓ Optimization converged!")

    # Extract and display solution in SI units
    solution = GasModels.extract_ia_solution(gm, model, 0, π_scale=π_scale)
    GasModels.print_ia_solution(solution)
else
    println("\n✗ Optimization failed: ", termination_status(model))
end

println("\n" * "="^80)
println("✓ Model construction successful!")
println("="^80)
