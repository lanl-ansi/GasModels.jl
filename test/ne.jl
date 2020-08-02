@testset "test ne" begin
    @testset "test minlp ne" begin
        @info "Testing minlp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test misocp ne" begin
        @info "Testing misocp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test mip ne" begin
        @info "Testing mip ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test lp ne" begin
        @info "Testing lp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

    @testset "test nlp ne" begin
        @info "Testing nlp ne"
        result = run_ne("../test/data/matgas/case-6-ne.m", NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1476; atol = 1e-1)
    end

end
