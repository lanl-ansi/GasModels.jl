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


"""
    correct_network_data!(data::Dict{String,Any})

Data integrity checks
"""
function correct_network_data!(data::Dict{String,Any})
    _IM.modify_data_with_function!(data, "ng", check_non_negativity)
    _IM.modify_data_with_function!(data, "ng", correct_p_mins!)

    _IM.modify_data_with_function!(data, "ng", per_unit_data_field_check!)
    _IM.modify_data_with_function!(data, "ng", add_compressor_fields!)

    _IM.modify_data_with_function!(data, "ng", make_si_units!)
    _IM.modify_data_with_function!(data, "ng", add_base_values!)
    _IM.modify_data_with_function!(data, "ng", make_per_unit!)

    # Assumes everything is in per unit.
    _IM.modify_data_with_function!(data, "ng", correct_f_bounds!)

    _IM.modify_data_with_function!(data, "ng", check_connectivity)
    _IM.modify_data_with_function!(data, "ng", check_status)
    _IM.modify_data_with_function!(data, "ng", check_edge_loops)

    _IM.modify_data_with_function!(data, "ng", check_global_parameters)
end
