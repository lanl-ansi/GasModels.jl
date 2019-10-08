#Check the second order code model
@testset "test misocp gf" begin
    @testset "gaslib 582 case" begin
        println("gaslib 582 - MISCOP")
        result = run_gf("../test/data/gaslib-582.json", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end
end


# Check the full nonlinear model
@testset "test minlp gf" begin
        @testset "gaslib 40 case" begin
            println("gaslib 40 - MINLP")
            result = run_gf("../test/data/gaslib-40.m", MINLPGasModel, minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
#        @testset "gaslib 135 case" begin
 #           println("gaslib 135 - MINLP")
  #          result = run_gf("../test/data/gaslib-135.m", MINLPGasModel, minlp_solver)
   #         @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    #        @test isapprox(result["objective"], 0; atol = 1e-6)
   #     end
end


# Check the full nonlinear model
@testset "test nlp gf" begin
        @testset "gaslib 40 case" begin
            println("gaslib 40 - NLP")
            result = run_gf("../test/data/gaslib-40.m", NLPGasModel, minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
#        @testset "gaslib 135 case" begin
#            println("gaslib 135 - NLP")
#            result = run_gf("../test/data/gaslib-135.m", NLPGasModel, minlp_solver)
#            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#            @test isapprox(result["objective"], 0; atol = 1e-6)
#        end
end
