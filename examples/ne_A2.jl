@testset "test ne A2" begin

    @testset "A2 minlp ne" begin
         @info "Testing A2 minlp ne"
         result = run_ne("../examples/data/matgas/A2.m", MINLPGasModel, minlp_solver)
         @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
         @test isapprox(result["objective"], 1687.46; atol = 1e-1)
     end

    @testset "A2 nlp ne" begin
        @info "Testing A2 nlp ne"
        result = run_ne("../examples/data/matgas/A2.m", NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1687.46; atol = 1e-1)
    end

    @testset "A2 misocp case" begin
        @info "Testing A2 misocp ne"
        result = run_ne("../examples/data/matgas/A2.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1687.46; atol = 1e-1)
    end

    @testset "A2 lp case" begin
        @info "Testing A2 lp ne"
        result = run_ne("../examples/data/matgas/A2.m", LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
        GC.gc()
    end

    @testset "A2 mip case" begin
        @info "Testing A2 mip ne"
        result = run_ne("../examples/data/matgas/A2.m", MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
    end

end
