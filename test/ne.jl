@testset "test minlp ne" begin
    @testset "A1 MINLP case" begin
        println("Testing A1 minlp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MINLP case" begin
        println("Testing A2 minlp ne")
        obj_normalization =  1.0
        result = run_ne("../test/data/A2.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

    @testset "A3 MINLP case" begin
        println("Testing A3 minlp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A3.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end

end

@testset "test misocp ne" begin
    @testset "A1 MISOCP case" begin
        println("Testing A1 misocp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", MISOCPGasModel, pavito_solver_glpk; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MISOCP case" begin
        println("Testing A2 misocp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A2.json", MISOCPGasModel, pavito_solver_glpk; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

end
