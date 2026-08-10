# Settings

Settings are used to support settings for the models that are not typical use cases.  The settings is a field name in the InfrastructureModels data structure and the most common way to populate or add
information to settings is to include them in the kwargs of the `solve` routines.  Example:

```julia
    data = GasModels.parse_file("../test/data/matgas/case-6.m")
    settings = Dict("output" => Dict("duals" => true))
    solve_ogf(data, WPGasModel, nlp_solver, setting=settings)
```


## Output

The `output` key is used to specify settings for uncommon outputs for solutions to a model


- `dual`: is the key used to report dual variable values in the output.  Use the boolean `true` to report dual variables in the solution.

## Config

The `config` key is used to specify settings for for configuration of a model

- `networks`: is the key used to identify the network keys to be used in populating an optimization model.  This is primarly used for specifying a network in the multi network structure to model with optimization.  While multiple network ids can be specified, this is generally ill advised as this will produce a single large decooupled optimization problem that is better solved individually. 

The following is an example of solving all networks in a multi network in a single optimization problem

```julia
    data = parse_multinetwork("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)

    settings = Dict("config" => Dict("networks" => parse.(Int, keys(mn_data["nw"]))))
    solve_ogf(data, WPGasModel, nlp_solver, setting=settings)
```

The following is an example of solving all networks in a multi network as a sequence of optimizations

```julia
    data = parse_multinetwork("../test/data/matgas/case-6.m", "../test/data/transient/time-series-case-6a.csv", time_step=864.0)
    
    result                                   = Dict{String, Any}()
    result["solution"]                       = Dict{String, Any}()
    result["solution"]["nw"]                 = Dict{String, Any}()
 
    for nw in keys(data["nw"])
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
```
