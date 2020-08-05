@testset "test gf" begin

    @testset "test crdwp gf" begin
        @testset "gaslib 40 crdwp gf" begin
            @info "Testing gaslib 40 crdwp gf"
            result = run_gf("../examples/data/matgas/gaslib-40-E.m", CRDWPGasModel, misocp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
            GC.gc()
        end

        @testset "gaslib 582 case" begin
            println("Testing gaslib 582 crdwp gf")
            result = run_gf("../examples/data/matgas/gaslib-582-G.m", CRDWPGasModel, misocp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
            GC.gc()
        end
    end


    @testset "test lrdwp gf" begin
        @testset "gaslib 40 lrdwp gf" begin
            @info "Testing gaslib 40 lrdwp gf"
            result = run_gf("../examples/data/matgas/gaslib-40-E.m", LRDWPGasModel, mip_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 135 lrdwp gf" begin
            @info "Testing gaslib 135 lrdwp gf"
            result = run_gf("../examples/data/matgas/gaslib-135-F.m", LRDWPGasModel, mip_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
    end


    @testset "test lrwp gf" begin
        @testset "gaslib 40 lrwp gf" begin
            @info "Testing gaslib 40 lrwp gf"
            result = run_gf("../examples/data/matgas/gaslib-40-E.m", LRWPGasModel, lp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end

        @testset "gaslib 135 lrwp gf" begin
            @info "Testing gaslib 135 lrwp gf"
            result = run_gf("../examples/data/matgas/gaslib-135-F.m", LRWPGasModel, lp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 0; atol = 1e-6)
        end
    end


    @testset "test dwp gf" begin
            @testset "gaslib 40 case" begin
                println("Testing gaslib 40 dwp gf")
                result = run_gf("../examples/data/matgas/gaslib-40-E.m", DWPGasModel, minlp_solver)
                @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
                @test isapprox(result["objective"], 0; atol = 1e-6)
            end
#           @testset "gaslib 135 case" begin
#               println("Testing gaslib 135 dwp gf")
#               result = run_gf("../examples/data/matgas/gaslib-135-F.m", DWPGasModel, minlp_solver)
#               @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#               @test isapprox(result["objective"], 0; atol = 1e-6)
#           end
    end


    @testset "test wp gf" begin
            @testset "gaslib 40 case" begin
                println("Testing gaslib 40 wp gf")
                result = run_gf("../examples/data/matgas/gaslib-40-E.m", WPGasModel, nlp_solver)
                @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
                @test isapprox(result["objective"], 0; atol = 1e-6)
            end

            @testset "gaslib 135 wp gf" begin
                @info "Testing gaslib 135 wp gf"
                result = run_gf("../examples/data/matgas/gaslib-135-F.m", WPGasModel, nlp_solver)
                @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_LOCALLY_SOLVED
                @test isapprox(result["objective"], 0; atol = 1e-6)
            end
    end

end
