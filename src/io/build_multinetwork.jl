# ----------------------------------------------------------------------
# refactored version of timeseries block from parse_files with no splining/interpolation
# ----------------------------------------------------------------------
function _create_tsb(
        data::Vector{Dict{String,Any}}; 
        time_step::Float64    = 3600.0,
    )::Dict{String,Any}

    raw_ts = DateTime[]

    for row in data #build timestamps list
        push!(raw_ts, DateTime(split(row["timestamp"], "+")[1]))
    end

    uniq_ts = sort!(unique(raw_ts))
    n_steps = length(uniq_ts)

    ts_index = Dict{DateTime,Int}(t=>i for (i,t) in enumerate(uniq_ts))

    ts_block = Dict{String,Any}(
        "num_steps"               => n_steps,
        "num_physical_time_points"=> n_steps,
        "num_time_points"         => n_steps,
        "time_point"              => Float64[],  
        "time_step"               => time_step,
        "timestamps"              => Vector{Any}(undef, n_steps)  # raw DateTime objects
    )

    first_ts = uniq_ts[1]
    for (i, t) in enumerate(uniq_ts)
        ts_block["time_point"] = push!(ts_block["time_point"], (t - first_ts)/Millisecond(1) / 1000.0)
        ts_block["timestamps"][i] = t
    end

    # helper to create (or fetch) the leaf vector that will hold the timeseries values for a particular component_type → component_id → parameter triple
    function _ensure_leaf!(root::Dict{String,Any},
                           comp_type::String, comp_id::String, param::String)
        # component level
        if !haskey(root, comp_type)
            root[comp_type] = Dict{String,Any}()
        elseif !(root[comp_type] isa Dict)
            Memento.error(_LOGGER,
                "Inconsistent column naming – \"$comp_type\" is both a parameter and a container")
        end
        comp_type_dict = root[comp_type]

        # id level
        if !haskey(comp_type_dict, comp_id)
            comp_type_dict[comp_id] = Dict{String,Any}()
        elseif !(comp_type_dict[comp_id] isa Dict)
            Memento.error(_LOGGER,
                "Inconsistent column naming – \"$comp_id\" is both a parameter and a container")
        end
        id_dict = comp_type_dict[comp_id]

        # parameter leaf
        if !haskey(id_dict, param)
            id_dict[param] = Vector{Any}(undef, n_steps)
        elseif !(id_dict[param] isa Vector)
            Memento.error(_LOGGER,
                "Inconsistent column naming – \"$param\" is both a container and a parameter")
        end
        return id_dict[param]   # the leaf vector
    end

    for row in data
        comp_type   = row["component_type"] |> string   #these are substrings by default
        comp_id    = row["component_id"] |> string
        param  = row["parameter"] |> string
        value  = parse(Float64, row["value"])
        ts_raw = DateTime(split(row["timestamp"], "+")[1])

        idx = ts_index[ts_raw]

        leaf = _ensure_leaf!(ts_block, (comp_type), (comp_id), (param)) 
        leaf[idx] = value
    end

    return ts_block
end

# forward arguments to _create_time.... with accounting for single timestep
function make_time_series_block(csv_rows; total_time=86400.0,
                               time_step=3600.0)
    if length(unique(r["timestamp"] for r in csv_rows)) == 1
        @warn "Only one timestamp found – a 1‑step multinetwork will be created. ⚠️ As of GMs 0.10.6, this formulation cannot be solved by `solve_ogf ⚠️`"
    end
    return _create_tsb(csv_rows; 
                                     time_step       = time_step)
end

#filepath function
function build_multinetwork(static_file::AbstractString,
                            transient_file::AbstractString;
                            time_step::Float64  = 3600.0)

    open(static_file, "r") do s_io
        open(transient_file, "r") do t_io
            return build_multinetwork(s_io, t_io;
                                      time_step    = time_step)
        end
    end
end

function build_multinetwork(static_io::IO,
                            transient_io::IO;
                            time_step::Float64  = 3600.0,
                            periodic::Bool = false)

    # ------------------------------------------------------------------
    static_data = parse_file(static_io, skip_correct=false)
    
    # these same functions are applied in parse_files
    check_non_negativity(static_data)
    check_pipeline_geometry!(static_data)  
    correct_p_mins!(static_data)
    add_base_values!(static_data) # moving this before per unit conversions
    per_unit_data_field_check!(static_data)
    add_compressor_fields!(static_data)
    
    # --- convert units in static network ---
    make_si_units!(static_data)
    propagate_topology_status!(static_data)
    check_connectivity(static_data)
    check_status(static_data)
    check_edge_loops(static_data)
    check_global_parameters(static_data)

    rows = parse_transient(transient_io)   # → Vector{Dict{String,Any}}, this is the same one used by parse_files

    ts = make_time_series_block(rows;
                                time_step       = time_step)

    #
    # Attach timeseries block to static data (same method as parse_files)
    apply_gm!(x -> x["time_series"] = deepcopy(ts),
              static_data; apply_to_subnetworks = false)

    _IM.logger_config!("error") #temporarily reduce logger level
    mnw = _IM.make_multinetwork(static_data, gm_it_name, _gm_global_keys)
    _IM.logger_config!("info")

    correct_f_bounds!(mnw)
    make_per_unit!(mnw)

    return mnw
end

"""
new workflow: build mnw:
parse file, static data, no apply_corrections
parse_csv
call IM build mnw
merge csv data into im timesteps
apply apply_corrections
return data
"""