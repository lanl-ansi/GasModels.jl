
# Grab the data from a json field
function parse_json(file_string)
    data_string = read(open(file_string), String)
    return JSON.parse(data_string)
end