

@testset "test gf" begin
    @testset "test misocp gf" begin
        @info "Testing misocp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
        data = GasModels.parse_file("../test/data/matgas/case-6-gf.m")
        gm = GasModels.instantiate_model(data, MINLPGasModel, GasModels.build_gf)
        check_pressure_status(result["solution"], gm)
        check_compressor_ratio(result["solution"], gm)
    end

    @testset "test mip gf" begin
        @info "Testing mip gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

    @testset "test lp gf" begin
        @info "Testing lp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", LPGasModel, lp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

    @testset "test nlp gf" begin
        @info "Testing nlp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", NLPGasModel, nlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

    @testset "test minlp gf" begin
        @info "Testing minlp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

end
