#=
workflow: call parse_file on the static data? will have to check that this will still work with the data checks removed
call parse_csv (maybe rename to parse_timeseries?)
call create_timeseries(static data, transient data)
something in that should apply the data checks to the static file (reference existing code)
=#

function parse_csv(filename::String)::Vector{Dict{String,Any}}
    raw = open(filename, "r") do io
        readlines(io)
    end
    return parse_csv(raw) 
end

function parse_csv(io::IO)::Vector{Dict{String,Any}}
    lines = readlines(io)
    return parse_csv(lines)
end

function parse_csv(lines::Vector{String})::Vector{Dict{String,Any}}
    header = split(lines[1], ",")
    data = Vector{Dict{String,Any}}()
    for line in lines[2:end]
        values = split(line, ",")
        row_dict = Dict{String,Any}()
        for (i, col_name) in enumerate(header)
            if i <= length(values) 
                row_dict[col_name] = values[i]
            end
        end
        push!(data, row_dict)
    end
    return data
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
function build_multinetwork(
    static_data::Dict{String,Any},
    csv_data::Vector{Dict{String,Any}};
    total_time = 86400.0,
    time_step = 3600.0,
    spatial_discretization = 10000.0,
    additional_time = 21600.0,
    apply_corrections = false
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
