@testset "test ogf comp power unc" begin
    @testset "test wp ogf comp power unc" begin
        @testset "case 6 ogf" begin
            @info "Testing OGF w/o Compressor Power"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf_comp_power_unc(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 ogf comp power unc" begin
            @info "Testing OGF w/o Compressor Power"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf_comp_power_unc(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 ogf comp power unc weymouth lin rel" begin
            @info "Testing OGF w/o Compressor Power but with Linear Relaxation of Pipe Weymouth Physics"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = solve_ogf_comp_power_unc(data, LRWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -260.001; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 130.00040358725565; atol = 1e-2)
        end


        @testset "case 6 wp ogf comp power unc binding energy constraint" begin
            @info "Testing OGF w/o Compressor Power with Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf_comp_power_unc(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -271.46; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 113.17; atol = 1e-2)
        end

        @testset "case 6 wp ogf comp power unc elevation constraint" begin
            @info "Testing OGF w/o Compressor Power Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf_comp_power_unc(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -285.768; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 124.6143508063051; atol = 1e-2)
        end

        @testset "case 6 cwp ogf comp power unc binding energy constraint" begin
            @info "Testing OGF w/o Compressor Power with Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = solve_ogf_comp_power_unc(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -271.46; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 113.17; atol = 1e-2)
        end

        @testset "case 6 cwp ogf comp power unc elevation constraint" begin
            @info "Testing OGF w/o Compressor Power with Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = solve_ogf_comp_power_unc(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -285.768; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 124.614; atol = 1e-2)
        end
    end
end
