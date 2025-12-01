@testset "confirm that changes occur in build_multinetwork" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    # withdrawal max changes during the transient in case 6a, does not in case 6b
    # withdrawal max is the only thing that changes in this csv
    @test (mn_data["nw"]["1"]["transfer"]["1"]["withdrawal_max"] !== mn_data["nw"]["100"]["transfer"]["1"]["withdrawal_max"])
    @test (mn_data["nw"]["20"]["transfer"]["1"]["withdrawal_max"] !== mn_data["nw"]["80"]["transfer"]["1"]["withdrawal_max"])
    @test (mn_data["nw"]["20"]["transfer"]["5"]["withdrawal_max"] !== mn_data["nw"]["80"]["transfer"]["5"]["withdrawal_max"])
    @test (mn_data["nw"]["1"]["transfer"]["3"]["withdrawal_max"] !== mn_data["nw"]["50"]["transfer"]["3"]["withdrawal_max"])
end

@testset "confirm that solution exists and is feasible" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
end

@testset "test elevation case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-elevation.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
end

@testset "test ls-priority case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-ls-priority.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
end

#lots of IM warnings associated with this one - WIP
@testset "test no limits case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-no-power-limits.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
end