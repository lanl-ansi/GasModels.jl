# stuff that is universal to all gas models

"root of the gas formulation hierarchy"
abstract type AbstractGasModel end


"a macro for adding the base GasModels fields to a type definition"
InfrastructureModels.@def gm_fields begin
    model::JuMP.AbstractModel

    data::Dict{String,<:Any}
    setting::Dict{String,<:Any}
    solution::Dict{String,<:Any}

    ref::Dict{Symbol,<:Any}
    var::Dict{Symbol,<:Any}
    con::Dict{Symbol,<:Any}
    cnw::Int

    # Extension dictionary
    # Extensions should define a type to hold information particular to
    # their functionality, and store an instance of the type in this
    # dictionary keyed on an extension-specific symbol
    ext::Dict{Symbol,<:Any}
end


"default generic constructor"
function InitializeGasModel(GasModel::Type, data::Dict{String,<:Any}; ext=Dict{Symbol,Any}(), setting=Dict{String,Any}(), jump_model::JuMP.Model=JuMP.Model(), kwargs...)
    @assert GasModel <: AbstractGasModel

    ref = InfrastructureModels.ref_initialize(data)  # reference data

    var = Dict{Symbol,Any}(:nw => Dict{Int,Any}())
    con = Dict{Symbol,Any}(:nw => Dict{Int,Any}())
    for nw_id in keys(ref[:nw])
        var[:nw][nw_id] = Dict{Symbol,Any}()
        con[:nw][nw_id] = Dict{Symbol,Any}()
    end

    cnw = minimum([k for k in keys(ref[:nw])])

    gm = GasModel(
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
ids(gm::AbstractGasModel, key::Symbol) = ids(gm, gm.cnw, key)
ids(gm::AbstractGasModel, n::Int, key::Symbol) = keys(gm.ref[:nw][n][key])

ref(gm::AbstractGasModel, key::Symbol) = ref(gm, gm.cnw, key)
ref(gm::AbstractGasModel, key::Symbol, idx) = ref(gm, gm.cnw, key, idx)
ref(gm::AbstractGasModel, n::Int, key::Symbol) = gm.ref[:nw][n][key]
ref(gm::AbstractGasModel, n::Int, key::Symbol, idx) = gm.ref[:nw][n][key][idx]

var(gm::AbstractGasModel, key::Symbol) = var(gm, gm.cnw, key)
var(gm::AbstractGasModel, key::Symbol, idx) = var(gm, gm.cnw, key, idx)
var(gm::AbstractGasModel, n::Int, key::Symbol) = gm.var[:nw][n][key]
var(gm::AbstractGasModel, n::Int, key::Symbol, idx) = gm.var[:nw][n][key][idx]


con(gm::AbstractGasModel, key::Symbol) = con(gm, gm.cnw, key)
con(gm::AbstractGasModel, key::Symbol, idx) = con(gm, gm.cnw, key, idx)
con(gm::AbstractGasModel, n::Int, key::Symbol) = gm.con[:nw][n][key]
con(gm::AbstractGasModel, n::Int, key::Symbol, idx) = gm.con[:nw][n][key][idx]

ext(gm::AbstractGasModel, key::Symbol) = ext(gm, gm.cnw, key)
ext(gm::AbstractGasModel, key::Symbol, idx) = ext(gm, gm.cnw, key, idx)
ext(gm::AbstractGasModel, n::Int, key::Symbol) = gm.ext[:nw][n][key]
ext(gm::AbstractGasModel, n::Int, key::Symbol, idx) = gm.ext[:nw][n][key][idx]


"Do a solve of the problem"
function JuMP.optimize!(gm::AbstractGasModel, optimizer::JuMP.OptimizerFactory)
    if gm.model.moi_backend.state == MOIU.NO_OPTIMIZER
        _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(gm.model, optimizer)
    else
        Memento.warn(_LOGGER, "Model already contains optimizer factory, cannot use optimizer specified in `optimize_model!`")
        _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(gm.model)
    end

    try
        solve_time = MOI.get(gm.model, MOI.SolveTime())
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the SolveTime() attribute, falling back on @timed.  This is not a rigorous timing value.")
    end

    return solve_time
end


""
function run_model(file::String, model_type, optimizer, post_method; kwargs...)
    data = GasModels.parse_file(file)
    return run_model(data, model_type, optimizer, post_method; kwargs...)
end


""
function run_model(data::Dict{String,<:Any}, model_type, optimizer, post_method; ref_extensions=[], solution_builder=solution_gf!, kwargs...)
    gm = build_model(data, model_type, post_method; kwargs...)
    solution = optimize_model!(gm, optimizer; solution_builder = solution_builder)
    return solution
end


""
function build_model(file::String,  model_type, post_method; kwargs...)
    data = GasModels.parse_file(file)
    return build_model(data, model_type, post_method; kwargs...)
end


""
function build_model(data::Dict{String,<:Any}, model_type::Type, post_method; ref_extensions=[], multinetwork=false, kwargs...)
    gm = InitializeGasModel(model_type, data; kwargs...)

    if !multinetwork && data["multinetwork"]
        Memento.warn(_LOGGER,"building a single network model with multinetwork data, only network ($(gm.cnw)) will be used.")
    end

    ref_add_core!(gm)
    for ref_ext in ref_extensions
        ref_ext(gm)
    end

    post_method(gm; kwargs...)

    return gm
end


""
function optimize_model!(gm::AbstractGasModel, optimizer::JuMP.OptimizerFactory; solution_builder=solution_gf!)
    solve_time = JuMP.optimize!(gm, optimizer)

    result = build_solution(gm, solve_time; solution_builder=solution_builder)

    gm.solution = result["solution"]

    return result
end


"used for building ref without the need to build a initialize an AbstractPowerModel"
function build_ref(data::Dict{String,<:Any}; ref_extensions=[])
    ref = InfrastructureModels.ref_initialize(data)
    _ref_add_core!(ref[:nw])
    for ref_ext in ref_extensions
        ref_ext(gm)
    end

    return ref
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
* `:degree` -- the degree of junction i using existing connections (see `ref_degree!`)),
* `degree_ne` -- the degree of junction i using existing and new connections (see `ref_degree_ne!`)),
* `:pd_min,:pd_max` -- the max and min square pressure difference (see `_calc_pd_bounds_sqr`)),
"""
function ref_add_core!(gm::AbstractGasModel)
    _ref_add_core!(gm.ref[:nw])
end


function _ref_add_core!(nw_refs::Dict)
    for (nw,ref) in nw_refs
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
        max_mass_flow = _calc_max_mass_flow(ref)
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

        ref_degree!(ref)
        ref_degree_ne!(ref)

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
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:pipe_ref][idx][:pd_min] = pd_min
            ref[:pipe_ref][idx][:pd_max] = pd_max
            ref[:pipe_ref][idx][:w] = _calc_pipe_resistance_thorley(ref, pipe)
            ref[:pipe_ref][idx][:f_min] = _calc_pipe_fmin(ref, idx)
            ref[:pipe_ref][idx][:f_max] = _calc_pipe_fmax(ref, idx)

            push!(ref[:f_pipes][i], idx)
            push!(ref[:t_pipes][j], idx)
            push!(ref[:parallel_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,pipe) in ref[:ne_pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:ne_pipe_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:ne_pipe_ref][idx][:pd_min] = pd_min
            ref[:ne_pipe_ref][idx][:pd_max] = pd_max
            ref[:ne_pipe_ref][idx][:w] = _calc_pipe_resistance_thorley(ref, pipe)
            ref[:ne_pipe_ref][idx][:f_min] = _calc_ne_pipe_fmin(ref, idx)
            ref[:ne_pipe_ref][idx][:f_max] = _calc_ne_pipe_fmax(ref, idx)
            push!(ref[:f_ne_pipes][i], idx)
            push!(ref[:t_ne_pipes][j], idx)
            push!(ref[:parallel_ne_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,compressor) in ref[:compressor]
            i = compressor["f_junction"]
            j = compressor["t_junction"]
            ref[:compressor_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, compressor["f_junction"], compressor["t_junction"])
            ref[:compressor_ref][idx][:pd_min] = pd_min
            ref[:compressor_ref][idx][:pd_max] = pd_max
            ref[:compressor_ref][idx][:f_min] = _calc_compressor_fmin(ref, idx)
            ref[:compressor_ref][idx][:f_max] = _calc_compressor_fmax(ref, idx)
            push!(ref[:f_compressors][i], idx)
            push!(ref[:t_compressors][j], idx)
            push!(ref[:parallel_compressors][(min(i,j), max(i,j))], idx)
        end

        for (idx,compressor) in ref[:ne_compressor]
            i = compressor["f_junction"]
            j = compressor["t_junction"]
            ref[:ne_compressor_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, compressor["f_junction"], compressor["t_junction"])
            ref[:ne_compressor_ref][idx][:pd_min] = pd_min
            ref[:ne_compressor_ref][idx][:pd_max] = pd_max
            ref[:ne_compressor_ref][idx][:f_min] = _calc_ne_compressor_fmin(ref, idx)
            ref[:ne_compressor_ref][idx][:f_max] = _calc_ne_compressor_fmax(ref, idx)
            push!(ref[:f_ne_compressors][i], idx)
            push!(ref[:t_ne_compressors][j], idx)
            push!(ref[:parallel_ne_compressors][(min(i,j), max(i,j))], idx)
        end

        for (idx,pipe) in ref[:short_pipe]
            i = pipe["f_junction"]
            j = pipe["t_junction"]
            ref[:short_pipe_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, pipe["f_junction"], pipe["t_junction"])
            ref[:short_pipe_ref][idx][:pd_min] = pd_min
            ref[:short_pipe_ref][idx][:pd_max] = pd_max
            ref[:short_pipe_ref][idx][:f_min] = _calc_short_pipe_fmin(ref, idx)
            ref[:short_pipe_ref][idx][:f_max] = _calc_short_pipe_fmax(ref, idx)
            push!(ref[:f_short_pipes][i], idx)
            push!(ref[:t_short_pipes][j], idx)
            push!(ref[:parallel_short_pipes][(min(i,j), max(i,j))], idx)
        end

        for (idx,resistor) in ref[:resistor]
            i = resistor["f_junction"]
            j = resistor["t_junction"]
            ref[:resistor_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, resistor["f_junction"], resistor["t_junction"])
            ref[:resistor_ref][idx][:pd_min] = pd_min
            ref[:resistor_ref][idx][:pd_max] = pd_max
            ref[:resistor_ref][idx][:w] = _calc_resistor_resistance_simple(ref, resistor)
            ref[:resistor_ref][idx][:f_min] = _calc_resistor_fmin(ref, idx)
            ref[:resistor_ref][idx][:f_max] = _calc_resistor_fmax(ref, idx)
            push!(ref[:f_resistors][i], idx)
            push!(ref[:t_resistors][j], idx)
            push!(ref[:parallel_resistors][(min(i,j), max(i,j))], idx)
        end

        for (idx,valve) in ref[:valve]
            i = valve["f_junction"]
            j = valve["t_junction"]
            ref[:valve_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, valve["f_junction"], valve["t_junction"])
            ref[:valve_ref][idx][:pd_min] = pd_min
            ref[:valve_ref][idx][:pd_max] = pd_max
            ref[:valve_ref][idx][:f_min] = _calc_valve_fmin(ref, idx)
            ref[:valve_ref][idx][:f_max] = _calc_valve_fmax(ref, idx)
            push!(ref[:f_valves][i], idx)
            push!(ref[:t_valves][j], idx)
            push!(ref[:parallel_valves][(min(i,j), max(i,j))], idx)
        end

        for (idx,valve) in ref[:control_valve]
            i = valve["f_junction"]
            j = valve["t_junction"]
            ref[:control_valve_ref][idx] = Dict()
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, valve["f_junction"], valve["t_junction"])
            ref[:control_valve_ref][idx][:pd_min] = pd_min
            ref[:control_valve_ref][idx][:pd_max] = pd_max
            ref[:control_valve_ref][idx][:f_min] = _calc_control_valve_fmin(ref, idx)
            ref[:control_valve_ref][idx][:f_max] = _calc_control_valve_fmax(ref, idx)
            push!(ref[:f_control_valves][i], idx)
            push!(ref[:t_control_valves][j], idx)
            push!(ref[:parallel_control_valves][(min(i,j), max(i,j))], idx)
        end
    end
end


"Add reference information for the degree of junction"
function ref_degree!(ref::Dict{Symbol,Any})
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
function ref_degree_ne!(ref::Dict{Symbol,Any})
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
