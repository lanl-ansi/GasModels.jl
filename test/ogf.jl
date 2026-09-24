@testset "test ogf" begin
    @testset "test wp ogf" begin
        @testset "case 6 ogf" begin
            @_info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219; atol = 1e-2)
        end
        
        @testset "test status zero components in solution" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            data["junction"]["1"]["status"] = 0
            data["pipe"]["1"]["status"] = 0
            p_default = 0.5 * (data["junction"]["1"]["p_min"] + data["junction"]["1"]["p_max"])
            res = run_model(data, 
                WPGasModel, 
                nlp_solver, 
                build_ogf;
                solution_processors=[sol_psqr_to_p!,
                sol_compressor_p_to_r!,
                sol_regulator_p_to_r!,
                sol_status_zero_components!],
            )
            # @test res["termination_status"] in [LOCALLY_SOLVED, OPTIMAL]
            @test haskey(res["solution"]["junction"], "1")
            @test res["solution"]["junction"]["1"]["status"] == 0
            @test res["solution"]["junction"]["1"]["p"] == 0
            @test res["solution"]["junction"]["1"]["psqr"] == 0
            @test res["solution"]["pipe"]["1"]["status"] == 0
            @test res["solution"]["pipe"]["1"]["f"] == 0.0
        end

        @testset "test solution hints for static file" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            solution_file = "../test/data/transient/case6_base_solution.json"
            add_solution_hints!(data, solution_file)
            res = solve_ogf(data, WPGasModel, nlp_solver)
            @test res["termination_status"] in [LOCALLY_SOLVED, OPTIMAL]
            @test isapprox(res["objective"], -167.19, rtol=1e-2)
        end
        
        @testset "test is_dispatchable zero components in solution" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")

            data["transfer"]["1"]["is_dispatchable"] = 0

            res = run_model(
                data,
                WPGasModel,
                nlp_solver,
                build_ogf;
                solution_processors = [
                    sol_psqr_to_p!,
                    sol_compressor_p_to_r!,
                    sol_regulator_p_to_r!,
                    sol_is_dispatchable_zero_components!,
                ],
            )

            @test res["primal_status"] in [MathOptInterface.FEASIBLE_POINT]
            @test haskey(res["solution"]["transfer"], "1")
        end

        @testset "test normalize solution base values from data" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            make_si_units!(result["solution"])

            result_pu = deepcopy(result)
            result_pu["solution"]["base_flow"] = result_pu["solution"]["base_flow"] * 2.0
            make_per_unit!(result_pu["solution"])
            pu_solution = GasModels.normalize_solution_base_values!(result_pu, data)

            @test pu_solution === result_pu["solution"]
            @test pu_solution["si_units"] == true
            @test pu_solution["per_unit"] == false
            @test pu_solution["base_flow"] == data["base_flow"]
            @test isapprox(pu_solution["receipt"]["1"]["fg"], result["solution"]["receipt"]["1"]["fg"], atol=1e-6)

            result_si = deepcopy(result["solution"])
            result_si["base_flow"] = result_si["base_flow"] * 2.0
            sol_root = GasModels.normalize_solution_base_values!(result_si, data)

            @test sol_root === result_si
            @test result_si["si_units"] == true
            @test result_si["per_unit"] == false
            @test result_si["base_flow"] == data["base_flow"]
            @test isapprox(result_si["receipt"]["1"]["fg"], result["solution"]["receipt"]["1"]["fg"], atol=1e-6)
        end

        @testset "test primal feasibility report from solution file" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            gm = GasModels.instantiate_model(data, WPGasModel, GasModels.build_ogf)
            solution_file = "../test/data/transient/case6_base_solution.json"
            report = GasModels.primal_feasibility_report(gm, solution_file; atol = 1e-6, skip_missing=true)
            @test isempty(report)

            solution = JSON.parsefile(solution_file)
            solution["solution"]["junction"]["1"]["psqr"] *= 0.95
            report = GasModels.primal_feasibility_report(gm, solution; atol = 1e-6, skip_missing=true)
            @test !isempty(report)
        end

        @testset "test primal feasibility report with compressor ratio auxiliaries" begin
            data = GasModels.parse_file("../test/data/matgas/direction.m")
            data["compressor"]["20"]["directionality"] = 0

            result = solve_ogf(data, WPGasModel, juniper_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]

            gm = GasModels.instantiate_model(data, WPGasModel, GasModels.build_ogf)
            report = GasModels.primal_feasibility_report(gm, result; atol = 1e-6, skip_missing=true)
            @test isempty(report)
        end

        @testset "case 6 ogf" begin
            @_info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219; atol = 1e-2)
        end

        @testset "case 6 ogf weymouth lin rel" begin
            @_info "Testing OGF Linear Relaxation of Pipe Weymouth Physics"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, LRWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -260.001; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 130.00040; atol = 1e-2)
        end


        @testset "case 6 wp ogf binding energy constraint" begin
            @_info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887; atol = 1e-2)
        end

        @testset "case 6 wp ogf elevation constraint" begin
            @_info "Testing OGF Elevation Constraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.27275; atol = 1e-2)
        end

        @testset "case 6 lrwp ogf elevation constraint" begin
            @_info "Testing LRWP OGF Elevation Constraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            data["economic_weighting"] = 1.0
            result = solve_ogf(data, LRWPGasModel, lp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 125.17; atol = 1e-2)
        end

        @testset "case 6 lrdwp ogf elevation constraint" begin
            @_info "Testing LRDWP OGF Elevation Constraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            data["economic_weighting"] = 1.0
            result = solve_ogf(data, LRDWPGasModel, mip_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 125.17; atol = 1e-2)
        end

        @testset "case 6 cwp ogf binding energy constraint" begin
            @_info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887; atol = 1e-2)
        end

        @testset "case 6 cwp ogf elevation constraint" begin
            @_info "Testing OGF Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.2727; atol = 1e-2)
        end
         @testset "6-bus case solution with duals" begin
            @_info "Testing OGF Report Duals"
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

        @testset "case 6 ogf pipe zero length/lambda tolerance setting" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")

            result_default = solve_ogf(data, WPGasModel, nlp_solver)
            @test result_default["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            GasModels.make_si_units!(result_default["solution"])
            p_fr_default = result_default["solution"]["junction"]["5"]["p"]
            p_to_default = result_default["solution"]["junction"]["2"]["p"]
            @test !isapprox(p_fr_default, p_to_default; atol = 1.0)

            # only pipe 1 (fr=5, to=2) has length 50000; the rest have length 80000, so a
            # tolerance between those isolates pipe 1 without collapsing the whole network
            length_settings = Dict("config" => Dict("pipe_zero_length_tolerance" => 6.0e4))
            result_length = solve_ogf(data, WPGasModel, nlp_solver, setting = length_settings)
            @test result_length["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            GasModels.make_si_units!(result_length["solution"])
            p_fr_length = result_length["solution"]["junction"]["5"]["p"]
            p_to_length = result_length["solution"]["junction"]["2"]["p"]
            @test isapprox(p_fr_length, p_to_length; atol = 1.0)

            # every pipe shares the same friction_factor (0.01), so a tolerance alone can't
            # isolate a single pipe; shrink pipe 1's friction factor first so only it collapses
            data_lambda = deepcopy(data)
            data_lambda["pipe"]["1"]["friction_factor"] = 1.0e-4
            lambda_settings = Dict("config" => Dict("pipe_zero_lambda_tolerance" => 1.0e-3))
            result_lambda = solve_ogf(data_lambda, WPGasModel, nlp_solver, setting = lambda_settings)
            @test result_lambda["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            GasModels.make_si_units!(result_lambda["solution"])
            p_fr_lambda = result_lambda["solution"]["junction"]["5"]["p"]
            p_to_lambda = result_lambda["solution"]["junction"]["2"]["p"]
            @test isapprox(p_fr_lambda, p_to_lambda; atol = 1.0)
        end

        @testset "case 6 ogf inclined pipe threshold setting" begin
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")

            result_default = solve_ogf(data, WPGasModel, nlp_solver)
            @test result_default["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            GasModels.make_si_units!(result_default["solution"])
            p3_default = result_default["solution"]["junction"]["3"]["p"]

            settings = Dict("config" => Dict("inclined_pipe_threshold" => 10.0))
            result_custom = solve_ogf(data, WPGasModel, nlp_solver, setting = settings)
            @test result_custom["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            GasModels.make_si_units!(result_custom["solution"])
            p3_custom = result_custom["solution"]["junction"]["3"]["p"]

            @test !isapprox(p3_default, p3_custom; atol = 1.0e3)
        end

        @testset "case 6 lrwp ogf num_flow_breakpoints setting" begin
            @_info "Testing LRWP OGF num_flow_breakpoints Setting"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            data["economic_weighting"] = 1.0

            result_coarse = solve_ogf(data, LRWPGasModel, lp_solver, setting = Dict("config" => Dict("num_flow_breakpoints" => 1)))
            @test result_coarse["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]

            result_fine = solve_ogf(data, LRWPGasModel, lp_solver, setting = Dict("config" => Dict("num_flow_breakpoints" => 32)))
            @test result_fine["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]

            # more breakpoints tighten the piecewise-linear relaxation of this maximization problem, raising the objective bound
            @test result_fine["objective"] > result_coarse["objective"] + 1e-2

            nested_settings = Dict("config" => Dict("num_flow_breakpoints" => Dict("default" => 1, "pipe" => 32)))
            result_nested = solve_ogf(data, LRWPGasModel, lp_solver, setting = nested_settings)
            @test result_nested["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result_nested["objective"], result_fine["objective"]; atol = 1e-6)
        end
    end
end
