@testset "test misocp ne" begin
    @testset "A1 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../test/data/matgas/A1.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../test/data/matgas/A2.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

    @testset "A3 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../examples/data/matgas/A3.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end




    end


end
