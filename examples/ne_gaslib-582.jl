@testset "test misocp ne gaslib 582" begin

    @testset "gaslib 582 case 5%" begin
        println("gaslib 582 - MISOCP 5%")
        result = run_ne("../examples/data/matgas/gaslib-582-5.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 582 case 10%" begin
        println("gaslib 582 - MISOCP 10%")
        result = run_ne("../examples/data/matgas/gaslib-582-10.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 582 case 25%" begin
        println("gaslib 582 - MISOCP 25%")
        result = run_ne("../examples/data/matgas/gaslib-582-25.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 582 case 50%" begin
        println("gaslib 582 - MISOCP 50%")
        result = run_ne("../examples/data/matgas/gaslib-582-50.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 14.93; atol = 1e-2)
        GC.gc()
     end

     @testset "gaslib 582 case 200%" begin
         println("gaslib 582 - MISOCP 200%")
         result = run_ne("../examples/data/matgas/gaslib-582-200.m", MISOCPGasModel, misocp_solver)
         @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
         GC.gc()
     end

     @testset "gaslib 582 case 300%" begin
         println("gaslib 582 - MISOCP 300%")
         result = run_ne("../examples/data/matgas/gaslib-582-300.m", MISOCPGasModel, misocp_solver)
         @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
         GC.gc()
     end

end
