@testset "test minlp ne" begin
    @testset "A1 MINLP case" begin
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MINLP case" begin
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
    @testset "A1 MISCOP case" begin
        obj_normalization = 1.0
        result = run_ne("../test/data/A1.json", MISOCPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        println(result["objective"]*obj_normalization)
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MISCOP case" begin
        obj_normalization = 1.0
        result = run_ne("../test/data/A2.json", MISOCPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

    #=
    # this case works in Pajarito v0.4 but not Pavito v0.1, not clear why
    @testset "A3 MISCOP case" begin
        obj_normalization = 1.0
        result = run_ne("../test/data/A3.json", MISOCPGasModel, pavito_solver_glpk; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end
    =#
end




