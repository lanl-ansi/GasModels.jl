#Check the second order code model
@testset "test misocp nelsfd" begin
    @testset "gaslib 40 case" begin
        result = run_nelsfd("../test/data/gaslib-40-nelsfd.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal || result["status"] == :Suboptimal
        @test isapprox(result["objective"], 108.372; atol = 1e-2)
    end      
end



