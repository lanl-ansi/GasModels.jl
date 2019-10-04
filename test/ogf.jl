#Check the NLP model
@testset "test nlp ogf" begin
    @testset "gaslib 40 case" begin
        println("Testing OGF")
        data = GasModels.parse_file("../test/data/model6ss_test_0.m")
        result = run_ogf(data, NLPGasModel, ipopt_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], -15.374806321775978; atol = 1e-6)
        GasModels.make_si_unit!(result["solution"])
        @test isapprox(result["solution"]["producer"]["6"]["fg"], 123.68517579504999; atol = 1e-6)
    end
end
