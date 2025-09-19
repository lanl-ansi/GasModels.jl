"""
    parse_file(io)

Parses the IOStream of a file into a GasModels data structure.
"""
function parse_file(io::IO; filetype::AbstractString = "m", skip_correct::Bool = false)
    if filetype == "m"
        gm_data = GasModels.parse_matgas(io)
    elseif filetype == "json"
        gm_data = GasModels.parse_json(io)
    elseif filetype == "zip"
        gm_data = GasModels.parse_gaslib(io)
    else
        Memento.error(_LOGGER, "only .m and .json files are supported")
    end

    if !skip_correct
        correct_network_data!(gm_data)
    end

    return gm_data
end


""
function parse_file(file::String; skip_correct::Bool = false)
    gm_data = open(file) do io
        parse_file(io; filetype = split(lowercase(file), '.')[end], skip_correct = skip_correct)
    end

    return gm_data
end

function parse_v3_file(m_path::String, csv_path::String)
    case = parse_file(m_path)
    df = CSV.read(csv_path, DataFrame)

    for row in eachrow(df)
        if row.component_type == "compressor"
            asset_key = string(row.component_id)
            case["compressor"][asset_key][row.parameter] = row.value
        elseif row.component_type == "transfer"
            asset_key = string(row.component_id)
            case["transfer"][asset_key][row.parameter] = row.value
        elseif row.component_type == "receipt"
            asset_key = string(row.component_id)
            case["receipt"][asset_key][row.parameter] = row.value
        else
            asset_key = string(row.component_id)
            case["delivery"][asset_key][row.parameter] = row.value
        end
    end

    return case

end


"""
    correct_network_data!(data::Dict{String,Any})

Data integrity checks
"""

#check that no pipes have diameter or length = 0
#check that no elevation change is larger than the length of the pipe
function check_pipeline_geometry!(data::Dict{String,Any})
    for (pipe_id, pipe) in data["pipe"]
        length = pipe["length"]
        diameter = pipe["diameter"]

        if length <= 0.0
            Memento.error(_LOGGER, "Pipeline $pipe_id has non-positive length: $length")
        end
        if diameter <= 0.0
            Memento.error(_LOGGER, "Pipeline $pipe_id has non-positive diameter: $diameter")
        end

        # Convert junction indices to strings before lookup
        fr_id = string(pipe["fr_junction"])
        to_id = string(pipe["to_junction"])

        if haskey(data["junction"], fr_id) && haskey(data["junction"], to_id)
            f_junc = data["junction"][fr_id]
            t_junc = data["junction"][to_id]

            if haskey(f_junc, "elevation") && haskey(t_junc, "elevation")
                dz = abs(f_junc["elevation"] - t_junc["elevation"])
                if dz > length
                    Memento.error(_LOGGER, "Pipeline $pipe_id has elevation change ($dz) greater than length ($length)")
                end
            end
        else
            Memento.warn(_LOGGER, "Pipeline $pipe_id refers to missing junction(s): $fr_id or $to_id")
        end
    end
end

function correct_network_data!(data::Dict{String,Any})
    check_non_negativity(data)
    check_pipeline_geometry!(data) #geo must be checked before per-unit conversion
    check_non_zero(data)
    check_rouge_junction_ids(data)
    correct_p_mins!(data)

    per_unit_data_field_check!(data)
    add_compressor_fields!(data)

    make_si_units!(data)
    # select_largest_component!(data)
    propagate_topology_status!(data)
    add_base_values!(data)
    make_per_unit!(data)

    # Assumes everything is in per unit.
    correct_f_bounds!(data)

    check_connectivity(data)
    check_status(data)
    check_edge_loops(data)
    check_global_parameters(data)
end
