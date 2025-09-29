@testset "test ls" begin
    #Check the second order cone model on load shedding
    @testset "test crdwp ls" begin
        @info "Testing case 6 crdwp ls"
        result = solve_ls("../test/data/matgas/case-6-ls.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the second order cone model on load shedding with priorities
    @testset "test case 6 crdwp ls priority" begin
        @info "Testing case 6 crdwp ls priority gaslib 40"
        result = solve_ls("../test/data/matgas/case-6-ls-priority.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end

    #Check the lrdwp model on load shedding
    @testset "test case 6 lrdwp ls" begin
        @info "Testing case 6 lrdwp ls gaslib 40"
        result = solve_ls("../test/data/matgas/case-6-ls.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the lrdwp model on load shedding with priorities
    @testset "test case 6 lrdwp ls priority" begin
        @info "Testing case 6 lrdwp ls priority gaslib 40"
        result = solve_ls("../test/data/matgas/case-6-ls-priority.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end

    #Check the lrwp model on load shedding
    @testset "test case 6 lrwp ls" begin
        @info "Testing case 6 lrwp ls gaslib 40"
        result = solve_ls("../test/data/matgas/case-6-ls.m", LRWPGasModel, lp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the lrwp model on load shedding with priorities
    @testset "test case 6 lrwp ls priority" begin
        @info "Testing case 6 lrwp ls priority gaslib 40"
        result = solve_ls("../test/data/matgas/case-6-ls-priority.m", LRWPGasModel, lp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end

    #Check the wp model on load shedding
    @testset "test case 6 wp ls" begin
        @info "Testing case 6 wp ls case"
        result = solve_ls("../test/data/matgas/case-6-ls.m", WPGasModel, nlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the wp model on load shedding with priorities
    @testset "test case 6 wp priority" begin
        @info "Testing case 6 ls priority case 6"
        result = solve_ls("../test/data/matgas/case-6-ls-priority.m", WPGasModel, nlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end

    #Check the cwp model on load shedding
    @testset "test case 6 cwp ls" begin
        @info "Testing case 6 cwp ls gaslib 40"
        result = solve_ls("../test/data/matgas/case-6-ls.m", CWPGasModel, nlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 5.0; atol = 1e-1)
    end

    #Check the cwp model on load shedding with priorities
    @testset "test case 6 40 cwp priority" begin
        @info "Testing case 6 cwp ls priority case 6"
        result = solve_ls("../test/data/matgas/case-6-ls-priority.m", CWPGasModel, nlp_solver)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test isapprox(result["objective"] * result["solution"]["base_flow"], 4.5; atol = 1e-1)
    end
end

