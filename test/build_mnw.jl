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

if !Sys.isapple()
    #SR note: even with ~80 solver hints added, this fails on mac CI. Passes on several LANL macs
    #skipping this test on mac CI for now, but got ls working
    @testset "test ls-priority case" begin
        mn_data = build_multinetwork("../test/data/matgas/case-6-ls-priority.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
        result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], -0.00023, atol = 1e-3) #
    end
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

# exclude julia 1.6 from tests
if (Sys.isapple() && VERSION > v"1.7") || !Sys.isapple()
    @testset "test ls case" begin
        mn_data = build_multinetwork("../test/data/matgas/case-6-ls.m", 
                                    "../test/data/transient/time-series-case-6a.csv", 
                                    time_step=864.0)
        
        result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], -0.00023, atol = 1e-3) 
    end
end