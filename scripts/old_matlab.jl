using InfrastructureModels

#####################################################################
#                                                                   #
# This file provides functions for interfacing with .m data files   #
#                                                                   #
#####################################################################

"Parses the matlab gas data from either a filename or an IO object"
function parse_old_matlab(file::Union{IO, String})
    mlab_data = parse_old_m_file(file)
    gm_data = _old_matlab_to_gasmodels(mlab_data)
    return gm_data
end


### Data and functions specific to the gas Matlab format ###

mlab_data_names = ["mgc.sound_speed", "mgc.temperature", "mgc.R",
    "mgc.compressibility_factor", "mgc.gas_molar_mass",
    "mgc.gas_specific_gravity", "mgc.specific_heat_capacity_ratio",
    "mgc.standard_density", "mgc.baseP", "mgc.baseF", "mgc.junction",
    "mgc.pipe", "mgc.ne_pipe", "mgc.compressor", "mgc.ne_compressor",
    "mgc.producer", "mgc.consumer","mgc.junction_name", "mgc.per_unit"
]

mlab_junction_columns = [
    ("junction_i", Int),
    ("junction_type", Int),
    ("pmin", Float64), ("pmax", Float64),
    ("status", Int),
    ("p", Float64)
]

mlab_junction_name_columns = [
    ("junction_name", Union{String,SubString{String}})
]

mlab_pipe_columns = [
    ("pipline_i", Int),
    ("f_junction", Int),
    ("t_junction", Int),
    ("diameter", Float64),
    ("length", Float64),
    ("friction_factor", Float64),
    ("status", Int)
]

mlab_ne_pipe_columns = [
    ("pipline_i", Int),
    ("f_junction", Int),
    ("t_junction", Int),
    ("diameter", Float64),
    ("length", Float64),
    ("friction_factor", Float64),
    ("status", Int),
    ("construction_cost", Float64)
]

mlab_compressor_columns = [
    ("compressor_i", Int),
    ("f_junction", Int),
    ("t_junction", Int),
    ("c_ratio_min", Float64), ("c_ratio_max", Float64),
    ("power_max", Float64),
    ("fmin", Float64),
    ("fmax", Float64),
    ("status", Int)
]

mlab_ne_compressor_columns = [
    ("compressor_i", Int),
    ("f_junction", Int),
    ("t_junction", Int),
    ("c_ratio_min", Float64), ("c_ratio_max", Float64),
    ("power_max", Float64),
    ("fmin", Float64),
    ("fmax", Float64),
    ("status", Int),
    ("construction_cost", Float64)
]

mlab_producer_columns = [
    ("producer_i", Int),
    ("junction", Int),
    ("fg_min", Float64), ("fg_max", Float64),
    ("fg", Float64),
    ("status", Int),
    ("dispatchable", Int)
]

mlab_consumer_columns = [
    ("consumer_i", Int),
    ("junction", Int),
    ("fd", Float64),
    ("status", Float64),
    ("dispatchable", Int)
]


""
function parse_old_m_file(file_string::String)
    mp_data = open(file_string) do io
        parse_old_m_file(io)
    end

    return mp_data
end


""
function parse_old_m_file(io::IO)
    data_string = read(io, String)

    return parse_old_m_string(data_string)
end


""
function parse_old_m_string(data_string::String)
    matlab_data, func_name, colnames = InfrastructureModels.parse_matlab_string(data_string, extended=true)

    case = Dict{String,Any}()

    if func_name != nothing
        case["name"] = func_name
    else
        @warn "no case name found in .m file.  The file seems to be missing \"function mgc = ...\""
        case["name"] = "no_name_found"
    end

    case["source_type"] = ".m"
    if haskey(matlab_data, "mgc.version")
        case["source_version"] = VersionNumber(matlab_data["mgc.version"])
    else
        @warn  "no case version found in .m file.  The file seems to be missing \"mgc.version = ...\""
        case["source_version"] = "0.0.0+"
    end

    data_names = ["mgc.sound_speed", "mgc.temperature", "mgc.R",
    "mgc.compressibility_factor", "mgc.gas_molar_mass",
    "mgc.gas_specific_gravity", "mgc.specific_heat_capacity_ratio",
    "mgc.standard_density"]

    for data_name in data_names
        if haskey(matlab_data, data_name)
            case[data_name[5:end]] = matlab_data[data_name]
        else
            @error  string("no $constant found in .m file")
        end
    end

    if haskey(matlab_data, "mgc.baseP")
        case["baseP"] = matlab_data["mgc.baseP"]
    else
        Memento.error(_LOGGER, string("no baseP found in .m file.
            The file seems to be missing \"mgc.baseP = ...\" \n
            Typical value is a pmin in any of the junction"))
    end

    if haskey(matlab_data, "mgc.baseF")
        case["baseF"] = matlab_data["mgc.baseF"]
    else
        Memento.error(_LOGGER, string("no baseF found in .m file.
            The file seems to be missing \"mgc.baseF = ...\" "))
    end

    if haskey(matlab_data, "mgc.per_unit")
        case["per_unit"] = matlab_data["mgc.per_unit"] == 1 ? true : false
    else
        Memento.error(_LOGGER, string("no per_unit found in .m file.
            The file seems to be missing \"mgc.per_unit = ...\" "))
    end

    if haskey(matlab_data, "mgc.junction")
        junctions = []
        for junction_row in matlab_data["mgc.junction"]
            junction_data = InfrastructureModels.row_to_typed_dict(junction_row, mlab_junction_columns)
            junction_data["index"] = InfrastructureModels.check_type(Int, junction_row[1])
            push!(junctions, junction_data)
        end
        case["junction"] = junctions
    else
        Memento.error(_LOGGER, string("no junction table found in .m file.
            The file seems to be missing \"mgc.junction = [...];\""))
    end

    if haskey(matlab_data, "mgc.pipe")
        pipes = []
        for pipe_row in matlab_data["mgc.pipe"]
            pipe_data = InfrastructureModels.row_to_typed_dict(pipe_row, mlab_pipe_columns)
            pipe_data["index"] = InfrastructureModels.check_type(Int, pipe_row[1])
            push!(pipes, pipe_data)
        end
        case["pipe"] = pipes
    else
        Memento.error(_LOGGER, string("no pipe table found in .m file.
            The file seems to be missing \"mgc.pipe = [...];\""))
    end

    if haskey(matlab_data, "mgc.ne_pipe")
        ne_pipes = []
        for pipe_row in matlab_data["mgc.ne_pipe"]
            pipe_data = InfrastructureModels.row_to_typed_dict(pipe_row, mlab_ne_pipe_columns)
            pipe_data["index"] = InfrastructureModels.check_type(Int, pipe_row[1])
            push!(ne_pipes, pipe_data)
        end
        case["ne_pipe"] = ne_pipes
    end

    if haskey(matlab_data, "mgc.compressor")
        compressors = []
        for compressor_row in matlab_data["mgc.compressor"]
            compressor_data = InfrastructureModels.row_to_typed_dict(compressor_row, mlab_compressor_columns)
            compressor_data["index"] = InfrastructureModels.check_type(Int, compressor_row[1])
            push!(compressors, compressor_data)
        end
        case["compressor"] = compressors
    else
        Memento.error(_LOGGER, string("no compressor table found in .m file.
            The file seems to be missing \"mgc.compressor = [...];\""))
    end

    if haskey(matlab_data, "mgc.ne_compressor")
        ne_compressors = []
        for compressor_row in matlab_data["mgc.ne_compressor"]
            compressor_data = InfrastructureModels.row_to_typed_dict(compressor_row, mlab_ne_compressor_columns)
            compressor_data["index"] = InfrastructureModels.check_type(Int, compressor_row[1])
            push!(ne_compressors, compressor_data)
        end
        case["ne_compressor"] = ne_compressors
    end

    if haskey(matlab_data, "mgc.producer")
        producers = []
        for producer_row in matlab_data["mgc.producer"]
            producer_data = InfrastructureModels.row_to_typed_dict(producer_row, mlab_producer_columns)
            producer_data["index"] = InfrastructureModels.check_type(Int, producer_row[1])
            push!(producers, producer_data)
        end
        case["producer"] = producers
    end

    if haskey(matlab_data, "mgc.consumer")
        consumers = []
        for consumer_row in matlab_data["mgc.consumer"]
            consumer_data = InfrastructureModels.row_to_typed_dict(consumer_row, mlab_consumer_columns)
            consumer_data["index"] = InfrastructureModels.check_type(Int, consumer_row[1])
            push!(consumers, consumer_data)
        end
        case["consumer"] = consumers
    end

    if haskey(matlab_data, "mgc.junction_name")
        junction_names = []
        for (i, junction_name_row) in enumerate(matlab_data["mgc.junction_name"])
            junction_name_data = InfrastructureModels.row_to_typed_dict(junction_name_row, mlab_junction_name_columns)
            junction_name_data["index"] = i
            push!(junction_names, junction_name_data)
        end
        case["junction_name"] = junction_names

        if length(case["junction_name"]) != length(case["junction"])
            Memento.error(_LOGGER, "incorrect .m file, the number of junction names
                ($(length(case["junction_name"]))) is inconsistent with
                the number of junctions ($(length(case["junction"]))).\n")
        end
    end


    for k in keys(matlab_data)
        if !in(k, mlab_data_names) && startswith(k, "mgc.")
            case_name = k[5:length(k)]
            value = matlab_data[k]
            if isa(value, Array)
                column_names = []
                if haskey(colnames, k)
                    column_names = colnames[k]
                end
                tbl = []
                for (i, row) in enumerate(matlab_data[k])
                    row_data = InfrastructureModels.row_to_dict(row, column_names)
                    row_data["index"] = i
                    push!(tbl, row_data)
                end
                case[case_name] = tbl
                @info "extending matlab format with data: $(case_name) $(length(tbl))x$(length(tbl[1])-1)"
            else
                case[case_name] = value
                @info "extending matlab format with constant data: $(case_name)"
            end
        end
    end

    return case
end

### Data and functions specific to GasModel format ###

"""
Converts a Matlab dict into a PowerModels dict
"""
function _old_matlab_to_gasmodels(mlab_data::Dict{String,Any})
    gm_data = deepcopy(mlab_data)

    if !haskey(gm_data, "connection")
        gm_data["connection"] = []
    end
    if !haskey(gm_data, "multinetwork")
        gm_data["multinetwork"] = false
    end

    # translate component models
    _old_mlab2gm_baseQ!(gm_data)
    _old_mlab2gm_producer!(gm_data)
    _old_mlab2gm_consumer!(gm_data)
    _old_mlab2gm_conmpressor!(gm_data)
    _old_mlab2gm_ne_compressor!(gm_data)

    # merge data tables
    _old_merge_junction_name_data!(gm_data)
    _old_merge_generic_data!(gm_data)

    # use once available
    InfrastructureModels.arrays_to_dicts!(gm_data)

    return gm_data
end

"adds baseQ to the gas models data"
function _old_mlab2gm_baseQ!(data::Dict{String,Any})
    data["baseQ"] = data["baseF"] / data["standard_density"]
    delete!(data, "baseF")
end

"adds the volumetric firm and flexible flows for the producers"
function _old_mlab2gm_producer!(data::Dict{String,Any})
    producers = [producer for producer in data["producer"]]
    for producer in producers
        producer["qg_junc"] = producer["junction"]
        producer["qgmin"]  = producer["fg_min"] / data["standard_density"]
        producer["qgmax"]  = producer["fg_max"] / data["standard_density"]
        producer["qg"]     = producer["fg"] / data["standard_density"]
        delete!(producer, "fg")
        delete!(producer, "fg_min")
        delete!(producer, "fg_max")
    end
end

"adds the volumetric firm and flexible flows for the consumers"
function _old_mlab2gm_consumer!(data::Dict{String,Any})
    consumers = [consumer for consumer in data["consumer"]]
    for consumer in consumers
        consumer["ql_junc"] = consumer["junction"]

        consumer["qlmin"] = 0
        consumer["qlmax"] = consumer["fd"] / data["standard_density"]
        consumer["ql"] = consumer["fd"] / data["standard_density"]

        delete!(consumer, "fd")
    end
end

"converts compressor q values to f"
function _old_mlab2gm_conmpressor!(data::Dict{String,Any})
    compressors = [compressor for compressor in data["compressor"]]
    for compressor in compressors
        compressor["qmin"] = compressor["fmin"] * data["standard_density"]
        compressor["qmax"] = compressor["fmax"] * data["standard_density"]
        delete!(compressor, "fmin")
        delete!(compressor, "fmax")
    end
end

"converts ne_compressor q values to f"
function _old_mlab2gm_ne_compressor!(data::Dict{String,Any})
    if (haskey(data, "ne_compressor"))
        compressors = [compressor for compressor in data["ne_compressor"]]
        for compressor in compressors
            compressor["qmin"] = compressor["fmin"] * data["standard_density"]
            compressor["qmax"] = compressor["fmax"] * data["standard_density"]
            delete!(compressor, "fmin")
            delete!(compressor, "fmax")
        end
    end
end

"merges junction name data into junctions, if names exist"
function _old_merge_junction_name_data!(data::Dict{String,Any})
    if haskey(data, "junction_name")
        # can assume same length is same as junction
        # this is validated during .m file parsing
        for (i, junction_name) in enumerate(data["junction_name"])
            junction = data["junction"][i]
            delete!(junction_name, "index")

            check_keys(junction, keys(junction_name))
            merge!(junction, junction_name)
        end
        delete!(data, "junction_name")
    end
end


"merges Matlab tables based on the table extension syntax"
function _old_merge_generic_data!(data::Dict{String,Any})
    mlab_matrix_names = [name[5:length(name)] for name in mlab_data_names]

    key_to_delete = []
    for (k,v) in data
        if isa(v, Array)
            for mlab_name in mlab_matrix_names
                if startswith(k, "$(mlab_name)_")
                    mlab_matrix = data[mlab_name]
                    push!(key_to_delete, k)

                    if length(mlab_matrix) != length(v)
                        @error "failed to extend the matlab matrix \"$(mlab_name)\" with the matrix \"$(k)\" because they do not have the same number of rows, $(length(mlab_matrix)) and $(length(v)) respectively."
                    end

                    @info "extending matlab format by appending matrix \"$(k)\" in to \"$(mlab_name)\""

                    for (i, row) in enumerate(mlab_matrix)
                        merge_row = v[i]
                        delete!(merge_row, "index")
                        for key in keys(merge_row)
                            if haskey(row, key)
                                @error  "failed to extend the matlab matrix \"$(mlab_name)\" with the matrix \"$(k)\" because they both share \"$(key)\" as a column name."
                            end
                            row[key] = merge_row[key]
                        end
                    end

                    break # out of mlab_matrix_names loop
                end
            end

        end
    end

    for key in key_to_delete
        delete!(data, key)
    end
end


"Get a default value for dict entry"
function _old_get_default(dict, key, default=0.0)
    if haskey(dict, key) && dict[key] != NaN
        return dict[key]
    end
    return default
end


"order data types should appear in matlab format"
const _matlab_data_order = ["junction", "pipe", "compressor", "short_pipe", "resistor", "regulator", "valve", "receipt", "delivery", "transfer", "storage"]


"order data fields should appear in matlab format"
const _matlab_field_order = Dict{String,Array}(
    "junction"      => ["id", "type", "pressure_lb", "pressure_ub", "pressure", "status"],
    "pipe"          => ["id", "fr_junction", "to_junction", "diameter", "length", "friction_factor", "status"],
    "compressor"    => ["id", "fr_junction", "to_junction", "compression_ratio_lb", "compression_ratio_ub", "power_ub", "flow_lb", "flow_ub", "status"],
    "short_pipe"    => ["id", "fr_junction", "to_junction", "status"],
    "resistor"      => ["id", "fr_junction", "to_junction", "drag", "status"],
    "regulator"     => ["id", "fr_junction", "to_junction", "reduction_factor_lb", "reduction_factor_ub", "flow_lb", "flow_ub", "status"],
    "valve"         => ["id", "fr_junction", "to_junction", "status"],
    "receipt"       => ["id", "junction", "flow_lb", "flow_ub", "flow", "dispatchable", "status"],
    "delivery"      => ["id", "junction", "flow_lb", "flow_ub", "flow", "dispatchable", "status"],
    "transfer"      => ["id", "junction", "flow_lb", "flow_ub", "flow", "dispatchable", "status"],
    "storage"       => ["id", "junction", "pressure", "compression_ratio_ub", "power_ub", "flow_injection_lb", "flow_injection_ub", "flow_withdrawl_lb", "flow_withdrawl_ub", "capacity", "status"]
)


"order of required global parameters"
const _matlab_global_params_order_required = ["specific_gravity", "specific_heat_capacity_ratio", "temperature", "compressibility_factor", "R", "sound_speed", "molar_mass"]


"order of optional global parameters"
const _matlab_global_params_order_optional = ["standard_density", "base_pressure", "base_flow", "per_unit"]


"fields that are unitless when per_unit == true"
const _per_unit_fields = ["pressure", "pressure_lb", "pressure_ub", "flow_lb", "flow_ub", "flow", "flow_injection_lb", "flow_injection_ub", "flow_withdrawl_lb", "flow_withdrawl_ub"]


"list of units of data fields for si and english"
const _units = Dict{String,Dict{String,String}}(
    "si" => Dict{String,String}(
        "specific_gravity" => "unitless",
        "specific_heat_capacity_ratio" => "unitless",
        "temperature" => "K",
        "compressibility_factor" => "unitless",
        "R" => "J/(mol K)",
        "sound_speed" => "m/s",
        "molar_mass" => "kg/mol",
        "standard_density" => "kg/m^3",
        "base_pressure" => "Pa",
        "base_flow" => "kg/s",
        "pressure_lb" => "Pa",
        "pressure_ub" => "Pa",
        "pressure" => "Pa",
        "diameter" => "m",
        "length" => "m",
        "friction_factor" => "unitless",
        "compression_ratio_lb" => "unitless",
        "compression_ratio_ub" => "unitless",
        "power_ub" => "W",
        "flow_lb" => "kg/s",
        "flow_ub" => "kg/s",
        "flow_injection_lb" => "kg/s",
        "flow_injection_ub" => "kg/s",
        "flow_withdrawl_lb" => "kg/s",
        "flow_withdrawl_ub" => "kg/s",
        "flow" => "kg/s",
        "drag" => "unitless",
        "reduction_factor_lb" => "unitless",
        "reduction_factor_ub" => "unitless",
        "capacity" => "m^3"
    ),
    "english" => Dict{String,String}(
        "specific_gravity" => "unitless",
        "specific_heat_capacity_ratio" => "unitless",
        "temperature" => "deg. C",
        "compressibility_factor" => "unitless",
        "R" => "?",
        "sound_speed" => "mph",
        "molar_mass" => "kg/mol",
        "standard_density" => "kg/m^3",
        "base_pressure" => "psi",
        "base_flow" => "mmscfd",
        "units" => "english",
        "pressure_lb" => "psi",
        "pressure_ub" => "psi",
        "pressure" => "psi",
        "diameter" => "inches",
        "length" => "miles",
        "friction_factor" => "unitless",
        "compression_ratio_lb" => "unitless",
        "compression_ratio_ub" => "unitless",
        "power_ub" => "hp",
        "flow_lb" => "mmscfd",
        "flow_ub" => "mmscfd",
        "flow_injection_lb" => "mmscfd",
        "flow_injection_ub" => "mmscfd",
        "flow_withdrawl_lb" => "mmscfd",
        "flow_withdrawl_ub" => "mmscfd",
        "flow" => "mmscfd",
        "drag" => "unitless",
        "reduction_factor_lb" => "unitless",
        "reduction_factor_ub" => "unitless",
        "capacity" => "mmscf"
    )
)


"write to matlab"
function _gasmodels_to_matlab_string(data::Dict{String,Any}; units::String="si", include_extended::Bool=false)::String
    lines = ["function mgc = $(replace(data["name"], " " => "_"))", ""]

    push!(lines, "%% required global data")
    for param in _matlab_global_params_order_required
        line = "mgc.$(param) = $(data[param]);"
        if haskey(_units[units], param)
            line = "$line  % $(_units[units][param])"
        end

        push!(lines, line)
    end
    push!(lines, "mgc.units = \"$units\";")
    push!(lines, "")

    if any(haskey(data, param) for param in _matlab_global_params_order_optional)
        push!(lines, "%% optional global data")
        for param in _matlab_global_params_order_optional
            if haskey(data, param)
                if !get(data, "per_unit", false) && param in ["base_pressure", "base_flow", "per_unit"]
                    continue
                else
                    line = "mgc.$(param) = $(data[param]);"

                    if haskey(_units[units], param)
                        line = "$line  % $(_units[units][param])"
                    end

                    push!(lines, line)
                end
            end
        end

        push!(lines, "")
    end

    for data_type in _matlab_data_order
        if haskey(data, data_type)
            push!(lines, "%% $data_type data")
            fields_header = []
            for field in _matlab_field_order[data_type]
                if haskey(_units[units], field)
                    field = "$field ($(get(data, "per_unit", false) && field in _per_unit_fields ? "unitless" : _units[units][field]))"
                end
                push!(fields_header, field)
            end

            push!(lines, "% $(join(fields_header, "\t\t"))")

            push!(lines, "mgc.$data_type = [")
            idxs = [parse(Int, i) for i in keys(data[data_type])]
            if !isempty(idxs)
                for i in sort(idxs)
                    push!(lines, "\t$(join([data[data_type]["$i"][field] for field in _matlab_field_order[data_type]], "\t\t"))")
                end
            end
            push!(lines, "];\n")
        end
    end

    if include_extended
        for data_type in _matlab_data_order
            if haskey(data, data_type)
                push!(lines, "%% $data_type data (extended)")
                all_ext_cols = Set([col for cols in keys(values(data[data_type])) for col in cols if !(col in _matlab_field_order[data_type])])
                common_ext_cols = [col for col in all_ext_cols if all(col in keys(item) for item in values(data[data_type]))]

                if !isempty(common_ext_cols)
                    push!(lines, "%column_names% $(join(common_ext_cols, "\t"))")
                    push!(lines, "mgc.$(data_type)_data = [")
                    for i in sort([parse(Int, i) for i in keys(data[data_type])])
                        push!(lines, "\t$(join([data[data_type]["$i"][col] for col in sort(common_ext_cols)], "\t"))")
                    end
                    push!(lines, "];\n")
                end
            end
        end
    end

    push!(lines, "end\n")

    return join(lines, "\n")
end


"writes data structure to matlab format"
function write_matlab!(data::Dict{String,Any}, fileout::String; units::String="si", include_extended::Bool=false)
    open(fileout, "w") do f
        write(f, _gasmodels_to_matlab_string(data; units=units, include_extended=include_extended))
    end
end
