@testset "test gf" begin
    @testset "test misocp gf" begin
        @testset "gaslib integration misocp gf" begin
            @info "Testing gaslib integration misocp gf"
            result = run_gf("../test/data/gaslib/GasLib-Integration.zip", MISOCPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 40 misocp gf" begin
            @info "Testing gaslib 40 misocp gf"
            result = run_gf("../test/data/matgas/gaslib-40-E.m", MISOCPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
            data = GasModels.parse_file("../test/data/matgas/gaslib-40-E.m")
            gm = GasModels.instantiate_model(data, MINLPGasModel, GasModels.build_gf)
            check_pressure_status(result["solution"], gm)
            check_compressor_ratio(result["solution"], gm)
        end
    end

    @testset "test mip gf" begin
        @testset "gaslib integration mip gf" begin
            @info "Testing gaslib integration mip gf"
            result = run_gf("../test/data/gaslib/GasLib-Integration.zip", MIPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 40 mip gf" begin
            @info "Testing gaslib 40 mip gf"
            result = run_gf("../test/data/matgas/gaslib-40-E.m", MIPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 135 mip gf" begin
            @info "Testing gaslib 135 mip gf"
            result = run_gf("../test/data/matgas/gaslib-135-F.m", MIPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
    end

    @testset "test lp gf" begin
        @testset "gaslib 40 lp gf" begin
            @info "Testing gaslib 40 lp gf"
            result = run_gf("../test/data/matgas/gaslib-40-E.m", LPGasModel, cvx_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 135 lp gf" begin
            @info "Testing gaslib 135 lp gf"
            result = run_gf("../test/data/matgas/gaslib-135-F.m", LPGasModel, cvx_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
    end

    @testset "test nlp gf" begin
        @testset "gaslib integration nlp gf" begin
            @info "Testing gaslib integration nlp gf"
            result = run_gf("../test/data/gaslib/GasLib-Integration.zip", NLPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 40 nlp gf" begin
            @info "Testing gaslib 40 nlp gf"
            result = run_gf("../test/data/matgas/gaslib-40-E.m", NLPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 135 nlp gf" begin
            @info "Testing gaslib 135 nlp gf"
            result = run_gf("../test/data/matgas/gaslib-135-F.m", NLPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
    end
end
