@testset "test ogf" begin
    @testset "test nlp ogf" begin
        @testset "case 6 ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = run_ogf(data, NLPGasModel, nlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68219958067358; atol = 1e-2)
        end

        @testset "case 6 nlp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = run_ogf(data, NLPGasModel, nlp_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], -237.816; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 97.33312801519526; atol = 1e-2)
        end
    end
end
