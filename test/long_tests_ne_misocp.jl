@testset "test misocp ne" begin
    @testset "A1 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../test/data/A1.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../test/data/A2.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

    @testset "A3 MISCOP case" begin
        obj_normalization = 1000000.0
        result = run_ne("../test/data/A3.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end

    @testset "gaslib 40 case 5%" begin
        println("gaslib 40 - MISOCP 5%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-40-5.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 11924688; atol = 1e3)
    end

    @testset "gaslib 40 case 10%" begin
        println("gaslib 40 - MISOCP 10%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-40-10.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 32827932; atol = 1e3)
    end

    @testset "gaslib 40 case 25%" begin
        println("gaslib 40 - MISOCP 25%")
        obj_normalization = 1e7
        result = run_ne("../test/data/gaslib-40-25.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 41082189; atol = 1e3)
    end

    @testset "gaslib 40 case 50%" begin
        println("gaslib 40 - MISOCP 50%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-40-50.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 156055200; atol = 1e3)
    end

    @testset "gaslib 40 case 75%" begin
        println("gaslib 40 - MISOCP 75%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-40-75.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 333007019; atol = 1e3)
    end

    @testset "gaslib 40 case 100%" begin
        println("gaslib 40 - MISOCP 100%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-40-100.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 551644663; atol = 1e3)
    end

    @testset "gaslib 40 case 125%" begin
        println("gaslib 40 - MISOCP 125%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-40-125.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end

    @testset "gaslib 40 case 150%" begin
        println("gaslib 40 - MISOCP 150%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-40-150.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end

    @testset "gaslib 135 case 5%" begin
        println("gaslib 135 - MISOCP 5%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-5.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-2)
    end

    @testset "gaslib 135 case 10%" begin
        println("gaslib 135 - MISOCP 10%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-10.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-2)
    end

    @testset "gaslib 135 case 25%" begin
        println("gaslib 135 - MISOCP 25%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-25.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 60439674; atol = 1e3)
    end

    @testset "gaslib 135 case 50%" begin
        println("gaslib 135 - MISOCP 50%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-50.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 95319858; atol = 1e3)
    end

    @testset "gaslib 135 case 75%" begin
        println("gaslib 135 - MISOCP 75%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-75.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 451591677; atol = 1e3) || isapprox(result["objective"]*obj_normalization, 466653583; atol = 1e3)
    end

    @testset "gaslib 135 case 100%" begin
        println("gaslib 135 - MISOCP 100%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-100.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        # This one has some slight numerical instabilities, depending on the version of the misocp solver
        @test isapprox(result["objective"]*obj_normalization, 1234234179; atol = 1e3) || isapprox(result["objective"]*obj_normalization, 1245093590; atol = 1e3)
    end

    @testset "gaslib 135 case 125%" begin
        println("gaslib 135 - MISOCP 125%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-125.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end

    @testset "gaslib 135 case 150%" begin
        println("gaslib 135 - MISOCP 150%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-150.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end

    @testset "gaslib 135 case 200%" begin
        println("gaslib 135 - MISOCP 200%")
        obj_normalization = 1000000.0
        result = run_ne("../test/data/gaslib-135-200.m", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end

    @testset "gaslib 582 case 5%" begin
        println("gaslib 582 - MISOCP 5%")
        obj_normalization = 10000.0
        result = run_ne("../test/data/gaslib-582-5.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end

    @testset "gaslib 582 case 10%" begin
        println("gaslib 582 - MISOCP 10%")
        obj_normalization = 1.0
        result = run_ne("../test/data/gaslib-582-10.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end

    @testset "gaslib 582 case 25%" begin
        println("gaslib 582 - MISOCP 25%")
        obj_normalization = 1.0
        result = run_ne("../test/data/gaslib-582-25.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end

    @testset "gaslib 582 case 50%" begin
        println("gaslib 582 - MISOCP 50%")
        obj_normalization = 1.0
        result = run_ne("../test/data/gaslib-582-50.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1.493228019682e7; atol = 1e3)
     end

     @testset "gaslib 582 case 200%" begin
         println("gaslib 582 - MISOCP 200%")
         obj_normalization = 1000000.0
         result = run_ne("../test/data/gaslib-582-200.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
         @test result["status"] == :Infeasible
     end

     @testset "gaslib 582 case 300%" begin
         println("gaslib 582 - MISOCP 300%")
         obj_normalization = 1000000.0
         result = run_ne("../test/data/gaslib-582-300.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
         @test result["status"] == :Infeasible
     end
end
