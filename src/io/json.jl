
"Grab the data from a json field"
function parse_json(file_string::AbstractString)
    data_string = read(open(file_string), String)
    gm_data = JSON.parse(data_string)
    return gm_data
end


""
function parse_json(io::IO)
    gm_data = JSON.parse(io)
end
