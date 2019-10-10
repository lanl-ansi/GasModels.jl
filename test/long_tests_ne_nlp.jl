@testset "test nlp ne" begin
    @testset "A1 NLP case" begin
        println("A1 NLP")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/A1.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end


#    @testset "A2 NLP case" begin
#        println("A2 MINLP")
#        obj_normalization = 10.0
#        result = run_ne("../test/data/A2.m", NLPGasModel, scip_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
#    end


#    @testset "A3 NLP case" begin
#        println("A3 NLP")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/A3.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
#    end


#    @testset "gaslib 40 5% case" begin
#        println("gaslib 40 - NLP 5%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-5.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 11924688; atol = 1e3)
#    end


#    @testset "gaslib 40 10% case" begin
#        println("gaslib 40 - NLP 10%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-10.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 32827932; atol = 1e3)
#    end


#    @testset "gaslib 40 25% case" begin
#        println("gaslib 40 - NLP 25%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-25.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 41082189; atol = 1e3)
#    end


#    @testset "gaslib 40 50% case" begin
#        println("gaslib 40 - NLP 50%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-50.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 156055200; atol = 1e3)
#    end


#    @testset "gaslib 40 75% case" begin
#        println("gaslib 40 - NLP 75%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-75.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 333007019; atol = 1e3)
#    end


#    @testset "gaslib 40 100% case" begin
#        println("gaslib 40 - NLP 100%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-100.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*obj_normalization, 551644663; atol = 1e3)
#    end


#    @testset "gaslib 40 125% case" begin
#        println("gaslib 40 - NLP 125%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-125.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
#    end


#    @testset "gaslib 40 150% case" begin
#        println("gaslib 40 - NLP 150%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-40-150.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
#    end


#        @testset "gaslib 135 5% case" begin
 #           println("gaslib 135 - NLP 5%")
#            obj_normalization = 1000000.0


  #          result = run_ne("../test/data/gaslib-135-5.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
   #         @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    #        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-2)
    #    end
#        @testset "gaslib 135 25% case" begin
#            println("gaslib 135 - NLP 25%")
#            obj_normalization = 1000000.0

#            result = run_ne("../test/data/gaslib-135-25.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#            @test isapprox(result["objective"]*obj_normalization, 6040000; atol = 1.0)
#        end


#    @testset "gaslib 135 125% case" begin
#        println("gaslib 135 - NLP 125%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-135-125.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
#    end


#    @testset "gaslib 135 150% case" begin
#        println("gaslib 135 - NLP 150%")
#        obj_normalization = 1000000.0
#        result = run_ne("../test/data/gaslib-135-150.m", NLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
#    end


#    @testset "gaslib 135 200% case" begin
#        println("gaslib 135 - NLP 200%")
#        result = run_ne("../test/data/gaslib-135-200.m", NLPGasModel, minlp_solver)
#        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
#    end
end
