
const _NOMINATION_ASSET_TYPES = ["receipt", "delivery", "transfer"]

function _build_nomination_step(
    time_series_block::Dict{String, Any},
    index::Int,
)::Dict{String, Any}
    nomination = Dict{String, Any}("has_changed" => index == 1)
    nomination["units"] = "si"
    nomination["time"] = time_series_block["time_point"][index]

    for field in _NOMINATION_ASSET_TYPES
        nomination[field] = Dict{String, Any}()
        if !haskey(time_series_block, field)
            continue
        end

        for (component_id, entry) in time_series_block[field]
            nomination[field][component_id] = Dict{String, Any}()
            for (column_name, series) in entry
                current_value = series[index]
                previous_value = index > 1 ? series[index - 1] : current_value
                nomination[field][component_id][column_name] = current_value
                nomination["has_changed"] |= current_value != previous_value
            end
        end
    end
    return nomination
end

function _parse_csv(
    gm_static_data::Dict,
    csv_filepath::AbstractString;
    time_step=3600.0, # 1 hour
)::Union{Dict{Int, Dict{String, Any}}, Nothing}
    @assert (isfile(csv_filepath) && endswith(csv_filepath, ".csv")) "Error: no valid csv file found at $csv_filepath"

    timeseries_data = GasModels.parse_transient(csv_filepath)
    GasModels.make_si_units!(timeseries_data, gm_static_data)

    #this function has interpolation/splining disabled
    time_series_block = GasModels.make_time_series_block(
        timeseries_data;
        total_time=24 * 3600.0,
        time_step=time_step,
    )

    nominations = Dict{Int, Dict{String, Any}}()
    for index in 1:time_series_block["num_steps"]
        nomination = _build_nomination_step(time_series_block, index)
        step_id = index - 1 # zero indexing for nominations dict

        nominations[step_id] = nomination
        if !nomination["has_changed"] && haskey(nominations, step_id - 1)
            for field in _NOMINATION_ASSET_TYPES
                if haskey(nominations[step_id - 1], field) &&
                    haskey(nominations[step_id], field)
                    nominations[step_id][field] = nominations[step_id - 1][field]
                end
            end
        end
    end
    return nominations
end

function _apply_nominations!(
    gm_static_data::AbstractDict{String, <:Any},
    bnds::AbstractDict{String, <:Any},
)
    if get(bnds, "units", "") != "si"
        throw(ArgumentError("Nominations must be in 'si' units."))
    end

    base_flow = gm_static_data["base_flow"]

    for field in _NOMINATION_ASSET_TYPES
        # Use get() with an empty Dict as a default to handle missing fields gracefully
        for (id, entry) in get(bnds, field, Dict())
            !haskey(gm_static_data[field], id) && continue
            for (col_name, val) in entry
                gm_static_data[field][id][col_name] = val / base_flow
            end
        end
    end
end

function parse_separated_data(m_file::String, static_csv::String)::Dict{String, Any}
    """return a case with the updated pricing and withdrawal/injection information"""
    case = parse_file(m_file)
    nominations = _parse_csv(case, static_csv)
    @assert length(nominations)==1 "Error: more than one timestep detected in the csv file. Use parse_files or parse_multinetwork instead"
    _apply_nominations!(case, nominations[0])
    return case #you can call solve_ogf directly on this
end