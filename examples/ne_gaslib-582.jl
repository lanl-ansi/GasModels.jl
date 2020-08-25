@testset "test crdwp ne gaslib 582" begin

    @testset "gaslib 582 case 5%" begin
        println("gaslib 582 - CRDWP 5%")
        result =
            run_ne("../examples/data/matgas/gaslib-582-G-5.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 582 case 10%" begin
        println("gaslib 582 - CRDWP 10%")
        result = run_ne(
            "../examples/data/matgas/gaslib-582-G-10.m",
            CRDWPGasModel,
            misocp_solver,
        )
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 582 case 25%" begin
        println("gaslib 582 - CRDWP 25%")
        result = run_ne(
            "../examples/data/matgas/gaslib-582-G-25.m",
            CRDWPGasModel,
            misocp_solver,
        )
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 582 case 50%" begin
        println("gaslib 582 - CRDWP 50%")
        result = run_ne(
            "../examples/data/matgas/gaslib-582-G-50.m",
            CRDWPGasModel,
            misocp_solver,
        )
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 14.93; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 582 case 200%" begin
        println("gaslib 582 - CRDWP 200%")
        result = run_ne(
            "../examples/data/matgas/gaslib-582-G-200.m",
            CRDWPGasModel,
            misocp_solver,
        )
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end

    @testset "gaslib 582 case 300%" begin
        println("gaslib 582 - CRDWP 300%")
        result = run_ne(
            "../examples/data/matgas/gaslib-582-G-300.m",
            CRDWPGasModel,
            misocp_solver,
        )
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end

end
