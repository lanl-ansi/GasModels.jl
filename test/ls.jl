#Check the second order code model
if misocp_solver != pajarito_solver  
    @testset "test misocp ls" begin
        @testset "gaslib 40 case" begin
            result = run_ls("../test/data/gaslib-40-ls.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 44.587; atol = 1e-2)  
        end      
    end
end



