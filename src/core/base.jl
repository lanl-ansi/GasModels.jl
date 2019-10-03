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
function parse_status(termination_status::MOI.TerminationStatusCode, primal_status::MOI.ResultStatusCode)
    if termination_status == MOI.OPTIMAL
        return :Optimal
    elseif termination_status == MOI.LOCALLY_SOLVED
        return :LocalOptimal
    elseif termination_status == MOI.TIME_LIMIT
        return primal_status == MOI.NO_SOLUTION ? :LocalInfeasible : :LocalOptimal
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
    primal_status = MOI.get(gm.model, MOI.PrimalStatus())
    status = parse_status(termination_status, primal_status)

    return build_solution(gm, status, solve_time; solution_builder = solution_builder)
end

"""
Returns a dict that stores commonly used pre-computed data from of the data dictionary,
primarily for converting data-types, filtering out deactivated components, and storing
system-wide values that need to be computed globally.

Some of the common keys include:

* `:max_mass_flow` (see `max_mass_flow(data)`),
* `:pipe` -- the set of connections that are pipes (based on the component type values),
* `:short_pipe` -- the set of connections that are short pipes (based on the component type values),
* `:compressor` -- the set of connections that are compressors (based on the component type values),
* `:valve` -- the set of connections that are valves (based on the component type values),
* `:control_valve` -- the set of connections that are control valves (based on the component type values),
* `:resistor` -- the set of connections that are resistors (based on the component type values),
* `:junction_consumers` -- the mapping `Dict(i => [consumer["ql_junc"] for (i,consumer) in ref[:consumer]])`.
* `:junction_producers` -- the mapping `Dict(i => [producer["qg_junc"] for (i,producer) in ref[:producer]])`.
* `:degree` -- the degree of junction i using existing connections (see `degree_ref!`)),
* `degree_ne` -- the degree of junction i using existing and new connections (see `degree_ne_ref!`)),
* `:pd_min,:pd_max` -- the max and min square pressure difference (see `calc_pd_bounds_sqr`)),
"""
function build_ref(data::Dict{String,Any})
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
        ref[:junction]      =                               Dict(x for x in ref[:junction]      if  !haskey(x.second,"status") || x.second["status"] == 1)
        ref[:consumer]      =                               Dict(x for x in ref[:consumer]      if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["ql_junc"]    in keys(ref[:junction]))
        ref[:producer]      =                               Dict(x for x in ref[:producer]      if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["qg_junc"]    in keys(ref[:junction]))
        ref[:pipe]          = haskey(ref, :pipe)          ? Dict(x for x in ref[:pipe]          if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:short_pipe]    = haskey(ref, :short_pipe)    ? Dict(x for x in ref[:short_pipe]    if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:compressor]    = haskey(ref, :compressor)    ? Dict(x for x in ref[:compressor]    if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:valve]         = haskey(ref, :valve)         ? Dict(x for x in ref[:valve]         if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:control_valve] = haskey(ref, :control_valve) ? Dict(x for x in ref[:control_valve] if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:resistor]      = haskey(ref, :resistor)      ? Dict(x for x in ref[:resistor]      if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_pipe]       = haskey(ref, :ne_pipe)       ? Dict(x for x in ref[:ne_pipe]       if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()
        ref[:ne_compressor] = haskey(ref, :ne_compressor) ? Dict(x for x in ref[:ne_compressor] if (!haskey(x.second,"status") || x.second["status"] == 1) && x.second["f_junction"] in keys(ref[:junction]) && x.second["t_junction"] in keys(ref[:junction])) : Dict()

        # compute the maximum flow
        max_mass_flow = calc_max_mass_flow(data)
        ref[:max_mass_flow] = max_mass_flow

        # create references to directed and undirected edges
        ref[:directed_pipe]          = Dict(x for x in ref[:pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_short_pipe]    = Dict(x for x in ref[:short_pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_compressor]    = Dict(x for x in ref[:compressor] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_valve]         = Dict(x for x in ref[:valve] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_control_valve] = Dict(x for x in ref[:control_valve] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_resistor]      = Dict(x for x in ref[:resistor] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_ne_pipe]       = Dict(x for x in ref[:ne_pipe] if haskey(x.second, "directed") && x.second["directed"] != 0)
        ref[:directed_ne_compressor] = Dict(x for x in ref[:ne_compressor] if haskey(x.second, "directed") && x.second["directed"] != 0)

        ref[:undirected_pipe]          = Dict(x for x in ref[:pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_short_pipe]    = Dict(x for x in ref[:short_pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_compressor]    = Dict(x for x in ref[:compressor] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_valve]         = Dict(x for x in ref[:valve] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_control_valve] = Dict(x for x in ref[:control_valve] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_resistor]      = Dict(x for x in ref[:resistor] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_ne_pipe]       = Dict(x for x in ref[:ne_pipe] if !haskey(x.second, "directed") || x.second["directed"] == 0)
        ref[:undirected_ne_compressor] = Dict(x for x in ref[:ne_compressor] if !haskey(x.second, "directed") || x.second["directed"] == 0)

        ref[:dispatch_consumer]        = Dict(x for x in ref[:consumer] if (x.second["dispatchable"] == 1))
        ref[:dispatch_producer]        = Dict(x for x in ref[:producer] if (x.second["dispatchable"] == 1))

        ref[:parallel_pipes] = Dict()
        for (idx, connection) in ref[:pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_pipes][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_compressors] = Dict()
        for (idx, connection) in ref[:compressor]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_compressors][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_resistors] = Dict()
        for (idx, connection) in ref[:resistor]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_resistors][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_short_pipes] = Dict()
        for (idx, connection) in ref[:short_pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_short_pipes][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_valves] = Dict()
        for (idx, connection) in ref[:valve]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_valves][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_control_valves] = Dict()
        for (idx, connection) in ref[:control_valve]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_control_valves][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_ne_pipes] = Dict()
        for (idx, connection) in ref[:ne_pipe]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_ne_pipes][(min(i,j), max(i,j))] = []
        end

        ref[:parallel_ne_compressors] = Dict()
        for (idx, connection) in ref[:ne_compressor]
            i = connection["f_junction"]
            j = connection["t_junction"]
            ref[:parallel_ne_compressors][(min(i,j), max(i,j))] = []
        end

        ref[:t_pipes]                 = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_pipes]                 = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_compressors]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_compressors]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_resistors]             = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_resistors]             = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_short_pipes]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_short_pipes]           = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_valves]                = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_valves]                = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_control_valves]        = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_control_valves]        = Dict(i => [] for (i,junction) in ref[:junction])

        ref[:t_ne_pipes]              = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_ne_pipes]              = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:t_ne_compressors]        = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:f_ne_compressors]        = Dict(i => [] for (i,junction) in ref[:junction])

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

        degree_ref!(ref)
        degree_ne_ref!(ref)

        ref[:pipe_ref]           = Dict()
        ref[:ne_pipe_ref]        = Dict()
        ref[:compressor_ref]     = Dict()
        ref[:ne_compressor_ref]  = Dict()
        ref[:junction_ref]       = Dict()
        ref[:short_pipe_ref]     = Dict()
        ref[:resistor_ref]       = Dict()
        ref[:valve_ref]          = Dict()
        ref[:control_valve_ref]  = Dict()

        for (idx,pipe) in ref[:pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:pipe_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:pipe_ref][idx][:pd_min] = pd_min
            ref[:pipe_ref][idx][:pd_max] = pd_max
            ref[:pipe_ref][idx][:w] = calc_pipe_resistance_thorley(ref, pipe)
            ref[:pipe_ref][idx][:f_min] = calc_pipe_fmin(ref, idx)
            ref[:pipe_ref][idx][:f_max] = calc_pipe_fmax(ref, idx)

            push!(ref[:f_pipes][i], idx)
            push!(ref[:t_pipes][j], idx)
            push!(ref[:parallel_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,pipe) in ref[:ne_pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:ne_pipe_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:ne_pipe_ref][idx][:pd_min] = pd_min
            ref[:ne_pipe_ref][idx][:pd_max] = pd_max
            ref[:ne_pipe_ref][idx][:w] = calc_pipe_resistance_thorley(ref, pipe)
            ref[:ne_pipe_ref][idx][:f_min] = calc_ne_pipe_fmin(ref, idx)
            ref[:ne_pipe_ref][idx][:f_max] = calc_ne_pipe_fmax(ref, idx)
            push!(ref[:f_ne_pipes][i], idx)
            push!(ref[:t_ne_pipes][j], idx)
            push!(ref[:parallel_ne_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,compressor) in ref[:compressor]
            i = compressor["f_junction"]
            j = compressor["t_junction"]
            ref[:compressor_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, compressor["f_junction"], compressor["t_junction"])
            ref[:compressor_ref][idx][:pd_min] = pd_min
            ref[:compressor_ref][idx][:pd_max] = pd_max
            ref[:compressor_ref][idx][:f_min] = calc_compressor_fmin(ref, idx)
            ref[:compressor_ref][idx][:f_max] = calc_compressor_fmax(ref, idx)
            push!(ref[:f_compressors][i], idx)
            push!(ref[:t_compressors][j], idx)
            push!(ref[:parallel_compressors][(min(i,j), max(i,j))], idx)
        end

        for (idx,compressor) in ref[:ne_compressor]
            i = compressor["f_junction"]
            j = compressor["t_junction"]
            ref[:ne_compressor_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, compressor["f_junction"], compressor["t_junction"])
            ref[:ne_compressor_ref][idx][:pd_min] = pd_min
            ref[:ne_compressor_ref][idx][:pd_max] = pd_max
            ref[:ne_compressor_ref][idx][:f_min] = calc_ne_compressor_fmin(ref, idx)
            ref[:ne_compressor_ref][idx][:f_max] = calc_ne_compressor_fmax(ref, idx)
            push!(ref[:f_ne_compressors][i], idx)
            push!(ref[:t_ne_compressors][j], idx)
            push!(ref[:parallel_ne_compressors][(min(i,j), max(i,j))], idx)
        end

        for (idx,pipe) in ref[:short_pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:short_pipe_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:short_pipe_ref][idx][:pd_min] = pd_min
            ref[:short_pipe_ref][idx][:pd_max] = pd_max
            ref[:short_pipe_ref][idx][:f_min] = calc_short_pipe_fmin(ref, idx)
            ref[:short_pipe_ref][idx][:f_max] = calc_short_pipe_fmax(ref, idx)
            push!(ref[:f_short_pipes][i], idx)
            push!(ref[:t_short_pipes][j], idx)
            push!(ref[:parallel_short_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,resistor) in ref[:resistor]
            i = resistor["f_junction"]
            j = resistor["t_junction"]
            ref[:resistor_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, resistor["f_junction"], resistor["t_junction"])
            ref[:resistor_ref][idx][:pd_min] = pd_min
            ref[:resistor_ref][idx][:pd_max] = pd_max
            ref[:resistor_ref][idx][:w] = calc_resistor_resistance_simple(ref, resistor)
            ref[:resistor_ref][idx][:f_min] = calc_resistor_fmin(ref, idx)
            ref[:resistor_ref][idx][:f_max] = calc_resistor_fmax(ref, idx)
            push!(ref[:f_resistors][i], idx)
            push!(ref[:t_resistors][j], idx)
            push!(ref[:parallel_resistors][(min(i,j), max(i,j))], idx)
        end

        for (idx,valve) in ref[:valve]
            i = valve["f_junction"]
            j = valve["t_junction"]
            ref[:valve_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, valve["f_junction"], valve["t_junction"])
            ref[:valve_ref][idx][:pd_min] = pd_min
            ref[:valve_ref][idx][:pd_max] = pd_max
            ref[:valve_ref][idx][:f_min] = calc_valve_fmin(ref, idx)
            ref[:valve_ref][idx][:f_max] = calc_valve_fmax(ref, idx)
            push!(ref[:f_valves][i], idx)
            push!(ref[:t_valves][j], idx)
            push!(ref[:parallel_valves][(min(i,j), max(i,j))], idx)
        end

        for (idx,valve) in ref[:control_valve]
            i = valve["f_junction"]
            j = valve["t_junction"]
            ref[:control_valve_ref][idx] = Dict()
            pd_min, pd_max = calc_pd_bounds_sqr(ref, valve["f_junction"], valve["t_junction"])
            ref[:control_valve_ref][idx][:pd_min] = pd_min
            ref[:control_valve_ref][idx][:pd_max] = pd_max
            ref[:control_valve_ref][idx][:f_min] = calc_control_valve_fmin(ref, idx)
            ref[:control_valve_ref][idx][:f_max] = calc_control_valve_fmax(ref, idx)
            push!(ref[:f_control_valves][i], idx)
            push!(ref[:t_control_valves][j], idx)
            push!(ref[:parallel_control_valves][(min(i,j), max(i,j))], idx)
        end
    end
    return refs
end

"Add reference information for the degree of junction"
function degree_ref!(ref::Dict{Symbol,Any})
    ref[:degree] = Dict()
    for (i,junction) in ref[:junction]
        ref[:degree][i] = 0
    end

    connections = Set()
    for (i,j) in keys(ref[:parallel_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_compressors]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_resistors]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_short_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_valves]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_control_valves]) push!(connections, (i,j)) end

    for (i,j) in connections
            ref[:degree][i] = ref[:degree][i] + 1
            ref[:degree][j] = ref[:degree][j] + 1
#        end
    end
end

"Add reference information for the degree of junction with expansion edges"
function degree_ne_ref!(ref::Dict{Symbol,Any})
    ref[:degree_ne] = Dict()
    for (i,junction) in ref[:junction]
        ref[:degree_ne][i] = 0
    end

    connections = Set()
    for (i,j) in keys(ref[:parallel_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_compressors]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_resistors]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_short_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_valves]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_control_valves]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_ne_pipes]) push!(connections, (i,j)) end
    for (i,j) in keys(ref[:parallel_ne_compressors]) push!(connections, (i,j)) end

    for (i,j) in connections
        ref[:degree_ne][i] = ref[:degree_ne][i] + 1
        ref[:degree_ne][j] = ref[:degree_ne][j] + 1
    end
end
