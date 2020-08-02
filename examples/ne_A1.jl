@testset "test ne A1" begin

    @testset "A1 minlp ne" begin
         @info "Testing A1 minlp ne"
         result = run_ne("../examples/data/matgas/A1.m", MINLPGasModel, minlp_solver)
         @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
         @test isapprox(result["objective"], 144.45; atol = 1e-1)
     end

    @testset "A1 nlp ne" begin
        @info "Testing A1 nlp ne"
        result = run_ne("../examples/data/matgas/A1.m", NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 144.45; atol = 1e-1)
    end

    @testset "A1 misocp case" begin
        @info "Testing A1 misocp ne"
        result = run_ne("../examples/data/matgas/A1.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 144.45; atol = 1e-1)
    end

    @testset "A1 lp case" begin
        @info "Testing A1 lp ne"
        result = run_ne("../examples/data/matgas/A1.m", LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
        GC.gc()
    end

    @testset "A1 mip case" begin
        @info "Testing A1 mip ne"
        result = run_ne("../examples/data/matgas/A1.m", MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
    end

end
