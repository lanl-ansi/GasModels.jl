@testset "Inner Approximation" begin

    @testset "Topology - build_ia_state_map" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)
        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)

        state_map = GasModels.build_ia_state_map(gm, 0)

        # Test structure
        @test haskey(state_map, :pipe_flow)
        @test haskey(state_map, :compressor_flow)
        @test haskey(state_map, :junction_psqr)
        @test haskey(state_map, :dim)

        # Test dimensions for case-6
        @test length(state_map[:pipe_flow]) == 4
        @test length(state_map[:compressor_flow]) == 2
        @test length(state_map[:junction_psqr]) == 5  # 6 junctions - 1 slack
        @test state_map[:dim] == 11

        # Test slack junction exclusion
        @test !(1 in keys(state_map[:junction_psqr]))

        # Test continuous indexing
        indices = sort(collect(values(state_map[:pipe_flow])))
        append!(indices, sort(collect(values(state_map[:compressor_flow]))))
        append!(indices, sort(collect(values(state_map[:junction_psqr]))))
        @test indices == collect(1:state_map[:dim])
    end

    @testset "Topology - build_ia_input_map" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)
        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)

        input_map = GasModels.build_ia_input_map(gm, 0)

        # Test structure
        @test haskey(input_map, :compressor_ratio)
        @test haskey(input_map, :receipt)
        @test haskey(input_map, :delivery)
        @test haskey(input_map, :transfer)
        @test haskey(input_map, :storage)
        @test haskey(input_map, :dim)

        # Test dimensions for case-6
        @test length(input_map[:compressor_ratio]) == 2
        @test length(input_map[:receipt]) == 1
        @test length(input_map[:transfer]) == 5
        @test input_map[:dim] == 8

        # Test continuous indexing
        indices = sort(collect(values(input_map[:compressor_ratio])))
        append!(indices, sort(collect(values(input_map[:receipt]))))
        append!(indices, sort(collect(values(input_map[:transfer]))))
        @test indices == collect(1:input_map[:dim])
    end

    @testset "Topology - helper functions" begin
        mock_state_map = Dict(
            :pipe_flow => Dict(1 => 1, 2 => 2),
            :junction_psqr => Dict(2 => 3)
        )
        @test GasModels.get_state_index(mock_state_map, :pipe_flow, 1) == 1
        @test GasModels.get_state_index(mock_state_map, :pipe_flow, 999) === nothing

        mock_input_map = Dict(
            :compressor_ratio => Dict(1 => 1),
            :receipt => Dict(1 => 2)
        )
        @test GasModels.get_input_index(mock_input_map, :receipt, 1) == 2
        @test GasModels.get_input_index(mock_input_map, :delivery, 1) === nothing
    end

    @testset "Matrix - assemble_ia_jacobian" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)

        fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")
        fp_solution = JSON.parsefile(fp_file)

        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
        gm.ext[:fixed_point] = fp_solution
        GasModels._prepare_ia_fixed_point!(gm)

        state_map = GasModels.build_ia_state_map(gm, 0)
        J = GasModels.assemble_ia_jacobian(gm, 0, state_map)

        @test size(J) == (11, 11)
        @test SparseArrays.nnz(J) > 0
        @test abs(LinearAlgebra.det(Matrix(J))) > 1e-10  # Invertible
    end

    @testset "Matrix - assemble_ia_input_matrix" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)

        fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")
        fp_solution = JSON.parsefile(fp_file)

        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
        gm.ext[:fixed_point] = fp_solution
        GasModels._prepare_ia_fixed_point!(gm)

        state_map = GasModels.build_ia_state_map(gm, 0)
        input_map = GasModels.build_ia_input_map(gm, 0)
        R = GasModels.assemble_ia_input_matrix(gm, 0, state_map, input_map)

        @test size(R) == (11, 8)
        @test SparseArrays.nnz(R) > 0

        # Weymouth rows should be all zeros
        R_dense = Matrix(R)
        for i in 1:4
            @test all(abs.(R_dense[i, :]) .< 1e-10)
        end
    end

    @testset "Matrix - compute_ia_coefficient_matrices" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)

        fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")
        fp_solution = JSON.parsefile(fp_file)

        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
        gm.ext[:fixed_point] = fp_solution
        GasModels._prepare_ia_fixed_point!(gm)

        result = GasModels.compute_ia_coefficient_matrices(gm, 0)

        # Test all required fields
        @test haskey(result, :M_pos) && haskey(result, :M_neg)
        @test haskey(result, :N_pos) && haskey(result, :N_neg)
        @test haskey(result, :J_star) && haskey(result, :R_star)

        # Test dimensions
        @test size(result.M_pos) == (11, 8)
        @test size(result.M_neg) == (11, 8)
        @test size(result.N) == (11, 11)

        # Test decomposition: M = M^+ - M^-
        M = result.N * result.R_star
        M_reconstructed = result.M_pos - result.M_neg
        @test maximum(abs.(M - M_reconstructed)) < 1e-10

        # Test non-negativity
        @test all(result.M_pos .>= -1e-10)
        @test all(result.M_neg .>= -1e-10)

        # Test N decomposition: N = N^+ - N^-
        N_reconstructed = result.N_pos - result.N_neg
        @test maximum(abs.(result.N - N_reconstructed)) < 1e-10
    end

    @testset "DETAILED: Matrix assembly investigation" begin
        println("\n" * "="^80)
        println("DETAILED INVESTIGATION - Weymouth Coefficients & Jacobian")
        println("="^80)

        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)

        fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")
        fp_solution = JSON.parsefile(fp_file)

        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
        gm.ext[:fixed_point] = fp_solution
        GasModels._prepare_ia_fixed_point!(gm)

        println("\n--- PIPE COEFFICIENTS ---")
        base_flow = gm.ref[:it][GasModels.gm_it_sym][:base_flow]

        for k in sort(collect(keys(GasModels.ref(gm, 0, :pipe))))
            pipe = GasModels.ref(gm, 0, :pipe, k)
            f_star_pu = GasModels._ia_fp_value(gm, 0, :pipe, k, "f")
            f_star_si = f_star_pu * base_flow

            w = GasModels._calc_pipe_resistance(
                pipe,
                gm.ref[:it][GasModels.gm_it_sym][:base_length],
                gm.ref[:it][GasModels.gm_it_sym][:base_pressure],
                gm.ref[:it][GasModels.gm_it_sym][:base_flow],
                gm.ref[:it][GasModels.gm_it_sym][:sound_speed]
            )
            k_e = 2 * abs(f_star_pu) / w

            println("Pipe $k: f*=$(round(f_star_si, digits=2)) kg/s, " *
                   "w=$(Printf.@sprintf("%.2e", w)), " *
                   "k_e=$(Printf.@sprintf("%.2e", k_e))")
        end

        println("\n--- JACOBIAN MATRIX ---")
        state_map = GasModels.build_ia_state_map(gm, 0)
        input_map = GasModels.build_ia_input_map(gm, 0)
        J = GasModels.assemble_ia_jacobian(gm, 0, state_map)
        R = GasModels.assemble_ia_input_matrix(gm, 0, state_map, input_map)

        J_dense = Matrix(J)
        R_dense = Matrix(R)

        println("J⋆ size: $(size(J_dense))")
        println("det(J⋆) = $(Printf.@sprintf("%.2e", det(J_dense)))")
        println("κ(J⋆) = $(Printf.@sprintf("%.2e", cond(J_dense)))")

        println("\nWeymouth rows (flow coefficients):")
        for (idx, k) in enumerate(sort(collect(keys(GasModels.ref(gm, 0, :pipe)))))
            row = idx
            flow_col = state_map[:pipe_flow][k]
            println("  Row $row (Pipe $k): $(Printf.@sprintf("%10.2f", J_dense[row, flow_col]))")
        end

        println("\n--- FULL JACOBIAN J⋆ (11×11) ---")
        println("Rows: [Weymouth(1-4), Compressor(5-6), MassBalance(7-11)]")
        println("Cols: [Pipe flows(1-4), Comp flows(5-6), Junction π(7-11)]")
        for i in 1:size(J_dense, 1)
            row_str = "Row $(@sprintf("%2d", i)): ["
            for j in 1:size(J_dense, 2)
                val = J_dense[i, j]
                if abs(val) < 1e-10
                    row_str *= "      0.00"
                else
                    row_str *= @sprintf("%10.2f", val)
                end
            end
            row_str *= " ]"
            println(row_str)
        end

        println("\nR⋆ size: $(size(R_dense))")
        println("R⋆ non-zeros: $(SparseArrays.nnz(R))")

        println("\n--- FULL INPUT MATRIX R⋆ (11×8) ---")
        println("Rows: [Weymouth(1-4), Compressor(5-6), MassBalance(7-11)]")
        println("Cols: [α₁, α₂, fg₁, ft₁, ft₂, ft₃, ft₄, ft₅]")
        for i in 1:size(R_dense, 1)
            row_str = "Row $(@sprintf("%2d", i)): ["
            for j in 1:size(R_dense, 2)
                val = R_dense[i, j]
                if abs(val) < 1e-10
                    row_str *= "    0.00"
                else
                    row_str *= @sprintf("%8.2f", val)
                end
            end
            row_str *= " ]"
            println(row_str)
        end

        println("\n--- PRODUCT MATRIX M = J⋆⁻¹R⋆ (11×8) ---")
        result = GasModels.compute_ia_coefficient_matrices(gm, 0)
        M = result.M  # Already computed as N * R_star

        println("Rows: [Pipe flows(1-4), Comp flows(5-6), Junction π(7-11)]")
        println("Cols: [α₁, α₂, fg₁, ft₁, ft₂, ft₃, ft₄, ft₅]")
        for i in 1:size(M, 1)
            row_str = "Row $(@sprintf("%2d", i)): ["
            for j in 1:size(M, 2)
                val = M[i, j]
                if abs(val) < 1e-10
                    row_str *= "      0.00"
                else
                    row_str *= @sprintf("%10.5f", val)
                end
            end
            row_str *= " ]"
            println(row_str)
        end

        println("\n--- DECOMPOSED MATRICES ---")
        println("\nM⁺ (positive part, 11×8):")
        for i in 1:size(result.M_pos, 1)
            row_str = "Row $(@sprintf("%2d", i)): ["
            for j in 1:size(result.M_pos, 2)
                val = result.M_pos[i, j]
                if abs(val) < 1e-10
                    row_str *= "      0.00"
                else
                    row_str *= @sprintf("%10.5f", val)
                end
            end
            row_str *= " ]"
            println(row_str)
        end

        println("\nM⁻ (negative part, 11×8):")
        for i in 1:size(result.M_neg, 1)
            row_str = "Row $(@sprintf("%2d", i)): ["
            for j in 1:size(result.M_neg, 2)
                val = result.M_neg[i, j]
                if abs(val) < 1e-10
                    row_str *= "      0.00"
                else
                    row_str *= @sprintf("%10.5f", val)
                end
            end
            row_str *= " ]"
            println(row_str)
        end

        # Verify decomposition
        M_check = result.M_pos - result.M_neg
        decomp_error = maximum(abs.(M_check - M))
        println("\nDecomposition verification: M = M⁺ - M⁻")
        println("  Max error: $(Printf.@sprintf("%.2e", decomp_error))")
        println("  M⁺ range: [$(Printf.@sprintf("%.5f", minimum(result.M_pos))), $(Printf.@sprintf("%.5f", maximum(result.M_pos)))]")
        println("  M⁻ range: [$(Printf.@sprintf("%.5f", minimum(result.M_neg))), $(Printf.@sprintf("%.5f", maximum(result.M_neg)))]")

        println("="^80)
        println()

        # Still run the standard tests
        @test size(J_dense) == (11, 11)
        @test abs(det(J_dense)) > 1.0  # Should be much larger now!
        @test size(R_dense) == (11, 8)
        @test decomp_error < 1e-10
    end

    @testset "Residuals - compute_residual_bounds" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)

        fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")
        fp_solution = JSON.parsefile(fp_file)

        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
        gm.ext[:fixed_point] = fp_solution
        GasModels._prepare_ia_fixed_point!(gm)

        state_map = GasModels.build_ia_state_map(gm, 0)
        input_map = GasModels.build_ia_input_map(gm, 0)

        # Create small test bounds
        n_states = state_map[:dim]
        n_inputs = input_map[:dim]
        ℓ_x = zeros(n_states, 2)
        ℓ_x[:, 1] .= -0.1  # ℓ^-
        ℓ_x[:, 2] .= 0.1   # ℓ^+

        ℓ_u = zeros(n_inputs, 2)
        ℓ_u[:, 1] .= -0.05
        ℓ_u[:, 2] .= 0.05

        # Compute residual bounds
        r_minus, r_plus = GasModels.assemble_residual_bounds(gm, 0, state_map, input_map, ℓ_x, ℓ_u)

        @test length(r_minus) == n_states
        @test length(r_plus) == n_states

        # Weymouth residuals (rows 1-4): bounds depend on flow direction
        # For positive flow: [0, r^+], for negative flow: [r^-, 0]
        for i in 1:4
            @test r_minus[i] <= r_plus[i]
            # Either lower is ~0 (positive flow) or upper is ~0 (negative flow)
            @test (abs(r_minus[i]) < 1e-10) || (abs(r_plus[i]) < 1e-10)
        end

        # Compressor residuals (rows 5-6) can be positive or negative
        # (bilinear term)
        @test r_minus[5] <= r_plus[5]
        @test r_minus[6] <= r_plus[6]

        # Mass balance residuals (rows 7-11) should be zero
        for i in 7:11
            @test r_minus[i] == 0.0
            @test r_plus[i] == 0.0
        end

        println("\n--- RESIDUAL BOUNDS TEST ---")
        println("Weymouth residuals (rows 1-4):")
        for i in 1:4
            println("  Row $i: [$(Printf.@sprintf("%.2e", r_minus[i])), $(Printf.@sprintf("%.2e", r_plus[i]))]")
        end
        println("Compressor residuals (rows 5-6):")
        for i in 5:6
            println("  Row $i: [$(Printf.@sprintf("%.2e", r_minus[i])), $(Printf.@sprintf("%.2e", r_plus[i]))]")
        end
    end

    @testset "Optimization Model - build_ia_model" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)

        fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")
        fp_solution = JSON.parsefile(fp_file)

        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
        gm.ext[:fixed_point] = fp_solution
        GasModels._prepare_ia_fixed_point!(gm)

        # Build IA optimization model
        model = GasModels.build_ia_model(gm, 0)

        # Test model structure
        @test JuMP.num_variables(model) == 60  # 11*2 states + 8*2 inputs + 11*2 residuals

        # Test constraint counts
        total_constraints = sum(JuMP.num_constraints(model, F, S) for (F, S) in JuMP.list_of_constraint_types(model))
        @test total_constraints == 130

        # Test that key constraint types exist
        constraint_types = JuMP.list_of_constraint_types(model)
        @test any(t -> t[2] == MOI.GreaterThan{Float64}, constraint_types)  # Has GreaterThan constraints

        println("\n--- OPTIMIZATION MODEL TEST ---")
        println("Variables: $(JuMP.num_variables(model))")
        println("Constraints: $total_constraints")
        println("\nConstraint breakdown:")
        for (F, S) in JuMP.list_of_constraint_types(model)
            count = JuMP.num_constraints(model, F, S)
            println("  $F-in-$S: $count")
        end

        # Test objective exists
        @test JuMP.objective_sense(model) == MOI.MAX_SENSE
    end

    @testset "Optimization Model - solve with Ipopt" begin
        case6_file = joinpath(@__DIR__, "data", "matgas", "case-6.m")
        data = GasModels.parse_file(case6_file)

        fp_file = joinpath(@__DIR__, "data", "transient", "case6_base_solution.json")
        fp_solution = JSON.parsefile(fp_file)

        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_gf)
        gm.ext[:fixed_point] = fp_solution
        GasModels._prepare_ia_fixed_point!(gm)

        # Build and solve IA optimization model
        model = GasModels.build_ia_model(gm, 0)
        JuMP.set_optimizer(model, Ipopt.Optimizer)
        JuMP.set_optimizer_attribute(model, "print_level", 0)
        JuMP.optimize!(model)

        # Test solve status
        @test JuMP.termination_status(model) in [MOI.LOCALLY_SOLVED, MOI.OPTIMAL]
        @test JuMP.primal_status(model) == MOI.FEASIBLE_POINT

        # Test solution is non-trivial
        ℓ_x_plus = JuMP.value.(model[:ℓ_x_plus])
        ℓ_x_minus = JuMP.value.(model[:ℓ_x_minus])
        ℓ_u_plus = JuMP.value.(model[:ℓ_u_plus])
        ℓ_u_minus = JuMP.value.(model[:ℓ_u_minus])

        @test all(ℓ_x_plus .>= -1e-6)
        @test all(ℓ_x_minus .>= -1e-6)
        @test all(ℓ_u_plus .>= -1e-6)
        @test all(ℓ_u_minus .>= -1e-6)

        # Test that polytope is non-degenerate (at least some non-zero bounds)
        @test sum(ℓ_x_plus .+ ℓ_x_minus) > 0.01
        @test sum(ℓ_u_plus .+ ℓ_u_minus) > 0.01

        obj_value = JuMP.objective_value(model)
        @test obj_value > 0.01

        println("\n--- SOLVE TEST ---")
        println("Termination: $(JuMP.termination_status(model))")
        println("Objective: $(Printf.@sprintf("%.6f", obj_value))")
        println("\nState bounds (first 5):")
        for i in 1:min(5, length(ℓ_x_plus))
            println("  State $i: [-$(Printf.@sprintf("%.4f", ℓ_x_minus[i])), +$(Printf.@sprintf("%.4f", ℓ_x_plus[i]))]")
        end
        println("\nInput bounds (first 5):")
        for i in 1:min(5, length(ℓ_u_plus))
            println("  Input $i: [-$(Printf.@sprintf("%.4f", ℓ_u_minus[i])), +$(Printf.@sprintf("%.4f", ℓ_u_plus[i]))]")
        end
    end

end
