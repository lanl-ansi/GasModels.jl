@testset "transient parsing" begin
    data = parse_transient("../test/data/transient/transient_case6.csv")
    @test length(data) == 404
    @test all(length(item) == 5 for item in data)
end
