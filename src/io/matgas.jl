"Parses the matgas data from either a filename or an IO object"
function parse_matgas(file::Union{IO, String})
    mg_data = parse_m_file(file)
    gm_data = _matgas_to_gasmodels(mg_data)
    return gm_data
end


const _mg_data_names = [
    "mgc.gas_specific_gravity", "mgc.specific_heat_capacity_ratio",
    "mgc.temperature", "mgc.sound_speed", "mgc.compressibility_factor", "mgc.R",
    "mgc.base_pressure", "mgc.base_length",
    "mgc.units", "mgc.is_per_unit",
    "mgc.junction", "mgc.pipe",
    "mgc.compressor", "mgc.receipt",
    "mgc.delivery", "mgc.transfer",
    "mgc.short_pipe", "mgc.resistor",
    "mgc.regulator", "mgc.valve",
    "mgc.storage", "mgc.ne_pipe",
    "mgc.ne_compressor"
]

const _mg_junction_columns = [
    ("id", Int),
    ("p_min", Float64), ("p_max", Float64), ("p_nominal", Float64),
    ("junction_type", Int),
    ("status", Int),
    ("pipeline_name", Union{String,SubString{String}}),
    ("edi_id", Union{Int,String,SubString{String}}),
    ("lat", Float64),
    ("lon", Float64)
]

const _mg_pipe_columns = [
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("diameter", Float64),
    ("length", Float64),
    ("friction_factor", Float64),
    ("p_min", Float64), ("p_max", Float64),
    ("status", Int),
    ("is_bidirectional", Int),
    ("pipeline_name", Union{String,SubString{String}}),
    ("num_spatial_discretization_points", Int)
]

const _mg_compressor_columns = [
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("c_ratio_min", Float64), ("c_ratio_max", Float64),
    ("power_max", Float64),
    ("flow_min", Float64), ("flow_max", Float64),
    ("inlet_p_min", Float64), ("inlet_p_max", Float64),
    ("outlet_p_min", Float64), ("outlet_p_max", Float64),
    ("status", Int),
    ("operating_cost", Float64),
    ("directionality", Int),
    ("compressor_station_name", Union{String, SubString{String}}),
    ("pipeline_name", Union{String, SubString{String}}),
    ("total_installed_power", Float64),
    ("num_compressor_units", Int),
    ("compressor_type", SubString{String}),
    ("design_suction_pressure", Float64),
    ("design_discharge_pressure", Float64),
    ("max_compressed_volume", Float64),
    ("design_fuel_required", Float64),
    ("design_electric_power_required", Float64),
    ("num_units_for_peak_service", Int),
    ("peak_year", Int)
]

const _mg_short_pipe_columns = [
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("status", Int),
    ("is_bidirectional", Int),
    ("pipeline_name", Union{String, SubString{String}})
]

const _mg_resistor_columns = [
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("drag", Float64),
    ("diameter", Float64),
    ("status", Int),
    ("is_bidirectional", Int),
    ("pipeline_name", Union{String, SubString{String}})
]

const _mg_transfer_columns = [
    ("id", Int),
    ("junction_id", Int),
    ("withdrawal_min", Float64), ("withdrawal_max", Float64),
    ("withdrawal_nominal", Float64),
    ("is_dispatchable", Int),
    ("status", Int),
    ("bid_price", Float64), ("offer_price", Float64),
    ("exchange_point_name", Union{String, SubString{String}}),
    ("pipeline_name", Union{String, SubString{String}}),
    ("other_pipeline_name", Union{String, SubString{String}}),
    ("design_pressure", Float64),
    ("meter_capacity", Float64),
    ("daily_scheduled_flow", Float64)
]

const _mg_receipt_columns = [
    ("id", Int),
    ("junction_id", Int),
    ("injection_min", Float64), ("injection_max", Float64),
    ("injection_nominal", Float64),
    ("is_dispatchable", Int),
    ("status", Int),
    ("offer_price", Float64),
    ("name", Union{String, SubString{String}}),
    ("company_name", Union{String, SubString{String}}),
    ("daily_scheduled_flow", Float64),
    ("design_capacity", Float64),
    ("operating_capacity", Float64),
    ("is_firm", Int),
    ("edi_id", Union{Int, String, SubString{String}})
]

const _mg_delivery_columns = [
    ("id", Int),
    ("junction_id", Int),
    ("withdrawal_min", Float64), ("withdrawal_max", Float64),
    ("withdrawal_nominal", Float64),
    ("is_dispatchable", Int),
    ("status", Int),
    ("bid_price", Float64),
    ("name", Union{String, SubString{String}}),
    ("company_name", Union{String, SubString{String}}),
    ("daily_scheduled_flow", Float64),
    ("design_capacity", Float64),
    ("operating_capacity", Float64),
    ("is_firm", Int),
    ("edi_id", Union{Int, String, SubString{String}})
]

const _mg_regulator_columns = [
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("reduction_factor_min", Float64), ("reduction_factor_max", Float64),
    ("flow_min", Float64), ("flow_max", Float64),
    ("status", Int),
    ("directionality", Int),
    ("discharge_coefficient", Float64),
    ("design_flow_rate", Float64),
    ("design_inlet_pressure", Float64),
    ("design_outlet_pressure", Float64),
    ("pipeline_name", Union{String, SubString{String}})
]

const _mg_valve_columns = [
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("status", Int),
    ("flow_coefficient", Float64),
    ("pipeline_name", Union{String, SubString{String}})
]

const _mg_storage_columns = [
    ("id", Int),
    ("junction_id", Int),
    ("pressure_nominal", Float64),
    ("flow_injection_rate_min", Float64), ("flow_injection_rate_max", Float64),
    ("flow_withdrawal_rate_min", Float64), ("flow_withdrawal_rate_max", Float64),
    ("capacity", Float64),
    ("status", Int),
    ("name", Union{String, SubString{String}}),
    ("owner_name", Union{String, SubString{String}}),
    ("storage_type", Union{String, SubString{String}}),
    ("daily_withdrawal_max", Float64),
    ("seasonal_withdrawal_max", Float64),
    ("base_gas_capacity", Float64),
    ("working_gas_capacity", Float64),
    ("total_field_capacity", Float64),
    ("edi_id", Union{Int, String, SubString{String}})
]


"parses matlab-formatted .m file"
function parse_m_file(file_string::String)
    mg_data = open(file_string) do io
        parse_m_file(io)
    end

    return mg_data
end


"parses matlab-formatted .m file"
function parse_m_file(io::IO)
    data_string = read(io, String)

    return parse_m_string(data_string)
end


"parses matlab-format string"
function parse_m_string(data_string::String)
    matlab_data, func_name, colnames = InfrastructureModels.parse_matlab_string(data_string, extended=true)

    case = Dict{String,Any}()

    if func_name != nothing
        case["name"] = func_name
    else
        Memento.warn(_LOGGER,"no case name found in .m file.  The file seems to be missing \"function mgc = ...\"")
        case["name"] = "no_name_found"
    end

    case["source_type"] = ".m"
    if haskey(matlab_data, "mgc.version")
        case["source_version"] = VersionNumber(matlab_data["mgc.version"])
    else
        Memento.warn(_LOGGER, "no case version found in .m file.  The file seems to be missing \"mgc.version = ...\"")
        case["source_version"] = "0.0.0+"
    end

    required_metadata_names = ["mgc.gas_specific_gravity", "mgc.specific_heat_capacity_ratio", "mgc.temperature", "mgc.compressibility_factor", "mgc.units"]

    optional_metadata_names = ["mgc.sound_speed", "mgc.R", "mgc.base_pressure", "mgc.base_length", "mgc.is_per_unit"]

    for data_name in required_metadata_names
        (data_name == "mgc.units") && (continue)
        if haskey(matlab_data, data_name)
            case[data_name[5:end]] = matlab_data[data_name]
        else
            Memento.error(_LOGGER, string("no $constant found in .m file"))
        end
    end

    if haskey(matlab_data, "mgc.units")
        case["units"] = matlab_data["mgc.units"]
        if matlab_data["mgc.units"] == "si"
            case["is_si_units"] = 1
            case["is_english_units"] = 0
        elseif matlab_data["mgc.units"] == "usc"
            case["is_english_units"] = 1
            case["is_si_units"] = 0
        else
            Memento.error(_LOGGER, string("the possible values for units field in .m file are \"si\" or \"usc\""))
        end
    else
        Memento.error(_LOGGER, string("no units field found in .m file.
        The file seems to be missing \"mgc.units = ...;\" \n
        Possible values are 1 (SI) or 2 (English units)"))
    end

    # handling optional meta data names
    if haskey(matlab_data, "mgc.base_pressure")
        case["base_pressure"] = matlab_data["mgc.base_pressure"]
    else
        Memento.warn(_LOGGER, string("no base_pressure found in .m file.
            This value will be auto-assigned based on the pressure limits provided in the data"))
    end

    if haskey(matlab_data, "mgc.base_length")
        case["base_length"] = matlab_data["mgc.base_length"]
    else
        Memento.warn(_LOGGER, string("no base_length found in .m file.
            This value will be auto-assigned based on the pipe data"))
    end

    if haskey(matlab_data, "mgc.is_per_unit")
        case["is_per_unit"] = matlab_data["mgc.is_per_unit"]
    else
        Memento.warn(_LOGGER, string("no is_per_unit found in .m file.
            Auto assigning a value of 0 (false) for the is_per_unit field"))
        case["is_per_unit"] = 0
    end

    if haskey(matlab_data, "mgc.R")
        case["R"] = matlab_data["mgc.R"]
    else
        case["R"] = 8.314
    end

    if haskey(matlab_data, "mgc.sound_speed")
        case["sound_speed"] = matlab_data["mgc.sound_speed"]
    else
        # v = sqrt(gamma * R * T / M)
        molecular_mass_of_air = 0.02896 # kg/mol
        gamma = case["specific_heat_capacity_ratio"]
        T = case["temperature"] # K
        R = case["R"] # J/mol/K
        case["sound_speed"] = round(sqrt(gamma * R * T / molecular_mass_of_air), digits=3) # m/s
    end

    if haskey(matlab_data, "mgc.junction")
        junctions = []
        for junction_row in matlab_data["mgc.junction"]
            junction_data = InfrastructureModels.row_to_typed_dict(junction_row, _mg_junction_columns)
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
            pipe_data = InfrastructureModels.row_to_typed_dict(pipe_row, _mg_pipe_columns)
            pipe_data["index"] = InfrastructureModels.check_type(Int, pipe_row[1])
            push!(pipes, pipe_data)
        end
        case["pipe"] = pipes
    else
        Memento.error(_LOGGER, string("no pipe table found in .m file.
            The file seems to be missing \"mgc.pipe = [...];\""))
    end

    if haskey(matlab_data, "mgc.compressor")
        compressors = []
        for compressor_row in matlab_data["mgc.compressor"]
            compressor_data = InfrastructureModels.row_to_typed_dict(compressor_row, _mg_compressor_columns)
            compressor_data["index"] = InfrastructureModels.check_type(Int, compressor_row[1])
            push!(compressors, compressor_data)
        end
        case["compressor"] = compressors
    else
        Memento.error(_LOGGER, string("no compressor table found in .m file.
            The file seems to be missing \"mgc.compressor = [...];\""))
    end

    if haskey(matlab_data, "mgc.short_pipe")
        short_pipes = []
        for short_pipe_row in matlab_data["mgc.short_pipe"]
            short_pipe_data = InfrastructureModels.row_to_typed_dict(short_pipe_row, _mg_short_pipe_columns)
            short_pipe_data["index"] = InfrastructureModels.check_type(Int, short_pipe_row[1])
            push!(short_pipes, short_pipe_data)
        end
        case["short_pipe"] = short_pipes
    end

    if haskey(matlab_data, "mgc.resistor")
        resistors = []
        for resistor_row in matlab_data["mgc.resistor"]
            resistor_data = InfrastructureModels.row_to_typed_dict(resistor_row, _mg_resistor_columns)
            resistor_data["index"] = InfrastructureModels.check_type(Int, resistor_row[1])
            push!(resistors, resistor_data)
        end
        case["resistor"] = resistors
    end

    if haskey(matlab_data, "mgc.transfer")
        transfers = []
        for transfer_row in matlab_data["mgc.transfer"]
            transfer_data = InfrastructureModels.row_to_typed_dict(transfer_row, _mg_transfer_columns)
            transfer_data["index"] = InfrastructureModels.check_type(Int, transfer_row[1])
            push!(transfers, transfer_data)
        end
        case["transfer"] = transfers
    end

    if haskey(matlab_data, "mgc.receipt")
        receipts = []
        for receipt_row in matlab_data["mgc.receipt"]
            receipt_data = InfrastructureModels.row_to_typed_dict(receipt_row, _mg_receipt_columns)
            receipt_data["index"] = InfrastructureModels.check_type(Int, receipt_row[1])
            push!(receipts, receipt_data)
        end
        case["receipt"] = receipts
    end

    if haskey(matlab_data, "mgc.delivery")
        deliveries = []
        for delivery_row in matlab_data["mgc.delivery"]
            delivery_data = InfrastructureModels.row_to_typed_dict(delivery_row, _mg_delivery_columns)
            delivery_data["index"] = InfrastructureModels.check_type(Int, delivery_row[1])
            push!(deliveries, delivery_data)
        end
        case["delivery"] = deliveries
    end

    if haskey(matlab_data, "mgc.regulator")
        regulators = []
        for regulator_row in matlab_data["mgc.regulator"]
            regulator_data = InfrastructureModels.row_to_typed_dict(regulator_row, _mg_regulator_columns)
            regulator_data["index"] = InfrastructureModels.check_type(Int, regulator_row[1])
            push!(regulators, regulator_data)
        end
        case["regulator"] = regulators
    end

    if haskey(matlab_data, "mgc.valve")
        valves = []
        for valve_row in matlab_data["mgc.valve"]
            valve_data = InfrastructureModels.row_to_typed_dict(valve_row, _mg_valve_columns)
            valve_data["index"] = InfrastructureModels.check_type(Int, valve_row[1])
            push!(valves, valve_data)
        end
        case["valve"] = valves
    end

    if haskey(matlab_data, "mgc.storage")
        storages = []
        for storage_row in matlab_data["mgc.storage"]
            storage_data = InfrastructureModels.row_to_typed_dict(storage_row, _mg_storage_columns)
            storage_data["index"] = InfrastructureModels.check_type(Int, storage_row[1])
            push!(regulators, storage_data)
        end
        case["storage"] = storages
    end


    for k in keys(matlab_data)
        if !in(k, _mg_data_names) && startswith(k, "mgc.")
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
                Memento.info(_LOGGER,"extending matlab format with data: $(case_name) $(length(tbl))x$(length(tbl[1])-1)")
            else
                case[case_name] = value
                Memento.info(_LOGGER,"extending matlab format with constant data: $(case_name)")
            end
        end
    end

    return case
end


"Converts a matgas dict into a PowerModels dict"
function _matgas_to_gasmodels(mg_data::Dict{String,Any})
    gm_data = deepcopy(mg_data)

    if !haskey(gm_data, "multinetwork")
        gm_data["multinetwork"] = false
    end

    # translate component models
    _merge_generic_data!(gm_data)

    # use once available
    InfrastructureModels.arrays_to_dicts!(gm_data)

    return gm_data
end


"merges Matlab tables based on the table extension syntax"
function _merge_generic_data!(data::Dict{String,Any})
    mg_matrix_names = [name[5:length(name)] for name in _mg_data_names]

    key_to_delete = []
    for (k,v) in data
        if isa(v, Array)
            for mg_name in mg_matrix_names
                if startswith(k, "$(mg_name)_")
                    mg_matrix = data[mg_name]
                    push!(key_to_delete, k)

                    if length(mg_matrix) != length(v)
                        Memento.error(_LOGGER,"failed to extend the matlab matrix \"$(mg_name)\" with the matrix \"$(k)\" because they do not have the same number of rows, $(length(mg_matrix)) and $(length(v)) respectively.")
                    end

                    Memento.info(_LOGGER,"extending matlab format by appending matrix \"$(k)\" in to \"$(mg_name)\"")

                    for (i, row) in enumerate(mg_matrix)
                        merge_row = v[i]
                        delete!(merge_row, "index")
                        for key in keys(merge_row)
                            if haskey(row, key)
                                Memento.error(_LOGGER, "failed to extend the matlab matrix \"$(mg_name)\" with the matrix \"$(k)\" because they both share \"$(key)\" as a column name.")
                            end
                            row[key] = merge_row[key]
                        end
                    end

                    break # out of mg_matrix_names loop
                end
            end

        end
    end

    for key in key_to_delete
        delete!(data, key)
    end
end


"Get a default value for dict entry"
function _get_default(dict, key, default=0.0)
    if haskey(dict, key) && dict[key] != NaN
        return dict[key]
    end
    return default
end


"order data types should appear in matlab format"
const _matlab_data_order = ["junction", "pipe", "compressor", "short_pipe", "resistor", "regulator", "valve", "receipt", "delivery", "transfer", "storage"]


"order data fields should appear in matlab format"
const _matlab_field_order = Dict{String,Array}(
    "junction"      => [entry[1] for entry in _mg_junction_columns],
    "pipe"          => [entry[1] for entry in _mg_pipe_columns],
    "compressor"    => [entry[1] for entry in _mg_compressor_columns],
    "short_pipe"    => [entry[1] for entry in _mg_short_pipe_columns],
    "resistor"      => [entry[1] for entry in _mg_resistor_columns],
    "regulator"     => [entry[1] for entry in _mg_regulator_columns],
    "valve"         => [entry[1] for entry in _mg_valve_columns],
    "receipt"       => [entry[1] for entry in _mg_receipt_columns],
    "delivery"      => [entry[1] for entry in _mg_delivery_columns],
    "transfer"      => [entry[1] for entry in _mg_transfer_columns],
    "storage"       => [entry[1] for entry in _mg_storage_columns]
)


"order of required global parameters"
const _matlab_global_params_order_required = ["gas_specific_gravity", "specific_heat_capacity_ratio", "temperature", "compressibility_factor"]


"order of optional global parameters"
const _matlab_global_params_order_optional = ["sound_speed", "R", "base_pressure", "base_length", "is_per_unit"]


"list of units of meta data fields"
const _units = Dict{String,Dict{String,String}}(
    "si" => Dict{String,String}(
        "specific_gravity" => "unitless",
        "specific_heat_capacity_ratio" => "unitless",
        "temperature" => "K",
        "compressibility_factor" => "unitless",
        "R" => "J/(mol K)",
        "sound_speed" => "m/s",
        "base_pressure" => "Pa",
        "base_length" => "m",
    ),
    "english" => Dict{String,String}(
        "specific_gravity" => "unitless",
        "specific_heat_capacity_ratio" => "unitless",
        "temperature" => "K",
        "compressibility_factor" => "unitless",
        "R" => "J/(mol K)",
        "sound_speed" => "m/s",
        "base_pressure" => "psi",
        "base_length" => "miles",
    )
)

const non_negative_metadata = [
    "gas_specific_gravity", "specific_heat_capacity_ratio",
    "temperature", "sound_speed", "compressibility_factor"
]

const non_negative_data = Dict{String,Vector{String}}(
    "junction" => ["p_min", "p_max", "p_nominal"],
    "pipe" => ["diameter", "length", "friction_factor", "p_min", "p_max"],
    "compressor" => ["c_ratio_min", "c_ratio_max", "power_max", "flow_max",
        "inlet_p_min", "inlet_p_max", "outlet_p_min", "outlet_p_max", "operating_cost"],
    "resistor" => ["drag", "diameter"],
    "transfer" => ["bid_price", "offer_price"],
    "receipt" => ["injection_min", "injection_max", "injection_nominal", "offer_price"],
    "delivery" => ["withdrawal_min", "withdrawal_max", "withdrawal_nominal", "bid_price"],
    "storage" => ["pressure_nominal", "flow_injection_rate_min", "flow_injection_rate_max",
        "flow_withdrawal_rate_min", "flow_withdrawal_rate_max", "capacity"]
)


"write to matgas"
function _gasmodels_to_matgas_string(data::Dict{String,Any}; units::String="si", include_extended::Bool=false)::String
    (data["is_english_units"] == true) && (units = "usc")
    lines = ["function mgc = $(replace(data["name"], " " => "_"))", ""]

    push!(lines, "%% required global data")
    for param in _matlab_global_params_order_required
        if isa(data[param], Float64)
            line = Printf.@sprintf "mgc.%s = %.4f;" param data[param]
        else
            line = "mgc.$(param) = $(data[param]);"
        end
        if haskey(_units[units], param)
            line = "$line  % $(_units[units][param])"
        end

        push!(lines, line)
    end
    push!(lines, "mgc.units = \'$units\';")
    push!(lines, "")

    push!(lines, "%% optional global data (that was either provided or computed based on required global data)")
    for param in _matlab_global_params_order_optional
        if isa(data[param], Float64)
            line = Printf.@sprintf "mgc.%s = %.4f;" param data[param]
        else
            line = "mgc.$(param) = $(data[param]);"
        end
        if haskey(_units[units], param)
            line = "$line  % $(_units[units][param])"
        end

        push!(lines, line)
    end
    push!(lines, "")

    for data_type in _matlab_data_order
        if haskey(data, data_type)
            push!(lines, "%% $data_type data")
            fields_header = []
            for field in _matlab_field_order[data_type]
                idxs = [parse(Int, i) for i in keys(data[data_type])]
                if !isempty(idxs)
                    check_id = idxs[1]
                    if haskey(data[data_type]["$check_id"], field)
                        push!(fields_header, field)
                    end
                end
            end
            push!(lines, "% $(join(fields_header, "\t"))")

            push!(lines, "mgc.$data_type = [")
            idxs = [parse(Int, i) for i in keys(data[data_type])]
            if !isempty(idxs)
                for i in sort(idxs)
                    entries = []
                    for field in fields_header
                        if haskey(data[data_type]["$i"], field)
                            if isa(data[data_type]["$i"][field], Union{String, SubString{String}})
                                push!(entries, "\'$(data[data_type]["$i"][field])\'")
                            elseif isa(data[data_type]["$i"][field], Float64)
                                push!(entries, Printf.@sprintf "%.4f" data[data_type]["$i"][field])
                            else
                                push!(entries, "$(data[data_type]["$i"][field])")
                            end
                        end
                    end
                    push!(lines, "$(join(entries, "\t"))")
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
function write_matgas!(data::Dict{String,Any}, fileout::String; units::String="si", include_extended::Bool=false)
    open(fileout, "w") do f
        write(f, _gasmodels_to_matgas_string(data; units=units, include_extended=include_extended))
    end
end
