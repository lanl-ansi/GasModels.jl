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

