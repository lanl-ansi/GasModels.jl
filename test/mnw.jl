solution_file = "../test/data/transient/case6_ls_a_solution.json"
elevation_solution_file = "../test/data/transient/case6elevationtr.json"

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
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -16708.421, atol = 1e-1) 
end

@testset "test elevation case" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6-elevation-transient.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    add_solution_hints!(mn_data, elevation_solution_file)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED 
    @test isapprox(result["objective"], -25216.73, atol = 1e-1) 
end

@testset "test ls-priority case" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6-ls-priority.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    add_solution_hints!(mn_data, solution_file)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
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
    
    add_solution_hints!(mn_data, solution_file)
    result = solve_transient_ogf(mn_data, WPGasModel, nlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -0.00023, atol = 1e-3) 
end

@testset "test multi network as a set of n independent steady-states solved as one large OGF problem" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6.m", 
                                "../test/data/transient/time-series-case-6a.csv", 
                                time_step=864.0)
    
    settings = Dict("config" => Dict("networks" => parse.(Int, keys(mn_data["nw"]))))
    result = GasModels.solve_ogf(mn_data, WPGasModel, nlp_solver, setting=settings)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], -16876.54423, atol = 1e-3)
    
    # verify that each network has a different solution
    make_si_units!(result["solution"])
    @test isapprox(result["solution"]["nw"]["1"]["transfer"]["1"]["ft"], 11.826, atol = 1e-2)
    @test isapprox(result["solution"]["nw"]["2"]["transfer"]["1"]["ft"], 12.225, atol = 1e-2)
end

@testset "test multi network as a set of n independent steady-states solved in sequence" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6.m", 
                                "../test/data/transient/time-series-case-6a.csv", 
                                time_step=864.0)
    
    result                                   = Dict{String, Any}()
    result["solution"]                       = Dict{String, Any}()
    result["solution"]["nw"]                 = Dict{String, Any}()
 
    for nw in keys(mn_data["nw"])
        settings = Dict("config" => Dict("networks" => [parse(Int,nw)]))
        solution = GasModels.solve_ogf(mn_data, WPGasModel, nlp_solver, setting=settings)
        @test solution["termination_status"] == LOCALLY_SOLVED
        result["solution"]["nw"][nw] = solution["solution"]["nw"][nw]

        # storing some individual solve information
        result["solution"]["nw"][nw]["termination_status"] = solution["termination_status"]
        result["solution"]["nw"][nw]["dual_status"]        = solution["dual_status"] 
        result["solution"]["nw"][nw]["solve_time"]         = solution["solve_time"]
        result["solution"]["nw"][nw]["primal_status"]      = solution["primal_status"] 
        result["solution"]["nw"][nw]["objective"]          = solution["objective"] 
        result["solution"]["nw"][nw]["objective_lb"]       = solution["objective_lb"] 

        # aggregate information
        result["solve_time"]   = get(result, "solve_time", 0) + solution["solve_time"]
        result["objective"]    = get(result, "objective", 0) + solution["objective"]
        result["objective_lb"] = get(result, "objective_lb", 0) + solution["objective_lb"]
        result["optimizer"]    = solution["optimizer"]
        result["model_type"]   = solution["model_type"]
        result["model_name"]   = solution["model_name"]

        #top level information
        result["solution"]["base_density"]         = solution["solution"]["base_density"] 
        result["solution"]["multinetwork"]         = solution["solution"]["multinetwork"] 
        result["solution"]["base_volume"]          = solution["solution"]["base_volume"] 
        result["solution"]["base_length"]          = solution["solution"]["base_length"] 
        result["solution"]["base_mass"]            = solution["solution"]["base_mass"] 
        result["solution"]["per_unit"]             = solution["solution"]["per_unit"] 
        result["solution"]["base_time"]            = solution["solution"]["base_time"] 
        result["solution"]["base_flow"]            = solution["solution"]["base_flow"] 
        result["solution"]["base_pressure"]        = solution["solution"]["base_pressure"] 
    end

    # verify that each network has a different solution
    make_si_units!(result["solution"])
    @test isapprox(result["objective"], -16876.54423, atol = 1e-3)
    @test isapprox(result["solution"]["nw"]["1"]["transfer"]["1"]["ft"], 11.826, atol = 1e-2)
    @test isapprox(result["solution"]["nw"]["2"]["transfer"]["1"]["ft"], 12.225, atol = 1e-2)

end

@testset "test multi network as a set of n independent steady-states solved as one large LS problem" begin
    mn_data = parse_multinetwork("../test/data/matgas/case-6-ls-mn.m", 
                                "../test/data/transient/time-series-case-6a.csv", 
                                time_step=864.0)
    settings = Dict("config" => Dict("networks" => parse.(Int, keys(mn_data["nw"]))))
    result = GasModels.solve_ls(mn_data, WPGasModel, nlp_solver, setting=settings)
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["objective"], 2.525, atol = 1e-3)
    
    # verify that each network has a different solution
    make_si_units!(result["solution"])
    @test isapprox(result["solution"]["nw"]["1"]["transfer"]["2"]["ft"], 0.0, atol = 1e-2)
    @test isapprox(result["solution"]["nw"]["2"]["transfer"]["2"]["ft"], 0.0, atol = 1e-2)

end