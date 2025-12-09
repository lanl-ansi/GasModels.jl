@testset "test ne" begin
    @testset "test dwp ne" begin
        @info "Testing dwp ne"
        result = solve_ne("../test/data/matgas/case-6-ne.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test crdwp ne" begin
        @info "Testing crdwp ne"
        result = solve_ne("../test/data/matgas/case-6-ne.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test lrdwp ne" begin
        @info "Testing lrdwp ne"
        result = solve_ne("../test/data/matgas/case-6-ne.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test lrwp ne" begin
        @info "Testing lrwp ne"
        result = solve_ne("../test/data/matgas/case-6-ne.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"], 1476, atol = 1e-1)
    end

    @testset "test wp ne" begin
        @info "Testing wp ne"
        result = solve_ne("../test/data/matgas/case-6-ne.m", WPGasModel, minlp_solver)
        if result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 1476; atol = 1e-1)
        else # CI compat for windows on Julia v1.6, 01/29/24
            @test result["termination_status"] in [ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        end
    end

    @testset "test cwp ne" begin
        @info "Testing cwp ne"
        result = solve_ne("../test/data/matgas/case-6-ne.m", CWPGasModel, minlp_solver)
        if result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 1476; atol = 1e-1)
        else # CI compat for windows on Julia v1.6, 01/29/24
            @test result["termination_status"] in [ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        end
    end
end
