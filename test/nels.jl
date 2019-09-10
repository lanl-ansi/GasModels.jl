#Check the second order cone model
#=
@testset "test misocp nels" begin
    @testset "gaslib 40 case" begin
        result = run_nels("../test/data/gaslib-40-nels.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        if  cvx_minlp_solver == pavito_solver_cbc # has some numerical stability challenges that creates slightly different solutions across platforms
            @test 98.0 * 10^6 / 24.0 / 60.0 / 60.0 <= result["objective"] * result["solution"]["baseQ"] <= 110.0 * 10^6 / 24.0 / 60.0 / 60.0
        else
            @test isapprox(result["objective"] * result["solution"]["baseQ"], 108.372 * 10^6 / 24.0 / 60.0 / 60.0; atol = 1e-2)
        end
    end
end
=#

#Check the second order cone model
@testset "test misocp nels directed" begin
    @testset "gaslib 40 case" begin
        println("Testing gaslib misocp nels gaslib 40")
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1252.95138889; atol = 1e-1)
    end
end

#Check the mip model
@testset "test mip nels directed" begin
    @testset "gaslib 40 case" begin
        println("Testing gaslib mip nels gaslib 40")
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", MIPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1371.8466068710943; atol = 1e-1)
    end
end

#Check the lp model
@testset "test lp nels directed" begin
    @testset "gaslib 40 case" begin
        println("Testing gaslib lp nels gaslib 40")
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", LPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1371.8466068710943; atol = 1e-1)
    end
end

#Check the nlp model
@testset "test nlp nels directed" begin
    @testset "gaslib 40 case" begin
        println("Testing gaslib nlp nels gaslib 40")
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.m", NLPGasModel, abs_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1254.3181889121502; atol = 1e-1)
    end
end
