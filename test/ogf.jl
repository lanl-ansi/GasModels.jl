@testset "test ogf" begin
    @testset "test nlp ogf" begin
        @testset "gaslib 40 nlp ogf" begin
            @info "Testing OGF"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits.m")
            result = run_ogf(data, NLPGasModel, ipopt_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], -15.377535238085375; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.68517579504999; atol = 1e-6)
        end

        @testset "gaslib 40 nlp ogf binding energy constraint" begin
            @info "Testing OGF Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6.m")
            result = run_ogf(data, NLPGasModel, ipopt_solver)
            @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], -11.56408051038651; atol = 1e-6) # check with Russell
            @test isapprox(result["objective"], -0.0153; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 97.88470742690157; atol = 1e-6)
        end
    end
end
