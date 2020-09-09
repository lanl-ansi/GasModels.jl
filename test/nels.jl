@testset "test nels" begin

    @testset "test crdwp nels" begin
        @info "Testing crdwp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL ||
              result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end

    @testset "test dwp nels" begin
        @info "Testing dwp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL ||
              result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end

    @testset "test lrdwp nels" begin
        @info "Testing lrdwp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL ||
              result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1036.93; atol = 1e-1)
    end

    @testset "test lrwp nels" begin
        @info "Testing lrwp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL ||
              result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1036.93; atol = 1e-1)
    end

    @testset "test wp nels" begin
        @info "Testing wp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL ||
              result["termination_status"] == :Suboptimal ||
              result["termination_status"] == ALMOST_LOCALLY_SOLVED
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end
end
