#Check the second order code model
@testset "test misocp ls" begin
    @testset "gaslib 40 case" begin
        result = run_ls("../test/data/gaslib-40-ls.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 44.587 * 10^6 / 24.0 / 60.0 / 60.0; atol = 1e-2) # multiplication is due to conversion to SI units (10^6 m^3 per day to m^3 per second)
     end      
end



