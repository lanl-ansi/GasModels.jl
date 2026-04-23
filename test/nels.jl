@testset "test nels" begin
    @testset "test crdwp nels" begin
        @_info "Testing crdwp nels"
        result = solve_nels("../test/data/matgas/case-6-nels.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end

    @testset "test dwp nels" begin
        @_info "Testing dwp nels"
        result = solve_nels("../test/data/matgas/case-6-nels.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end

    @testset "test lrdwp nels" begin
        @_info "Testing lrdwp nels"
        result = solve_nels("../test/data/matgas/case-6-nels.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1036.93; atol = 1e-1)
    end

    @testset "test lrwp nels" begin
        @_info "Testing lrwp nels"
        result = solve_nels("../test/data/matgas/case-6-nels.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1036.93; atol = 1e-1)
    end

    @testset "test wp nels" begin
        @_info "Testing wp nels"
        result = solve_nels("../test/data/matgas/case-6-nels.m", WPGasModel, minlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end

    @testset "test cwp nels" begin
        @_info "Testing cwp nels"
        result = solve_nels("../test/data/matgas/case-6-nels.m", CWPGasModel, minlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end
end
