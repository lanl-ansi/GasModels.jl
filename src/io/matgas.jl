"Parses the matgas data from either a filename or an IO object"
function parse_matgas(file::Union{IO,String})
    mg_data = parse_m_file(file)
    gm_data = _matgas_to_gasmodels(mg_data)
    return gm_data
end


const _mg_data_names = Vector{String}([
    "mgc.gas_specific_gravity",
    "mgc.specific_heat_capacity_ratio",
    "mgc.temperature",
    "mgc.sound_speed",
    "mgc.compressibility_factor",
    "mgc.R",
    "mgc.gas_molar_mass",
    "mgc.base_pressure",
    "mgc.base_length",
    "mgc.units",
    "mgc.is_per_unit",
    "mgc.sources",
    "mgc.junction",
    "mgc.pipe",
    "mgc.compressor",
    "mgc.receipt",
    "mgc.delivery",
    "mgc.transfer",
    "mgc.short_pipe",
    "mgc.resistor",
    "mgc.regulator",
    "mgc.valve",
    "mgc.storage",
    "mgc.ne_pipe",
    "mgc.ne_compressor",
])

const _mg_sources_columns = Vector{Tuple{String,Type}}([
    ("name", String),
    ("agreement_year", Int),
    ("description", String),
])

const _mg_junction_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("p_min", Float64),
    ("p_max", Float64),
    ("p_nominal", Float64),
    ("junction_type", Int),
    ("status", Int),
    ("pipeline_name", Union{String,SubString{String}}),
    ("edi_id", Union{Int,String,SubString{String}}),
    ("lat", Float64),
    ("lon", Float64),
])

const _mg_pipe_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("diameter", Float64),
    ("length", Float64),
    ("friction_factor", Float64),
    ("p_min", Float64),
    ("p_max", Float64),
    ("status", Int),
    ("is_bidirectional", Int),
    ("pipeline_name", Union{String,SubString{String}}),
    ("num_spatial_discretization_points", Int),
])

const _mg_ne_pipe_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("diameter", Float64),
    ("length", Float64),
    ("friction_factor", Float64),
    ("p_min", Float64),
    ("p_max", Float64),
    ("status", Int),
    ("construction_cost", Float64),
    ("is_bidirectional", Int),
    ("pipeline_name", Union{String,SubString{String}}),
    ("num_spatial_discretization_points", Int),
])

const _mg_ne_compressor_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("c_ratio_min", Float64),
    ("c_ratio_max", Float64),
    ("power_max", Float64),
    ("flow_min", Float64),
    ("flow_max", Float64),
    ("inlet_p_min", Float64),
    ("inlet_p_max", Float64),
    ("outlet_p_min", Float64),
    ("outlet_p_max", Float64),
    ("status", Int),
    ("construction_cost", Float64),
    ("operating_cost", Float64),
    ("directionality", Int),
    ("compressor_station_name", Union{String,SubString{String}}),
    ("pipeline_name", Union{String,SubString{String}}),
    ("total_installed_power", Float64),
    ("num_compressor_units", Int),
    ("compressor_type", SubString{String}),
    ("design_suction_pressure", Float64),
    ("design_discharge_pressure", Float64),
    ("max_compressed_volume", Float64),
    ("design_fuel_required", Float64),
    ("design_electric_power_required", Float64),
    ("num_units_for_peak_service", Int),
    ("peak_year", Int),
])

const _mg_compressor_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("c_ratio_min", Float64),
    ("c_ratio_max", Float64),
    ("power_max", Float64),
    ("flow_min", Float64),
    ("flow_max", Float64),
    ("inlet_p_min", Float64),
    ("inlet_p_max", Float64),
    ("outlet_p_min", Float64),
    ("outlet_p_max", Float64),
    ("status", Int),
    ("operating_cost", Float64),
    ("directionality", Int),
    ("compressor_station_name", Union{String,SubString{String}}),
    ("pipeline_name", Union{String,SubString{String}}),
    ("total_installed_power", Float64),
    ("num_compressor_units", Int),
    ("compressor_type", SubString{String}),
    ("design_suction_pressure", Float64),
    ("design_discharge_pressure", Float64),
    ("max_compressed_volume", Float64),
    ("design_fuel_required", Float64),
    ("design_electric_power_required", Float64),
    ("num_units_for_peak_service", Int),
    ("peak_year", Int),
])

const _mg_short_pipe_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("status", Int),
    ("is_bidirectional", Int),
    ("pipeline_name", Union{String,SubString{String}}),
])

const _mg_resistor_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("drag", Float64),
    ("diameter", Float64),
    ("status", Int),
    ("is_bidirectional", Int),
    ("pipeline_name", Union{String,SubString{String}}),
])

const _mg_transfer_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("junction_id", Int),
    ("withdrawal_min", Float64),
    ("withdrawal_max", Float64),
    ("withdrawal_nominal", Float64),
    ("is_dispatchable", Int),
    ("status", Int),
    ("bid_price", Float64),
    ("offer_price", Float64),
    ("exchange_point_name", Union{String,SubString{String}}),
    ("pipeline_name", Union{String,SubString{String}}),
    ("other_pipeline_name", Union{String,SubString{String}}),
    ("design_pressure", Float64),
    ("meter_capacity", Float64),
    ("daily_scheduled_flow", Float64),
])

const _mg_receipt_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("junction_id", Int),
    ("injection_min", Float64),
    ("injection_max", Float64),
    ("injection_nominal", Float64),
    ("is_dispatchable", Int),
    ("status", Int),
    ("offer_price", Float64),
    ("name", Union{String,SubString{String}}),
    ("company_name", Union{String,SubString{String}}),
    ("daily_scheduled_flow", Float64),
    ("design_capacity", Float64),
    ("operating_capacity", Float64),
    ("is_firm", Int),
    ("edi_id", Union{Int,String,SubString{String}}),
])

const _mg_delivery_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("junction_id", Int),
    ("withdrawal_min", Float64),
    ("withdrawal_max", Float64),
    ("withdrawal_nominal", Float64),
    ("is_dispatchable", Int),
    ("status", Int),
    ("bid_price", Float64),
    ("name", Union{String,SubString{String}}),
    ("company_name", Union{String,SubString{String}}),
    ("daily_scheduled_flow", Float64),
    ("design_capacity", Float64),
    ("operating_capacity", Float64),
    ("is_firm", Int),
    ("edi_id", Union{Int,String,SubString{String}}),
])

const _mg_regulator_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("reduction_factor_min", Float64),
    ("reduction_factor_max", Float64),
    ("flow_min", Float64),
    ("flow_max", Float64),
    ("status", Int),
    ("directionality", Int),
    ("discharge_coefficient", Float64),
    ("design_flow_rate", Float64),
    ("design_inlet_pressure", Float64),
    ("design_outlet_pressure", Float64),
    ("pipeline_name", Union{String,SubString{String}}),
])

const _mg_valve_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("fr_junction", Int),
    ("to_junction", Int),
    ("status", Int),
    ("flow_coefficient", Float64),
    ("pipeline_name", Union{String,SubString{String}}),
])

const _mg_storage_columns = Vector{Tuple{String,Type}}([
    ("id", Int),
    ("junction_id", Int),
    ("well_diameter", Float64),
    ("well_depth", Float64),
    ("well_friction_factor", Float64),
    ("reservoir_p_max", Float64),
    ("base_gas_capacity", Float64),
    ("total_field_capacity", Float64),
    ("initial_field_capacity_percent", Float64),
    ("reduction_factor_max", Float64),
    ("c_ratio_max", Float64),
    ("status", Int),
    ("flow_injection_rate_min", Float64),
    ("flow_injection_rate_max", Float64),
    ("flow_withdrawal_rate_min", Float64),
    ("flow_withdrawal_rate_max", Float64),
    ("name", Union{String,SubString{String}}),
    ("owner_name", Union{String,SubString{String}}),
    ("storage_type", Union{String,SubString{String}}),
    ("daily_withdrawal_max", Float64),
    ("seasonal_withdrawal_max", Float64),
    ("edi_id", Union{Int,String,SubString{String}}),
])

const _mg_dtype_lookup = Dict{String,Dict{String,Type}}(
    "mgc.junction" => Dict{String,Type}(_mg_junction_columns),
    "mgc.pipe" => Dict{String,Type}(_mg_pipe_columns),
    "mgc.compressor" => Dict{String,Type}(_mg_compressor_columns),
    "mgc.short_pipe" => Dict{String,Type}(_mg_short_pipe_columns),
    "mgc.resistor" => Dict{String,Type}(_mg_resistor_columns),
    "mgc.regulator" => Dict{String,Type}(_mg_regulator_columns),
    "mgc.valve" => Dict{String,Type}(_mg_valve_columns),
    "mgc.transfer" => Dict{String,Type}(_mg_transfer_columns),
    "mgc.receipt" => Dict{String,Type}(_mg_receipt_columns),
    "mgc.delivery" => Dict{String,Type}(_mg_delivery_columns),
    "mgc.storage" => Dict{String,Type}(_mg_storage_columns),
    "mgc.ne_pipe" => Dict{String,Type}(_mg_ne_pipe_columns),
    "mgc.ne_compressor" => Dict{String,Type}(_mg_ne_compressor_columns),
)


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
    matlab_data, func_name, colnames = _IM.parse_matlab_string(data_string, extended = true)


    _colnames = Dict{String,Vector{Tuple{String,Type}}}()
    for (component_type, cols) in colnames
        _colnames[component_type] = Vector{Tuple{String,Type}}([])
        for col in cols
            dtype = get(
                get(_mg_dtype_lookup, component_type, Dict{String,Type}()),
                col,
                SubString{String},
            )
            push!(_colnames[component_type], (col, dtype))
        end
    end

    case = Dict{String,Any}()

    if func_name != nothing
        case["name"] = func_name
    else
        Memento.warn(_LOGGER, "no case name found in .m file.  The file seems to be missing \"function mgc = ...\"")
        case["name"] = "no_name_found"
    end

    case["source_type"] = ".m"
    if haskey(matlab_data, "mgc.version")
        case["source_version"] = VersionNumber(matlab_data["mgc.version"])
    else
        Memento.warn(_LOGGER, "no case version found in .m file.  The file seems to be missing \"mgc.version = ...\"")
        case["source_version"] = "0.0.0+"
    end

    required_metadata_names = [
        "mgc.gas_specific_gravity",
        "mgc.specific_heat_capacity_ratio",
        "mgc.temperature",
        "mgc.compressibility_factor",
        "mgc.units",
        "mgc.name",
    ]

    optional_metadata_names = [
        "mgc.sound_speed",
        "mgc.R",
        "mgc.base_pressure",
        "mgc.base_length",
        "mgc.is_per_unit",
        "mgc.gas_molar_mass",
        "mgc.economic_weighting",
    ]

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
        Memento.warn(
            _LOGGER,
            string("no base_pressure found in .m file.
This value will be auto-assigned based on the pressure limits provided in the data"),
        )
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

    if haskey(matlab_data, "mgc.gas_molar_mass")
        case["gas_molar_mass"] = matlab_data["mgc.gas_molar_mass"]
    else
        case["gas_molar_mass"] = 0.02896 * case["gas_specific_gravity"]
    end

    if haskey(matlab_data, "mgc.sound_speed")
        case["sound_speed"] = matlab_data["mgc.sound_speed"]
    else
        # v = sqrt(R_g * T); R_g = R/M_g = R/M_a/G; R_g is specific gas constant; g-gas, a-air
        molecular_mass = case["gas_molar_mass"] # kg/mol
        T = case["temperature"] # K
        R = case["R"] # J/mol/K
        case["sound_speed"] = sqrt(R * T / molecular_mass) # m/s
    end

    if haskey(matlab_data, "mgc.economic_weighting")
        case["economic_weighting"] = matlab_data["mgc.economic_weighting"]
    else
        case["economic_weighting"] = 1.0
        Memento.warn(
            _LOGGER,
            "economic_weighting value set to 1.0; the transient ogf
objective is economic_weighting * (load shed) +
(1-economic_weighting) * (compressor power)",
        )
    end

    if haskey(matlab_data, "mgc.junction")
        junctions = []
        for junction_row in matlab_data["mgc.junction"]
            junction_data = _IM.row_to_typed_dict(
                junction_row,
                get(_colnames, "mgc.junction", _mg_junction_columns),
            )
            junction_data["index"] = _IM.check_type(Int, junction_row[1])
            junction_data["is_si_units"] = case["is_si_units"]
            junction_data["is_english_units"] = case["is_english_units"]
            junction_data["is_per_unit"] = case["is_per_unit"]
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
            pipe_data = _IM.row_to_typed_dict(
                pipe_row,
                get(_colnames, "mgc.pipe", _mg_pipe_columns),
            )
            pipe_data["index"] = _IM.check_type(Int, pipe_row[1])
            pipe_data["is_si_units"] = case["is_si_units"]
            pipe_data["is_english_units"] = case["is_english_units"]
            pipe_data["is_per_unit"] = case["is_per_unit"]
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
            pipe_data = _IM.row_to_typed_dict(
                pipe_row,
                get(_colnames, "mgc.ne_pipe", _mg_ne_pipe_columns),
            )
            pipe_data["index"] = _IM.check_type(Int, pipe_row[1])
            pipe_data["is_si_units"] = case["is_si_units"]
            pipe_data["is_english_units"] = case["is_english_units"]
            pipe_data["is_per_unit"] = case["is_per_unit"]
            push!(ne_pipes, pipe_data)
        end
        case["ne_pipe"] = ne_pipes
    end

    if haskey(matlab_data, "mgc.compressor")
        compressors = []
        for compressor_row in matlab_data["mgc.compressor"]
            compressor_data = _IM.row_to_typed_dict(
                compressor_row,
                get(_colnames, "mgc.compressor", _mg_compressor_columns),
            )
            compressor_data["index"] = _IM.check_type(Int, compressor_row[1])
            compressor_data["is_si_units"] = case["is_si_units"]
            compressor_data["is_english_units"] = case["is_english_units"]
            compressor_data["is_per_unit"] = case["is_per_unit"]
            push!(compressors, compressor_data)
        end
        case["compressor"] = compressors
    end

    if haskey(matlab_data, "mgc.ne_compressor")
        ne_compressors = []
        for compressor_row in matlab_data["mgc.ne_compressor"]
            compressor_data = _IM.row_to_typed_dict(
                compressor_row,
                get(_colnames, "mgc.ne_compressor", _mg_ne_compressor_columns),
            )
            compressor_data["index"] = _IM.check_type(Int, compressor_row[1])
            compressor_data["is_si_units"] = case["is_si_units"]
            compressor_data["is_english_units"] = case["is_english_units"]
            compressor_data["is_per_unit"] = case["is_per_unit"]
            push!(ne_compressors, compressor_data)
        end
        case["ne_compressor"] = ne_compressors
    end

    if haskey(matlab_data, "mgc.short_pipe")
        short_pipes = []
        for short_pipe_row in matlab_data["mgc.short_pipe"]
            short_pipe_data = _IM.row_to_typed_dict(
                short_pipe_row,
                get(_colnames, "mgc.short_pipe", _mg_short_pipe_columns),
            )
            short_pipe_data["index"] = _IM.check_type(Int, short_pipe_row[1])
            short_pipe_data["is_si_units"] = case["is_si_units"]
            short_pipe_data["is_english_units"] = case["is_english_units"]
            short_pipe_data["is_per_unit"] = case["is_per_unit"]
            push!(short_pipes, short_pipe_data)
        end
        case["short_pipe"] = short_pipes
    end

    if haskey(matlab_data, "mgc.resistor")
        resistors = []
        for resistor_row in matlab_data["mgc.resistor"]
            resistor_data = _IM.row_to_typed_dict(
                resistor_row,
                get(_colnames, "mgc.resistor", _mg_resistor_columns),
            )
            resistor_data["index"] = _IM.check_type(Int, resistor_row[1])
            resistor_data["is_si_units"] = case["is_si_units"]
            resistor_data["is_english_units"] = case["is_english_units"]
            resistor_data["is_per_unit"] = case["is_per_unit"]
            push!(resistors, resistor_data)
        end
        case["resistor"] = resistors
    end

    if haskey(matlab_data, "mgc.transfer")
        transfers = []
        for transfer_row in matlab_data["mgc.transfer"]
            transfer_data = _IM.row_to_typed_dict(
                transfer_row,
                get(_colnames, "mgc.transfer", _mg_transfer_columns),
            )
            transfer_data["index"] = _IM.check_type(Int, transfer_row[1])
            transfer_data["is_si_units"] = case["is_si_units"]
            transfer_data["is_english_units"] = case["is_english_units"]
            transfer_data["is_per_unit"] = case["is_per_unit"]
            push!(transfers, transfer_data)
        end
        case["transfer"] = transfers
    end

    if haskey(matlab_data, "mgc.receipt")
        receipts = []
        for receipt_row in matlab_data["mgc.receipt"]
            receipt_data = _IM.row_to_typed_dict(
                receipt_row,
                get(_colnames, "mgc.receipt", _mg_receipt_columns),
            )
            receipt_data["index"] = _IM.check_type(Int, receipt_row[1])
            receipt_data["is_si_units"] = case["is_si_units"]
            receipt_data["is_english_units"] = case["is_english_units"]
            receipt_data["is_per_unit"] = case["is_per_unit"]
            push!(receipts, receipt_data)
        end
        case["receipt"] = receipts
    end

    if haskey(matlab_data, "mgc.delivery")
        deliveries = []
        for delivery_row in matlab_data["mgc.delivery"]
            delivery_data = _IM.row_to_typed_dict(
                delivery_row,
                get(_colnames, "mgc.delivery", _mg_delivery_columns),
            )
            delivery_data["index"] = _IM.check_type(Int, delivery_row[1])
            delivery_data["is_si_units"] = case["is_si_units"]
            delivery_data["is_english_units"] = case["is_english_units"]
            delivery_data["is_per_unit"] = case["is_per_unit"]
            push!(deliveries, delivery_data)
        end
        case["delivery"] = deliveries
    end

    if haskey(matlab_data, "mgc.regulator")
        regulators = []
        for regulator_row in matlab_data["mgc.regulator"]
            regulator_data = _IM.row_to_typed_dict(
                regulator_row,
                get(_colnames, "mgc.regulator", _mg_regulator_columns),
            )
            regulator_data["index"] = _IM.check_type(Int, regulator_row[1])
            regulator_data["is_si_units"] = case["is_si_units"]
            regulator_data["is_english_units"] = case["is_english_units"]
            regulator_data["is_per_unit"] = case["is_per_unit"]
            push!(regulators, regulator_data)
        end
        case["regulator"] = regulators
    end

    if haskey(matlab_data, "mgc.valve")
        valves = []
        for valve_row in matlab_data["mgc.valve"]
            valve_data = _IM.row_to_typed_dict(
                valve_row,
                get(_colnames, "mgc.valve", _mg_valve_columns),
            )
            valve_data["index"] = _IM.check_type(Int, valve_row[1])
            valve_data["is_si_units"] = case["is_si_units"]
            valve_data["is_english_units"] = case["is_english_units"]
            valve_data["is_per_unit"] = case["is_per_unit"]
            push!(valves, valve_data)
        end
        case["valve"] = valves
    end

    if haskey(matlab_data, "mgc.storage")
        storages = []
        for storage_row in matlab_data["mgc.storage"]
            storage_data = _IM.row_to_typed_dict(
                storage_row,
                get(_colnames, "mgc.storage", _mg_storage_columns),
            )
            storage_data["index"] = _IM.check_type(Int, storage_row[1])
            storage_data["is_si_units"] = case["is_si_units"]
            storage_data["is_english_units"] = case["is_english_units"]
            storage_data["is_per_unit"] = case["is_per_unit"]
            push!(storages, storage_data)
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
                    row_data = _IM.row_to_dict(row, column_names)
                    row_data["index"] = i
                    push!(tbl, row_data)
                end
                case[case_name] = tbl
                Memento.info(_LOGGER, "extending matlab format with data: $(case_name) $(length(tbl))x$(length(tbl[1])-1)")
            else
                case[case_name] = value
                Memento.info(_LOGGER, "extending matlab format with constant data: $(case_name)")
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
    _IM.arrays_to_dicts!(gm_data)

    return gm_data
end


"merges Matlab tables based on the table extension syntax"
function _merge_generic_data!(data::Dict{String,Any})
    mg_matrix_names = [name[5:length(name)] for name in _mg_data_names]

    key_to_delete = []
    for (k, v) in data
        if isa(v, Array)
            for mg_name in mg_matrix_names
                if startswith(k, "$(mg_name)_")
                    mg_matrix = data[mg_name]
                    push!(key_to_delete, k)

                    if length(mg_matrix) != length(v)
                        Memento.error(_LOGGER, "failed to extend the matlab matrix \"$(mg_name)\" with the matrix \"$(k)\" because they do not have the same number of rows, $(length(mg_matrix)) and $(length(v)) respectively.")
                    end

                    Memento.info(_LOGGER, "extending matlab format by appending matrix \"$(k)\" in to \"$(mg_name)\"")

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
function _get_default(dict, key, default = 0.0)
    if haskey(dict, key) && dict[key] != NaN
        return dict[key]
    end
    return default
end


"order data types should appear in matlab format"
const _matlab_data_order = [
    "sources",
    "junction",
    "pipe",
    "compressor",
    "short_pipe",
    "resistor",
    "regulator",
    "valve",
    "receipt",
    "delivery",
    "transfer",
    "storage",
    "ne_pipe",
    "ne_compressor",
]


"order data fields should appear in matlab format"
const _matlab_field_order = Dict{String,Array}(
    "sources" => [key for (key, dtype) in _mg_sources_columns],
    "junction" => [key for (key, dtype) in _mg_junction_columns],
    "pipe" => [key for (key, dtype) in _mg_pipe_columns],
    "compressor" => [key for (key, dtype) in _mg_compressor_columns],
    "short_pipe" => [key for (key, dtype) in _mg_short_pipe_columns],
    "resistor" => [key for (key, dtype) in _mg_resistor_columns],
    "regulator" => [key for (key, dtype) in _mg_regulator_columns],
    "valve" => [key for (key, dtype) in _mg_valve_columns],
    "receipt" => [key for (key, dtype) in _mg_receipt_columns],
    "delivery" => [key for (key, dtype) in _mg_delivery_columns],
    "transfer" => [key for (key, dtype) in _mg_transfer_columns],
    "storage" => [key for (key, dtype) in _mg_storage_columns],
    "ne_pipe" => [key for (key, dtype) in _mg_ne_pipe_columns],
    "ne_compressor" => [key for (key, dtype) in _mg_ne_compressor_columns],
)


"order of required global parameters"
const _matlab_global_params_order_required = [
    "name",
    "gas_specific_gravity",
    "specific_heat_capacity_ratio",
    "temperature",
    "compressibility_factor",
]


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
    ),
)

const non_negative_metadata = [
    "gas_specific_gravity",
    "specific_heat_capacity_ratio",
    "temperature",
    "sound_speed",
    "compressibility_factor",
]

const non_negative_data = Dict{String,Vector{String}}(
    "junction" => ["p_min", "p_max", "p_nominal"],
    "pipe" => ["diameter", "length", "friction_factor", "p_min", "p_max"],
    "compressor" => [
        "c_ratio_min",
        "c_ratio_max",
        "power_max",
        "flow_max",
        "inlet_p_min",
        "inlet_p_max",
        "outlet_p_min",
        "outlet_p_max",
        "operating_cost",
    ],
    "resistor" => ["drag", "diameter"],
    "transfer" => [],
    "receipt" => ["injection_min", "injection_max", "injection_nominal"],
    "delivery" => ["withdrawal_min", "withdrawal_max", "withdrawal_nominal"],
    "storage" => [
        "pressure_nominal",
        "flow_injection_rate_min",
        "flow_injection_rate_max",
        "flow_withdrawal_rate_min",
        "flow_withdrawal_rate_max",
        "capacity",
    ],
)


"write to matgas"
function _gasmodels_to_matgas_string(
    data::Dict{String,Any};
    units::String = "si",
    include_extended::Bool = false,
)::String
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

    push!(
        lines,
        "%% optional global data (that was either provided or computed based on required global data)",
    )
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
                            if isa(
                                data[data_type]["$i"][field],
                                Union{String,SubString{String}},
                            )
                                push!(entries, "\'$(data[data_type]["$i"][field])\'")
                            elseif isa(data[data_type]["$i"][field], Float64)
                                push!(
                                    entries,
                                    Printf.@sprintf "%.4f" data[data_type]["$i"][field]
                                )
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
                all_ext_cols = Set([
                    col for item in values(data[data_type])
                    for col in keys(item) if !(col in _matlab_field_order[data_type])
                ])
                common_ext_cols = [
                    col
                    for
                    col in all_ext_cols if
                    all(col in keys(item) for item in values(data[data_type]))
                ]

                if !isempty(common_ext_cols)
                    push!(lines, "%% $data_type data (extended)")
                    push!(lines, "%column_names% $(join(common_ext_cols, "\t"))")
                    push!(lines, "mgc.$(data_type)_data = [")
                    for i in sort([parse(Int, i) for i in keys(data[data_type])])
                        push!(
                            lines,
                            "\t$(join([data[data_type]["$i"][col] for col in sort(common_ext_cols)], "\t"))",
                        )
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
function write_matgas!(
    data::Dict{String,Any},
    fileout::String;
    units::String = "si",
    include_extended::Bool = false,
)
    if haskey(data, "original_pipe")
        data["new_pipe"] = deepcopy(data["pipe"])
        data["pipe"] = deepcopy(data["original_pipe"])
        delete!(data, "original_pipe")
    end
    if haskey(data, "original_junction")
        data["new_junction"] = deepcopy(data["junction"])
        data["junction"] = deepcopy(data["original_junction"])
        delete!(data, "original_junction")
    end

    open(fileout, "w") do f
        write(
            f,
            _gasmodels_to_matgas_string(
                data;
                units = units,
                include_extended = include_extended,
            ),
        )
    end

    if haskey(data, "new_pipe")
        data["original_pipe"] = deepcopy(data["pipe"])
        data["pipe"] = deepcopy(data["new_pipe"])
        delete!(data, "new_pipe")
    end
    if haskey(data, "new_junction")
        data["original_junction"] = deepcopy(data["junction"])
        data["junction"] = deepcopy(data["new_junction"])
        delete!(data, "new_junction")
    end
end
