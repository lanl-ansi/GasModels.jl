@testset "test ne" begin
    @testset "test minlp ne" begin
        @testset "A1 minlp ne" begin
            @info "Testing A1 minlp ne"
            result = run_ne("../test/data/matgas/A1.m", MINLPGasModel, minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 144.4; atol = 1e-1)
        end

        @testset "A2 minlp ne" begin
            @info "Testing A2 minlp ne"
            result = run_ne("../test/data/matgas/A2.m", MINLPGasModel, minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 1687; atol = 1.0)
        end

        # @testset "A3 minlp ne" begin
        #     result = run_ne("../test/data/matgas/A3.m", MINLPGasModel, minlp_solver)
        #     @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        #     @test isapprox(result["objective"], 1781; atol = 1.0)
        # end

    end

    @testset "test misocp ne" begin
        @testset "A1 miscop ne" begin
            @info "Testing A1 misocp ne"
            result = run_ne("../test/data/matgas/A1.m", MISOCPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 144.4; atol = 1e-1)
        end

        @testset "A2 miscop ne" begin
            @info "Testing A2 misocp ne"
            result = run_ne("../test/data/matgas/A2.m", MISOCPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 1687; atol = 1.0)
        end

    end

    @testset "test mip ne" begin
        @testset "A1 mip ne" begin
            @info "Testing A1 mip ne"
            result = run_ne("../test/data/matgas/A1.m", MIPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end

        @testset "A2 mip ne" begin
            @info "Testing A2 mip ne"
            result = run_ne("../test/data/matgas/A2.m", MIPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end
    end

    @testset "test lp ne" begin
        @testset "A1 lp ne" begin
            @info "Testing A1 lp ne"
            result = run_ne("../test/data/matgas/A1.m", LPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end

        @testset "A2 lp ne" begin
            @info "Testing A2 lp ne"
            result = run_ne("../test/data/matgas/A2.m", LPGasModel, cvx_minlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end

    end

    @testset "test nlp ne" begin
        @testset "A1 nlp ne" begin
            @info "Testing A1 nlp ne"
            result = run_ne("../test/data/matgas/A1.m", NLPGasModel, cvx_minlp_solver)
            if !(result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL)
                result = run_ne("../test/data/matgas/A1.m", NLPGasModel, abs_minlp_solver)
            end
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 144.4; atol = 1e-1)
        end

        @testset "A2 nlp ne" begin
            @info "Testing A2 nlp ne"
            result = run_ne("../test/data/matgas/A2.m", NLPGasModel, cvx_minlp_solver)
            if !(result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL)
                result = run_ne("../test/data/matgas/A2.m", NLPGasModel, abs_minlp_solver)
            end
            # @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            # some discpreany between windows, mac, and linux
            # @test isapprox(result["objective"], 3222.1,; atol = 1e-1) || isapprox(result["objective"], 3187.45,; atol = 1e-1) || isapprox(result["objective"], 3338.4,; atol = 1e-1)
        end
    end
end
