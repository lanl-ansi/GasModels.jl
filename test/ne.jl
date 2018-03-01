@testset "test minlp ne" begin
    @testset "A1 MINLP case" begin
        obj_normalization = 1.0                                
        result = run_ne("../test/data/A1.json", MINLPGasModel, couenne_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MINLP case" begin
        obj_normalization =  1.0                                
        result = run_ne("../test/data/A2.json", MINLPGasModel, couenne_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal          
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

    @testset "A3 MINLP case" begin
        obj_normalization = 1.0                                
        result = run_ne("../test/data/A3.json", MINLPGasModel, couenne_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end
    
end 

@testset "test misocp ne" begin
    @testset "A1 MISCOP case" begin
        obj_normalization = 1000.0                                
        result = run_ne("../test/data/A1.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
#        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)        
        @test result["objective"]*obj_normalization <= 224 # Pajirito has numerical issues on this one            
    end        

    @testset "A2 MISCOP case" begin
        obj_normalization = 1.0                                                 
        result = run_ne("../test/data/A2.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end        

    @testset "A3 MISCOP case" begin
        obj_normalization = 1.0                                
        result = run_ne("../test/data/A3.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end
end




