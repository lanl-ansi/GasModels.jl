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
    check_non_negativity(data)
    check_non_zero(data)
    check_rouge_junction_ids(data)
    correct_p_mins!(data)

    per_unit_data_field_check!(data)
    add_compressor_fields!(data)

    make_si_units!(data)
    # select_largest_component!(data)
    propagate_topology_status!(data)
    add_base_values!(data)
    make_per_unit!(data)

    # Assumes everything is in per unit.
    correct_f_bounds!(data)

    check_connectivity(data)
    check_status(data)
    check_edge_loops(data)
    check_global_parameters(data)
end
