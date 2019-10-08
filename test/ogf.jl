#Check the NLP model
@testset "test nlp ogf" begin
    @testset "gaslib 40 case" begin
        println("Testing OGF")
        data = GasModels.parse_file("../test/data/model6ss_test_0.m")
        result = run_ogf(data, NLPGasModel, ipopt_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], -15.377535238085375; atol = 1e-6)
        GasModels.make_si_unit!(result["solution"])
        @test isapprox(result["solution"]["producer"]["6"]["fg"], 123.68517579504999; atol = 1e-6)
    end

    @testset "gaslib 40 case" begin
        println("Testing OGF Binding Energy Cosntraint")
        data = GasModels.parse_file("../test/data/model6ss_test_1.m")
        result = run_ogf(data, NLPGasModel, ipopt_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], -11.56408051038651; atol = 1e-6)
        GasModels.make_si_unit!(result["solution"])
        @test isapprox(result["solution"]["producer"]["6"]["fg"], 97.88470742690157; atol = 1e-6)
    end
end
