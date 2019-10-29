
"Grab the data from a json field"
function parse_json(file_string::AbstractString)
    gm_data = open(file_string, "r") do io
        parse_json(io)
    end

    return gm_data
end


""
function parse_json(io::IO)
    gm_data = JSON.parse(io)

    # Fix for existing json files that don't have "junction_i" or "index"
    for comp_type in _gm_component_types
        if haskey(gm_data, comp_type)
            for (i, comp) in gm_data[comp_type]
                if !haskey(comp, "index")
                    comp["index"] = parse(Int, i)
                end

                if comp_type == "junction" && !haskey(comp, "junction_i")
                    comp["junction_i"] = parse(Int, i)
                end
            end
        end
    end

    return gm_data
end
