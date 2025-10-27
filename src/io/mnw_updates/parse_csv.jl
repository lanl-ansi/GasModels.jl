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
    sizehint!(nw, 24)  # expecting 24 hours to be the most common so this allows for some preallocation
    
    timestamp_to_int = Dict{String,String}()
    sizehint!(timestamp_to_int, 24)  
    current_timestep = 0
    
    line_number = 0
    for line in eachline(io)
        line_number += 1
        # Skip header
        if occursin("timestep", lowercase(line)) || occursin("timestamp", lowercase(line))
            continue
        end
        
        values = split(line, ",")

        if length(values) < 5
            error("Line $line_number: Expected at least 5 columns but got $(length(values)). Line content: $line")
        end

        @assert length(values)==5 "Error: fewer values than expected on line $line_number"
        raw_timestamp = values[1]
        asset_type = values[2]
        asset_id = values[3]
        parameter = values[4]
        value = values[5]

        # Convert timestamp to integer
        if !haskey(timestamp_to_int, raw_timestamp)
            current_timestep += 1
            timestamp_to_int[raw_timestamp] = string(current_timestep)
        end
        
        timestep_key = timestamp_to_int[raw_timestamp]
        
        # set up nested dictionaries
        # timesteps
        if !haskey(nw, timestep_key)
            nw[timestep_key] = Dict{String,Any}()
            sizehint!(nw[timestep_key], 3)  #3 asset types within each time key
        end
        
        # asset type
        if !haskey(nw[timestep_key], asset_type)
            nw[timestep_key][asset_type] = Dict{String,Any}()
            # not consistent enough data to put a size hint here
        end
        
        # asset id
        if !haskey(nw[timestep_key][asset_type], asset_id)
            nw[timestep_key][asset_type][asset_id] = Dict{String,Any}()
        end
        
        # parameter and value
        nw[timestep_key][asset_type][asset_id][parameter] = value
    end
    
    # min timestep should be 1
    @assert current_timestep > 0 "No valid data was found: the csv must contain at least 1 timestep"

    return Dict("nw" => nw)
end

# note: this function is likely deprecated as a result of commit 8f3ba93
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