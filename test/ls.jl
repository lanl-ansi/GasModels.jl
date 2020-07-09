@testset "test ls" begin
    #Check the second order cone model on load shedding
    @testset "test gaslib 40 misocp ls" begin
        @info "Testing gaslib misocp ls gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        # after relaxation
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 494.38; atol = 1e-1)
    end

    #Check the second order cone model on load shedding with priorities
    @testset "test gaslib 40 misocp ls priority" begin
        @info "Testing gaslib misocp ls priority gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls-priority.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        # After relaxation
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 444.82; atol = 1e-1)
    end

    #Check the mip model on load shedding
    @testset "test gaslib 40 mip ls" begin
        @info "Testing gaslib mip ls gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls.m", MIPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 838.76; atol = 1e-1)
    end

    #Check the mip model on load shedding with priorities
    @testset "test gaslib 40 mip ls priority" begin
        @info "Testing gaslib mip ls priority gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls-priority.m", MIPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 754.88; atol = 1e-1)
    end

    #Check the lp model on load shedding
    @testset "test gaslib 40 lp ls" begin
        @info "Testing gaslib lp ls gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls.m", LPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 838.75; atol = 1e-1)
    end

    #Check the lp model on load shedding with priorities
    @testset "test gaslib 40 lp ls priority" begin
        @info "Testing gaslib lp ls priority gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls-priority.m", LPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 754.88; atol = 1e-1)
    end

    #Check the nlp model on load shedding
    @testset "test gaslib 40 nlp ls" begin
        @info "Testing gaslib nlp ls gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls.m", NLPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 298.06; atol = 1e-1)
        @warn(result["termination_status"])
    end

    #Check the nlp model on load shedding with priorities
    @testset "test gaslib 40 nlp priority" begin
        @info "Testing gaslib nlp ls priority gaslib 40"
        result = run_ls("../test/data/matgas/gaslib-40-E-ls-priority.m", NLPGasModel, cvx_solver)
        println(result["termination_status"])
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 268.25; atol = 1e-1)
    end
end
