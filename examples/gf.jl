@testset "test gf" begin

    @testset "test misocp gf" begin
        @testset "gaslib 40 misocp gf" begin
            @info "Testing gaslib 40 misocp gf"
            result = run_gf("../examples/data/matgas/gaslib-40-E.m", MISOCPGasModel, misocp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
            GC.gc()
        end

        @testset "gaslib 582 case" begin
            println("gaslib 582 - MISOCP")
            result = run_gf("../examples/data/matgas/gaslib-582-G.m", MISOCPGasModel, misocp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
            GC.gc()
        end
    end


    @testset "test mip gf" begin
        @testset "gaslib 40 mip gf" begin
            @info "Testing gaslib 40 mip gf"
            result = run_gf("../examples/data/matgas/gaslib-40-E.m", MIPGasModel, mip_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 135 mip gf" begin
            @info "Testing gaslib 135 mip gf"
            result = run_gf("../examples/data/matgas/gaslib-135-F.m", MIPGasModel, mip_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
    end


    @testset "test lp gf" begin
        @testset "gaslib 40 lp gf" begin
            @info "Testing gaslib 40 lp gf"
            result = run_gf("../examples/data/matgas/gaslib-40-E.m", LPGasModel, lp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 135 lp gf" begin
            @info "Testing gaslib 135 lp gf"
            result = run_gf("../examples/data/matgas/gaslib-135-F.m", LPGasModel, lp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
    end


    @testset "test minlp gf" begin
            @testset "gaslib 40 case" begin
                println("gaslib 40 - MINLP")
                result = run_gf("../examples/data/matgas/gaslib-40-E.m", MINLPGasModel, minlp_solver)
                @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
                @test isapprox(result["objective"], 0; atol = 1e-6)
            end
           @testset "gaslib 135 case" begin
               println("gaslib 135 - MINLP")
               result = run_gf("../examples/data/matgas/gaslib-135-F.m", MINLPGasModel, minlp_solver)
               @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
               @test isapprox(result["objective"], 0; atol = 1e-6)
           end
    end


    @testset "test nlp gf" begin
            @testset "gaslib 40 case" begin
                println("gaslib 40 - NLP")
                result = run_gf("../examples/data/matgas/gaslib-40-E.m", NLPGasModel, nlp_solver)
                @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
                @test isapprox(result["objective"], 0; atol = 1e-6)
            end

            @testset "gaslib 135 nlp gf" begin
                @info "Testing gaslib 135 nlp gf"
                result = run_gf("../examples/data/matgas/gaslib-135-F.m", NLPGasModel, nlp_solver)
                @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
                @test isapprox(result["objective"], 0; atol = 1e-6)
            end
    end

end
