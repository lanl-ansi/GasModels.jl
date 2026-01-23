@testset "test ogf" begin
    @testset "test wp ogf" begin
        @testset "case 6 ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end
        
        @testset "test solution hints for static file" begin
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            solution_file = "../test/data/transient/case6_base_solution.json"
            add_solution_hints!(data, solution_file)
            res = solve_ogf(data, WPGasModel, nlp_solver)
            @test res["termination_status"] in [LOCALLY_SOLVED, OPTIMAL]
            @test isapprox(res["objective"], -167.19, rtol=1e-2)
        end

        @testset "case 6 ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 ogf weymouth lin rel" begin
            @info "Testing OGF Linear Relaxation of Pipe Weymouth Physics"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf(data, LRWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -260.001; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 130.00040358725565; atol = 1e-2)
        end


        @testset "case 6 wp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887353509726; atol = 1e-2)
        end

        @testset "case 6 wp ogf elevation constraint" begin
            @info "Testing OGF Elevation Constraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.6788; atol = 1e-2)
        end

        @testset "case 6 cwp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887353509726; atol = 1e-2)
        end

        @testset "case 6 cwp ogf elevation constraint" begin
            @info "Testing OGF Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.1902; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.6788; atol = 1e-2)
        end
    end
end
