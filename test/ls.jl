#Check the second order code model
@testset "test misocp ls" begin
    @testset "gaslib 40 case" begin
        result = run_ls("../test/data/gaslib-40-ls.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        if misocp_solver == gurobi_solver  
            @test isapprox(result["objective"], 58.38; atol = 1e-2)
        else
            @test isapprox(result["objective"], 6.65; atol = 1e-2)          
        end
    end      
end




