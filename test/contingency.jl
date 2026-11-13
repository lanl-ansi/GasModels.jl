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

@testset "directional flow limit contingency" begin
    @testset "data mapping" begin
        case = parse_file("../test/data/matgas/case-6.m")
        base_flow = case["base_flow"]
        pipe2_min, pipe2_max = case["pipe"]["2"]["flow_min"], case["pipe"]["2"]["flow_max"]
        pipe4_min, pipe4_max = case["pipe"]["4"]["flow_min"], case["pipe"]["4"]["flow_max"]

        # pipe 2 runs 2 -> 3 (north-east): northbound = forward, westbound = reverse
        # pipe 4 runs 3 -> 4 (north-west): southbound = reverse
        scenario = ContingencyScenario(
            name = "directional limits",
            contingencies = [
                DirectionalFlowLimitContingency(asset_type="pipe", asset_id="2", direction="north", max_mass_flow=15.0),
                DirectionalFlowLimitContingency(asset_type="pipe", asset_id="2", direction="West", max_mass_flow=5.0),
                DirectionalFlowLimitContingency(asset_type="pipe", asset_id="4", direction="south", max_mass_flow=0.0),
            ],
        )
        results = apply_contingency!(case, scenario)
        @test all_applied(results)

        @test isapprox(case["pipe"]["2"]["flow_max"], 15.0 / base_flow)
        @test isapprox(case["pipe"]["2"]["flow_min"], -5.0 / base_flow)
        @test case["pipe"]["4"]["flow_min"] == 0.0
        @test case["pipe"]["4"]["flow_max"] == pipe4_max

        # limits only tighten: a loose cap leaves bounds unchanged
        loose = DirectionalFlowLimitContingency(asset_type="pipe", asset_id="2", direction="north", max_mass_flow=1e6)
        @test apply_contingency!(case, ContingencyScenario(name="loose", contingencies=[loose]))[1].success
        @test isapprox(case["pipe"]["2"]["flow_max"], 15.0 / base_flow)

        # compressor 1 runs due north (same longitude), so east/west is ambiguous
        perpendicular = DirectionalFlowLimitContingency(asset_type="compressor", asset_id="1", direction="east", max_mass_flow=1.0)
        @test !apply_contingency!(case, ContingencyScenario(name="perp", contingencies=[perpendicular]))[1].success

        # compressor 1 is forward-only (flow_min = 0): limiting southbound is a no-op tightening
        @test apply_contingency!(case, ContingencyScenario(name="s", contingencies=[
            DirectionalFlowLimitContingency(asset_type="compressor", asset_id="1", direction="south", max_mass_flow=0.0)]))[1].success
        @test case["compressor"]["1"]["flow_min"] == 0.0

        # coordinates are required
        no_coords = parse_file("../test/data/matgas/case-6.m")
        delete!(no_coords["junction"]["3"], "lat")
        c = DirectionalFlowLimitContingency(asset_type="pipe", asset_id="2", direction="north", max_mass_flow=15.0)
        @test !apply_contingency!(no_coords, ContingencyScenario(name="nc", contingencies=[c]))[1].success
        @test no_coords["pipe"]["2"]["flow_max"] == pipe2_max

        # constructor validation
        @test_throws ArgumentError DirectionalFlowLimitContingency(asset_type="pipe", asset_id="2", direction="up", max_mass_flow=1.0)
        @test_throws ArgumentError DirectionalFlowLimitContingency(asset_type="pipe", asset_id="2", direction="north", max_mass_flow=-1.0)
        @test_throws ArgumentError DirectionalFlowLimitContingency(asset_type="junction", asset_id="2", direction="north", max_mass_flow=1.0)
    end

    @testset "energy to mass flow conversion" begin
        case = parse_file("../test/data/matgas/case-6.m")
        # 1037 Dth/d at 1037 Btu/scf is exactly 1 MMSCFD
        @test isapprox(dth_per_day_to_kgps(1037.0, case), get_mmscfd_to_kgps_conversion_factor(case))
        @test isapprox(dth_per_day_to_kgps(2000.0, case; heating_value=1000.0), 2 * get_mmscfd_to_kgps_conversion_factor(case))
        @test_throws ArgumentError dth_per_day_to_kgps(1.0, case; heating_value=0.0)
    end

    # baseline OGF moves ~27 kg/s north through pipe 2; cap it at 15 kg/s
    cap_kgps = 15.0
    function dispatchable_case()
        case = parse_file("../test/data/matgas/case-6.m")
        for (_, deliv) in case["delivery"]
            deliv["is_dispatchable"] = 1
        end
        return case
    end
    function capped_case()
        case = dispatchable_case()
        apply_contingency!(case, ContingencyScenario(name="cap", contingencies=[
            DirectionalFlowLimitContingency(asset_type="pipe", asset_id="2", direction="north", max_mass_flow=cap_kgps)]))
        return case
    end

    @testset "wp ogf respects limit" begin
        case = dispatchable_case()
        base = solve_ogf(case, WPGasModel, nlp_solver)
        @test base["termination_status"] == LOCALLY_SOLVED
        @test base["solution"]["pipe"]["2"]["f"] * case["base_flow"] > cap_kgps

        case = capped_case()
        output = solve_ogf(case, WPGasModel, nlp_solver)
        @test output["termination_status"] == LOCALLY_SOLVED
        @test output["solution"]["pipe"]["2"]["f"] * case["base_flow"] <= cap_kgps + 1e-4
        @test output["objective"] > base["objective"]
    end

    @testset "dwp ogf respects limit" begin
        case = capped_case()
        output = solve_ogf(case, DWPGasModel, minlp_solver)
        @test output["termination_status"] == LOCALLY_SOLVED
        @test output["solution"]["pipe"]["2"]["f"] * case["base_flow"] <= cap_kgps + 1e-4
    end
end
