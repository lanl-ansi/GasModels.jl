# SR- storage has issues on all 3 OS. ls, ls priority do not solve on mac but do solve on windows
# ipopt uses apple accelerate on mac, blas/mkl on windows/linux
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
    @test isapprox(result["objective"], -16708.421, atol = 1e-2) 
end

@testset "test elevation case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-elevation.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -16708.421, atol = 1e-2) 
end

#this test doesn't pass on mac current julia version. passes on julia 1.6
@testset "test ls-priority case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-ls-priority.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -0.00023, atol = 1e-3) #
end

@testset "test no limits case - model structure validation" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-no-power-limits.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    
    @test haskey(mn_data, "nw")
    @test length(mn_data["nw"]) > 0
    
    @test haskey(mn_data["nw"]["1"], "transfer")
    @test length(mn_data["nw"]["1"]["transfer"]) > 0
    
    @test mn_data["nw"]["1"]["transfer"]["1"]["withdrawal_max"] >= 0
end

# SR- solves locally on windows, does not solve on CI. Goes to -36040.1
# @testset "test storage case" begin
#     mn_data = build_multinetwork("../test/data/matgas/case-6-storage.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
#     result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
#     @test result["termination_status"] == LOCALLY_SOLVED #fails on windows, hit iteration limit
#     @test isapprox(result["objective"], -28280.6027907, atol = 1e-2)
# end

@testset "test ls case" begin
    mn_data = build_multinetwork("../test/data/matgas/case-6-ls.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    # set parameters to coax the solver to a better state
    mn_data["nw"]["32"]["receipt"]["1"]["injection_nominal"] = 1.373485013568335e-7
    mn_data["nw"]["32"]["transfer"]["1"]["injection_nominal"] = 0
    mn_data["nw"]["1"]["transfer"]["1"]["injection_nominal"] = 0
    mn_data["nw"]["1"]["compressor"]["1"]["flow_max"] = 1.3734850135686312e-7
    mn_data["nw"]["2"]["transfer"]["1"]["injection_nominal"] = 0
    mn_data["nw"]["2"]["transfer"]["2"]["injection_nominal"] = 0
    mn_data["nw"]["2"]["transfer"]["3"]["injection_nominal"] = 0
    mn_data["nw"]["2"]["transfer"]["4"]["injection_nominal"] = 0
    mn_data["nw"]["2"]["junction"]["4"]["p_nominal"] = 1.3334 
    mn_data["nw"]["2"]["junction"]["3"]["p_nominal"] = 1.3334 
    mn_data["nw"]["2"]["junction"]["2"]["p_nominal"] = 1.3334 
    mn_data["nw"]["2"]["junction"]["1"]["p_nominal"] = 1.3334 
    mn_data["nw"]["53"]["junction"]["4"]["p_nominal"] = 1.3334 
    mn_data["nw"]["53"]["junction"]["3"]["p_nominal"] = 1.3334 
    mn_data["nw"]["53"]["junction"]["2"]["p_nominal"] = 1.3334 
    mn_data["nw"]["53"]["junction"]["1"]["p_nominal"] = 1.3334 
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -0.00023, atol = 1e-3) 
end