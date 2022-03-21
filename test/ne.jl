@testset "test ne" begin
    @testset "test dwp ne" begin
        @info "Testing dwp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test crdwp ne" begin
        @info "Testing crdwp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test lrdwp ne" begin
        @info "Testing lrdwp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test lrwp ne" begin
        @info "Testing lrwp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test wp ne" begin
        @info "Testing wp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", WPGasModel, minlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1326; atol = 1e-1)
    end
end
