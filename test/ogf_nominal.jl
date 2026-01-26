@testset "test ogf nominal" begin
    @testset "test wp ogf nominal" begin
        @testset "case 6 ogf nominal" begin
            @info "Testing OGF Nominal"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits-nominal.m")
            result = solve_ogf_nominal(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 ogf nominal" begin
            @info "Testing OGF Nominal"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits-nominal.m")
            result = solve_ogf_nominal(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 ogf nominal weymouth lin rel" begin
            @info "Testing OGF Nominal Linear Relaxation of Pipe Weymouth Physics"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits-nominal.m")
            result = solve_ogf_nominal(data, LRWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -260.001; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 130.00040358725565; atol = 1e-2)
        end

        @testset "case 6 wp ogf nominal binding energy constraint" begin
            @info "Testing OGF Nominal Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-nominal.m")
            result = solve_ogf_nominal(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887353509726; atol = 1e-2)
        end

        @testset "case 6 wp ogf nominal elevation constraint" begin
            @info "Testing OGF Nominal Elevation Constraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation-nominal.m")
            result = solve_ogf_nominal(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.6788; atol = 1e-2)
        end

        @testset "case 6 cwp ogf nominal binding energy constraint" begin
            @info "Testing OGF Nominal Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-nominal.m")
            result = solve_ogf_nominal(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887353509726; atol = 1e-2)
        end

        @testset "case 6 cwp ogf nominal elevation constraint" begin
            @info "Testing OGF Nominal Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation-nominal.m")
            result = solve_ogf_nominal(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.1902; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.6788; atol = 1e-2)
        end
    end
end
