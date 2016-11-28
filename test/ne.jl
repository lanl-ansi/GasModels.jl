@testset "test minlp ne" begin
    @testset "A1 MINLP case" begin
        result = run_ne("../test/data/A1.json", MINLPGasModel, couenne_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.444e-4; atol = 1e-2)
    end

    @testset "A2 MINLP case" begin
        result = run_ne("../test/data/A2.json", MINLPGasModel, couenne_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.687e-3; atol = 1e-2)
    end

    @testset "A3 MINLP case" begin
        result = run_ne("../test/data/A3.json", MINLPGasModel, couenne_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.781e-3; atol = 1e-2)
    end
    
end 


@testset "test misocp ne" begin
    @testset "A1 MISCOP case" begin
        result = run_ne("../test/data/A1.json", MISOCPGasModel, misocp_solver)
        println(result["objective"])
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.444e-4; atol = 1e-2)
    end        

    @testset "A2 MISCOP case" begin
        result = run_ne("../test/data/A2.json", MISOCPGasModel, misocp_solver) 
        println(result["objective"])
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.687e-3; atol = 1e-2)
    end        

    @testset "A3 MISCOP case" begin
        result = run_ne("../test/data/A3.json", MISOCPGasModel, misocp_solver)
        println(result["objective"])
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.781e-3; atol = 1e-2)
    end
end




