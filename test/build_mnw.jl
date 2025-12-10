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
    @test isapprox(result["objective"], -16708.3, atol = 1e-2) # fails on windows, evaluated -16708.421272034844 == -16708.3
end

@testset "test elevation case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-elevation.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -16708.3, atol = 1e-2) # fails on windows, -16708.421272034844, -16708.3
end

#this test doesn't pass on mac current julia version. passes on julia 1.6. windows+linux solve, windows solutions appear wrong
@testset "test ls-priority case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-ls-priority.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], 0.00658821, atol = 1e-3) #fails on windows, evaluated -0.00023705838606865443 == 0.00658821
end

#lots of IM warnings associated with this one - WIP
@testset "test no limits case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-no-power-limits.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -23756.0, atol = 1e-2) # fails on windows, -24332.96114365799, -23756.0
end

@testset "test storage case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-storage.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED #fails on windows, hit iteration limit
    @test isapprox(result["objective"], -36040.1, atol = 1e-2)
end

@testset "test ls case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-ls.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], 0.00658821, atol = 1e-3) #fails on windows, evaluated -0.00023705838606865443 == 0.00658821
end