

@testset "test gf" begin
    @testset "test crdwp gf" begin
        @info "Testing crdwp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
        data = GasModels.parse_file("../test/data/matgas/case-6-gf.m")
        gm = GasModels.instantiate_model(data, CRDWPGasModel, GasModels.build_gf)
        check_pressure_status(result["solution"], gm)
        check_compressor_ratio(result["solution"], gm)
    end

    @testset "test lrdwp gf" begin
        @info "Testing lrdwp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

    @testset "test lrwp gf" begin
        @info "Testing lrwp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", LRWPGasModel, lp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

    @testset "test wp gf" begin
        @info "Testing wp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", WPGasModel, nlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

    @testset "test dwp gf" begin
        @info "Testing dwp gf"
        result = run_gf("../test/data/matgas/case-6-gf.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end

end
