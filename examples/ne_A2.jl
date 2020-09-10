@testset "test ne A2" begin

    @testset "A2 dwp ne" begin
        @info "Testing A2 dwp ne"
        result = run_ne("../examples/data/matgas/A2.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1687.46; atol = 1e-1)
    end

    @testset "A2 wp ne" begin
        @info "Testing A2 wp ne"
        result = run_ne("../examples/data/matgas/A2.m", WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1687.46; atol = 1e-1)
    end

    @testset "A2 crdwp case" begin
        @info "Testing A2 crdwp ne"
        result = run_ne("../examples/data/matgas/A2.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1687.46; atol = 1e-1)
    end

    @testset "A2 lrwp case" begin
        @info "Testing A2 lrwp ne"
        result = run_ne("../examples/data/matgas/A2.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
        GC.gc()
    end

    @testset "A2 lrdwp case" begin
        @info "Testing A2 lrdwp ne"
        result = run_ne("../examples/data/matgas/A2.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
    end

end
