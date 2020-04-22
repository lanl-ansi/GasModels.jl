@testset "transient parsing" begin
    data = parse_transient("../test/data/transient/time-series-case-6b.csv")
    @test length(data) == 505
    @test all(length(item) == 5 for item in data)

    mn_data = parse_files("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6b.csv", 
        spatial_discretization=1e4, additional_time=0.0);
    @test length(mn_data["nw"]) == 25
    @test isapprox(mn_data["time_step"] * mn_data["base_time"], 3600.0; atol = 1e-3)

    mn_data = parse_files("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", 
        spatial_discretization=1e4, additional_time=0.0);
    @test length(mn_data["nw"]) == 25
    @test isapprox(mn_data["time_step"] * mn_data["base_time"], 3600.0; atol = 1e-3)
end

@testset "transient (steady state replicate) case" begin
    mn_data = parse_files("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6b.csv", 
        spatial_discretization=1e4, additional_time=0.0);
    result = solve_transient_ogf(mn_data, NLPGasModel, ipopt_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -5414.35, atol=1e-1)
    make_si_units!(result["solution"])
    @test isapprox(result["solution"]["nw"]["1"]["receipt"]["1"]["injection"], 54.97, atol=1e-1)
    @test isapprox(result["solution"]["nw"]["2"]["receipt"]["1"]["injection"], 99.44, atol=1e-1)
    @test isapprox(result["solution"]["nw"]["2"]["compressor"]["1"]["power"], 3e6, atol=10)
end 

@testset "transient time-periodic withdrawal case" begin
    mn_data = parse_files("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", 
        spatial_discretization=1e4, additional_time=0.0);
    result = solve_transient_ogf(mn_data, NLPGasModel, ipopt_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -5207.86, atol=1e-1)
    make_si_units!(result["solution"])
    @test isapprox(result["solution"]["nw"]["1"]["receipt"]["1"]["injection"], 43.84, atol=1e-1)
    @test isapprox(result["solution"]["nw"]["2"]["receipt"]["1"]["injection"], 98.65, atol=1e-1)
    @test isapprox(result["solution"]["nw"]["2"]["compressor"]["1"]["power"], 3e6, atol=10)
end 


