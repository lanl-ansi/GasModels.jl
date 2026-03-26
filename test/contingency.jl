#example scenarios to pull from
SCENARIO_LIBRARY = Dict{String, ContingencyScenario}(
    "winter_storm" => ContingencyScenario(
        name = "Winter Storm",
        description = "One pipe disabled, one compressor at reduced power",
        contingencies = [
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

    # baseline solve (no contingency)
    base_output = solve_ogf(case, WPGasModel, nlp_solver)
    @test base_output["termination_status"] == LOCALLY_SOLVED
    @test base_output["primal_status"] == FEASIBLE_POINT
    base_obj = base_output["objective"]

    # apply contingency
    results = apply_contingency!(case, SCENARIO_LIBRARY["winter_storm"])
    for i in eachindex(results)
        @test results[i].success
    end

    #check data modifications
    @test case["pipe"]["2"]["status"] == 0
    @test isapprox(case["compressor"]["1"]["c_ratio_max"], 1.12, atol=0.01)  # reduced power
    
    #make deliveries dispatchable
    for (del_id, deliv) in case["delivery"]
        deliv["is_dispatchable"] = 1
    end
    
    @test case["delivery"]["1"]["is_dispatchable"] == 1
    @test case["transfer"]["1"]["is_dispatchable"] == 1
    @test case["receipt"]["1"]["is_dispatchable"] == 1

    #solve new case
    output = solve_ogf(case, DWPGasModel, minlp_solver)

    #check convergence
    @test output["termination_status"] == LOCALLY_SOLVED 
    @test output["primal_status"] == FEASIBLE_POINT

    #check objective value changed
    @test output["objective"] != base_obj
end


@testset "maintenance contingency" begin
    case = parse_file("../test/data/matgas/case-6.m")

    base_output = solve_ogf(case, WPGasModel, nlp_solver)
    @test base_output["termination_status"] == LOCALLY_SOLVED
    @test base_output["primal_status"] == FEASIBLE_POINT
    base_obj = base_output["objective"]

    results = apply_contingency!(case, SCENARIO_LIBRARY["maintenance"])
    for i in eachindex(results)
        @test results[i].success
    end

    #check data dictionary modifications
    @test case["compressor"]["2"]["status"] == 0

    #make deliveries dispatchable
    for (del_id, deliv) in case["delivery"]
        deliv["is_dispatchable"] = 1
    end

    output = solve_ogf(case, WPGasModel, nlp_solver)

    #convergence checks
    @test output["termination_status"] == LOCALLY_SOLVED
    @test output["primal_status"] == FEASIBLE_POINT

    #objective should change 
    @test output["objective"] != base_obj
    BASE_OBJ_MAINT = -126.4268
    @test isapprox(output["objective"], BASE_OBJ_MAINT, atol=1e-1)
end


@testset "power outage contingency" begin
    case = parse_file("../test/data/matgas/case-6.m")

    base_output = solve_ogf(case, WPGasModel, nlp_solver)
    @test base_output["termination_status"] == LOCALLY_SOLVED
    @test base_output["primal_status"] == FEASIBLE_POINT
    base_obj = base_output["objective"]

    results = apply_contingency!(case, SCENARIO_LIBRARY["power_grid_issue"])
    for i in eachindex(results)
        @test results[i].success
    end

    #check data dictionary modifications
    @test case["compressor"]["1"]["c_ratio_max"] <= 1.2
    @test case["compressor"]["2"]["c_ratio_max"] <= 1.2

    #make deliveries dispatchable
    for (del_id, deliv) in case["delivery"]
        deliv["is_dispatchable"] = 1
    end

    output = solve_ogf(case, WPGasModel, nlp_solver)

    #convergence checks
    @test output["termination_status"] == LOCALLY_SOLVED
    @test output["primal_status"] == FEASIBLE_POINT

    #objective should change
    @test output["objective"] != base_obj
end