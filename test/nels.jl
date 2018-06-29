#Check the second order code model
@testset "test misocp nels" begin
    @testset "gaslib 40 case" begin
        result = run_nels("../test/data/gaslib-40-nels.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        if  misocp_solver == pajarito_solver_cbc # has some numerical stability challenges that creates slightly different solutions across platforms
            @test 100.0 * 10^6 / 24.0 / 60.0 / 60.0 <= result["objective"] <= 110.0 * 10^6 / 24.0 / 60.0 / 60.0
        else
            @test isapprox(result["objective"], 108.372 * 10^6 / 24.0 / 60.0 / 60.0; atol = 1e-2)
        end
    end      
end

#Check the second order code model
@testset "test misocp nels directed" begin
    @testset "gaslib 40 case" begin
        result = run_nels("../test/data/gaslib-40-nelsfd.json", MISOCPDirectedGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"], 108.372 * 10^6 / 24.0 / 60.0 / 60.0; atol = 1e-2) # conversion from 10^6 cubic meters per day to cubic meters per second
    end      
end


