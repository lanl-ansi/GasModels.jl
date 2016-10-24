#Check the second order code model
@testset "test misocp nels" begin
    @testset "gaslib 40 case" begin
        result = run_nels("../test/data/gaslib-40-nels.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        println(result["objective"])  
        @test isapprox(result["objective"], 122.17; atol = 1e-2)
    end      
end




