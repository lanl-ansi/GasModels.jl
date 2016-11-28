#Check the second order code model
if misocp_solver == gurobi_solver  
    @testset "test misocp nels" begin
        @testset "gaslib 40 case" begin
            result = run_nels("../test/data/gaslib-40-nels.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 108.372; atol = 1e-2)
        end      
    end
end



