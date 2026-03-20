"Parses the matgas data from either a filename or an IO object"
function parse_matgas(file::Union{IO,String})
    mg_data = parse_m_file(file)
    gm_data = _matgas_to_gasmodels(mg_data)
    return gm_data
end


const _mg_data_names = Vector{String}([
    "mgc.name",
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
    "mgc.per_unit",
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
    ("name", Union{String,SubString{String}}),
    ("agreement_year", Int),
    ("description", Union{String,SubString{String}}),
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
    "mgc.sources" => Dict{String,Type}(_mg_sources_columns),
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

    if func_name !== nothing
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
    ]

    optional_metadata_names = [
        "mgc.name",
        "mgc.sound_speed",
        "mgc.R",
        "mgc.base_pressure",
        "mgc.base_length",
        "mgc.per_unit",
        "mgc.gas_molar_mass",
        "mgc.economic_weighting",
    ]

    for data_name in required_metadata_names
        (data_name == "mgc.units") && (continue)
        if haskey(matlab_data, data_name)
            case[data_name[5:end]] = matlab_data[data_name]
        else
            Memento.error(_LOGGER, string("no $data_name found in .m file"))
        end
    end

    if haskey(matlab_data, "mgc.units")
        case["units"] = matlab_data["mgc.units"]
        if matlab_data["mgc.units"] == "si"
            case["si_units"] = true
            case["english_units"] = false
        elseif matlab_data["mgc.units"] == "usc"
            case["english_units"] = true
            case["si_units"] = false
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
        case["per_unit"] = matlab_data["mgc.is_per_unit"]
    else
        Memento.warn(_LOGGER, string("no is_per_unit found in .m file.
            Auto assigning a value of 0 (false) for the per_unit field"))
        case["per_unit"] = false
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

    if haskey(matlab_data, "mgc.sources")
        sources = []
        for source_row in matlab_data["mgc.sources"]
            source_data = _IM.row_to_typed_dict(source_row, get(_colnames, "mgc.sources", _mg_sources_columns))
            push!(sources, source_data)
        end
        case["sources"] = sources
    end

    if haskey(matlab_data, "mgc.junction")
        junctions = []
        for junction_row in matlab_data["mgc.junction"]
            junction_data = _IM.row_to_typed_dict(
                junction_row,
                get(_colnames, "mgc.junction", _mg_junction_columns),
            )
            junction_data["index"] = _IM.check_type(Int, junction_row[1])
            junction_data["si_units"] = case["si_units"]
            junction_data["english_units"] = case["english_units"]
            junction_data["per_unit"] = case["per_unit"]
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
            pipe_data["si_units"] = case["si_units"]
            pipe_data["english_units"] = case["english_units"]
            pipe_data["per_unit"] = case["per_unit"]
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
            pipe_data["si_units"] = case["si_units"]
            pipe_data["english_units"] = case["english_units"]
            pipe_data["per_unit"] = case["per_unit"]
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
            compressor_data["si_units"] = case["si_units"]
            compressor_data["english_units"] = case["english_units"]
            compressor_data["per_unit"] = case["per_unit"]
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
            compressor_data["si_units"] = case["si_units"]
            compressor_data["english_units"] = case["english_units"]
            compressor_data["per_unit"] = case["per_unit"]
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
            short_pipe_data["si_units"] = case["si_units"]
            short_pipe_data["english_units"] = case["english_units"]
            short_pipe_data["per_unit"] = case["per_unit"]
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
            resistor_data["si_units"] = case["si_units"]
            resistor_data["english_units"] = case["english_units"]
            resistor_data["per_unit"] = case["per_unit"]
            push!(resistors, resistor_data)
        end
        case["resistor"] = resistors
    end

    if haskey(matlab_data, "mgc.transfer")
        transfers = Array{Dict,1}([])
        for transfer_row in matlab_data["mgc.transfer"]
            transfer_data = _IM.row_to_typed_dict(
                transfer_row,
                get(_colnames, "mgc.transfer", _mg_transfer_columns),
            )
            transfer_data["index"] = _IM.check_type(Int, transfer_row[1])
            transfer_data["si_units"] = case["si_units"]
            transfer_data["english_units"] = case["english_units"]
            transfer_data["per_unit"] = case["per_unit"]
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
            receipt_data["si_units"] = case["si_units"]
            receipt_data["english_units"] = case["english_units"]
            receipt_data["per_unit"] = case["per_unit"]
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
            delivery_data["si_units"] = case["si_units"]
            delivery_data["english_units"] = case["english_units"]
            delivery_data["per_unit"] = case["per_unit"]
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
            regulator_data["si_units"] = case["si_units"]
            regulator_data["english_units"] = case["english_units"]
            regulator_data["per_unit"] = case["per_unit"]
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
            valve_data["si_units"] = case["si_units"]
            valve_data["english_units"] = case["english_units"]
            valve_data["per_unit"] = case["per_unit"]
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
            storage_data["si_units"] = case["si_units"]
            storage_data["english_units"] = case["english_units"]
            storage_data["per_unit"] = case["per_unit"]
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

    check_fields = ["receipt", "delivery", "transfer", "storage"]

    receipts = haskey(gm_data, "receipt") ? length(gm_data["receipt"]) : 0
    transfers = haskey(gm_data, "transfer") ? length(gm_data["transfer"]) : 0
    storages = haskey(gm_data, "storage") ? length(gm_data["storage"]) : 0

    num_supplies = receipts + transfers + storages
    if num_supplies == 0
        Memento.warn(_LOGGER, "no supply points are present in the data file")
    end

    for field in check_fields
        if haskey(gm_data, field) && length(gm_data[field]) == 0
            gm_data[field] = Dict()
        end
    end


    if haskey(gm_data, "sources") && isa(gm_data, Dict)
        gm_data["sources"] = Vector{Dict{String,Any}}([source for source in values(gm_data["sources"])])
    end

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
    "gas_specific_gravity",
    "specific_heat_capacity_ratio",
    "temperature",
    "compressibility_factor",
]


"order of optional global parameters"
const _matlab_global_params_order_optional = ["sound_speed", "R", "base_pressure", "base_length", "per_unit", "version", "pipeline_id", "base_volume", "economic_weighting"]


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
    "ne_pipe" => ["diameter", "length", "friction_factor", "p_min", "p_max"],
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
    "ne_compressor" => [
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

const non_zero_data = Dict{String,Vector{String}}(
    "pipe" => ["diameter", "length", "friction_factor"],
    "ne_pipe" => ["diameter", "length", "friction_factor"],
    "resistor" => ["drag", "diameter"],
)

const rouge_junction_id_fields = Dict{String,Vector{String}}(
    "pipe" => ["fr_junction", "to_junction"],
    "compressor" => ["fr_junction", "to_junction"],
    "resistor" => ["fr_junction", "to_junction"],
    "valve" => ["fr_junction", "to_junction"],
    "transfer" => ["junction_id"],
    "receipt" => ["junction_id"],
    "delivery" => ["junction_id"],
    "storage" => ["junction_id"],
)

function _validate_schema(data)
    """prevent writer from silently crashing if data is missing"""
    for (data_type, fields) in _matlab_field_order
        if haskey(data, data_type)
            for (id, entry) in data[data_type]
                for field in fields
                    haskey(entry, field) || Memento.error(_LOGGER, "Missing $field in $data_type $id")
                end
            end
        end
    end
end

const _mg_extra_data_columns = Dict{String,Vector{String}}(
    "junction"   => ["coordinates", "elevation"],
    "pipe"       => ["coordinates"],
    "compressor" => ["coordinates", "mapping_id"],
    "transfer"   => ["coordinates", "wmg_location_role_id", "mapping_id", "market_id"],
    "receipt"    => ["coordinates", "wmg_location_role_id", "mapping_id", "market_id"],
    "delivery"   => ["coordinates", "wmg_location_role_id", "mapping_id", "market_id"],
)


"""
    write_matgas(filename::String, gm_data::Dict{String,<:Any})
    write_matgas(io::IO, gm_data::Dict{String,<:Any})
"""
function write_matgas(filename::String, gm_data::Dict{String,<:Any})
    open(filename, "w") do io
        write_matgas(io, gm_data)
    end
end

function write_matgas(io::IO, gm_data::Dict{String,<:Any})
    case_name = get(gm_data, "name", "gas_network")
    func_name = _sanitize_matlab_identifier(String(case_name))

    println(io, "function mgc = ", func_name)
    println(io)

    # ---- scalar metadata ----
    _write_scalar_if_present(io, "mgc.version", get(gm_data, "source_version", v"0.0.0"))
    _write_scalar_if_present(io, "mgc.name", get(gm_data, "name", func_name))
    _write_scalar_if_present(io, "mgc.gas_specific_gravity", gm_data["gas_specific_gravity"])
    _write_scalar_if_present(io, "mgc.specific_heat_capacity_ratio", gm_data["specific_heat_capacity_ratio"])
    _write_scalar_if_present(io, "mgc.temperature", gm_data["temperature"])
    _write_scalar_if_present(io, "mgc.sound_speed", get(gm_data, "sound_speed", nothing))
    _write_scalar_if_present(io, "mgc.compressibility_factor", gm_data["compressibility_factor"])
    _write_scalar_if_present(io, "mgc.R", get(gm_data, "R", nothing))
    _write_scalar_if_present(io, "mgc.gas_molar_mass", get(gm_data, "gas_molar_mass", nothing))
    _write_scalar_if_present(io, "mgc.base_pressure", get(gm_data, "base_pressure", nothing))
    _write_scalar_if_present(io, "mgc.base_length", get(gm_data, "base_length", nothing))
    _write_scalar_if_present(io, "mgc.units", gm_data["units"])
    _write_scalar_if_present(io, "mgc.per_unit", get(gm_data, "per_unit", nothing))
    _write_scalar_if_present(io, "mgc.economic_weighting", get(gm_data, "economic_weighting", nothing))
    println(io)

    # ---- tabular sections ----
    _write_section_if_present(io, "sources", get(gm_data, "sources", nothing), _mg_sources_columns)
    _write_section_if_present(io, "junction", get(gm_data, "junction", nothing), _mg_junction_columns)
    _write_section_if_present(io, "pipe", get(gm_data, "pipe", nothing), _mg_pipe_columns)
    _write_section_if_present(io, "compressor", get(gm_data, "compressor", nothing), _mg_compressor_columns)
    _write_section_if_present(io, "receipt", get(gm_data, "receipt", nothing), _mg_receipt_columns)
    _write_section_if_present(io, "delivery", get(gm_data, "delivery", nothing), _mg_delivery_columns)
    _write_section_if_present(io, "transfer", get(gm_data, "transfer", nothing), _mg_transfer_columns)
    _write_section_if_present(io, "short_pipe", get(gm_data, "short_pipe", nothing), _mg_short_pipe_columns)
    _write_section_if_present(io, "resistor", get(gm_data, "resistor", nothing), _mg_resistor_columns)
    _write_section_if_present(io, "regulator", get(gm_data, "regulator", nothing), _mg_regulator_columns)
    _write_section_if_present(io, "valve", get(gm_data, "valve", nothing), _mg_valve_columns)
    _write_section_if_present(io, "storage", get(gm_data, "storage", nothing), _mg_storage_columns)
    _write_section_if_present(io, "ne_pipe", get(gm_data, "ne_pipe", nothing), _mg_ne_pipe_columns)
    _write_section_if_present(io, "ne_compressor", get(gm_data, "ne_compressor", nothing), _mg_ne_compressor_columns)
end


# ------------------------------------------------------------------
# scalar writers
# ------------------------------------------------------------------

function _write_scalar_if_present(io::IO, lhs::String, value)
    value === nothing && return
    println(io, lhs, " = ", _format_matgas_scalar(value), ";")
end

function _format_matgas_scalar(x)
    if x isa VersionNumber
        return "'" * string(x) * "'"
    elseif x isa AbstractString || x isa SubString{String}
        return "'" * _escape_matgas_string(String(x)) * "'"
    elseif x isa Bool
        return x ? "1" : "0"
    elseif x isa Integer
        return string(x)
    elseif x isa AbstractFloat
        return isnan(x) ? "NaN" : _format_float(x)
    else
        return "'" * _escape_matgas_string(string(x)) * "'"
    end
end


# ------------------------------------------------------------------
# section writers
# ------------------------------------------------------------------

function _write_section_if_present(io::IO, section_name::String, rows, canonical_cols::Vector{Tuple{String,Type}})
    rows === nothing && return
    isempty(rows) && return

    row_dicts = _normalize_rows(rows, section_name)

    # main section: exclude extra-data-only columns
    extra_cols = get(_mg_extra_data_columns, section_name, String[])
    main_cols = _present_columns(row_dicts, canonical_cols; exclude=Set(extra_cols))

    if !isempty(main_cols)
        _write_table(io, section_name, row_dicts, main_cols)
    end

    # optional *_data section
    if haskey(_mg_extra_data_columns, section_name)
        data_cols = _present_extra_columns(row_dicts, _mg_extra_data_columns[section_name])

        if !isempty(data_cols)
            _write_table(io, section_name * "_data", row_dicts, data_cols)
        end
    end
end

function _write_table(io::IO, table_name::String, row_dicts::Vector{Dict{String,Any}}, cols::Vector{String})
    println(io, "%% ", table_name)
    println(io, "%column_names% ", join(cols, " "))
    println(io, "mgc.", table_name, " = [")

    for row in row_dicts
        vals = [_format_matgas_cell(_row_get(row, col)) for col in cols]
        println(io, join(vals, "\t"))
    end

    println(io, "];")
    println(io)
end

# ------------------------------------------------------------------
# row normalization
# ------------------------------------------------------------------

function _normalize_rows(rows::AbstractVector, section_name::String)
    out = Vector{Dict{String,Any}}()
    sizehint!(out, length(rows))
    for row in rows
        push!(out, _normalize_row(row, section_name))
    end
    return out
end

function _normalize_rows(rows::AbstractDict, section_name::String)
    vals = collect(values(rows))

    sort!(vals; by = row -> begin
        if haskey(row, "id")
            row["id"]
        elseif haskey(row, :id)
            row[:id]
        elseif haskey(row, "index")
            row["index"]
        elseif haskey(row, :index)
            row[:index]
        else
            typemax(Int)
        end
    end)

    out = Vector{Dict{String,Any}}()
    sizehint!(out, length(vals))
    for xrow in vals
        push!(out, _normalize_row(xrow, section_name))
    end
    return out
end

function _normalize_row(row::AbstractDict, section_name::String)
    out = Dict{String,Any}()

    for (k, v) in row
        ks = String(k)

        # internal bookkeeping
        if ks in (
            "si_units", "english_units", "per_unit",
            "is_si_units", "is_english_units", "is_per_unit"
        )
            continue
        end

        # don't write index directly
        if ks == "index"
            continue
        end

        out[ks] = v
    end

    # ensure id exists
    if !haskey(out, "id")
        if haskey(row, "id")
            out["id"] = row["id"]
        elseif haskey(row, :id)
            out["id"] = row[:id]
        elseif haskey(row, "index")
            out["id"] = row["index"]
        elseif haskey(row, :index)
            out["id"] = row[:index]
        end
    end

    return out
end

# ------------------------------------------------------------------
# column selection
# ------------------------------------------------------------------

function _present_columns(
    rows::Vector{Dict{String,Any}},
    canonical_cols::Vector{Tuple{String,Type}};
    exclude::Set{String}=Set{String}()
)
    canonical_names = [name for (name, _) in canonical_cols if !(name in exclude)]
    present = Set{String}()

    for row in rows
        for k in keys(row)
            if !(k in exclude)
                push!(present, k)
            end
        end
    end

    # only write canonical and present columns
    return [name for name in canonical_names if name in present]
end

function _present_extra_columns(rows::Vector{Dict{String,Any}}, extra_cols::Vector{String})
    present = Set{String}()

    for row in rows
        for col in extra_cols
            val = _row_get(row, col)
            if !(val === nothing || val isa Missing)
                push!(present, col)
            end
        end
    end

    return [col for col in extra_cols if col in present]
end

# ------------------------------------------------------------------
# cell formatting
# ------------------------------------------------------------------

function _format_matgas_cell(x)
    if x === nothing || x isa Missing
        return "''"
    elseif x isa Bool
        return x ? "1" : "0"
    elseif x isa Integer
        return string(x)
    elseif x isa AbstractFloat
        return isnan(x) ? "''" : _format_float(x)
    elseif x isa AbstractString || x isa SubString{String}
        return "'" * _escape_matgas_string(String(x)) * "'"
    else
        return "'" * _escape_matgas_string(string(x)) * "'"
    end
end

_format_float(x::AbstractFloat) = Printf.@sprintf("%.4g", x)

_escape_matgas_string(s::String) = replace(s, "'" => "''")


# ------------------------------------------------------------------
# lookup helpers
# ------------------------------------------------------------------

function _row_get(row::AbstractDict, col::String)
    if haskey(row, col)
        return row[col]
    elseif haskey(row, Symbol(col))
        return row[Symbol(col)]
    else
        return nothing
    end
end

function _sanitize_matlab_identifier(s::String)
    s2 = replace(s, r"[^A-Za-z0-9_]" => "_")
    if isempty(s2)
        return "gas_network"
    elseif occursin(r"^[0-9]", s2)
        return "case_" * s2
    else
        return s2
    end
end