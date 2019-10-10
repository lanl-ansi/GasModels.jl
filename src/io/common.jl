"""
    parse_file(io)

Parses the IOStream of a file into a GasModels data structure.
"""
function parse_file(io::IO; filetype::AbstractString="m")
    if filetype == "m"
        pmd_data = GasModels.parse_matlab(io)
    elseif filetype == "json"
        pmd_data = GasModels.parse_json(io)
    else
        Memento.error(_LOGGER, "only .m and .json files are supported")
    end

    correct_network_data!(pmd_data)

    return pmd_data
end


""
function parse_file(file::String)
    pmd_data = open(file) do io
        parse_file(io; filetype=split(lowercase(file), '.')[end])
    end
    return pmd_data
end


""
function correct_network_data!(data::Dict{String,Any})
    make_per_unit!(data)
end
