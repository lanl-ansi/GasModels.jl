"parses transient data format CSV into list of dictionarys"
function parse_transient(file::String)::Array{Dict{String,Any},1}
    open(file, "r") do io
        parse_transient(io)
    end
end


"parses transient data format CSV into "
function parse_transient(io::IO)::Array{Dict{String,Any},1}
    raw = readlines(io)

    data = []
    for line in raw[2:end]
        timestamp, component_type, component_id, parameter, value = split(line, ",")
        push!(data, Dict("timestamp" => timestamp, "component_type" => component_type, "component_id" => component_id, "parameter" => parameter, "value" => value))
    end

    return data
end
