@testset "test nels" begin
    #=
    @testset "test misocp nels" begin
        @testset "gaslib 40 case" begin
            result = run_nels("../test/data/gaslib-40-nels.m", MISOCPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            if  cvx_minlp_solver == pavito_solver_cbc # has some numerical stability challenges that creates slightly different solutions across platforms
                @test 98.0 * 10^6 / 24.0 / 60.0 / 60.0 <= result["objective"] * result["solution"]["baseQ"] <= 110.0 * 10^6 / 24.0 / 60.0 / 60.0
            else
                @test isapprox(result["objective"] * result["solution"]["baseQ"], 108.372 * 10^6 / 24.0 / 60.0 / 60.0; atol = 1e-2)
            end
        end
    end
    =#

    @testset "test gaslib 40 misocp nels directed" begin
        @info "Testing gaslib misocp nels gaslib 40"
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1252.95138889; atol = 1e-1)
    end

    @testset "test gaslib 40 mip nels directed" begin
        @info "Testing gaslib mip nels gaslib 40"
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", MIPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1371.8466068710943; atol = 1e-1)
    end

    @testset "test gaslib 40 lp nels directed" begin
        @info "Testing gaslib lp nels gaslib 40"
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", LPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1371.8466068710943; atol = 1e-1)
    end

    @testset "test gaslib 40 nlp nels directed" begin
        @info "Testing gaslib nlp nels gaslib 40"
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", NLPGasModel, abs_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1254.3181889121502; atol = 1e-1)
    end
end
