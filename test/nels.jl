@testset "test nels" begin

    @testset "test misocp nels" begin
        @info "Testing misocp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end

    @testset "test minlp nels" begin
        @info "Testing minlp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end

    @testset "test mip nels" begin
        @info "Testing mip nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1036.93; atol = 1e-1)
    end

    @testset "test lp nels" begin
        @info "Testing lp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1036.93; atol = 1e-1)
    end

    @testset "test nlp nels" begin
        @info "Testing nlp nels"
        result = run_nels("../test/data/matgas/case-6-nels.m", NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal || result["termination_status"] == ALMOST_LOCALLY_SOLVED
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1031.60; atol = 1e-1)
    end
end
