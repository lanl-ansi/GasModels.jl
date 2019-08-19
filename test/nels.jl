#Check the second order cone model
#=
@testset "test misocp nels" begin
    @testset "gaslib 40 case" begin
        result = run_nels("../test/data/gaslib-40-nels.json", MISOCPGasModel, cvx_minlp_solver)
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
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.json", MISOCPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 108.255 * 10^6 / 24.0 / 60.0 / 60.0; atol = 1e-1) # conversion from 10^6 cubic meters per day to cubic meters per second
    end
end

#Check the second order cone model
@testset "test mip nels directed" begin
    @testset "gaslib 40 case" begin
        println("Testing gaslib mip nels gaslib 40")
        result = run_nels_directed("../test/data/gaslib-40-nelsfd.json", MIPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["baseQ"] , 1560.1204003868688; atol = 1e-1)
    end
end
