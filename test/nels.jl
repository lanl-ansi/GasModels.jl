@testset "test nels" begin
    #=
    @testset "test misocp nels" begin
        @testset "gaslib 40 case" begin
            result = solve_nels("../test/data/matgas/gaslib-40-nels.m", MISOCPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            if  cvx_minlp_solver == pavito_solver_cbc # has some numerical stability challenges that creates slightly different solutions across platforms
                @test 98.0 * 10^6 / 24.0 / 60.0 / 60.0 <= result["objective"] * result["solution"]["base_flow"] <= 110.0 * 10^6 / 24.0 / 60.0 / 60.0
            else
                @test isapprox(result["objective"] * result["solution"]["base_flow"], 108.372 * 10^6 / 24.0 / 60.0 / 60.0; atol = 1e-2)
            end
        end
    end
    =#

    @testset "test gaslib 40 misocp nels directed" begin
        @info "Testing gaslib misocp nels gaslib 40"
        result = solve_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"] , 1560.12; atol = 1e-1)
    end

    @testset "test gaslib 40 mip nels directed" begin
        @info "Testing gaslib mip nels gaslib 40"
        result = solve_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", MIPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"] , 1560.12; atol = 1e-1)
    end

    @testset "test gaslib 40 lp nels directed" begin
        @info "Testing gaslib lp nels gaslib 40"
        result = solve_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", LPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"] , 1560.12; atol = 1e-1)
    end

    @testset "test gaslib 40 nlp nels directed" begin
        @info "Testing gaslib nlp nels gaslib 40"
        result = solve_nels_directed("../test/data/matgas/gaslib-40-nelsfd.m", NLPGasModel, abs_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal || result["termination_status"] == ALMOST_LOCALLY_SOLVED
        @test isapprox(result["objective"] * result["solution"]["base_flow"] , 1560.12; atol = 1e-1)
    end
end
