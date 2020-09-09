@testset "test ls" begin
    #Check the second order cone model on load shedding
    @testset "test crdwp ls" begin
        @info "Testing gaslib crdwp ls"
        result = run_ls("../test/data/matgas/case-6-ls.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the second order cone model on load shedding with priorities
    @testset "test gaslib 40 crdwp ls priority" begin
        @info "Testing gaslib crdwp ls priority gaslib 40"
        result =
            run_ls("../test/data/matgas/case-6-ls-priority.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end

    #Check the lrdwp model on load shedding
    @testset "test gaslib 40 lrdwp ls" begin
        @info "Testing gaslib lrdwp ls gaslib 40"
        result = run_ls("../test/data/matgas/case-6-ls.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the lrdwp model on load shedding with priorities
    @testset "test gaslib 40 lrdwp ls priority" begin
        @info "Testing gaslib lrdwp ls priority gaslib 40"
        result =
            run_ls("../test/data/matgas/case-6-ls-priority.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end

    #Check the lrwp model on load shedding
    @testset "test gaslib 40 lrwp ls" begin
        @info "Testing gaslib lrwp ls gaslib 40"
        result = run_ls("../test/data/matgas/case-6-ls.m", LRWPGasModel, lp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the lrwp model on load shedding with priorities
    @testset "test gaslib 40 lrwp ls priority" begin
        @info "Testing gaslib lrwp ls priority gaslib 40"
        result = run_ls("../test/data/matgas/case-6-ls-priority.m", LRWPGasModel, lp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end

    #Check the wp model on load shedding
    @testset "test gaslib 40 wp ls" begin
        @info "Testing gaslib wp ls gaslib 40"
        result = run_ls("../test/data/matgas/case-6-ls.m", WPGasModel, nlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
        @warn(result["termination_status"])
    end

    #Check the wp model on load shedding with priorities
    @testset "test gaslib 40 wp priority" begin
        @info "Testing gaslib wp ls priority gaslib 40"
        result = run_ls("../test/data/matgas/case-6-ls-priority.m", WPGasModel, nlp_solver)
        println(result["termination_status"])
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end
end
