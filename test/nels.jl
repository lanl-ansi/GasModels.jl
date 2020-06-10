@testset "test nels" begin

    @testset "test gaslib 40 misocp nels directed" begin
        @info "Testing gaslib misocp nels gaslib 40"
        result = run_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1254.15; atol = 1e-1)
    end

    @testset "test gaslib 40 minlp nels directed" begin
        @info "Testing gaslib minlp nels gaslib 40"
        result = run_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1255.1; atol = 1e-1)
    end

    @testset "test gaslib 40 mip nels directed" begin
        @info "Testing gaslib mip nels gaslib 40"
        result = run_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", MIPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1373.39; atol = 1e-1)
    end

    @testset "test gaslib 40 lp nels directed" begin
        @info "Testing gaslib lp nels gaslib 40"
        result = run_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", LPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1373.39; atol = 1e-1)
    end

    @testset "test gaslib 40 nlp nels directed" begin
        @info "Testing gaslib nlp nels gaslib 40"
        result = run_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", NLPGasModel, abs_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal || result["termination_status"] == ALMOST_LOCALLY_SOLVED
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 1255.56; atol = 1e-1)
    end
end
