#example scenarios to pull from
SCENARIO_LIBRARY = Dict{String, ContingencyScenario}(
    "winter_storm" => ContingencyScenario(
        name = "Winter Storm",
        description = "Two pipes frozen, one compressor at reduced power",
        contingencies = [
            FailedComponentContingency(asset_type="pipe", asset_id="1"),
            FailedComponentContingency(asset_type="pipe", asset_id="2"),
            PowerOutageContingency(asset_type="compressor", asset_id="1", available_power_fraction=0.3),
        ]
    ),
    
    "maintenance" => ContingencyScenario(
        name = "Scheduled Maintenance",
        description = "Compressor offline for maintenance",
        contingencies = [
            FailedComponentContingency(asset_type="compressor", asset_id="2"),
        ]
    ),
    
    "power_grid_issue" => ContingencyScenario(
        name = "Power Grid Issue",
        description = "Multiple compressors at reduced capacity",
        contingencies = [
            PowerOutageContingency(asset_type="compressor", asset_id="1", available_power_fraction=0.5),
            PowerOutageContingency(asset_type="compressor", asset_id="2", available_power_fraction=0.5),
        ]
    ),
)

@testset "winter storm contingency" begin
    case = parse_file("../test/data/matgas/case-6.m")
    results = apply_contingency!(case, SCENARIO_LIBRARY["winter_storm"])
    for i in eachindex(results)
        @test results[i].success
    end
    output = solve_ogf(case, WPGasModel, nlp_solver)
    @test !haskey(output["solution"]["pipe"], "1") #components with status 0 are not included in solution
    @test !haskey(output["solution"]["pipe"], "2")
    @test output["solution"]["compressor"]["1"]["r"] < 1.3 #reduced power means it can't get to 1.4
end

@testset "maintenance contingency" begin
    case = parse_file("../test/data/matgas/case-6.m")
    results = apply_contingency!(case, SCENARIO_LIBRARY["maintenance"]) #"results" is a vector of results
    for i in eachindex(results)
        @test results[i].success
    end
    output = solve_ogf(case, WPGasModel, nlp_solver)
    @test output["solution"]["compressor"]["1"]["r"] < 1.3 #reduced power means it can't get to 1.4
end

@testset "power outage contingency" begin
    case = parse_file("../test/data/matgas/case-6.m")
    results = apply_contingency!(case, SCENARIO_LIBRARY["power_grid_issue"]) #"results" is a vector of results
    for i in eachindex(results)
        @test results[i].success
    end
    output = solve_ogf(case, WPGasModel, nlp_solver)
    @test output["solution"]["compressor"]["1"]["r"] < 1.3 #reduced power means it can't get to 1.4
    @test output["solution"]["compressor"]["2"]["r"] < 1.3
    #only 2 compressors in this model, would be good to test with more
end