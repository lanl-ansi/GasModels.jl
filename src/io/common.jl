"""
    parse_file(io)

Parses the IOStream of a file into a GasModels data structure.
"""
function parse_file(io::IO; filetype::AbstractString="m", skip_correct::Bool=false)
    if filetype == "m"
        pmd_data = GasModels.parse_matlab(io)
    elseif filetype == "json"
        pmd_data = GasModels.parse_json(io)
    else
        Memento.error(_LOGGER, "only .m and .json files are supported")
    end

    if !skip_correct
        correct_network_data!(pmd_data)
    end

    return pmd_data
end


""
function parse_file(file::String; skip_correct::Bool=false)
    pmd_data = open(file) do io
        parse_file(io; filetype=split(lowercase(file), '.')[end], skip_correct=skip_correct)
    end
    return pmd_data
end


""
function correct_network_data!(data::Dict{String,Any})
    check_pressure_limits(data)
    check_pipe_parameters(data)
    check_compressor_parameters(data)

    make_per_unit!(data)

    check_connectivity(data)
    check_status(data)
    check_edge_loops(data)

    check_global_parameters(data)
end
