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
function InitializeGasModel(GasModel::Type, data::Dict{String,<:Any}; ext=Dict{Symbol,Any}(), setting=Dict{String,Any}(), jump_model::JuMP.AbstractModel=JuMP.Model(), kwargs...)
    @assert GasModel <: AbstractGasModel

    ref = InfrastructureModels.ref_initialize(data, _gm_global_keys)  # reference data

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

### Helper functions for working with multinetworks and multiconductors
ismultinetwork(gm::AbstractGasModel) = (length(gm.ref[:nw]) > 1)
nw_ids(gm::AbstractGasModel) = keys(gm.ref[:nw])
nws(gm::AbstractGasModel) = gm.ref[:nw]

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

""
function run_model(file::String, model_type, optimizer, build_method; kwargs...)
    data = GasModels.parse_file(file)
    return run_model(data, model_type, optimizer, build_method; kwargs...)
end

""
function run_model(data::Dict{String,<:Any}, model_type, optimizer, build_method; ref_extensions=[], solution_builder=solution_gf!, kwargs...)
    gm = instantiate_model(data, model_type, build_method; ref_extensions=ref_extensions, kwargs...)
    result = optimize_model!(gm, optimizer=optimizer; solution_builder = solution_builder)
    return result
end

""
function instantiate_model(file::String,  model_type, build_method; kwargs...)
    data = GasModels.parse_file(file)
    return instantiate_model(data, model_type, build_method; kwargs...)
end

""
function instantiate_model(data::Dict{String,<:Any}, model_type, build_method; ref_extensions=[], multinetwork=false, kwargs...)
    gm = InitializeGasModel(model_type, data; kwargs...)

    if !multinetwork && data["multinetwork"]
        Memento.warn(_LOGGER,"building a single network model with multinetwork data, only network ($(gm.cnw)) will be used.")
    end

    ref_add_core!(gm)
    for ref_ext in ref_extensions
        ref_ext(gm)
    end

    build_method(gm; kwargs...)

    return gm
end

""
function optimize_model!(gm::AbstractGasModel; optimizer::Union{JuMP.OptimizerFactory,Nothing}=nothing, solution_builder=solution_gf!)
    if optimizer === nothing
        if gm.model.moi_backend.state == MOIU.NO_OPTIMIZER
            Memento.error(_LOGGER, "no optimizer specified in `optimize_model!` or the given JuMP model.")
        else
            _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(gm.model)
        end
    else
        if gm.model.moi_backend.state == MOIU.NO_OPTIMIZER
            _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(gm.model, optimizer)
        else
            Memento.warn(_LOGGER, "Model already contains optimizer factory, cannot use optimizer specified in `optimize_model!`")
            _, solve_time, solve_bytes_alloc, sec_in_gc = @timed JuMP.optimize!(gm.model)
        end
    end

    try
        solve_time = MOI.get(gm.model, MOI.SolveTime())
    catch
        Memento.warn(_LOGGER, "the given optimizer does not provide the SolveTime() attribute, falling back on @timed.  This is not a rigorous timing value.")
    end

    result = build_solution(gm, solve_time; solution_builder=solution_builder)
    gm.solution = result["solution"]
    return result
end


"used for building ref without the need to build a initialize an AbstractGasModel"
function build_ref(data::Dict{String,<:Any}; ref_extensions=[])
    ref = InfrastructureModels.ref_initialize(data, _gm_global_keys)
    _ref_add_core!(ref[:nw], base_length=data["base_length"])
    # for ref_ext in ref_extensions
    #     ref_ext(gm)
    # end

    return ref
end


"""
Returns a dict that stores commonly used pre-computed data from of the data dictionary,
primarily for converting data-types, filtering out deactivated components, and storing
system-wide values that need to be computed globally.

Some of the common keys include:

* `:max_mass_flow` (see `max_mass_flow(data)`),
* `:junction` -- the set of junctions in the system,
* `:pipe` -- the set of pipes in the system,
* `:compressor` -- the set of compressors in the system,
* `:short_pipe` -- the set of short pipe in the system,
* `:resistor` -- the set of resistors in the system,
* `:transfer` -- the set of transfer points in the system,
* `:receipt` -- the set of receipt points in the system,
* `:delivery` -- the set of delivery points in the system,
* `:regulatpr` -- the set of pressure-reducing valves in the system,
* `:valve` -- the set of valves in the system,
* `:storage` -- the set of storages in the system,
* `:degree` -- the degree of junction i using existing connections (see `ref_degree!`)),
* `"pd_min","pd_max"` -- the max and min square pressure difference (see `_calc_pd_bounds_sqr`)),
"""
function ref_add_core!(gm::AbstractGasModel)
    _ref_add_core!(gm.ref[:nw], base_length=gm.ref[:base_length])
end

function _ref_add_core!(nw_refs::Dict; base_length=5000.0)
    for (nw, ref) in nw_refs
        ref[:junction] = haskey(ref, :junction) ? Dict(x for x in ref[:junction] if x.second["status"] == 1) : Dict()
        ref[:pipe] = haskey(ref, :pipe) ? Dict(x for x in ref[:pipe] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:compressor] = haskey(ref, :compressor) ? Dict(x for x in ref[:compressor] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:short_pipe] = haskey(ref, :short_pipe) ? Dict(x for x in ref[:short_pipe] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:resistor] = haskey(ref, :resistor) ? Dict(x for x in ref[:resistor] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:transfer] = haskey(ref, :transfer) ? Dict(x for x in ref[:transfer] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()
        ref[:receipt] = haskey(ref, :receipt) ? Dict(x for x in ref[:receipt] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()
        ref[:delivery] = haskey(ref, :delivery) ? Dict(x for x in ref[:delivery] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()
        ref[:regulator] = haskey(ref, :regulator) ? Dict(x for x in ref[:regulator] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:valve] = haskey(ref, :valve) ? Dict(x for x in ref[:valve] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:storage] = haskey(ref, :storage) ? Dict(x for x in ref[:storage] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()

        # compute the maximum flow
        ref[:max_mass_flow] = _calc_max_mass_flow(ref)

        # create references to directed and undirected edges
        ref[:directed_pipe] = Dict(x for x in ref[:pipe] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] != 0)
        ref[:directed_short_pipe] = Dict(x for x in ref[:short_pipe] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] != 0)
        ref[:directed_resistor] = Dict(x for x in ref[:resistor] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] != 0)
        ref[:directed_regulator] = Dict(x for x in ref[:regulator] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] != 0)

        ref[:undirected_pipe] = Dict(x for x in ref[:pipe] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] == 0)
        ref[:undirected_short_pipe] = Dict(x for x in ref[:short_pipe] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] == 0)
        ref[:undirected_resistor] = Dict(x for x in ref[:resistor] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] == 0)
        ref[:undirected_regulator] = Dict(x for x in ref[:regulator] if haskey(x.second, "is_bidirectional") && x.second["is_bidirectional"] == 0)

        # compressor types
        # default allows compression with uncompressed flow reversals
        ref[:default_compressor] = Dict(x for x in ref[:compressor] if haskey(x.second, "directionality") && x.second["directionality"] == 2)
        ref[:bidirectional_compressor] = Dict(x for x in ref[:compressor] if haskey(x.second, "directionality") && x.second["directionality"] == 0)
        ref[:unidirectional_compressor] = Dict(x for x in ref[:compressor] if haskey(x.second, "directionality") && x.second["directionality"] == 1)


        # dispatchable tranfers, receipts, and deliveries
        ref[:dispatchable_transfer] = Dict(x for x in ref[:transfer] if x.second["is_dispatchable"] == 1)
        ref[:dispatchable_receipt] = Dict(x for x in ref[:receipt] if x.second["is_dispatchable"] == 1)
        ref[:dispatchable_delivery] = Dict(x for x in ref[:delivery] if x.second["is_dispatchable"] == 1)
        ref[:nondispatchable_transfer] = Dict(x for x in ref[:transfer] if x.second["is_dispatchable"] == 0)
        ref[:nondispatchable_receipt] = Dict(x for x in ref[:receipt] if x.second["is_dispatchable"] == 0)
        ref[:nondispatchable_delivery] = Dict(x for x in ref[:delivery] if x.second["is_dispatchable"] == 0)

        # transfers, receipts, deliveries and storages in junction
        ref[:dispatchable_transfers_in_junction] = Dict([(i, []) for (i,junction) in ref[:junction]])
        ref[:dispatchable_receipts_in_junction] = Dict([(i, []) for (i,junction) in ref[:junction]])
        ref[:dispatchable_deliveries_in_junction] = Dict([(i, []) for (i,junction) in ref[:junction]])
        ref[:nondispatchable_transfers_in_junction] = Dict([(i, []) for (i,junction) in ref[:junction]])
        ref[:nondispatchable_receipts_in_junction] = Dict([(i, []) for (i,junction) in ref[:junction]])
        ref[:nondispatchable_deliveries_in_junction] = Dict([(i, []) for (i,junction) in ref[:junction]])
        ref[:storages_in_junction] = Dict([(i, []) for (i,junction) in ref[:junction]])

        _add_junction_map!(ref[:dispatchable_transfers_in_junction], ref[:dispatchable_transfer])
        _add_junction_map!(ref[:nondispatchable_transfers_in_junction], ref[:nondispatchable_transfer])
        _add_junction_map!(ref[:dispatchable_receipts_in_junction], ref[:dispatchable_receipt])
        _add_junction_map!(ref[:nondispatchable_receipts_in_junction], ref[:nondispatchable_receipt])
        _add_junction_map!(ref[:dispatchable_deliveries_in_junction], ref[:dispatchable_delivery])
        _add_junction_map!(ref[:nondispatchable_deliveries_in_junction], ref[:nondispatchable_delivery])
        _add_junction_map!(ref[:storages_in_junction], ref[:storage])

        ref[:parallel_pipes] = Dict()
        ref[:parallel_compressors] = Dict()
        ref[:parallel_short_pipes] = Dict()
        ref[:parallel_resistors] = Dict()
        ref[:parallel_regulators] = Dict()
        ref[:parallel_valves] = Dict()
        _add_parallel_edges!(ref[:parallel_pipes], ref[:pipe])
        _add_parallel_edges!(ref[:parallel_compressors], ref[:compressor])
        _add_parallel_edges!(ref[:parallel_short_pipes], ref[:short_pipe])
        _add_parallel_edges!(ref[:parallel_resistors], ref[:resistor])
        _add_parallel_edges!(ref[:parallel_regulators], ref[:regulator])
        _add_parallel_edges!(ref[:parallel_valves], ref[:valve])

        ref[:pipes_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:pipes_to] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:compressors_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:compressors_to] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:short_pipes_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:short_pipes_to] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:resistors_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:resistors_to] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:regulators_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:regulators_to] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:valves_fr] = Dict(i => [] for (i,junction) in ref[:junction])
        ref[:valves_to] = Dict(i => [] for (i,junction) in ref[:junction])
        _add_edges_to_junction_map!(ref[:pipes_fr], ref[:pipes_to], ref[:pipe])
        _add_edges_to_junction_map!(ref[:compressors_fr], ref[:compressors_to], ref[:compressor])
        _add_edges_to_junction_map!(ref[:short_pipes_fr], ref[:short_pipes_to], ref[:short_pipe])
        _add_edges_to_junction_map!(ref[:resistors_fr], ref[:resistors_to], ref[:resistor])
        _add_edges_to_junction_map!(ref[:regulators_fr], ref[:regulators_to], ref[:regulator])
        _add_edges_to_junction_map!(ref[:valves_fr], ref[:valves_to], ref[:valve])

        ref_degree!(ref)

        for (idx, pipe) in ref[:pipe]
            i = pipe["fr_junction"]
            j = pipe["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            pipe["pd_min"] = pd_min
            pipe["pd_max"] = pd_max
            pipe["resistance"] = _calc_pipe_resistance(pipe, base_length=base_length)
            pipe["flow_min"] = _calc_pipe_flow_min(ref, pipe)
            pipe["flow_max"] = _calc_pipe_flow_max(ref, pipe)
        end

        for (idx, compressor) in ref[:compressor]
            i = compressor["fr_junction"]
            j = compressor["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            compressor["pd_min"] = pd_min
            compressor["pd_max"] = pd_max
            compressor["resistance"] = _calc_pipe_resistance(compressor, base_length=base_length)
            compressor["flow_min"] = _calc_pipe_flow_min(ref, compressor)
            compressor["flow_max"] = _calc_pipe_flow_max(ref, compressor)
        end

        for (idx, pipe) in ref[:short_pipe]
            i = pipe["fr_junction"]
            j = pipe["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            pipe["pd_min"] = pd_min
            pipe["pd_max"] = pd_max
            pipe["flow_min"] = _calc_short_pipe_flow_min(ref, idx)
            pipe["flow_max"] = _calc_short_pipe_flow_max(ref, idx)
        end

        for (idx, resistor) in ref[:resistor]
            i = resistor["fr_junction"]
            j = resistor["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            resistor["pd_min"] = pd_min
            resistor["pd_max"] = pd_max
            resistor["resistance"] = _calc_resistor_resistance(resistor)
            resistor["flow_min"] = _calc_resistor_flow_min(ref, resistor)
            resistor["flow_max"] = _calc_resistor_flow_max(ref, resistor)
        end

        for (idx, valve) in ref[:valve]
            i = valve["fr_junction"]
            j = valve["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            valve["pd_min"] = pd_min
            valve["pd_max"] = pd_max
            valve["flow_min"] = _calc_valve_flow_min(ref, valve)
            valve["flow_max"] = _calc_valve_flow_max(ref, valve)
        end

        for (idx, regulator) in ref[:regulator]
            i = regulator["fr_junction"]
            j = regulator["to_junction"]
            pd_min, pd_max = _calc_pd_bounds_sqr(ref, i, j)
            regulator["pd_min"] = pd_min
            regulator["pd_max"] = pd_max
            regulator["flow_min"] = _calc_regulator_flow_min(ref, regulator)
            regulator["flow_max"] = _calc_regulator_flow_max(ref, regulator)
        end
    end

end

function _add_junction_map!(junction_map::Dict, collection::Dict)
    for (i, component) in collection
        junction_id = component["junction_id"]
        push!(junction_map[junction_id], i)
    end
end

function _add_parallel_edges!(parallel_ref::Dict, collection::Dict)
    for (idx, connection) in collection
        i = connection["fr_junction"]
        j = connection["to_junction"]
        fr = min(i, j)
        to = max(i, j)
        if get(parallel_ref, (fr, to), false) == 1
            push!(parallel_ref[(fr, to)], idx)
        else
            parallel_ref[(fr, to)] = []
            push!(parallel_ref[(fr, to)], idx)
        end
    end
end

function _add_edges_to_junction_map!(fr_ref::Dict, to_ref::Dict, collection::Dict)
    for (idx, connection) in collection
        i = connection["fr_junction"]
        j = connection["to_junction"]
        push!(fr_ref[i], idx)
        push!(to_ref[j], idx)
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
    for (i,j) in keys(ref[:parallel_regulators]) push!(connections, (i,j)) end

    for (i,j) in connections
        ref[:degree][i] = ref[:degree][i] + 1
        ref[:degree][j] = ref[:degree][j] + 1
    end
end
