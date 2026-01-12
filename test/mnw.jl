@testset "confirm that changes occur in parse_multinetwork" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    @test (mn_data["nw"]["1"]["transfer"]["1"]["withdrawal_max"] !== mn_data["nw"]["100"]["transfer"]["1"]["withdrawal_max"])
    @test (mn_data["nw"]["20"]["transfer"]["1"]["withdrawal_max"] !== mn_data["nw"]["80"]["transfer"]["1"]["withdrawal_max"])
    @test (mn_data["nw"]["20"]["transfer"]["5"]["withdrawal_max"] !== mn_data["nw"]["80"]["transfer"]["5"]["withdrawal_max"])
    @test (mn_data["nw"]["1"]["transfer"]["3"]["withdrawal_max"] !== mn_data["nw"]["50"]["transfer"]["3"]["withdrawal_max"])
end

@testset "confirm that solution exists and is feasible" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    stat_result = solve_ogf(mn_data, WPGasModel, nlp_solver)
    @test stat_result["termination_status"] == LOCALLY_SOLVED
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -16875.6010, atol = 1e-2) 
end

@testset "test elevation case" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6-elevation.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    stat_result = solve_ogf(mn_data, WPGasModel, nlp_solver)
    @test stat_result["termination_status"] == LOCALLY_SOLVED
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -16875.6010, atol = 1e-2) 
end

@testset "test ls-priority case" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6-ls-priority.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    stat_result = solve_ogf(mn_data, WPGasModel, nlp_solver)
    @test stat_result["termination_status"] == LOCALLY_SOLVED
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -0.00023, atol = 1e-3) #
end

@testset "test no limits case - model structure validation" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6-no-power-limits.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    
    @test haskey(mn_data, "nw")
    @test length(mn_data["nw"]) > 0
    
    @test haskey(mn_data["nw"]["1"], "transfer")
    @test length(mn_data["nw"]["1"]["transfer"]) > 0
    
    @test mn_data["nw"]["1"]["transfer"]["1"]["withdrawal_max"] >= 0
end

@testset "test ls case" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6-ls.m", 
                                "../test/data/transient/time-series-case-6a.csv", 
                                time_step=864.0)
    
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    stat_result = solve_ogf(mn_data, WPGasModel, nlp_solver)
    @test stat_result["termination_status"] == LOCALLY_SOLVED
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -0.00023, atol = 1e-3) 
end