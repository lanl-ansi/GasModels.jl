#####################################################################
#                                                                   #
# This file provides functions for interfacing with .m data files   #
#                                                                   #
#####################################################################

"Parses the matlab gas data from either a filename or an IO object"
function parse_matlab(file::Union{IO, String})
    mlab_data = parse_m_file(file)
    gm_data = matlab_to_gasmodels(mlab_data)
    return gm_data
end


### Data and functions specific to the gas Matlab format ###

mlab_data_names = ["mgc.sound_speed", "mgc.temperature", "mgc.R",
    "mgc.compressibility_factor", "mgc.gas_molar_mass",
    "mgc.gas_specific_gravity", "mgc.specific_heat_capacity_ratio",
    "mgc.standard_density", "mgc.baseP", "mgc.baseF", "mgc.junction",
    "mgc.pipe", "mgc.compressor", "mgc.producer", "mgc.consumer",
    "mgc.junction_name"
]

mlab_junction_columns = [
    ("junction_i", Int),
    ("junction_type", Int),
    ("pmin", Float64), ("pmax", Float64),
    ("status", Int),
    ("p_nominal", Float64)
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
function parse_m_file(file_string::String)
    mp_data = open(file_string) do io
        parse_m_file(io)
    end

    return mp_data
end


""
function parse_m_file(io::IO)
    data_string = read(io, String)

    return parse_m_string(data_string)
end


""
function parse_m_string(data_string::String)
    matlab_data, func_name, colnames = parse_matlab_string(data_string, extended=true)

    case = Dict{String,Any}()

    if func_name != nothing
        case["name"] = func_name
    else
        warn(LOGGER,"no case name found in .m file.  The file seems to be missing \"function mgc = ...\"")
        case["name"] = "no_name_found"
    end

    case["source_type"] = ".m"
    if haskey(matlab_data, "mgc.version")
        case["source_version"] = VersionNumber(matlab_data["mgc.version"])
    else
        warn(LOGGER, "no case version found in .m file.  The file seems to be missing \"mgc.version = ...\"")
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
            error(LOGGER, string("no $constant found in .m file"))
        end
    end

    if haskey(matlab_data, "mgc.baseP")
        case["baseP"] = matlab_data["mgc.baseP"]
    else
        error(LOGGER, string("no baseP found in .m file.
            The file seems to be missing \"mgc.baseP = ...\" \n
            Typical value is a pmin in any of the junction"))
    end

    if haskey(matlab_data, "mgc.baseF")
        case["baseF"] = matlab_data["mgc.baseF"]
    else
        error(LOGGER, string("no baseF found in .m file.
            The file seems to be missing \"mgc.baseF = ...\" "))
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
        error(LOGGER, string("no junction table found in .m file.
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
        error(LOGGER, string("no pipe table found in .m file.
            The file seems to be missing \"mgc.pipe = [...];\""))
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
        error(LOGGER, string("no compressor table found in .m file.
            The file seems to be missing \"mgc.compressor = [...];\""))
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
            error(LOGGER, "incorrect .m file, the number of junction names
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
                info(LOGGER,"extending matlab format with data: $(case_name) $(length(tbl))x$(length(tbl[1])-1)")
            else
                case[case_name] = value
                info(LOGGER,"extending matlab format with constant data: $(case_name)")
            end
        end
    end

    return case
end

### Data and functions specific to GasModel format ###

"""
Converts a Matlab dict into a PowerModels dict
"""
function matlab_to_gasmodels(mlab_data::Dict{String,Any})
    gm_data = deepcopy(mlab_data)

    if !haskey(gm_data, "connection")
        gm_data["connection"] = []
    end
    if !haskey(gm_data, "multinetwork")
        gm_data["multinetwork"] = false
    end

    # translate component models
    mlab2gm_baseQ(gm_data)
    mlab2gm_producer(gm_data)
    mlab2gm_consumer(gm_data)
    mlab2gm_connection(gm_data)

    # merge data tables
    merge_junction_name_data(gm_data)
    merge_generic_data(gm_data)

    # use once available
    InfrastructureModels.arrays_to_dicts!(gm_data)

    return gm_data
end

"adds baseQ to the gas models data"
function mlab2gm_baseQ(data::Dict{String,Any})
    data["baseQ"] = data["baseF"] / data["standard_density"]
    delete!(data, "baseF")
end

"adds the volumetric firm and flexible flows for the producers"
function mlab2gm_producer(data::Dict{String,Any})
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
function mlab2gm_consumer(data::Dict{String,Any})
    consumers = [consumer for consumer in data["consumer"]]
    for consumer in consumers
        consumer["ql_junc"] = consumer["junction"]

        consumer["qlmin"] = 0
        consumer["qlmax"] = consumer["fd"] / data["standard_density"]
        consumer["ql"] = consumer["fd"] / data["standard_density"]

        delete!(consumer, "fd")
    end
end

"merges pipes and compressor to connections"
function mlab2gm_connection(data::Dict{String,Any})
    compressors = [compressor for compressor in data["compressor"]]
    for compressor in compressors
        compressor["qmin"] = compressor["fmin"] * data["standard_density"]
        compressor["qmax"] = compressor["fmax"] * data["standard_density"]
        delete!(compressor, "fmin")
        delete!(compressor, "fmax")
    end
end

"merges junction name data into junctions, if names exist"
function merge_junction_name_data(data::Dict{String,Any})
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
function merge_generic_data(data::Dict{String,Any})
    mlab_matrix_names = [name[5:length(name)] for name in mlab_data_names]

    key_to_delete = []
    for (k,v) in data
        if isa(v, Array)
            for mlab_name in mlab_matrix_names
                if startswith(k, "$(mlab_name)_")
                    mlab_matrix = data[mlab_name]
                    push!(key_to_delete, k)

                    if length(mlab_matrix) != length(v)
                        error(LOGGER,"failed to extend the matlab matrix \"$(mlab_name)\" with the matrix \"$(k)\" because they do not have the same number of rows, $(length(mlab_matrix)) and $(length(v)) respectively.")
                    end

                    info(LOGGER,"extending matlab format by appending matrix \"$(k)\" in to \"$(mlab_name)\"")

                    for (i, row) in enumerate(mlab_matrix)
                        merge_row = v[i]
                        delete!(merge_row, "index")
                        for key in keys(merge_row)
                            if haskey(row, key)
                                error(LOGGER, "failed to extend the matlab matrix \"$(mlab_name)\" with the matrix \"$(k)\" because they both share \"$(key)\" as a column name.")
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


" Get a default value for dict entry "
function get_default(dict, key, default=0.0)
    if haskey(dict, key) && dict[key] != NaN
        return dict[key]
    end
    return default
end
