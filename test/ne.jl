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

    # @testset "A3 MINLP case" begin
    #     obj_normalization = 1.0
    #     result = run_ne("../test/data/A3.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
    #     @test result["status"] == :LocalOptimal || result["status"] == :Optimal
    #     @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    # end

end

@testset "test misocp ne" begin
    @testset "A1 MISOCP case" begin
        println("Testing A1 misocp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", MISOCPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MISOCP case" begin
        println("Testing A2 misocp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A2.json", MISOCPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end
end

@testset "test mip ne" begin
    @testset "A1 MIP case" begin
        println("Testing A1 mip ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", MIPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0001168127693870263; atol = 1e-1)
    end

    @testset "A2 MIP case" begin
        println("Testing A2 mip ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A2.json", MIPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0001848186414315826; atol = 1e-1)
    end
end

@testset "test lp ne" begin
    @testset "A1 LP case" begin
        println("Testing A1 lp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", LPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0001168127693870263; atol = 1e-1)
    end

    @testset "A2 LP case" begin
        println("Testing A2 lp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A2.json", LPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0001848186414315826; atol = 1e-1)
    end
end

@testset "test nlp ne" begin
    @testset "A1 NLP case" begin
        println("Testing A1 nlp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", NLPGasModel, abs_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 NLP case" begin
        println("Testing A2 nlp ne")
        obj_normalization = 1.0
        result = run_ne("../test/data/A2.json", NLPGasModel, abs_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
#        @test isapprox(result["objective"]*obj_normalization, 3222.1,; atol = 1e-1)
    end
end
