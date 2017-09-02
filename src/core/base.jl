# stuff that is universal to all gas models

export 
    GenericGasModel,
    setdata, setsolver, solve,
    run_generic_model, build_generic_model, solve_generic_model

""
@compat abstract type AbstractGasFormulation end
        
"""
```
type GenericGasModel{T<:AbstractGasFormulation}
    model::JuMP.Model
    data::Dict{String,Any}
    setting::Dict{String,Any}
    solution::Dict{String,Any}
    var::Dict{Symbol,Any} # model variable lookup
    constraint::Dict{Symbol, Dict{Any, ConstraintRef}} # model constraint lookup
    ref::Dict{Symbol,Any} # reference data
    ext::Dict{Symbol,Any} # user extentions
end
```
where

* `data` is the original data, usually from reading in a `.json` file,
* `setting` usually looks something like `Dict("output" => Dict("flows" => true))`, and
* `ref` is a place to store commonly used pre-computed data from of the data dictionary,
    primarily for converting data-types, filtering out deactivated components, and storing
    system-wide values that need to be computed globally. See `build_ref(data)` for further details.

Methods on `GenericGasModel` for defining variables and adding constraints should

* work with the `ref` dict, rather than the original `data` dict,
* add them to `model::JuMP.Model`, and
* follow the conventions for variable and constraint names.
"""
type GenericGasModel{T<:AbstractGasFormulation} 
    model::Model
    data::Dict{String,Any}
    setting::Dict{String,Any}
    solution::Dict{String,Any}
    ref::Dict{Symbol,Any} # data reference data
    var::Dict{Symbol,Any} # JuMP variables
    constraint::Dict{Symbol,Dict{Any, ConstraintRef}} # data reference data    
    ext::Dict{Symbol,Any} 
end


"default generic constructor"
function GenericGasModel(data::Dict{String,Any}, T::DataType; setting = Dict{String,Any}(), solver = JuMP.UnsetSolver())
    gm = GenericGasModel{T}(
        Model(solver = solver), # model
        data, # data
        setting, # setting
        Dict{String,Any}(), # solution
        build_ref(data), # reference data
        Dict{Symbol,Any}(), # vars
        Dict{Symbol,Dict{Any, ConstraintRef}}(), # constraints
        Dict{Symbol,Any}() # ext
    )
    return gm
end

" Set the solver "
function JuMP.setsolver(gm::GenericGasModel, solver::MathProgBase.AbstractMathProgSolver)
    setsolver(gm.model, solver)
end

" Do a solve of the problem "
function JuMP.solve(gm::GenericGasModel)
    status, solve_time, solve_bytes_alloc, sec_in_gc = @timed solve(gm.model)

    try
        solve_time = getsolvetime(gm.model)
    catch
        warn("there was an issue with getsolvetime() on the solver, falling back on @timed.  This is not a rigorous timing value.");
    end

    return status, solve_time
end

""
function run_generic_model(file::String, model_constructor, solver, post_method; kwargs...)
    data = GasModels.parse_file(file)
    return run_generic_model(data, model_constructor, solver, post_method; kwargs...)
end

""
function run_generic_model(data::Dict{String,Any}, model_constructor, solver, post_method; solution_builder = get_solution, kwargs...)
    gm = build_generic_model(data, model_constructor, post_method; kwargs...)
    solution = solve_generic_model(gm, solver; solution_builder = solution_builder)
    return solution
end

""
function build_generic_model(file::String,  model_constructor, post_method; kwargs...)
    data = GasModels.parse_file(file)
    return build_generic_model(data, model_constructor, post_method; kwargs...)
end


""
function build_generic_model(data::Dict{String,Any}, model_constructor, post_method; kwargs...)
    gm = model_constructor(data; kwargs...)
    post_method(gm)
    return gm
end

""
function solve_generic_model(gm::GenericGasModel, solver; solution_builder = get_solution)
    setsolver(gm.model, solver)
    status, solve_time = solve(gm)
    return build_solution(gm, status, solve_time; solution_builder = solution_builder)
end

"""
Returns a dict that stores commonly used pre-computed data from of the data dictionary,
primarily for converting data-types, filtering out deactivated components, and storing
system-wide values that need to be computed globally.

Some of the common keys include:

* `:max_flow` (see `max_flow(data)`),
* `:connection` -- the set of connections that are active in the network (based on the component status values),
* `:pipe` -- the set of connections that are pipes (based on the component type values),
* `:short_pipe` -- the set of connections that are short pipes (based on the component type values),
* `:compressor` -- the set of connections that are compressors (based on the component type values),
* `:valve` -- the set of connections that are valves (based on the component type values),
* `:control_valve` -- the set of connections that are control valves (based on the component type values),
* `:resistor` -- the set of connections that are resistors (based on the component type values),
* `:parallel_connections` -- the set of all existing connections between junction pairs (i,j),
* `:all_parallel_connections` -- the set of all existing and new connections between junction pairs (i,j),
* `:junction_connections` -- the set of all existing connections of junction i,
* `:junction_ne_connections` -- the set of all new connections of junction i,
* `junction[degree]` -- the degree of junction i using existing connections (see `add_degree`)),
* `junction[all_degree]` -- the degree of junction i using existing and new connections (see `add_degree`)),
* `connection[pd_min,pd_max]` -- the max and min square pressure difference (see `add_pd_bounds_swr`)),

If `:ne_connection` does not exist, then an empty reference is added
If `status` does not exist in the data, then 1 is added
If `construction cost` does not exist in the `:ne_connection`, then 0 is added
"""
function build_ref(data::Dict{String,Any})
    # Do some robustness on the data to add missing fields
    add_default_data(data)
    add_default_status(data)
    add_default_construction_cost(data)
      
    ref = Dict{Symbol,Any}()
    for (key, item) in data
        if isa(item, Dict)
            item_lookup = Dict([(parse(Int, k), v) for (k,v) in item])
            ref[Symbol(key)] = item_lookup
        else
            ref[Symbol(key)] = item
        end
    end
    
    # filter turned off stuff
    ref[:connection] = filter((i, connection) -> connection["status"] == 1 && connection["f_junction"] in keys(ref[:junction]) && connection["t_junction"] in keys(ref[:junction]), ref[:connection])
    ref[:ne_connection] = filter((i, connection) -> connection["status"] == 1 && connection["f_junction"] in keys(ref[:junction]) && connection["t_junction"] in keys(ref[:junction]), ref[:ne_connection])

    # compute the maximum flow  
    max_flow = calc_max_flow(data)
    ref[:max_flow] = max_flow  
            
    # create some sets based on connection types
    ref[:pipe] = filter((i, connection) -> connection["type"] == "pipe", ref[:connection])
    ref[:short_pipe] = filter((i, connection) -> connection["type"] == "short_pipe", ref[:connection])
    ref[:compressor] = filter((i, connection) -> connection["type"] == "compressor", ref[:connection])
    ref[:valve] = filter((i, connection) -> connection["type"] == "valve", ref[:connection])
    ref[:control_valve] = filter((i, connection) -> connection["type"] == "control_valve", ref[:connection])
    ref[:resistor] = filter((i, connection) -> connection["type"] == "resistor", ref[:connection])

    ref[:ne_pipe] = filter((i, connection) -> connection["type"] == "pipe", ref[:ne_connection])
    ref[:ne_compressor] = filter((i, connection) -> connection["type"] == "compressor", ref[:ne_connection])
      
      
    # collect all the parallel connections and connections of a junction
    # These are split by new connections and existing connections
    ref[:parallel_connections] = Dict()
    ref[:all_parallel_connections] = Dict()              
    for entry in [ref[:connection]; ref[:ne_connection]]
        for (idx, connection) in entry   
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_connections][(min(i,j), max(i,j))] = []
            ref[:all_parallel_connections][(min(i,j), max(i,j))] = []
        end
    end
 
    ref[:junction_connections] = Dict(i => [] for (i,junction) in ref[:junction])
    ref[:junction_ne_connections] = Dict(i => [] for (i,junction) in ref[:junction])
      
    for (idx, connection) in ref[:connection]
        i = connection["f_junction"]
        j = connection["t_junction"]   
        push!(ref[:junction_connections][i], idx)
        push!(ref[:junction_connections][j], idx)        
        push!(ref[:parallel_connections][(min(i,j), max(i,j))], idx)
        push!(ref[:all_parallel_connections][(min(i,j), max(i,j))], idx)                        
    end
    
    for (idx,connection) in ref[:ne_connection]
        i = connection["f_junction"]
        j = connection["t_junction"]          
        push!(ref[:junction_ne_connections][i], idx)
        push!(ref[:junction_ne_connections][j], idx)        
        push!(ref[:all_parallel_connections][(min(i,j), max(i,j))], idx)                        
    end
      
    add_degree(ref)    
    add_pd_bounds_sqr(ref)    
    return ref
end

"Just make sure there is an empty set for new connections if it does not exist"
function add_default_data(data :: Dict{String,Any})
    if !haskey(data, "ne_connection")
        data["ne_connection"] = []
    end               
end
