@testset "test ls" begin
    #Check the second order cone model on load shedding
    @testset "test gaslib 40 misocp ls" begin
        @info "Testing gaslib misocp ls gaslib 40"
        result = run_ls("../test/data/gaslib-40-ls.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        # after erlaxation
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 515.2312009025778; atol = 1e-1) || isapprox(result["objective"]*result["solution"]["baseQ"], 456.52; atol = 1e-1)
    end

    #Check the second order cone model on load shedding with priorities
    @testset "test gaslib 40 misocp ls priority" begin
        @info "Testing gaslib misocp ls priority gaslib 40"
        result = run_ls("../test/data/gaslib-40-ls-priority.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        # After relaxation
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 463.624073939234; atol = 1e-1) || isapprox(result["objective"]*result["solution"]["baseQ"], 410.75; atol = 1e-1)
    end

    #Check the mip model on load shedding
    @testset "test gaslib 40 mip ls" begin
        @info "Testing gaslib mip ls gaslib 40"
        result = run_ls("../test/data/gaslib-40-ls.m", MIPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 828.241566956375; atol = 1e0)
    end

    #Check the mip model on load shedding with priorities
    @testset "test gaslib 40 mip ls priority" begin
        @info "Testing gaslib mip ls priority gaslib 40"
        result = run_ls("../test/data/gaslib-40-ls-priority.m", MIPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 745.3635379170676; atol = 1e-1)
    end

    #Check the lp model on load shedding
    @testset "test gaslib 40 lp ls" begin
        @info "Testing gaslib lp ls gaslib 40"
        result = run_ls("../test/data/gaslib-40-ls.m", LPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 828.241566956375; atol = 1e0)
    end

    #Check the lp model on load shedding with priorities
    @testset "test gaslib 40 lp ls priority" begin
        @info "Testing gaslib lp ls priority gaslib 40"
        result = run_ls("../test/data/gaslib-40-ls-priority.m", LPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 745.5144120833442; atol = 1e-1)
    end

    #Check the nlp model on load shedding
    @testset "test gaslib 40 nlp ls" begin
        @info "Testing gaslib nlp ls gaslib 40"
        result = run_ls("../test/data/gaslib-40-ls.m", NLPGasModel, cvx_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 378.80800085143744; atol = 1e0)
    end

    #Check the nlp model on load shedding with priorities
    @testset "test nlp ls priority" begin
        @testset "gaslib 40 case" begin
            @info "Testing gaslib nlp ls priority gaslib 40"
            result = run_ls("../test/data/gaslib-40-ls-priority.m", NLPGasModel, tol_ipopt_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL || result["termination_status"] == :Suboptimal
            @test isapprox(result["objective"]*result["solution"]["baseQ"], 340.92659091007965; atol = 1e-1)
        end
    end
end
