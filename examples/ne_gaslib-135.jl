@testset "test wp ne gaslib 135" begin

    @testset "gaslib 135 5% case" begin
        println("gaslib 135 - WP 5%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-5.m", WPGasModel, minlp_solver; )
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
    end

    @testset "gaslib 135 200% case" begin
        println("gaslib 135 - WP 200%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-200.m", WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end

end



@testset "test dwp ne gaslib 135" begin

#    @testset "gaslib 135 5% case" begin
#        println("gaslib 135 - DWP 5%")
#        result = run_ne("../examples/data/matgas/gaslib-135-F-5.m", DWPGasModel, minlp_solver)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"], 0.0; atol = 1e-2)
#    end

    @testset "gaslib 135 25% case" begin
        println("gaslib 135 - DWP 25%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-25.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 60.43; atol = 1e-2)
    end

    @testset "gaslib 135 125% case" begin
        println("gaslib 135 - DWP 125%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-125.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end

    @testset "gaslib 135 150% case" begin
        println("gaslib 135 - DWP 150%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-150.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end

    @testset "gaslib 135 200% case" begin
        println("gaslib 135 - DWP 200%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-200.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end
end

@testset "test crdwp ne gaslib 135" begin

    @testset "gaslib 135 case 5%" begin
        println("gaslib 135 - CRDWP 5%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-5.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 135 case 10%" begin
        println("gaslib 135 - CRDWP 10%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-10.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 135 case 25%" begin
        println("gaslib 135 - CRDWP 25%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-25.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 60.43; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 135 case 50%" begin
        println("gaslib 135 - CRDWP 50%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-50.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 95.32; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 135 case 75%" begin
        println("gaslib 135 - CRDWP 75%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-75.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        # The gas expansion planning paper reported a lower bound (CRDWP) solution of 451.5.  Subsequent
        # tightenings of the relaxation have improved the lower bound
        @test result["objective"] <= 491.0
        @test result["objective"] >= 451.5
        GC.gc()
    end

    @testset "gaslib 135 case 100%" begin
        println("gaslib 135 - CRDWP 100%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-100.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        # The gas expansion planning paper reported a lower bound (CRDWP) solution of 1234.2.  Subsequent
        # tightenings of the relaxation have improved the lower bound
        @test result["objective"] <= 1261
        @test result["objective"] >= 1234.2
        GC.gc()
    end

    @testset "gaslib 135 case 125%" begin
        println("gaslib 135 - CRDWP 125%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-125.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end

    @testset "gaslib 135 case 150%" begin
        println("gaslib 135 - CRDWP 150%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-150.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end

    @testset "gaslib 135 case 200%" begin
        println("gaslib 135 - CRDWP 200%")
        result = run_ne("../examples/data/matgas/gaslib-135-F-200.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end

end
