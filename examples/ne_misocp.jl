@testset "test misocp ne" begin
    @testset "A1 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../test/data/matgas/A1.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../test/data/matgas/A2.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

    @testset "A3 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../examples/data/matgas/A3.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end




    end

    @testset "gaslib 582 case 5%" begin
        println("gaslib 582 - MISOCP 5%")
        obj_normalization = 10000.0
        result = run_ne("../examples/data/matgas/gaslib-582-5.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end

    @testset "gaslib 582 case 10%" begin
        println("gaslib 582 - MISOCP 10%")
        obj_normalization = 1.0
        result = run_ne("../examples/data/matgas/gaslib-582-10.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end

    @testset "gaslib 582 case 25%" begin
        println("gaslib 582 - MISOCP 25%")
        obj_normalization = 1.0
        result = run_ne("../examples/data/matgas/gaslib-582-25.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end

    @testset "gaslib 582 case 50%" begin
        println("gaslib 582 - MISOCP 50%")
        obj_normalization = 1.0
        result = run_ne("../examples/data/matgas/gaslib-582-50.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*obj_normalization, 1.493228019682e7; atol = 1e3)
     end

     @testset "gaslib 582 case 200%" begin
         println("gaslib 582 - MISOCP 200%")
         obj_normalization = 1000000.0
         result = run_ne("../examples/data/matgas/gaslib-582-200.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
         @test result["termination_status"] == INFEASIBLE
     end

     @testset "gaslib 582 case 300%" begin
         println("gaslib 582 - MISOCP 300%")
         obj_normalization = 1000000.0
         result = run_ne("../examples/data/matgas/gaslib-582-300    ", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
         @test result["termination_status"] == INFEASIBLE
     end
end
