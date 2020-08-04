@testset "test ne A3" begin

    @testset "A3 dwp ne" begin
         @info "Testing A3 dwp ne"
         result = run_ne("../examples/data/matgas/A3.m", DWPGasModel, minlp_solver)
         @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
         @test isapprox(result["objective"], 1781; atol = 1e-1)
     end

    @testset "A3 wp ne" begin
        @info "Testing A3 wp ne"
        result = run_ne("../examples/data/matgas/A3.m", WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1781; atol = 1e-1)
    end

    @testset "A3 crdwp case" begin
        @info "Testing A3 crdwp ne"
        result = run_ne("../examples/data/matgas/A3.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1781; atol = 1e-1)
    end

    @testset "A3 lrwp case" begin
        @info "Testing A3 lrwp ne"
        result = run_ne("../examples/data/matgas/A3.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
        GC.gc()
    end

    @testset "A3 lrdwp case" begin
        @info "Testing A3 lrdwp ne"
        result = run_ne("../examples/data/matgas/A3.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
    end

end
