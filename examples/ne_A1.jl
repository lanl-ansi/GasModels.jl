@testset "test ne A1" begin

    @testset "A1 dwp ne" begin
        @info "Testing A1 dwp ne"
        result = run_ne("../examples/data/matgas/A1.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 144.45; atol = 1e-1)
    end

    @testset "A1 wp ne" begin
        @info "Testing A1 wp ne"
        result = run_ne("../examples/data/matgas/A1.m", WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 144.45; atol = 1e-1)
    end

    @testset "A1 crdwp case" begin
        @info "Testing A1 crdwp ne"
        result = run_ne("../examples/data/matgas/A1.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 144.45; atol = 1e-1)
    end

    @testset "A1 lrwp case" begin
        @info "Testing A1 lrwp ne"
        result = run_ne("../examples/data/matgas/A1.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
        GC.gc()
    end

    @testset "A1 lrdwp case" begin
        @info "Testing A1 lrdwp ne"
        result = run_ne("../examples/data/matgas/A1.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED ||
              result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
    end

end
