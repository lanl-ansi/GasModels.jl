
#WARNING: INCLUDING THIS CODE WILL CAUSE PRECOMP TO FAIL
#DO NOT ADD TO GASMODELS.JL UNTIL IMPORTS HAVE BEEN RESOLVED


using DataFrames, .Threads, GasModels
apply_corrections = true
#=
new parser strat: extract text between starts and ends. convert those into dataframes in parallel. eventually convert dataframes to dicts
pass the output to gasmodels correction and make per unit functions. no need to rewrite those
=#

# this is probably IO bound, so not worth it to parallelize
function extract_text_between(raw_text::AbstractString, start_string::AbstractString, end_string::AbstractString)
    start_pos = findfirst(start_string, raw_text)
    if start_pos === nothing
        return ""  # Start string not found
    end
    
    start_pos_with_marker = last(start_pos) + 1
    end_pos = findnext(end_string, raw_text, start_pos_with_marker)
    if end_pos === nothing
        return ""  # End string not found
    end
    
    return raw_text[first(start_pos):last(end_pos)]
end

function parse_raw_data_to_df(raw_text::String)
    # Find column names
    column_names_match = match(r"%column_names%\s+(.*?)$"m, raw_text)
    if column_names_match === nothing
        throw(ArgumentError("Column names not found in the raw text"))
    end
    column_names = split(strip(column_names_match.captures[1]))
    
    # data between brackets is matgas table
    data_match = match(r"\[(.*?)\];"s, raw_text)
    if data_match === nothing
        throw(ArgumentError("Data not found in the raw text"))
    end
    
    data_text = strip(data_match.captures[1])
    rows = [strip(line) for line in split(data_text, '\n') if !isempty(strip(line))]
    
    # vector of vectors to represent the table
    data = Vector{Any}[]
    
    for row in rows
        string_literals = String[]
        
        row_with_placeholders = row
        for m in eachmatch(r"'([^']*)'", row)
            push!(string_literals, m.captures[1])
            placeholder = "__STRING__$(length(string_literals)-1)__"
            row_with_placeholders = replace(row_with_placeholders, m.match => placeholder, count=1)
        end
        
        # split by spaces and rmmissing
        values = filter(!isempty, split(row_with_placeholders))
        
        processed_row = Any[]
        for i in eachindex(values)
            val = values[i]
            if startswith(val, "__STRING__")
                index = parse(Int, replace(val, r"__STRING__(\d+)__" => s"\1")) + 1
                push!(processed_row, string_literals[index])
            else
                try
                    if occursin(".", val)
                        push!(processed_row, parse(Float64, val))
                    else
                        push!(processed_row, parse(Int, val))
                    end
                catch
                    push!(processed_row, val)
                end
            end
        end
        
        # make sure the dimensions are correct to build the dataframe
        if length(processed_row) > length(column_names)
            processed_row = processed_row[1:length(column_names)]
        elseif length(processed_row) < length(column_names)
            append!(processed_row, fill(missing, length(column_names) - length(processed_row)))
        end
        
        push!(data, processed_row)
    end
    
    # build df
    column_vectors = [getindex.(data, i) for i in 1:length(column_names)]
    df = DataFrame(column_vectors, Symbol.(column_names))
    
    return df
end

#wrap the previous 2 functions, then call in parallel on the different parts of the dataframe
function process_data_pair_to_dict(text1, text2, asset_type)
    @assert (!isempty(text1)&&!isempty(text2)) "Important data missing from $asset_type"

    df1 = parse_raw_data_to_df(text1)
    df2 = parse_raw_data_to_df(text2)
    combined_df = hcat(df1, df2)
    
    # start converting df to dict
    result_dict = Dict{String, Dict{String, Any}}()
    
    # assuming first column always contains asset IDs
    id_col = names(combined_df)[1]
    
    for i in 1:nrow(combined_df)
        asset_id = string(combined_df[i, id_col])
        if !haskey(result_dict, asset_id)
            result_dict[asset_id] = Dict{String, Any}()
        end
        for col_name in names(combined_df)[2:end]
            result_dict[asset_id][string(col_name)] = combined_df[i, col_name] #store the value
        end
    end
    
    for key in keys(result_dict)
        result_dict[key]["is_per_unit"] = 0
        result_dict[key]["is_si_units"] = 1
        result_dict[key]["is_english_units"] = 0
        result_dict[key]["id"] = key
        result_dict[key]["index"] = key
    end

    return result_dict
end

function extract_metadata(content)
    # Look for the metadata section
    metadata_start = "function mgc ="
    metadata_end = "mgc.units ="  # We'll capture up to this line and handle the last lines separately
    
    # Extract the metadata text block
    metadata_text = extract_text_between(content, metadata_start, metadata_end)
    if isempty(metadata_text)
        return Dict{String, Any}()  # Return empty dict if not found
    end
    
    # Add back the last line we used as an end marker for extraction
    metadata_text = metadata_text * "mgc.units ="
    
    # Also get the economic_weighting line that comes after
    econ_line = ""
    if occursin("mgc.economic_weighting =", content)
        econ_regex = r"mgc\.economic_weighting\s*=\s*([0-9.]+);"
        econ_match = match(econ_regex, content)
        if econ_match !== nothing
            econ_line = "mgc.economic_weighting = $(econ_match[1]);"
        end
    end
    
    # Combine all metadata text
    metadata_text = metadata_text * "\n" * econ_line
    
    # Parse the metadata
    metadata = Dict{String, Any}()
    
    # Process each line
    for line in split(metadata_text, '\n')
        line = strip(line)
        if isempty(line) || !occursin('=', line)
            continue
        end
        
        # Extract key and value
        parts = split(line, '=', limit=2)
        if length(parts) != 2
            continue
        end
        
        key = strip(parts[1])
        value = strip(parts[2])
        
        # Remove "mgc." prefix from key
        if startswith(key, "mgc.")
            key = key[5:end]
        end
        
        # Remove trailing semicolon from value
        if endswith(value, ';')
            value = value[1:end-1]
        end
        
        # Convert string values in quotes to actual strings
        if (startswith(value, "'") && endswith(value, "'")) || (startswith(value, "\"") && endswith(value, "\""))
            value = value[2:end-1]
        # Convert numeric values to numbers
        elseif occursin(r"^[0-9.]+$", value)
            value = parse(Float64, value)
        end
        
        metadata[key] = value
    end
    
    return metadata
end

filepath = "KernRiverGT_YELLOW_v3.m"

# next task: add asserts to make parser more robust wrt per unit
function fast_m_parse(filepath::String, apply_corrections=true)
    content = read(filepath, String)

    starts = ["%% junction", "%% pipe", "%% compressor", "%% transfer", "%% receipt", "%% delivery"]
    data_starts = ["%% junction data", "%% pipe data", "%% compressor data", "%% transfer data", "%% receipt data", "%% delivery data"]
    end_marker = "];"

    # get the main data for each asset type
    junction_text = extract_text_between(content, starts[1], end_marker)
    pipe_text = extract_text_between(content, starts[2], end_marker)
    compressor_text = extract_text_between(content, starts[3], end_marker)
    transfer_text = extract_text_between(content, starts[4], end_marker)
    receipt_text = extract_text_between(content, starts[5], end_marker)
    delivery_text = extract_text_between(content, starts[6], end_marker)

    # get the additional data. this will be appended to the main df
    junction_data_text = extract_text_between(content, data_starts[1], end_marker)
    pipe_data_text = extract_text_between(content, data_starts[2], end_marker)
    compressor_data_text = extract_text_between(content, data_starts[3], end_marker)
    transfer_data_text = extract_text_between(content, data_starts[4], end_marker)
    receipt_data_text = extract_text_between(content, data_starts[5], end_marker)
    delivery_data_text = extract_text_between(content, data_starts[6], end_marker)

    # tasks for parallel processing
    junction_task = Threads.@spawn process_data_pair_to_dict(junction_text, junction_data_text, "junction")
    pipe_task = Threads.@spawn process_data_pair_to_dict(pipe_text, pipe_data_text, "pipe")
    compressor_task = Threads.@spawn process_data_pair_to_dict(compressor_text, compressor_data_text, "compressor")
    transfer_task = Threads.@spawn process_data_pair_to_dict(transfer_text, transfer_data_text, "transfer")
    receipt_task = Threads.@spawn process_data_pair_to_dict(receipt_text, receipt_data_text, "receipt")
    delivery_task = Threads.@spawn process_data_pair_to_dict(delivery_text, delivery_data_text, "delivery")

    # gather the results from the threads
    case = Dict{String,Any}()

    case["junction"] = fetch(junction_task)
    case["pipe"] = fetch(pipe_task)
    case["compressor"] = fetch(compressor_task)
    case["transfer"] = fetch(transfer_task)
    case["receipt"] = fetch(receipt_task)
    case["delivery"] = fetch(delivery_task)
    
    #one big assert to check that everything exists
    @assert (!isempty(case["junction"]) && !isempty(case["pipe"]) && !isempty(case["compressor"]) && !isempty(case["transfer"]) && !isempty(case["receipt"]) && !isempty(case["delivery"])) "Not all component types were read in properly"

    metadata = extract_metadata(content)
    for (key, value) in metadata
        case[key] = value
    end

    #starting checks, adding in the things that were missing from the base file
    case["gas_molar_mass"] = 0.02896 * case["gas_specific_gravity"]
    unitsmatch = match(r"mgc.units = 'si'", content)
    if unitsmatch !== nothing
        case["is_si_units"] = 1
        case["is_per_unit"] = 0
        case["is_english_units"] = 0
        delete!(case, "units") #this gets added in the metadata loop
    end
    # case["version"] and case["source_version"] are both in the original parser result. is this necessary?
    case["name"] = case["function mgc"]
    delete!(case, "function mgc")
    case["source_type"] = ".m"
    case["multinetwork"] = false
    case["pipeline_id"] = round(Int, case["pipeline_id"])
    case["units"] = "si" # why do we have to say the units are SI so many times???

    if apply_corrections
        check_non_negativity(case)
        check_pipeline_geometry!(case) #geo must be checked before per-unit conversion
        check_non_zero(case)
        correct_p_mins!(case)

        per_unit_data_field_check!(case) #note: this is from core/data.jl, like check_connectivity and check_status does not fix things
        add_compressor_fields!(case)

        make_si_units!(case) # per unit, si transforms are not applying to the case
        propagate_topology_status!(case)
        add_base_values!(case)
        make_per_unit!(case)

        # Assumes everything is per unit
        correct_f_bounds!(case)

        # check_connectivity(case) #edit 10/28: including these functions does not make the case solve
        #lots of warnings related to junction_id xxxx in pipe/compressor/delivery/receipt xxxx not defined
        # check_status(case)
        check_edge_loops(case)
        check_global_parameters(case)
    end
   return case
end