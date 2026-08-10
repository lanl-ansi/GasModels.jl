# Inner Approximation Implementation Guide

**Complete reference for implementing inner approximation of gas flow input flexibility sets using Brouwer's fixed-point theorem.**

## Overview
Correct implementation based on Research_Ideas-2.pdf that:
1. Assembles J⋆ and R⋆ matrices
2. Inverts J⋆ 
3. Computes PRODUCTS and decomposes them
4. Writes constraints on equation (83)

## File Structure

```
src/prob/
├── ia.jl                  # Main entry point (exists)
├── ia_topology.jl         # Index mappings (✅ COMPLETED)
├── ia_matrix.jl          # Matrix assembly & inversion (✅ COMPLETED)
└── ia_constraints.jl     # Sufficient condition constraints (TODO)
```

## Implementation Status

### ✅ Completed

#### 1. `ia_topology.jl`
- `build_ia_state_map(gm, n)`: Maps [pipes, compressors, junctions] → state indices
- `build_ia_input_map(gm, n)`: Maps [ratios, receipts, deliveries, transfers, storage] → input indices
- `get_state_index(...)`: Helper to retrieve state index
- `get_input_index(...)`: Helper to retrieve input index

**Key**: Uses sorted IDs for consistent ordering!

#### 2. `ia_matrix.jl` (Core Logic)
- `assemble_ia_jacobian(gm, n, state_map)`: Builds J⋆ matrix
  - Rows: [Weymouth, Compressor boost, Mass balance]
  - Columns: [pipe flows, compressor flows, junction psqr]
  
- `assemble_ia_input_matrix(gm, n, state_map, input_map)`: Builds R⋆ matrix
  - R⋆ = -J_u (negative of input Jacobian)
  
- `decompose_matrix_positive_negative(M)`: M = M⁺ - M⁻
  
- `compute_ia_coefficient_matrices(gm, n)`: **MAIN FUNCTION**
  ```julia
  matrices = compute_ia_coefficient_matrices(gm, n)
  # Returns:
  #   - M_pos, M_neg: Decomposition of J⋆^{-1}R⋆ 
  #   - J_inv: Full J⋆^{-1} for residual coefficients
  #   - state_map, input_map
  #   - J, R: Original matrices
  ```

**Key Insight**: We decompose the PRODUCT M = J⋆^{-1}R⋆, not J⋆^{-1} itself!

### 🚧 TODO

#### 3. `ia_constraints.jl` (Inequality Generation)

Need to implement:

```julia
function generate_ia_sufficient_conditions!(gm, n, matrices)
    # For each state i:
    #   Δxᵢ = Σⱼ Mᵢⱼ Δuⱼ - Σₖ (J⋆^{-1})ᵢₖ rₖ(Δx, Δu)
    #
    # Upper bound: Φᵢ(Δx; Δu) ≤ ℓₓᵢ⁺
    #   Σⱼ (Mᵢⱼ⁺ℓᵤⱼ⁺ + Mᵢⱼ⁻ℓᵤⱼ⁻) - Σₖ (J⋆^{-1})ᵢₖ rₖ_min/max ≤ ℓₓᵢ⁺
    #
    # Lower bound: -ℓₓᵢ⁻ ≤ Φᵢ(Δx; Δu)
    #   Analogous with opposite signs
end
```

**Critical Part**: Residual bounds
- Pipe Weymouth: `γₑ(Δfₑ)` depends on flow direction (Section 1.3-1.4)
  - Without reversal: Simple quadratic bounds
  - With reversal: Piecewise bounds (Section 1.4.2)
  
- Compressor: `ηc(Δα, Δπᵢ) = Δα·Δπᵢ` (bilinear, Section 2.1)
  - Use McCormick-style bounds or explicit formulas from equation (47)

#### 4. Update `build_ia()` in `ia.jl`

Replace current constraint generation with:

```julia
function build_ia(gm::AbstractGasModel)
    _prepare_ia_fixed_point!(gm)
    variable_ia(gm)  # Creates ℓ variables (already exists)
    
    # NEW: Compute coefficient matrices
    matrices = compute_ia_coefficient_matrices(gm, nw_id_default)
    
    # Store in gm.ext for access
    gm.ext[:ia][:matrices] = matrices
    
    # NEW: Generate sufficient condition constraints
    generate_ia_sufficient_conditions!(gm, nw_id_default, matrices)
    
    # Add physical bounds (Section 5)
    add_ia_physical_bounds!(gm, nw_id_default, matrices)
    
    # Objective: Maximize polytope volume (Section 6.2)
    objective_max_ia_polytope(gm)
end
```

#### 5. Physical Bounds (Section 5)

```julia
function add_ia_physical_bounds!(gm, n, matrices)
    # Pressure bounds (5.1): ℓπᵢ⁻ ≤ πᵢ* - πᵢ_min, ℓπᵢ⁺ ≤ πᵢ_max - πᵢ*
    # Flow bounds (5.3): ℓfₑ⁻ ≤ fₑ* - fₑ_min, ℓfₑ⁺ ≤ fₑ_max - fₑ*
    # Compressor ratio bounds (5.2): Similar
end
```

#### 6. Objective Function

```julia
function objective_max_ia_polytope(gm::AbstractGasModel)
    # Strategy options:
    # 1. Volumetric: sum of all ℓ variables
    # 2. Weighted: prioritize certain inputs (e.g., deliveries)
    # 3. Min-max: maximize minimum ℓ
    
    JuMP.@objective(gm.model, Max,
        sum(var(gm, :l_pi_p)) + sum(var(gm, :l_pi_n)) +
        sum(var(gm, :l_f_pipe_p)) + sum(var(gm, :l_f_pipe_n)) +
        # ... all other ℓ variables
    )
end
```

## Current vs. Correct Approach

### ❌ Current (WRONG)
```julia
# Writes constraints directly on individual equations
constraint_ia_pipe_weymouth(gm, k)  # One constraint per pipe
constraint_ia_mass_flow_balance(gm, i)  # One constraint per junction
```
**Problem**: These don't capture the coupling through J⋆^{-1}!

### ✅ Correct (YOUR INSIGHT)
```julia
# 1. Assemble full system
J, R = assemble_ia_jacobian(...), assemble_ia_input_matrix(...)

# 2. Invert and compute products
M = inv(J) * R

# 3. Decompose PRODUCTS
M_pos, M_neg = decompose_matrix_positive_negative(M)

# 4. Write coupled constraints
# For each state i, constraint depends on ALL inputs through M[i, :]
# and ALL residuals through J_inv[i, :]
generate_ia_sufficient_conditions!(...)
```

## Key Equations

### Self-Map Form (Equation 83)
```
Δx = Φ(Δx; Δu) = J⋆^{-1}(R⋆Δu + r(Δx, Δu))
```

### Component-wise
```
Δxᵢ = Σⱼ Mᵢⱼ Δuⱼ + Σₖ (J⋆^{-1})ᵢₖ rₖ(Δx, Δu)
```
where `M = J⋆^{-1}R⋆`

### Sufficient Condition
Ensure `Φ(X, U) ⊆ X` where:
- `X = {Δx : -ℓₓ⁻ ≤ Δx ≤ ℓₓ⁺}`
- `U = {Δu : -ℓᵤ⁻ ≤ Δu ≤ ℓᵤ⁺}`

Becomes constraints on the ℓ bounds (decision variables).

## Testing Strategy

### Test 1: Matrix Assembly
```julia
@testset "Matrix assembly" begin
    gm = instantiate_model(case6_file, WPGasModel, build_ia)
    matrices = compute_ia_coefficient_matrices(gm, nw_id_default)
    
    @test size(matrices.J) == (11, 11)  # 4 pipes + 2 comps + 5 non-slack junctions
    @test abs(det(matrices.J)) > 1e-6   # J is invertible
    @test size(matrices.M_pos) == (11, 5)  # 5 inputs for case-6
end
```

### Test 2: Decomposition
```julia
@testset "Matrix decomposition" begin
    M = matrices.M_pos - matrices.M_neg
    M_check = matrices.J_inv * matrices.R
    @test maximum(abs.(M - M_check)) < 1e-10
end
```

### Test 3: Full Solve
```julia
@testset "Case-6 IA solve" begin
    fp_solution = JSON.parsefile("test/data/transient/case6_base_solution.json")
    result = solve_ia(case6_file, WPGasModel, optimizer,
                      ext = Dict(:fixed_point => fp_solution))
    
    @test result["termination_status"] == LOCALLY_SOLVED
    @test result["objective"] > 0  # Positive polytope volume
end
```

## Next Steps (Priority Order)

1. **Complete `ia_constraints.jl`** with residual bound expressions
   - Start with simple case: no flow reversal
   - Use global quadratic bounds from Lemma 1
   - Later: Add tighter case-specific bounds

2. **Update `build_ia()`** to use matrix-based approach

3. **Add objective function** for polytope maximization

4. **Test on case-6** with fixed point from `case6_base_solution.json`

5. **Verify sufficient conditions** are satisfied in solution

6. **Extend to flow reversal** using Section 1.4.2 bounds

7. **Scale to larger networks** (gaslib-40, gaslib-582)

## Questions to Address

1. **Residual bound expressions**: Should these be:
   - Constants computed from ℓ bounds (conservative)?
   - Expressions involving ℓ variables (tighter but more complex)?
   
   **Recommendation**: Start with constants, add expressions later.

2. **Bilinear terms** in compressor residual: Use McCormick envelopes or explicit max formulas?
   
   **Recommendation**: Use explicit max{...} as in equation (47).

3. **Objective function**: Which maximization strategy?
   
   **Recommendation**: Start with simple sum, add weighting later.

## File Includes

Need to add to `src/GasModels.jl`:
```julia
include("prob/ia.jl")
include("prob/ia_topology.jl")  # NEW
include("prob/ia_matrix.jl")    # NEW  
include("prob/ia_constraints.jl")  # NEW
```

Currently only `ia.jl` is included (line 160).
