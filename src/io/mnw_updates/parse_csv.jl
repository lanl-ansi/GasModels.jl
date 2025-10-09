#=
workflow: call parse_file on the static data? will have to check that this will still work with the data checks removed
call parse_csv (maybe rename to parse_timeseries?)
call create_timeseries(static data, transient data)
something in that should apply the data checks to the static file (reference existing code)
=#

function parse_csv(filename::String)::Dict{String,Any}
    open(filename, "r") do io
        return parse_csv(io)
    end
end

function parse_csv(io::IO)::Dict{String,Any}

    nw = Dict{String,Any}()
    
    timestamp_to_int = Dict{String,String}()
    current_timestep = 0
    
    for line in eachline(io)
        # Skip header
        if occursin("timestep", lowercase(line)) || occursin("timestamp", lowercase(line))
            continue
        end
        
        values = split(line, ",")
        
        raw_timestamp = values[1]
        asset_type = values[2]
        asset_id = values[3]
        parameter = values[4]
        value = values[5]
        
        # Assign integer timestep
        if !haskey(timestamp_to_int, raw_timestamp)
            current_timestep += 1
            timestamp_to_int[raw_timestamp] = string(current_timestep)
        end
        
        timestep_key = timestamp_to_int[raw_timestamp]
        
        # set up the nested dicts
        # timestep
        if !haskey(nw, timestep_key)
            nw[timestep_key] = Dict{String,Any}()
        end
        # asset type
        if !haskey(nw[timestep_key], asset_type)
            nw[timestep_key][asset_type] = Dict{String,Any}()
        end
        # asset id
        if !haskey(nw[timestep_key][asset_type], asset_id)
            nw[timestep_key][asset_type][asset_id] = Dict{String,Any}()
        end
        # parameter and value
        nw[timestep_key][asset_type][asset_id][parameter] = value
    end
    
    return Dict("nw" => nw)
end


function update_static_case(case::Dict, csv_data::Dict)
	for row in csv_data
        component_type = row["component_type"]
        asset_key = string(row["component_id"])
        parameter = row["parameter"]
        value = row["value"]
        
        if component_type == "transfer"
            case["transfer"][asset_key][parameter] = value
        elseif component_type == "receipt"
            case["receipt"][asset_key][parameter] = value
        else
            case["delivery"][asset_key][parameter] = value
        end
    end
    
    return case
end

# assemble multinetwork using pieces of existing parse_files
# understanding the issues I had with this version vs kaarthik's original version:
# per unit conversion was applied in the wrong order. parse_file 
function build_multinetwork(
    static_data::Dict{String,Any},
    csv_data::Vector{Dict{String,Any}};
    total_time = 86400.0,
    time_step = 3600.0,
    spatial_discretization = 10000.0,
    additional_time = 21600.0,
    apply_corrections = true
)::Dict{String,Any}
    if apply_corrections
        check_non_negativity(static_data)
        check_pipeline_geometry!(static_data)
        correct_p_mins!(static_data)
        per_unit_data_field_check!(static_data)
        add_compressor_fields!(static_data)

        make_si_units!(static_data)
        propagate_topology_status!(static_data)
        add_base_values!(static_data)
        correct_f_bounds!(static_data)
        check_connectivity(static_data)
        check_status(static_data)
        check_edge_loops(static_data)
        check_global_parameters(static_data)
    end
    
    prep_transient_data!(static_data; spatial_discretization=spatial_discretization)

    
    # Convert the CSV data to the format expected by _create_time_series_block
    transient_data = Vector{Dict{String,Any}}()
    for row in csv_data
        if haskey(row, "timestamp") && 
           haskey(row, "component_type") && 
           haskey(row, "component_id") && 
           haskey(row, "parameter") && 
           haskey(row, "value")
            push!(transient_data, Dict{String,Any}(
                "timestamp" => row["timestamp"],
                "component_type" => row["component_type"],
                "component_id" => row["component_id"],
                "parameter" => row["parameter"],
                "value" => row["value"]
            ))
        end
    end
    
    # make sure the static csv can't be used to make a mnw case
    timestamps = unique([row["timestamp"] for row in transient_data])
    if length(timestamps) < 2
        Memento.error(_LOGGER, "Transient data must contain more than one unique timestamp")
    end
    
    make_si_units!(transient_data, static_data)

    time_series_block = _create_time_series_block(
        transient_data,
        total_time = total_time,
        time_step = time_step,
        additional_time = additional_time,
        periodic = true
    )

    apply_gm!(
        x -> x["time_series"] = deepcopy(time_series_block),
        static_data;
        apply_to_subnetworks = false
    )

    mn_data = _IM.make_multinetwork(static_data, gm_it_name, _gm_global_keys)
    
    # --- Final per-unit conversion ---
    make_per_unit!(mn_data)
    
    # convert network indices from strings to integers (trying to fix the key 0 not found error)
    new_nw = Dict{Int, Any}()
    for (k, v) in mn_data["nw"]
        new_nw[parse(Int, k)] = v
    end
    mn_data["nw"] = new_nw

    return mn_data
end
