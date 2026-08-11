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
        @test haskey(result, :J_inv) && haskey(result, :J) && haskey(result, :R)

        # Test dimensions
        @test size(result.M_pos) == (11, 8)
        @test size(result.M_neg) == (11, 8)
        @test size(result.J_inv) == (11, 11)

        # Test decomposition: M = M⁺ - M⁻
        M = result.J_inv * result.R
        M_reconstructed = result.M_pos - result.M_neg
        @test maximum(abs.(M - M_reconstructed)) < 1e-10

        # Test non-negativity
        @test all(result.M_pos .>= -1e-10)
        @test all(result.M_neg .>= -1e-10)
    end

end
