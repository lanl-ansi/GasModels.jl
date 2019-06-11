# stuff that is universal to all gas models

export
    GenericGasModel,
    optimize!,
    run_generic_model, build_generic_model, solve_generic_model

""
abstract type AbstractGasFormulation end

"""
```
mutable struct GenericGasModel{T<:AbstractGasFormulation}
    model::JuMP.Model
    data::Dict{String,Any}
    setting::Dict{String,Any}
    solution::Dict{String,Any}
    var::Dict{Symbol,Any} # model variable lookup
    constraint::Dict{Symbol, Dict{Any, ConstraintRef}} # model constraint lookup
    ref::Dict{Symbol,Any} # reference data
    ext::Dict{Symbol,Any} # user extensions
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
mutable struct GenericGasModel{T<:AbstractGasFormulation}
    model::JuMP.Model
    data::Dict{String,Any}
    setting::Dict{String,Any}
    solution::Dict{String,Any}
    ref::Dict{Symbol,Any} # data reference data
    var::Dict{Symbol,Any} # JuMP variables
    con::Dict{Symbol,Any} # data reference data

    cnw::Int # current network index value
    ext::Dict{Symbol,Any}
end

"default generic constructor"
function GenericGasModel(data::Dict{String,Any}, Typ::DataType; ext = Dict{String,Any}(), setting = Dict{String,Any}(), jump_model::JuMP.Model=JuMP.Model())
    ref = build_ref(data) # reference data

    var = Dict{Symbol,Any}(:nw => Dict{Int,Any}())
    con = Dict{Symbol,Any}(:nw => Dict{Int,Any}())
    for nw_id in keys(ref[:nw])
        var[:nw][nw_id] = Dict{Symbol,Any}()
        con[:nw][nw_id] = Dict{Symbol,Any}()
    end

    cnw = minimum([k for k in keys(ref[:nw])])

    gm = GenericGasModel{Typ}(
        jump_model, # model
        data, # data
        setting, # setting
        Dict{String,Any}(), # solution
        ref,
        var, # vars
        con,
        cnw,
        ext # ext
    )
    return gm
end

### Helper functions for ignoring multinetwork support
ids(gm::GenericGasModel, key::Symbol) = ids(gm, gm.cnw, key)
ids(gm::GenericGasModel, n::Int, key::Symbol) = keys(gm.ref[:nw][n][key])

ref(gm::GenericGasModel, key::Symbol) = ref(gm, gm.cnw, key)
ref(gm::GenericGasModel, key::Symbol, idx) = ref(gm, gm.cnw, key, idx)
ref(gm::GenericGasModel, n::Int, key::Symbol) = gm.ref[:nw][n][key]
ref(gm::GenericGasModel, n::Int, key::Symbol, idx) = gm.ref[:nw][n][key][idx]


var(gm::GenericGasModel, key::Symbol) = var(gm, gm.cnw, key)
var(gm::GenericGasModel, key::Symbol, idx) = var(gm, gm.cnw, key, idx)
var(gm::GenericGasModel, n::Int, key::Symbol) = gm.var[:nw][n][key]
var(gm::GenericGasModel, n::Int, key::Symbol, idx) = gm.var[:nw][n][key][idx]


con(gm::GenericGasModel, key::Symbol) = con(gm, gm.cnw, key)
con(gm::GenericGasModel, key::Symbol, idx) = con(gm, gm.cnw, key, idx)
con(gm::GenericGasModel, n::Int, key::Symbol) = gm.con[:nw][n][key]
con(gm::GenericGasModel, n::Int, key::Symbol, idx) = gm.con[:nw][n][key][idx]

ext(gm::GenericGasModel, key::Symbol) = ext(gm, gm.cnw, key)
ext(gm::GenericGasModel, key::Symbol, idx) = ext(gm, gm.cnw, key, idx)
ext(gm::GenericGasModel, n::Int, key::Symbol) = gm.ext[:nw][n][key]
ext(gm::GenericGasModel, n::Int, key::Symbol, idx) = gm.ext[:nw][n][key][idx]


" Do a solve of the problem "
function optimize!(gm::GenericGasModel, optimizer::JuMP.OptimizerFactory)
    if gm.model.moi_backend.state == MOIU.NO_OPTIMIZER
        _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(gm.model, optimizer)
    else
        @warn "Model already contains optimizer factory, cannot use optimizer specified in `solve_generic_model`"
        _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(gm.model)
    end

    try
        solve_time = MOI.get(gm.model, MOI.SolveTime())
    catch
        warn(LOGGER, "the given optimizer does not provide the SolveTime() attribute, falling back on @timed.  This is not a rigorous timing value.")
    end

    return JuMP.termination_status(gm.model), solve_time
end


""
function run_generic_model(file::String, model_constructor, optimizer, post_method; kwargs...)
    data = GasModels.parse_file(file)
    return run_generic_model(data, model_constructor, optimizer, post_method; kwargs...)
end

""
function run_generic_model(data::Dict{String,Any}, model_constructor, optimizer, post_method; solution_builder = get_solution, kwargs...)
    gm = build_generic_model(data, model_constructor, post_method; kwargs...)
    solution = solve_generic_model(gm, optimizer; solution_builder = solution_builder)
    return solution
end

""
function build_generic_model(file::String,  model_constructor, post_method; kwargs...)
    data = GasModels.parse_file(file)
    return build_generic_model(data, model_constructor, post_method; kwargs...)
end


""
function build_generic_model(data::Dict{String,Any}, model_constructor, post_method; multinetwork=false, kwargs...)
    gm = model_constructor(data; kwargs...)

    if !multinetwork && data["multinetwork"]
        warn(LOGGER,"building a single network model with multinetwork data, only network ($(gm.cnw)) will be used.")
    end

    post_method(gm; kwargs...)
    return gm
end

""
function parse_status(termination_status::MOI.TerminationStatusCode)
    if termination_status == MOI.OPTIMAL
        return :Optimal
    elseif termination_status == MOI.LOCALLY_SOLVED
        return :LocalOptimal
    elseif termination_status == MOI.INFEASIBLE
        return :Infeasible
    elseif termination_status == MOI.LOCALLY_INFEASIBLE
        return :LocalInfeasible
    elseif termination_status == MOI.INFEASIBLE_OR_UNBOUNDED
        return :Infeasible
    else
        return :Error
    end
end

""
function solve_generic_model(gm::GenericGasModel, optimizer::JuMP.OptimizerFactory; solution_builder = get_solution)
    termination_status, solve_time = optimize!(gm, optimizer)
    status = parse_status(termination_status)

    return build_solution(gm, status, solve_time; solution_builder = solution_builder)
end

"""
Returns a dict that stores commonly used pre-computed data from of the data dictionary,
primarily for converting data-types, filtering out deactivated components, and storing
system-wide values that need to be computed globally.

Some of the common keys include:

* `:max_mass_flow` (see `max_mass_flow(data)`),
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
* `:junction_consumers` -- the mapping `Dict(i => [consumer["ql_junc"] for (i,consumer) in ref[:consumer]])`.
* `:junction_producers` -- the mapping `Dict(i => [producer["qg_junc"] for (i,producer) in ref[:producer]])`.
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
    add_default_consumer_priority(data)
    add_default_construction_cost(data)
    add_default_direction(data)

    refs = Dict{Symbol,Any}()
    nws = refs[:nw] = Dict{Int,Any}()

    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)

    for (n,nw_data) in nws_data
        nw_id = parse(Int, n)
        ref = nws[nw_id] = Dict{Symbol,Any}()

        for (key, item) in nw_data
            if isa(item, Dict)
                item_lookup = Dict([(parse(Int, k), v) for (k,v) in item])
                ref[Symbol(key)] = item_lookup
            else
                ref[Symbol(key)] = item
            end
        end

        # filter turned off stuff
        ref[:junction] = Dict(x for x in ref[:junction] if x.second["status"] == 1)
        ref[:consumer] = Dict(x for x in ref[:consumer] if x.second["status"] == 1 && x.second["ql_junc"] in keys(ref[:junction]))
        ref[:producer] = Dict(x for x in ref[:producer] if x.second["status"] == 1 && x.second["qg_junc"] in keys(ref[:junction]))
        ref[:pipe] = haskey(ref, :pipe) ? Dict(x for x in ref[:pipe] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:short_pipe] = haskey(ref, :short_pipe) ? Dict(x for x in ref[:short_pipe] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:compressor] = haskey(ref, :compressor) ? Dict(x for x in ref[:compressor] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:valve] = haskey(ref, :valve) ? Dict(x for x in ref[:valve] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:control_valve] = haskey(ref, :control_valve) ? Dict(x for x in ref[:control_valve] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:resistor] = haskey(ref, :resistor) ? Dict(x for x in ref[:resistor] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_pipe] = haskey(ref, :ne_pipe) ? Dict(x for x in ref[:ne_pipe] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_compressor] = haskey(ref, :ne_compressor) ? Dict(x for x in ref[:ne_compressor] if x.second["status"] == 1 && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()

        # compute the maximum flow
        max_mass_flow = calc_max_mass_flow(data)
        ref[:max_mass_flow] = max_mass_flow

        # create references to all connections in the system
        ref[:connection] =  merge(ref[:pipe],ref[:short_pipe],ref[:compressor],ref[:valve],ref[:control_valve],ref[:resistor])
        ref[:ne_connection] =  merge(ref[:ne_pipe],ref[:ne_compressor])

        # create references to directed and undirected edges
        ref[:directed_pipe] = Dict(x for x in ref[:pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_short_pipe] = Dict(x for x in ref[:short_pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_compressor] = Dict(x for x in ref[:compressor] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_valve] = Dict(x for x in ref[:valve] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_control_valve] = Dict(x for x in ref[:control_valve] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_resistor] = Dict(x for x in ref[:resistor] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_ne_pipe] = Dict(x for x in ref[:ne_pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_ne_compressor] = Dict(x for x in ref[:ne_compressor] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_connection] =  merge(ref[:directed_pipe],ref[:directed_short_pipe],ref[:directed_compressor],ref[:directed_valve],ref[:directed_control_valve],ref[:directed_resistor])
        ref[:directed_ne_connection] =  merge(ref[:directed_ne_pipe],ref[:directed_ne_compressor])

        ref[:undirected_pipe] = Dict(x for x in ref[:pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_short_pipe] = Dict(x for x in ref[:short_pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_compressor] = Dict(x for x in ref[:compressor] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_valve] = Dict(x for x in ref[:valve] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_control_valve] = Dict(x for x in ref[:control_valve] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_resistor] = Dict(x for x in ref[:resistor] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_ne_pipe] = Dict(x for x in ref[:ne_pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_ne_compressor] = Dict(x for x in ref[:ne_compressor] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_connection] =  merge(ref[:undirected_pipe],ref[:undirected_short_pipe],ref[:undirected_compressor],ref[:undirected_valve],ref[:undirected_control_valve],ref[:undirected_resistor])
        ref[:undirected_ne_connection] =  merge(ref[:undirected_ne_pipe],ref[:undirected_ne_compressor])

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

        ref[:parallel_ne_pipes] = Dict()
        for (idx, connection) in ref[:ne_pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_ne_pipes][(min(i,j), max(i,j))] = []
        end

        ref[:junction_connections]    = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:junction_ne_connections] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_connections]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_connections]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_ne_connections]        = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_ne_connections]        = Dict(i => [] for (i,junction) in ref[:junction])

        for (idx, connection) in ref[:connection]
            i = connection["f_junction"]
            j = connection["t_junction"]
            push!(ref[:junction_connections][i], idx)
            push!(ref[:junction_connections][j], idx)
            push!(ref[:parallel_connections][(min(i,j), max(i,j))], idx)
            push!(ref[:all_parallel_connections][(min(i,j), max(i,j))], idx)
            push!(ref[:f_connections][i], idx)
            push!(ref[:t_connections][j], idx)
        end

        for (idx,connection) in ref[:ne_connection]
            i = connection["f_junction"]
            j = connection["t_junction"]
            push!(ref[:junction_ne_connections][i], idx)
            push!(ref[:junction_ne_connections][j], idx)
            push!(ref[:all_parallel_connections][(min(i,j), max(i,j))], idx)
            push!(ref[:f_ne_connections][i], idx)
            push!(ref[:t_ne_connections][j], idx)
        end

        for (idx,connection) in ref[:ne_pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            push!(ref[:parallel_ne_pipes][(min(i,j), max(i,j))], idx)
        end

        junction_consumers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_dispatchable_consumers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_nondispatchable_consumers = Dict([(i, []) for (i,junction) in ref[:junction]])
        for (i,consumer) in ref[:consumer]
            push!(junction_consumers[consumer["ql_junc"]], i)
            if (consumer["dispatchable"] == 1)
                push!(junction_dispatchable_consumers[consumer["ql_junc"]], i)
            else
                push!(junction_nondispatchable_consumers[consumer["ql_junc"]], i)
            end
        end
        ref[:junction_consumers] = junction_consumers
        ref[:junction_dispatchable_consumers] = junction_dispatchable_consumers
        ref[:junction_nondispatchable_consumers] = junction_nondispatchable_consumers

        junction_producers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_dispatchable_producers = Dict([(i, []) for (i,junction) in ref[:junction]])
        junction_nondispatchable_producers = Dict([(i, []) for (i,junction) in ref[:junction]])
        for (i,producer) in ref[:producer]
            push!(junction_producers[producer["qg_junc"]], i)
            if (producer["dispatchable"] == 1)
                push!(junction_dispatchable_producers[producer["qg_junc"]], i)
            else
                push!(junction_nondispatchable_producers[producer["qg_junc"]], i)
            end
        end
        ref[:junction_producers] = junction_producers
        ref[:junction_dispatchable_producers] = junction_dispatchable_producers
        ref[:junction_nondispatchable_producers] = junction_nondispatchable_producers

        add_degree(ref)
        add_pd_bounds_sqr(ref)
    end
    return refs
end

"Just make sure there is an empty set for new connections if it does not exist"
function add_default_data(data :: Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)

    for (n,data) in nws_data
        if !haskey(data, "ne_pipe")
            data["ne_pipe"] = []
        end
        if !haskey(data, "ne_compressor")
            data["ne_compressor"] = []
        end
        if !haskey(data, "compressor")
            data["compressor"] = []
        end
        if !haskey(data, "pipe")
            data["pipe"] = []
        end
        if !haskey(data, "short_pipe")
            data["short_pipe"] = []
        end
        if !haskey(data, "resistor")
            data["resistor"] = []
        end
        if !haskey(data, "valve")
            data["valve"] = []
        end
        if !haskey(data, "control_valve")
            data["control_valve"] = []
        end
    end
end
