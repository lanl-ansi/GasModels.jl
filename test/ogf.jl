@testset "test ogf" begin
    @testset "test wp ogf" begin
        @testset "case 6 ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219; atol = 1e-2)
        end

        @testset "test solution hints for static file" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            solution_file = "../test/data/transient/case6_base_solution.json"
            add_solution_hints!(data, solution_file)
            res = solve_ogf(data, WPGasModel, nlp_solver)
            @test res["termination_status"] in [LOCALLY_SOLVED, OPTIMAL]
            @test isapprox(res["objective"], -167.19, rtol=1e-2)
        end

        @testset "test primal feasibility report from solution file" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            gm = GasModels.instantiate_model(data, WPGasModel, GasModels.build_ogf)
            solution_file = "../test/data/transient/case6_base_solution.json"
            skip_missing_err = ErrorException(
                "`skip_missing = true` is not allowed when nonlinear constraints are present.",
            )

            report = JuMP.primal_feasibility_report(gm, solution_file; atol = 1e-6)
            @test isempty(report)
            @test_throws skip_missing_err JuMP.primal_feasibility_report(
                gm,
                solution_file;
                atol = 1e-6,
                skip_missing = true,
            )

            solution = JSON.parsefile(solution_file)
            solution["solution"]["junction"]["1"]["psqr"] *= 0.95
            report = JuMP.primal_feasibility_report(gm, solution; atol = 1e-6)
            @test !isempty(report)
            @test_throws skip_missing_err JuMP.primal_feasibility_report(
                gm,
                solution;
                atol = 1e-6,
                skip_missing = true,
            )
        end

        @testset "case 6 ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219; atol = 1e-2)
        end

        @testset "case 6 ogf weymouth lin rel" begin
            @info "Testing OGF Linear Relaxation of Pipe Weymouth Physics"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, LRWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -260.001; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 130.00040; atol = 1e-2)
        end


        @testset "case 6 wp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887; atol = 1e-2)
        end

        @testset "case 6 wp ogf elevation constraint" begin
            @info "Testing OGF Elevation Constraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.27275; atol = 1e-2)
        end

        @testset "case 6 cwp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887; atol = 1e-2)
        end

        @testset "case 6 cwp ogf elevation constraint" begin
            @info "Testing OGF Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.2727; atol = 1e-2)
        end
         @testset "6-bus case solution with duals" begin
            @info "Testing OGF Report Duals"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            settings = Dict("output" => Dict("duals" => true))
            result = solve_ogf(data, CWPGasModel, nlp_solver, setting=settings)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)

            @test isapprox(result["solution"]["junction"]["1"]["lam_junction_mfb"], 9585.2624, atol=1e-2)
            @test isapprox(result["solution"]["junction"]["2"]["lam_junction_mfb"], 23004.6300, atol=1e-2)
            @test isapprox(result["solution"]["junction"]["3"]["lam_junction_mfb"], 30672.8399, atol=1e-2)
            @test isapprox(result["solution"]["junction"]["4"]["lam_junction_mfb"], 24621.9535, atol=1e-2)
            @test isapprox(result["solution"]["junction"]["5"]["lam_junction_mfb"], 9584.9839, atol=1e-2)
            @test isapprox(result["solution"]["junction"]["6"]["lam_junction_mfb"], 23004.3516, atol=1e-2)

            # test the unit conversions on duals work
            result_base = deepcopy(result)
            GasModels.make_english_units!(result["solution"])
            GasModels.make_si_units!(result["solution"])
            GasModels.make_per_unit!(result["solution"])

            @test compare(result["solution"], result_base["solution"], rtol=1e-6)
        end
    end
end
