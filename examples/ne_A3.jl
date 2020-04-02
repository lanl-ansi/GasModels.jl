@testset "test minlp ne A3" begin

    @testset "A3 minlp ne" begin
         @info "Testing A3 minlp ne"
         result = run_ne("../examples/data/matgas/A3.m", MINLPGasModel, minlp_solver)
         @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
         @test isapprox(result["objective"], 1781; atol = 1e-1)
     end

end


@testset "test nlp ne A3" begin

    @testset "A3 nlp ne" begin
        @info "Testing A3 nlp ne"
        result = run_ne("../examples/data/matgas/A3.m", NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1781; atol = 1e-1)
    end

end


@testset "test misocp ne A3" begin

    @testset "A3 misocp case" begin
        @info "Testing A3 misocp ne"
        result = run_ne("../examples/data/matgas/A3.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 1781; atol = 1e-1)
    end

end

@testset "test lp ne A3" begin

    @testset "A3 lp case" begin
        @info "Testing A3 lp ne"
        result = run_ne("../examples/data/matgas/A3.m", LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
    end

end


@testset "test mip ne A3" begin

    @testset "A3 mip case" begin
        @info "Testing A3 mip ne"
        result = run_ne("../examples/data/matgas/A3.m", MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
    end

end
