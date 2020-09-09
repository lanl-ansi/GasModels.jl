# stuff that is universal to all gas models
"root of the gas formulation hierarchy"
abstract type AbstractGasModel <: _IM.AbstractInfrastructureModel end


"a macro for adding the base GasModels fields to a type definition"
_IM.@def gm_fields begin
    GasModels.@im_fields
end


""
function run_model(
    file::String,
    model_type,
    optimizer,
    build_method;
    ref_extensions = [],
    solution_processors = [],
    kwargs...,
)
    data = GasModels.parse_file(file)
    return run_model(
        data,
        model_type,
        optimizer,
        build_method;
        ref_extensions = ref_extensions,
        solution_processors = solution_processors,
        kwargs...,
    )
end

""
function run_model(
    data::Dict{String,<:Any},
    model_type,
    optimizer,
    build_method;
    ref_extensions = [],
    solution_processors = [],
    kwargs...,
)
    gm = instantiate_model(
        data,
        model_type,
        build_method;
        ref_extensions = ref_extensions,
        ext = get(kwargs, :ext, Dict{Symbol,Any}()),
        setting = get(kwargs, :setting, Dict{String,Any}()),
        jump_model = get(kwargs, :jump_model, JuMP.Model()),
    )
    result = optimize_model!(
        gm,
        optimizer = optimizer,
        solution_processors = solution_processors,
    )

    if haskey(data, "objective_normalization")
        result["objective"] *= data["objective_normalization"]
    end

    return result
end

""
function instantiate_model(file::String, model_type, build_method; kwargs...)
    data = GasModels.parse_file(file)
    return instantiate_model(data, model_type, build_method; kwargs...)
end


function instantiate_model(
    data::Dict{String,<:Any},
    model_type::Type,
    build_method;
    kwargs...,
)
    gm = _IM.instantiate_model(
        data,
        model_type,
        build_method,
        ref_add_core!,
        _gm_global_keys;
        kwargs...,
    )
    return gm
end


"""
Builds the ref dictionary from the data dictionary. Additionally the ref
dictionary would contain fields populated by the optional vector of
ref_extensions provided as a keyword argument.
"""
function build_ref(data::Dict{String,<:Any}; ref_extensions = [])
    return _IM.build_ref(
        data,
        ref_add_core!,
        _gm_global_keys,
        ref_extensions = ref_extensions,
    )
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
* `:loss_resistor` -- the set of loss_resistors in the system,
* `:transfer` -- the set of transfer points in the system,
* `:receipt` -- the set of receipt points in the system,
* `:delivery` -- the set of delivery points in the system,
* `:regulator` -- the set of pressure-reducing valves in the system,
* `:valve` -- the set of valves in the system,
* `:storage` -- the set of storages in the system,
* `:degree` -- the degree of junction i using existing connections (see `ref_degree!`)),
"""
function ref_add_core!(refs::Dict{Symbol,<:Any})
    _ref_add_core!(
        refs[:nw],
        refs[:base_length],
        refs[:base_pressure],
        refs[:base_flow],
        refs[:sound_speed],
    )
end

function _ref_add_core!(
    nw_refs::Dict{Int,<:Any},
    base_length,
    base_pressure,
    base_flow,
    sound_speed,
)
    for (nw, ref) in nw_refs
        ref[:junction] = haskey(ref, :junction) ? Dict(x for x in ref[:junction] if x.second["status"] == 1) : Dict()
        ref[:pipe] = haskey(ref, :pipe) ? Dict(x for x in ref[:pipe] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:compressor] = haskey(ref, :compressor) ? Dict(x for x in ref[:compressor] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:short_pipe] = haskey(ref, :short_pipe) ? Dict(x for x in ref[:short_pipe] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:resistor] = haskey(ref, :resistor) ? Dict(x for x in ref[:resistor] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:loss_resistor] = haskey(ref, :loss_resistor) ? Dict(x for x in ref[:loss_resistor] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:transfer] = haskey(ref, :transfer) ? Dict(x for x in ref[:transfer] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()
        ref[:receipt] = haskey(ref, :receipt) ? Dict(x for x in ref[:receipt] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()
        ref[:delivery] = haskey(ref, :delivery) ? Dict(x for x in ref[:delivery] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()
        ref[:regulator] = haskey(ref, :regulator) ? Dict(x for x in ref[:regulator] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:valve] = haskey(ref, :valve) ? Dict(x for x in ref[:valve] if x.second["status"] == 1 && x.second["fr_junction"] in keys(ref[:junction]) && x.second["to_junction"] in keys(ref[:junction])) : Dict()
        ref[:storage] = haskey(ref, :storage) ? Dict(x for x in ref[:storage] if x.second["status"] == 1 && x.second["junction_id"] in keys(ref[:junction])) : Dict()

        # compute the maximum flow
        mf =
            ref[:max_mass_flow] =
                _calc_max_mass_flow(ref[:receipt], ref[:storage], ref[:transfer])

        # dispatchable tranfers, receipts, and deliveries
        ref[:dispatchable_transfer] = Dict(x for x in ref[:transfer] if x.second["is_dispatchable"] == 1)
        ref[:dispatchable_receipt] = Dict(x for x in ref[:receipt] if x.second["is_dispatchable"] == 1)
        ref[:dispatchable_delivery] = Dict(x for x in ref[:delivery] if x.second["is_dispatchable"] == 1)
        ref[:nondispatchable_transfer] = Dict(x for x in ref[:transfer] if x.second["is_dispatchable"] == 0)
        ref[:nondispatchable_receipt] = Dict(x for x in ref[:receipt] if x.second["is_dispatchable"] == 0)
        ref[:nondispatchable_delivery] = Dict(x for x in ref[:delivery] if x.second["is_dispatchable"] == 0)

        # transfers, receipts, deliveries and storages in junction
        ref[:dispatchable_transfers_in_junction] = Dict([(i, []) for (i, junction) in ref[:junction]])
        ref[:dispatchable_receipts_in_junction] = Dict([(i, []) for (i, junction) in ref[:junction]])
        ref[:dispatchable_deliveries_in_junction] = Dict([(i, []) for (i, junction) in ref[:junction]])
        ref[:nondispatchable_transfers_in_junction] = Dict([(i, []) for (i, junction) in ref[:junction]])
        ref[:nondispatchable_receipts_in_junction] = Dict([(i, []) for (i, junction) in ref[:junction]])
        ref[:nondispatchable_deliveries_in_junction] = Dict([(i, []) for (i, junction) in ref[:junction]])
        ref[:storages_in_junction] = Dict([(i, []) for (i, junction) in ref[:junction]])

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
        ref[:parallel_loss_resistors] = Dict()
        ref[:parallel_regulators] = Dict()
        ref[:parallel_valves] = Dict()
        _add_parallel_edges!(ref[:parallel_pipes], ref[:pipe])
        _add_parallel_edges!(ref[:parallel_compressors], ref[:compressor])
        _add_parallel_edges!(ref[:parallel_short_pipes], ref[:short_pipe])
        _add_parallel_edges!(ref[:parallel_resistors], ref[:resistor])
        _add_parallel_edges!(ref[:parallel_loss_resistors], ref[:loss_resistor])
        _add_parallel_edges!(ref[:parallel_regulators], ref[:regulator])
        _add_parallel_edges!(ref[:parallel_valves], ref[:valve])

        ref[:pipes_fr] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:pipes_to] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:compressors_fr] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:compressors_to] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:short_pipes_fr] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:short_pipes_to] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:resistors_fr] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:resistors_to] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:loss_resistors_fr] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:loss_resistors_to] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:regulators_fr] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:regulators_to] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:valves_fr] = Dict(i => [] for (i, junction) in ref[:junction])
        ref[:valves_to] = Dict(i => [] for (i, junction) in ref[:junction])
        _add_edges_to_junction_map!(ref[:pipes_fr], ref[:pipes_to], ref[:pipe])
        _add_edges_to_junction_map!(ref[:compressors_fr], ref[:compressors_to], ref[:compressor])
        _add_edges_to_junction_map!(ref[:short_pipes_fr], ref[:short_pipes_to], ref[:short_pipe])
        _add_edges_to_junction_map!(ref[:resistors_fr], ref[:resistors_to], ref[:resistor])
        _add_edges_to_junction_map!(ref[:loss_resistors_fr], ref[:loss_resistors_to], ref[:loss_resistor])
        _add_edges_to_junction_map!(ref[:regulators_fr], ref[:regulators_to], ref[:regulator])
        _add_edges_to_junction_map!(ref[:valves_fr], ref[:valves_to], ref[:valve])

        ref_degree!(ref)
        ref_storage!(ref)

        for (idx, pipe) in ref[:pipe]
            i = pipe["fr_junction"]
            j = pipe["to_junction"]
            pipe["area"] = pi * pipe["diameter"] * pipe["diameter"] / 4.0
        end

        for (idx, compressor) in ref[:compressor]
            i = compressor["fr_junction"]
            j = compressor["to_junction"]
            compressor["area"] = pi * compressor["diameter"] * compressor["diameter"] / 4.0
        end

        for (idx, storage) in ref[:storage]
            storage["well_area"] =
                pi * storage["well_diameter"] * storage["well_diameter"] / 4.0
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
    for (i, junction) in ref[:junction]
        ref[:degree][i] = 0
    end

    connections = Set()
    for (i, j) in keys(ref[:parallel_pipes])
        push!(connections, (i, j))
    end
    for (i, j) in keys(ref[:parallel_compressors])
        push!(connections, (i, j))
    end
    for (i, j) in keys(ref[:parallel_resistors])
        push!(connections, (i, j))
    end
    for (i, j) in keys(ref[:parallel_loss_resistors])
        push!(connections, (i, j))
    end
    for (i, j) in keys(ref[:parallel_short_pipes])
        push!(connections, (i, j))
    end
    for (i, j) in keys(ref[:parallel_valves])
        push!(connections, (i, j))
    end
    for (i, j) in keys(ref[:parallel_regulators])
        push!(connections, (i, j))
    end

    for (i, j) in connections
        ref[:degree][i] = ref[:degree][i] + 1
        ref[:degree][j] = ref[:degree][j] + 1
    end
end


"Add reference information for storage facilities"
function ref_storage!(ref::Dict{Symbol,Any})
    for (i, storage) in ref[:storage]
        storage["reservoir_density_max"] = storage["reservoir_p_max"]
        storage["reservoir_volume"] =
            storage["total_field_capacity"] / storage["reservoir_density_max"]
        storage["reservoir_p_min"] =
            storage["base_gas_capacity"] / storage["total_field_capacity"] *
            storage["reservoir_p_max"]
        storage["reservoir_density_min"] = storage["reservoir_p_min"]
        storage["initial_capacity"] =
            storage["total_field_capacity"] * storage["initial_field_capacity_percent"]
        storage["initial_density"] =
            storage["initial_capacity"] / storage["reservoir_volume"]
    end
end
