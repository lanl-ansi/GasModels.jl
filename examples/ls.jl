@testset "test ls" begin

    #Check the second order cone model on load shedding
    @testset "test gaslib 40 crdwp ls" begin
        @info "Testing gaslib crdwp ls gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            497.3;
            atol = 1e-1,
        )
    end

    #Check the second order cone model on load shedding with priorities
    @testset "test gaslib 40 crdwp ls priority" begin
        @info "Testing gaslib crdwp ls priority gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls-priority.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            447.54;
            atol = 1e-1,
        )
    end

    #Check the lrdwp model on load shedding
    @testset "test gaslib 40 lrdwp ls" begin
        @info "Testing gaslib lrdwp ls gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            838.76;
            atol = 1e-1,
        )
    end

    #Check the lrdwp model on load shedding with priorities
    @testset "test gaslib 40 lrdwp ls priority" begin
        @info "Testing gaslib lrdwp ls priority gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls-priority.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            754.88;
            atol = 1e-1,
        )
    end

    #Check the lrwp model on load shedding
    @testset "test gaslib 40 lrwp ls" begin
        @info "Testing gaslib lrwp ls gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls.m", LRWPGasModel, lp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            838.75;
            atol = 1e-1,
        )
    end

    #Check the lrwp model on load shedding with priorities
    @testset "test gaslib 40 lrwp ls priority" begin
        @info "Testing gaslib lrwp ls priority gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls-priority.m", LRWPGasModel, lp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            754.88;
            atol = 1e-1,
        )
    end

    #Check the wp model on load shedding
    @testset "test gaslib 40 wp ls" begin
        @info "Testing gaslib wp ls gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls.m", WPGasModel, lp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            420.91;
            atol = 1e-1,
        )
        @warn(result["termination_status"])
    end

    #Check the wp model on load shedding with priorities
    @testset "test gaslib 40 wp priority" begin
        @info "Testing gaslib wp ls priority gaslib 40"
        result = run_ls("../examples/data/matgas/gaslib-40-E-ls-priority.m", WPGasModel, nlp_solver)
        println(result["termination_status"])
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(
            result["objective"] * result["solution"]["base_flow"],
            378.82;
            atol = 1e-1,
        )
    end
end
