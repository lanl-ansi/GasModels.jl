@testset "test SLP algorithm" begin
    @testset "test run_slp" begin
        data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
        gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_ogf)
        x0, _ = GasModels._get_start_value(gm)
        slpopt = GasModels._SLP.Optimizer(HiGHS.Optimizer; tol = 1e-5, silent = true)
        result = GasModels._SLP.run_slp(slpopt, gm.model, x0)
        @test result.termination_status in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test result.primal_status == JuMP.FEASIBLE_POINT
        @test isempty(JuMP.primal_feasibility_report(gm.model, result.primal_solution, atol = 1e-5))
    end
    @testset "test SLP solve_ogf" begin
        fname = "../test/data/matgas/case-6-no-power-limits.m"
        slpopt = GasModels._SLP.Optimizer(HiGHS.Optimizer; tol = 1e-5, silent = true)
        result = GasModels.solve_ogf(fname, GasModels.WPGasModel, slpopt)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test result["primal_status"] == JuMP.FEASIBLE_POINT

        data = GasModels.parse_file(fname)
        # Test method that accepts data
        result = GasModels.solve_ogf(data, GasModels.WPGasModel, slpopt)
        @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
        @test result["primal_status"] == JuMP.FEASIBLE_POINT
    end
end
