@testset "test wp ne gaslib 40" begin

    @testset "gaslib 40 150% case" begin
        println("gaslib 40 - WP 150%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-150.m", WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end

end


@testset "test dwp ne gaslib 40" begin
    @testset "gaslib 40 5% case" begin
        println("gaslib 40 - DWP 5%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-5.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 11.92; atol = 1e-2)
    end

    @testset "gaslib 40 10% case" begin
        println("gaslib 40 - DWP 10%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-10.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 32.83; atol = 1e-2)
    end

    @testset "gaslib 40 25% case" begin
        println("gaslib 40 - DWP 25%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-25.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 41.08; atol = 1e-2)
    end

    @testset "gaslib 40 50% case" begin
        println("gaslib 40 - DWP 50%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-50.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 156.06; atol = 1e-2)
    end

    @testset "gaslib 40 75% case" begin
        println("gaslib 40 - DWP 75%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-75.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 333.01; atol = 1e-2)
    end

    @testset "gaslib 40 100% case" begin
        println("gaslib 40 - DWP 100%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-100.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 551.64; atol = 1e-2)
    end

    @testset "gaslib 40 125% case" begin
        println("gaslib 40 - DWP 125%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-125.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end

    @testset "gaslib 40 150% case" begin
        println("gaslib 40 - DWP 150%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-150.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end
end

@testset "test crdwp ne gaslib 40" begin
    @testset "gaslib 40 case 5%" begin
        println("gaslib 40 - CRDWP 5%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-5.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 11.92; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 10%" begin
        println("gaslib 40 - CRDWP 10%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-10.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 32.83; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 25%" begin
        println("gaslib 40 - CRDWP 25%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-25.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 41.08; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 50%" begin
        println("gaslib 40 - CRDWP 50%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-50.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 156.06; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 75%" begin
        println("gaslib 40 - CRDWP 75%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-75.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 333.01; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 100%" begin
        println("gaslib 40 - CRDWP 100%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-100.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 551.64; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 125%" begin
        println("gaslib 40 - CRDWP 125%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-125.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end

    @testset "gaslib 40 case 150%" begin
        println("gaslib 40 - CRDWP 150%")
        result = run_ne("../examples/data/matgas/gaslib-40-E-150.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end
end
