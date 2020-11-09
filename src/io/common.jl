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
    _IM.modify_data_with_function!(data, _gm_it_name, check_non_negativity)
    _IM.modify_data_with_function!(data, _gm_it_name, correct_p_mins!)

    _IM.modify_data_with_function!(data, _gm_it_name, per_unit_data_field_check!)
    _IM.modify_data_with_function!(data, _gm_it_name, add_compressor_fields!)

    _IM.modify_data_with_function!(data, _gm_it_name, make_si_units!)
    _IM.modify_data_with_function!(data, _gm_it_name, add_base_values!)
    _IM.modify_data_with_function!(data, _gm_it_name, make_per_unit!)

    # Assumes everything is in per unit.
    _IM.modify_data_with_function!(data, _gm_it_name, correct_f_bounds!)

    _IM.modify_data_with_function!(data, _gm_it_name, check_connectivity)
    _IM.modify_data_with_function!(data, _gm_it_name, check_status)
    _IM.modify_data_with_function!(data, _gm_it_name, check_edge_loops)

    _IM.modify_data_with_function!(data, _gm_it_name, check_global_parameters)
end
