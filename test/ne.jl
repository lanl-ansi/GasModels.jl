@testset "test ne" begin
    @testset "test minlp ne" begin
        @testset "A1 minlp ne" begin
            @info "Testing A1 minlp ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A1.m", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
        end

        @testset "A2 minlp ne" begin
            @info "Testing A2 minlp ne"
            obj_normalization =  1.0
            result = run_ne("../test/data/A2.m", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
        end

        # @testset "A3 minlp ne" begin
        #     obj_normalization = 1.0
        #     result = run_ne("../test/data/A3.m", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        #     @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        #     @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
        # end

    end

    @testset "test misocp ne" begin
        @testset "A1 miscop ne" begin
            @info "Testing A1 misocp ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A1.m", MISOCPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
        end

        @testset "A2 miscop ne" begin
            @info "Testing A2 misocp ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A2.m", MISOCPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
        end
    end

    @testset "test mip ne" begin
        @testset "A1 mip ne" begin
            @info "Testing A1 mip ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A1.m", MIPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
        end

        @testset "A2 mip ne" begin
            @info "Testing A2 mip ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A2.m", MIPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
        end
    end

    @testset "test lp ne" begin
        @testset "A1 lp ne" begin
            @info "Testing A1 lp ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A1.m", LPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
        end

        @testset "A2 lp ne" begin
            @info "Testing A2 lp ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A2.m", LPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
        end
    end

    @testset "test nlp ne" begin
        @testset "A1 nlp ne" begin
            @info "Testing A1 nlp ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A1.m", NLPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            if !(result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL)
                result = run_ne("../test/data/A1.m", NLPGasModel, abs_minlp_solver; obj_normalization = obj_normalization)
            end
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
        end

        @testset "A2 nlp ne" begin
            @info "Testing A2 nlp ne"
            obj_normalization = 1.0
            result = run_ne("../test/data/A2.m", NLPGasModel, cvx_minlp_solver; obj_normalization = obj_normalization)
            if !(result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL)
                result = run_ne("../test/data/A2.m", NLPGasModel, abs_minlp_solver; obj_normalization = obj_normalization)
            end
            # @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            # some discpreany between windows, mac, and linux
            # @test isapprox(result["objective"]*obj_normalization, 3222.1,; atol = 1e-1) || isapprox(result["objective"]*obj_normalization, 3187.45,; atol = 1e-1) || isapprox(result["objective"]*obj_normalization, 3338.4,; atol = 1e-1)
        end
    end
end
