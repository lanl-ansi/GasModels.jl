@testset "test new ogf" begin
    @testset "test wp new ogf" begin
        @testset "case 6 new ogf" begin
            @info "Testing OGF with compressor power and pipe weymouth proxy (linear)"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = run_ogf_comp_power_and_pipe_proxy(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -230.534; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 100.53; atol = 1e-2)
        end

        @testset "case 6 new ogf weymouth lin rel" begin
            @info "Testing  OGF with compressor power proxy and pipe weymouth proxy"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = run_ogf_comp_power_and_pipe_proxy(data, LRWPGasModel, lp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -230.534; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 100.53; atol = 1e-2)
        end


        @testset "case 6 wp new ogf binding energy constraint" begin
            @info "Testing  OGF with compressor power and pipe weymouth proxy Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = run_ogf_comp_power_and_pipe_proxy(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -187.253; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 67.01; atol = 1e-2)
        end

        @testset "case 6 wp new ogf elevation constraint" begin
            @info "Testing  OGF with compressor power and pipe weymouth proxy Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation.m")
            result = run_ogf_comp_power_and_pipe_proxy(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -219.461; atol = 1e-1)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 86.33; atol = 1e-2)
        end
    end
end
