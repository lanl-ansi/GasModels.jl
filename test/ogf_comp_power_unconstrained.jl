@testset "test ogf" begin
    @testset "test wp ogf" begin
        @testset "case 6 ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = run_ogf_comp_power_unc(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = run_ogf_comp_power_unc(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 ogf weymouth lin rel" begin
            @info "Testing OGF Linear Relaxation of Pipe Weymouth Physics"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = run_ogf_comp_power_unc(data, LRWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -260.001; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 130.00040358725565; atol = 1e-2)
        end


        @testset "case 6 wp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = run_ogf_comp_power_unc(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887353509726; atol = 1e-2)
        end

        @testset "case 6 wp ogf elevation constraint" begin
            @info "Testing OGF Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = run_ogf_comp_power_unc(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.27275616368388; atol = 1e-2)
        end

        @testset "case 6 cwp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = run_ogf_comp_power_unc(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.67887353509726; atol = 1e-2)
        end

        @testset "case 6 cwp ogf elevation constraint" begin
            @info "Testing OGF Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = run_ogf_comp_power_unc(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.27275616368388; atol = 1e-2)
        end
    end
end
