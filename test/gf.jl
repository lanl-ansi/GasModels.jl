
minlp_solver = couenne_solver # Paper used SCIP
misocp_solver = bonmin_solver # Paper used CPLEX - switch to Pajirito

#@testset "test minlp gf" begin
 #   @testset "gaslib 40 case" begin
  #      result = run_gf("../test/data/gaslib-40.json", MINLPGasModel, minlp_solver)
        
   #     @test result["status"] == :LocalOptimal
    #    @test isapprox(result["objective"], 0; atol = 1e-6)

#        @test isapprox(result["solution"]["gen"][1]["pg"], 148.0; atol = 1e-1)
 #       @test isapprox(result["solution"]["gen"][1]["qg"], 54.6; atol = 1e-1)

  #      @test isapprox(result["solution"]["bus"][1]["vm"], 1.10000; atol = 1e-3)
   #     @test isapprox(result["solution"]["bus"][1]["va"], 0.00000; atol = 1e-3)

    #    @test isapprox(result["solution"]["bus"][2]["vm"], 0.92617; atol = 1e-3)
    #    @test isapprox(result["solution"]["bus"][2]["va"], 7.25886; atol = 1e-3)

     #   @test isapprox(result["solution"]["bus"][3]["vm"], 0.90000; atol = 1e-3)
      #  @test isapprox(result["solution"]["bus"][3]["va"], -17.26711; atol = 1e-3)
#    end
#    @testset "24-bus rts case" begin
 #       result = run_pf("../test/data/case24.json", ACPPowerModel, ipopt_solver)

  #      @test result["status"] == :LocalOptimal
   #     @test isapprox(result["objective"], 0; atol = 1e-2)
   # end
#end


@testset "test misocp gf" begin
    @testset "gaslib 40 case" begin
        result = run_gf("../test/data/gaslib-40.json", MISOCPGasModel, misocp_solver)

        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-6)

#        @test isapprox(result["solution"]["gen"][1]["pg"], 148.0; atol = 1e-1)
 #       @test isapprox(result["solution"]["gen"][1]["qg"], 54.6; atol = 1e-1)

  #      @test isapprox(result["solution"]["bus"][1]["vm"], 1.10000; atol = 1e-3)
   #     @test isapprox(result["solution"]["bus"][1]["va"], 0.00000; atol = 1e-3)

    #    @test isapprox(result["solution"]["bus"][2]["vm"], 0.92617; atol = 1e-3)
    #    @test isapprox(result["solution"]["bus"][2]["va"], 7.25886; atol = 1e-3)

     #   @test isapprox(result["solution"]["bus"][3]["vm"], 0.90000; atol = 1e-3)
      #  @test isapprox(result["solution"]["bus"][3]["va"], -17.26711; atol = 1e-3)
    end
#    @testset "24-bus rts case" begin
 #       result = run_pf("../test/data/case24.json", ACPPowerModel, ipopt_solver)

  #      @test result["status"] == :LocalOptimal
   #     @test isapprox(result["objective"], 0; atol = 1e-2)
   # end
end





