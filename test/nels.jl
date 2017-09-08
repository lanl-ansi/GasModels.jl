#Check the second order code model
@testset "test misocp nels" begin
    @testset "gaslib 40 case" begin
        result = run_nels("../test/data/gaslib-40-nels.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        if  misocp_solver == pajarito_solver # has some numerical stability challenges that creates slightly different solutions across platforms
            @test 100.0 <= result["objective"] <= 110.0
        else
            @test isapprox(result["objective"], 108.372; atol = 1e-2)
        end
    end      
end



