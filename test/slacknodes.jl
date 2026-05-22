@testset "parse_file slack node correction" begin
    
    const _PKG_ROOT = dirname(dirname(pathof(GasModels)))
    const CASE6NOSLACK = joinpath(
        _PKG_ROOT,
        "test",
        "data",
        "matgas",
        "case-6-no-slack.m",
    )

    @testset "correct_slack_nodes preserves existing slack" begin
        data = parse_file(CASE6PATH; correct_slack_nodes = true)

        slacks = [
            k for (k, j) in data["junction"]
            if j["status"] == 1 && j["junction_type"] == 1
        ]

        @test slacks == ["1"]
    end

    @testset "parse_files does not add slack unless requested" begin
        data = parse_file(CASE6NOSLACK)
        @test count(j -> j["junction_type"] == 1, values(data["junction"])) == 0
    end

    @testset "parse_file adds slack when requested" begin
        data = parse_file(CASE6NOSLACK; correct_slack_nodes = true)

        slacks = [
            k for (k, j) in data["junction"]
            if j["status"] == 1 && j["junction_type"] == 1
        ]

        @test length(slacks) == 1
    end
end