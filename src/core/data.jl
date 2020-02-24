# tools for working with GasModels internal data format


"data getters"
@inline get_base_pressure(data::Dict{String, Any}) = data["base_pressure"]
@inline get_base_length(data::Dict{String, Any}) = data["base_length"]
@inline get_base_flow(data::Dict{String, Any}) = data["base_flow"]
@inline get_base_time(data::Dict{String, Any}) = data["base_time"]


"calculates base_pressure"
function calc_base_pressure(data::Dict{String,<:Any})
    p_mins = filter(x->x>0, [junction["p_min"] for junction in values(data["junction"])])

    return isempty(p_mins) ? 1.0 : minimum(p_mins)
end

"calculates the base_time"
function calc_base_time(data::Dict{String,<:Any})
    return get_base_length(data) / get_sound_speed(data)
end

"calculates the base_flow"
function calc_base_flow(data::Dict{String,<:Any})
    return get_base_pressure(data) / get_sound_speed(data)
end

"apply a function on a dict entry"
function _apply_func!(data::Dict{String,Any}, key::String, func)
    if haskey(data, key)
        data[key] = func(data[key])
    end
end


"if original data is in per-unit ensure it has base values"
function per_unit_data_field_check!(data::Dict{String, Any})
    if get(data, "is_per_unit", false) == true
        if get(data, "base_pressure", false) == false || get(data, "base_length", false) == false
            Memento.error(_LOGGER, "data in .m file is in per unit but no base_pressure (in Pa) and base_length (in m) values are provided")
        else
            data["base_time"] = calc_base_time(data)
            (get(data, "base_flow", false) == false) && (data["base_flow"] = calc_base_flow(data))
        end
    end
end


"adds additional non-dimensional constants to data dictionary"
function add_base_values!(data::Dict{String, Any})
    (get(data, "base_pressure", false) == false) && (data["base_pressure"] = calc_base_pressure(data))
    (get(data, "base_length", false) == false) && (data["base_length"] = 5000.0)
    data["base_time"] = calc_base_time(data)
    (get(data, "base_flow", false) == false) && (data["base_flow"] = calc_base_flow(data))
end


"Transforms static network data into si units"
function make_si_units!(data::Dict{String,<:Any})

    if get(data, "is_si_units", false) == true
        return
    end

    if get(data, "is_per_unit", false) == true
        rescale_flow      = x -> x * get_base_flow(data)
        rescale_pressure  = x -> x * get_base_pressure(data)
        rescale_length    = x -> x * get_base_length(data)
        rescale_time      = x -> x * get_base_time(data)
        rescale_mass      = x -> x * get_base_flow(data) * get_base_time(data)

        for (i, junction) in get(data, "junction", [])
            _apply_func!(junction, "p_min", rescale_pressure)
            _apply_func!(junction, "p_max", rescale_pressure)
            _apply_func!(junction, "p_nominal", rescale_pressure)
        end

        for (i, pipe) in get(data, "pipe", [])
            _apply_func!(pipe, "length", rescale_length)
            _apply_func!(pipe, "p_min", rescale_pressure)
            _apply_func!(pipe, "p_max", rescale_pressure)
        end

        for (i, pipe) in get(data, "ne_pipe", [])
            _apply_func!(pipe, "length", rescale_length)
            _apply_func!(pipe, "p_min", rescale_pressure)
            _apply_func!(pipe, "p_max", rescale_pressure)
        end

        for (i, compressor) in get(data, "compressor", [])
            _apply_func!(compressor, "length", rescale_length)
            _apply_func!(compressor, "flow_min", rescale_flow)
            _apply_func!(compressor, "flow_max", rescale_flow)
            _apply_func!(compressor, "inlet_p_min", rescale_pressure)
            _apply_func!(compressor, "inlet_p_max", rescale_pressure)
            _apply_func!(compressor, "outlet_p_min", rescale_pressure)
            _apply_func!(compressor, "outlet_p_max", rescale_pressure)
        end

        for (i, compressor) in get(data, "ne_compressor", [])
            _apply_func!(compressor, "length", rescale_length)
            _apply_func!(compressor, "flow_min", rescale_flow)
            _apply_func!(compressor, "flow_max", rescale_flow)
            _apply_func!(compressor, "inlet_p_min", rescale_pressure)
            _apply_func!(compressor, "inlet_p_max", rescale_pressure)
            _apply_func!(compressor, "outlet_p_min", rescale_pressure)
            _apply_func!(compressor, "outlet_p_max", rescale_pressure)
        end


        for (i, transfer) in get(data, "transfer", [])
            _apply_func!(transfer, "withdrawal_min", rescale_flow)
            _apply_func!(transfer, "withdrawal_max", rescale_flow)
            _apply_func!(transfer, "withdrawal_nominal", rescale_flow)
        end

        for (i, receipt) in get(data, "receipt", [])
            _apply_func!(receipt, "injection_min", rescale_flow)
            _apply_func!(receipt, "injection_max", rescale_flow)
            _apply_func!(receipt, "injection_nominal", rescale_flow)
        end

        for (i, delivery) in get(data, "delivery", [])
            _apply_func!(delivery, "withdrawal_min", rescale_flow)
            _apply_func!(delivery, "withdrawal_max", rescale_flow)
            _apply_func!(delivery, "withdrawal_nominal", rescale_flow)
        end

        for (i, regulator) in get(data, "regulator", [])
            _apply_func!(regulator, "flow_min", rescale_flow)
            _apply_func!(regulator, "flow_max", rescale_flow)
            _apply_func!(regulator, "design_flow_rate", rescale_flow)
            _apply_func!(regulator, "design_inlet_pressure", rescale_pressure)
            _apply_func!(regulator, "design_outlet_pressure", rescale_pressure)
        end

        for (i, storage) in get(data, "storage", [])
            _apply_func!(storage, "pressure_nominal", rescale_pressure)
            _apply_func!(storage, "flow_injection_rate_min", rescale_flow)
            _apply_func!(storage, "flow_injection_rate_max", rescale_flow)
            _apply_func!(storage, "flow_withdrawal_rate_min", rescale_flow)
            _apply_func!(storage, "flow_withdrawal_rate_max", rescale_flow)
            _apply_func!(storage, "capacity", rescale_mass)
        end

        data["is_per_unit"] = 0
        data["is_si_units"] = 1
        data["is_english_units"] = 0
    end

    if get(data, "is_english_units", false) == true
        mmscfd_to_kgps = x -> x * get_mmscfd_to_kgps_conversion_factor(data)
        inv_mmscfd_to_kgps = x -> x / get_mmscfd_to_kgps_conversion_factor(data)
        mmscf_to_kg = x -> x * get_mmscfd_to_kgps_conversion_factor(data) * 86400.0

        for (i, junction) in get(data, "junction", [])
            _apply_func!(junction, "p_min", psi_to_pascal)
            _apply_func!(junction, "p_max", psi_to_pascal)
            _apply_func!(junction, "p_nominal", psi_to_pascal)
        end

        for (i, pipe) in get(data, "pipe", [])
            _apply_func!(pipe, "diameter", inches_to_m)
            _apply_func!(pipe, "length", miles_to_m)
            _apply_func!(pipe, "p_min", psi_to_pascal)
            _apply_func!(pipe, "p_max", psi_to_pascal)
        end

        for (i, pipe) in get(data, "ne_pipe", [])
            _apply_func!(pipe, "diameter", inches_to_m)
            _apply_func!(pipe, "length", miles_to_m)
            _apply_func!(pipe, "p_min", psi_to_pascal)
            _apply_func!(pipe, "p_max", psi_to_pascal)
        end

        for (i, resistor) in get(data, "resistor", [])
            _apply_func!(resistor, "diameter", inches_to_m)
        end

        for (i, compressor) in get(data, "compressor", [])
            _apply_func!(compressor, "power_max", hp_to_watts)
            _apply_func!(compressor, "diameter", inches_to_m)
            _apply_func!(compressor, "length", miles_to_m)
            _apply_func!(compressor, "flow_min", mmscfd_to_kgps)
            _apply_func!(compressor, "flow_max", mmscfd_to_kgps)
            _apply_func!(compressor, "inlet_p_min", psi_to_pascal)
            _apply_func!(compressor, "inlet_p_max", psi_to_pascal)
            _apply_func!(compressor, "outlet_p_min", psi_to_pascal)
            _apply_func!(compressor, "outlet_p_max", psi_to_pascal)
        end

        for (i, compressor) in get(data, "ne_compressor", [])
            _apply_func!(compressor, "power_max", hp_to_watts)
            _apply_func!(compressor, "diameter", inches_to_m)
            _apply_func!(compressor, "length", miles_to_m)
            _apply_func!(compressor, "flow_min", mmscfd_to_kgps)
            _apply_func!(compressor, "flow_max", mmscfd_to_kgps)
            _apply_func!(compressor, "inlet_p_min", psi_to_pascal)
            _apply_func!(compressor, "inlet_p_max", psi_to_pascal)
            _apply_func!(compressor, "outlet_p_min", psi_to_pascal)
            _apply_func!(compressor, "outlet_p_max", psi_to_pascal)
        end

        for (i, transfer) in get(data, "transfer", [])
            _apply_func!(transfer, "withdrawal_min", mmscfd_to_kgps)
            _apply_func!(transfer, "withdrawal_max", mmscfd_to_kgps)
            _apply_func!(transfer, "withdrawal_nominal", mmscfd_to_kgps)
            _apply_func!(transfer, "bid_price", inv_mmscfd_to_kgps)
            _apply_func!(transfer, "offer_price", inv_mmscfd_to_kgps)
        end

        for (i, receipt) in get(data, "receipt", [])
            _apply_func!(receipt, "injection_min", mmscfd_to_kgps)
            _apply_func!(receipt, "injection_max", mmscfd_to_kgps)
            _apply_func!(receipt, "injection_nominal", mmscfd_to_kgps)
            _apply_func!(receipt, "offer_price", inv_mmscfd_to_kgps)
        end

        for (i, delivery) in get(data, "delivery", [])
            _apply_func!(delivery, "withdrawal_min", mmscfd_to_kgps)
            _apply_func!(delivery, "withdrawal_max", mmscfd_to_kgps)
            _apply_func!(delivery, "withdrawal_nominal", mmscfd_to_kgps)
            _apply_func!(delivery, "bid_price", inv_mmscfd_to_kgps)
        end

        for (i, regulator) in get(data, "regulator", [])
            _apply_func!(regulator, "flow_min", mmscfd_to_kgps)
            _apply_func!(regulator, "flow_max", mmscfd_to_kgps)
            _apply_func!(regulator, "design_flow_rate", mmscfd_to_kgps)
            _apply_func!(regulator, "design_inlet_pressure", psi_to_pascal)
            _apply_func!(regulator, "design_outlet_pressure", psi_to_pascal)
        end

        for (i, storage) in get(data, "storage", [])
            _apply_func!(storage, "pressure_nominal", psi_to_pascal)
            _apply_func!(storage, "flow_injection_rate_min", mmscfd_to_kgps)
            _apply_func!(storage, "flow_injection_rate_max", mmscfd_to_kgps)
            _apply_func!(storage, "flow_withdrawal_rate_min", mmscfd_to_kgps)
            _apply_func!(storage, "flow_withdrawal_rate_max", mmscfd_to_kgps)
            _apply_func!(storage, "capacity", mmscf_to_kg)
        end

        data["is_per_unit"] = 0
        data["is_si_units"] = 1
        data["is_english_units"] = 0
    end
    return
end


"Transforms network data into english units"
function make_english_units!(data::Dict{String,<:Any})
    if get(data, "is_english_units", false) == true
        return
    end
    if get(data, "is_per_unit", false) == true
        make_si_units!(data)
    end
    if get(data, "is_si_units", false) == true
        kgps_to_mmscfd = x -> x * get_kgps_to_mmscfd_conversion_factor(data)
        inv_kgps_to_mmscfd = x -> x / get_kgps_to_mmscfd_conversion_factor(data)
        kg_to_mmscf= x -> x / get_mmscfd_to_kgps_conversion_factor(data) / 86400.0

        for (i, junction) in get(data, "junction", [])
            _apply_func!(junction, "p_min", pascal_to_psi)
            _apply_func!(junction, "p_max", pascal_to_psi)
            _apply_func!(junction, "p_nominal", pascal_to_psi)
        end

        for (i, pipe) in get(data, "pipe", [])
            _apply_func!(pipe, "diameter", m_to_inches)
            _apply_func!(pipe, "length", m_to_miles)
            _apply_func!(pipe, "p_min", pascal_to_psi)
            _apply_func!(pipe, "p_max", pascal_to_psi)
        end

        for (i, pipe) in get(data, "ne_pipe", [])
            _apply_func!(pipe, "diameter", m_to_inches)
            _apply_func!(pipe, "length", m_to_miles)
            _apply_func!(pipe, "p_min", pascal_to_psi)
            _apply_func!(pipe, "p_max", pascal_to_psi)
        end

        for (i, resistor) in get(data, "resistor", [])
            _apply_func!(resistor, "diameter", m_to_inches)
        end

        for (i, compressor) in get(data, "compressor", [])
            _apply_func!(compressor, "power_max", watts_to_hp)
            _apply_func!(compressor, "diameter", m_to_inches)
            _apply_func!(compressor, "length", m_to_miles)
            _apply_func!(compressor, "flow_min", kgps_to_mmscfd)
            _apply_func!(compressor, "flow_max", kgps_to_mmscfd)
            _apply_func!(compressor, "inlet_p_min", pascal_to_psi)
            _apply_func!(compressor, "inlet_p_max", pascal_to_psi)
            _apply_func!(compressor, "outlet_p_min", pascal_to_psi)
            _apply_func!(compressor, "outlet_p_max", pascal_to_psi)
        end

        for (i, compressor) in get(data, "ne_compressor", [])
            _apply_func!(compressor, "power_max", watts_to_hp)
            _apply_func!(compressor, "diameter", m_to_inches)
            _apply_func!(compressor, "length", m_to_miles)
            _apply_func!(compressor, "flow_min", kgps_to_mmscfd)
            _apply_func!(compressor, "flow_max", kgps_to_mmscfd)
            _apply_func!(compressor, "inlet_p_min", pascal_to_psi)
            _apply_func!(compressor, "inlet_p_max", pascal_to_psi)
            _apply_func!(compressor, "outlet_p_min", pascal_to_psi)
            _apply_func!(compressor, "outlet_p_max", pascal_to_psi)
        end

        for (i, transfer) in get(data, "transfer", [])
            _apply_func!(transfer, "withdrawal_min", kgps_to_mmscfd)
            _apply_func!(transfer, "withdrawal_max", kgps_to_mmscfd)
            _apply_func!(transfer, "withdrawal_nominal", kgps_to_mmscfd)
            _apply_func!(transfer, "bid_price", inv_kgps_to_mmscfd)
            _apply_func!(transfer, "offer_price", inv_kgps_to_mmscfd)
        end

        for (i, receipt) in get(data, "receipt", [])
            _apply_func!(receipt, "injection_min", kgps_to_mmscfd)
            _apply_func!(receipt, "injection_max", kgps_to_mmscfd)
            _apply_func!(receipt, "injection_nominal", kgps_to_mmscfd)
            _apply_func!(receipt, "offer_price", inv_kgps_to_mmscfd)
        end

        for (i, delivery) in get(data, "delivery", [])
            _apply_func!(delivery, "withdrawal_min", kgps_to_mmscfd)
            _apply_func!(delivery, "withdrawal_max", kgps_to_mmscfd)
            _apply_func!(delivery, "withdrawal_nominal", kgps_to_mmscfd)
            _apply_func!(delivery, "bid_price", inv_kgps_to_mmscfd)
        end

        for (i, regulator) in get(data, "regulator", [])
            _apply_func!(regulator, "flow_min", kgps_to_mmscfd)
            _apply_func!(regulator, "flow_max", kgps_to_mmscfd)
            _apply_func!(regulator, "design_flow_rate", kgps_to_mmscfd)
            _apply_func!(regulator, "design_inlet_pressure", pascal_to_psi)
            _apply_func!(regulator, "design_outlet_pressure", pascal_to_psi)
        end

        for (i, storage) in get(data, "storage", [])
            _apply_func!(storage, "pressure_nominal", pascal_to_psi)
            _apply_func!(storage, "flow_injection_rate_min", kgps_to_mmscfd)
            _apply_func!(storage, "flow_injection_rate_max", kgps_to_mmscfd)
            _apply_func!(storage, "flow_withdrawal_rate_min", kgps_to_mmscfd)
            _apply_func!(storage, "flow_withdrawal_rate_max", kgps_to_mmscfd)
            _apply_func!(storage, "capacity", kg_to_mmscf)
        end

        data["is_per_unit"] = 0
        data["is_si_units"] = 0
        data["is_english_units"] = 1
    end
    return
end


"Transforms network data into per unit"
function make_per_unit!(data::Dict{String,<:Any})
    if get(data, "is_per_unit", false) == true
        return
    end
    if get(data, "is_english_units", false) == true
        make_si_units!(data)
    end
    if get(data, "is_si_units", false) == true
        rescale_flow      = x -> x / get_base_flow(data)
        rescale_pressure  = x -> x / get_base_pressure(data)
        rescale_length    = x -> x / get_base_length(data)
        rescale_time      = x -> x / get_base_time(data)
        rescale_mass      = x -> x / get_base_flow(data) / get_base_time(data)

        for (i, junction) in get(data, "junction", [])
            _apply_func!(junction, "p_min", rescale_pressure)
            _apply_func!(junction, "p_max", rescale_pressure)
            _apply_func!(junction, "p_nominal", rescale_pressure)
        end

        for (i, pipe) in get(data, "pipe", [])
            _apply_func!(pipe, "length", rescale_length)
            _apply_func!(pipe, "p_min", rescale_pressure)
            _apply_func!(pipe, "p_max", rescale_pressure)
        end

        for (i, pipe) in get(data, "ne_pipe", [])
            _apply_func!(pipe, "length", rescale_length)
            _apply_func!(pipe, "p_min", rescale_pressure)
            _apply_func!(pipe, "p_max", rescale_pressure)
        end

        for (i, compressor) in get(data, "compressor", [])
            _apply_func!(compressor, "length", rescale_length)
            _apply_func!(compressor, "flow_min", rescale_flow)
            _apply_func!(compressor, "flow_max", rescale_flow)
            _apply_func!(compressor, "inlet_p_min", rescale_pressure)
            _apply_func!(compressor, "inlet_p_max", rescale_pressure)
            _apply_func!(compressor, "outlet_p_min", rescale_pressure)
            _apply_func!(compressor, "outlet_p_max", rescale_pressure)
        end

        for (i, compressor) in get(data, "ne_compressor", [])
            _apply_func!(compressor, "length", rescale_length)
            _apply_func!(compressor, "flow_min", rescale_flow)
            _apply_func!(compressor, "flow_max", rescale_flow)
            _apply_func!(compressor, "inlet_p_min", rescale_pressure)
            _apply_func!(compressor, "inlet_p_max", rescale_pressure)
            _apply_func!(compressor, "outlet_p_min", rescale_pressure)
            _apply_func!(compressor, "outlet_p_max", rescale_pressure)
        end

        for (i, transfer) in get(data, "transfer", [])
            _apply_func!(transfer, "withdrawal_min", rescale_flow)
            _apply_func!(transfer, "withdrawal_max", rescale_flow)
            _apply_func!(transfer, "withdrawal_nominal", rescale_flow)
        end

        for (i, receipt) in get(data, "receipt", [])
            _apply_func!(receipt, "injection_min", rescale_flow)
            _apply_func!(receipt, "injection_max", rescale_flow)
            _apply_func!(receipt, "injection_nominal", rescale_flow)
        end

        for (i, delivery) in get(data, "delivery", [])
            _apply_func!(delivery, "withdrawal_min", rescale_flow)
            _apply_func!(delivery, "withdrawal_max", rescale_flow)
            _apply_func!(delivery, "withdrawal_nominal", rescale_flow)
        end

        for (i, regulator) in get(data, "regulator", [])
            _apply_func!(regulator, "flow_min", rescale_flow)
            _apply_func!(regulator, "flow_max", rescale_flow)
            _apply_func!(regulator, "design_flow_rate", rescale_flow)
            _apply_func!(regulator, "design_inlet_pressure", rescale_pressure)
            _apply_func!(regulator, "design_outlet_pressure", rescale_pressure)
        end

        for (i, storage) in get(data, "storage", [])
            _apply_func!(storage, "pressure_nominal", rescale_pressure)
            _apply_func!(storage, "flow_injection_rate_min", rescale_flow)
            _apply_func!(storage, "flow_injection_rate_max", rescale_flow)
            _apply_func!(storage, "flow_withdrawal_rate_min", rescale_flow)
            _apply_func!(storage, "flow_withdrawal_rate_max", rescale_flow)
            _apply_func!(storage, "capacity", rescale_mass)
        end

        data["is_per_unit"] = 1
        data["is_si_units"] = 0
        data["is_english_units"] = 0
    end
    return
end


"checks for non-negativity of certain fields in the data"
function check_non_negativity(data::Dict{String,<:Any})
    for field in non_negative_metadata
        if get(data, field, 0.0) < 0.0
            Memento.error(_LOGGER, "metadata $field is < 0")
        end
    end

    for field in keys(non_negative_data)
        for (i, table) in get(data, field, [])
            for column_name in get(non_negative_data, field, [])
                if get(table, column_name, 0.0) < 0.0
                    Memento.error(_LOGGER, "$field[$i][$column_name] is < 0")
                end
            end
        end
    end
end


"checks validity of global-level parameters"
function check_global_parameters(data::Dict{String,<:Any})
    if get(data, "temperature", 273.15) < 260 || get(data, "temperature", 273.15) > 320
        Memento.warn(_LOGGER, "temperature of $(data["temperature"]) K is unrealistic")
    end

    if get(data, "specific_heat_capacity_ratio", 1.4) < 1.2 || get(data, "specific_heat_capacity_ratio", 1.4) > 1.6
        Memento.warn(_LOGGER, "specific heat capacity ratio of $(data["specific_heat_capacity_ratio"]) is unrealistic")
    end

    if get(data, "gas_specific_gravity", 0.6) < 0.5 || get(data, "gas_specific_gravity", 0.6) > 0.7
        Memento.warn(_LOGGER, "gas specific gravity $(data["gas_specific_gravity"]) is unrealistic")
    end

    if get(data, "sound_speed", 355.0) < 300.0 || get(data, "sound_speed", 355.0) > 410.0
        Memento.warn(_LOGGER, "sound speed of $(data["sound_speed"]) m/s is unrealistic")
    end

    if get(data, "compressibility_factor", 0.8) < 0.7 || get(data, "compressibility_factor", 0.8) > 1.0
        Memento.warn(_LOGGER, "compressibility_factor $(data["compressibility_factor"]) is unrealistic")
    end
end


"correct minimum pressures"
function correct_p_mins!(data::Dict{String, Any}; si_value=1.37e6, english_value=200.0)
    for (i, junction) in get(data, "junction", [])
        if junction["p_min"] < 1e-5
            Memento.warn(_LOGGER, "junction $i's p_min changed to 1.37E6 Pa (200 PSI) from 0")
            (data["is_si_units"] == 1) && (junction["p_min"] = si_value)
            (data["is_si_units"] == 1) && (junction["p_min"] = english_value)
        end
    end

    for (i, pipe) in get(data, "pipe", [])
        if pipe["p_min"] < 1e-5
            Memento.warn(_LOGGER, "pipe $i's p_min changed to 1.37E6 Pa (200 PSI) from 0")
            (data["is_si_units"] == 1) && (pipe["p_min"] = si_value)
            (data["is_si_units"] == 1) && (pipe["p_min"] = english_value)
        end
    end

    for (i, compressor) in get(data, "compressor", [])
        if compressor["inlet_p_min"] < 1e-5
            Memento.warn(_LOGGER, "compressor $i's inlet_p_min changed to 1.37E6 Pa (200 PSI) from 0")
            (data["is_si_units"] == 1) && (compressor["inlet_p_min"] = si_value)
            (data["is_si_units"] == 1) && (compressor["inlet_p_min"] = english_value)
        end
        if compressor["outlet_p_min"] < 1e-5
            Memento.warn(_LOGGER, "compressor $i's outlet_p_min changed to 1.37E6 Pa (200 PSI) from 0")
            (data["is_si_units"] == 1) && (compressor["outlet_p_min"] = si_value)
            (data["is_si_units"] == 1) && (compressor["outlet_p_min"] = english_value)
        end
    end

    return
end


"add additional compressor fields - required for transient"
function add_compressor_fields!(data::Dict{String,<:Any})
    is_si_units = get(data, "is_si_units", 0)
    is_english_units = get(data, "is_english_units", 0)
    is_per_unit = get(data, "is_per_unit", false)
    for (i, compressor) in data["compressor"]
        if is_si_units == true
            compressor["diameter"] = 1.0
            compressor["length"] = 250.0
            compressor["friction_factor"] = 0.001
        end
        if is_english_units == true
            compressor["diameter"] = 39.37
            compressor["length"] = 0.16
            compressor["friction_factor"] = 0.001
        end
        if is_per_unit == true
            base_length = get(data, "base_length", 5000.0)
            compressor["diameter"] = 1.0
            compressor["length"] = 250.0/base_length
            compressor["friction_factor"] = 0.001
        end
    end

    if haskey(data, "ne_compressor")
        for (i, compressor) in data["ne_compressor"]
            if is_si_units == true
                compressor["diameter"] = 1.0
                compressor["length"] = 250.0
                compressor["friction_factor"] = 0.001
            end
            if is_english_units == true
                compressor["diameter"] = 39.37
                compressor["length"] = 0.16
                compressor["friction_factor"] = 0.001
            end
            if is_per_unit == true
                base_length = get(data, "base_length", 5000.0)
                compressor["diameter"] = 1.0
                compressor["length"] = 250.0/base_length
                compressor["friction_factor"] = 0.001
            end
        end
    end
end


"checks that all buses are unique and other components link to valid buses"
function check_connectivity(data::Dict{String,<:Any})
    if InfrastructureModels.ismultinetwork(data)
        for (n, nw_data) in data["nw"]
            _check_connectivity(nw_data)
        end
    else
        _check_connectivity(data)
    end
end


const _gm_component_types = ["pipe", "compressor", "valve", "regulator", "short_pipe",
    "resistor", "ne_pipe", "ne_compressor", "junction", "delivery", "receipt"]

const _gm_junction_keys = ["fr_junction", "to_junction", "junction"]

const _gm_edge_types = ["pipe", "compressor", "valve", "regulator", "short_pipe", "resistor", "ne_pipe", "ne_compressor"]


"checks that all buses are unique and other components link to valid buses"
function _check_connectivity(data::Dict{String,<:Any})
    junc_ids = Set(junc["id"] for (i,junc) in data["junction"])
    @assert(length(junc_ids) == length(data["junction"])) # if this is not true something very bad is going on

    for comp_type in _gm_component_types
        for (i, comp) in get(data, comp_type, Dict())
            for junc_key in _gm_junction_keys
                if haskey(comp, junc_key)
                    if !(comp[junc_key] in junc_ids)
                        Memento.warn(_LOGGER, "$junc_key $(comp[junc_key]) in $comp_type $i is not defined")
                    end
                end
            end
        end
    end
end


"checks that active components are not connected to inactive buses, otherwise prints warnings"
function check_status(data::Dict{String,<:Any})
    if InfrastructureModels.ismultinetwork(data)
        Memento.error(_LOGGER, "check_status does not yet support multinetwork data")
    end

    active_junction_ids = Set(junction["id"] for (i,junction) in data["junction"] if get(junction, "status", 1) != 0)

    for comp_type in _gm_component_types
        for (i, comp) in get(data, comp_type, Dict())
            for junc_key in _gm_junction_keys
                if haskey(comp, junc_key)
                    if get(comp, "status", 1) != 0 && !(comp[junc_key] in active_junction_ids)
                        Memento.warn(_LOGGER, "active $comp_type $i is connected to inactive junction $(comp[junc_key])")
                    end
                end
            end
        end
    end
end


"checks that all edges connect two distinct junctions"
function check_edge_loops(data::Dict{String,<:Any})
    if InfrastructureModels.ismultinetwork(data)
        Memento.error(_LOGGER, "check_edge_loops does not yet support multinetwork data")
    end

    for edge_type in _gm_edge_types
        if haskey(data, edge_type)
            for edge in values(data[edge_type])
                if edge["fr_junction"] == edge["to_junction"]
                    Memento.error(_LOGGER, "both sides of $edge_type $(edge["index"]) connect to junction $(edge["fr_junction"])")
                end
            end
        end
    end
end


"helper function to propagate disabled status of junctions to connected components"
function propagate_topology_status!(data::Dict{String,<:Any})
    disabled_junctions = Set([junc["junction_i"] for junc in values(data["junction"]) if junc["status"] == 0])

    for comp_type in _gm_component_types
        if haskey(data, comp_type) && comp_type != "junction"
            for comp in values(data[comp_type])
                for junc_key in _gm_junction_keys
                    if haskey(comp, junc_key) && comp[junc_key] in disabled_junctions
                        comp["status"] = 0
                        Memento.info(_LOGGER, "Change status of $comp_type $(comp["index"]) because connecting junction $(comp[junc_key]) is disabled")
                        break
                    end
                end
            end
        end
    end
end


"Calculates max mass flow network wide using ref"
function _calc_max_mass_flow(ref::Dict{Symbol,Any})
    max_flow = 0
    for (idx, receipt) in ref[:receipt]
        if receipt["injection_max"] > 0
            max_flow = max_flow + receipt["injection_max"]
        end
    end
    for (idx, storage) in ref[:storage]
        if storage["flow_injection_rate_max"] > 0
            max_flow = max_flow + storage["flow_injection_rate_max"]
        end
    end
    for (idx, transfer) in ref[:transfer]
        if transfer["withdrawal_min"] < 0
            max_flow = max_flow - transfer["withdrawal_min"]
        end
    end
    return max_flow
end


"Calculate the bounds on minimum and maximum pressure difference squared"
function _calc_pd_bounds_sqr(ref::Dict{Symbol,Any}, i_idx::Int, j_idx::Int)
    i = ref[:junction][i_idx]
    j = ref[:junction][j_idx]

    pd_max = i["p_max"]^2 - j["p_min"]^2
    pd_min = i["p_min"]^2 - j["p_max"]^2

    return pd_min, pd_max
end


"Calculates pipeline resistance from this paper Thorley and CH Tiley. Unsteady and transient flow of compressible
fluids in pipelines–a review of theoretical and some experimental studies.
International Journal of Heat and Fluid Flow, 8(1):3–15, 1987
This is used in many of Zlotnik's papers
This calculation expresses resistance in terms of mass flow equations"
function _calc_pipe_resistance(pipe::Dict{String,Any}, base_length, base_pressure, base_flow, sound_speed)
    lambda     = pipe["friction_factor"]
    D          = pipe["diameter"]
    L          = pipe["length"] * base_length

    a_sqr = sound_speed^2
    A     = (pi*D^2) / 4 # cross sectional area
    resistance = ( (D * A^2) / (lambda * L * a_sqr)) * (base_pressure^2 / base_flow^2) # second half is the non-dimensionalization
    return resistance
end


"Calculates pipeline resistance from this paper Thorley and CH Tiley.
Unsteady and transient flow of compressible
fluids in pipelines–a review of theoretical and some experimental studies.
International Journal of Heat and Fluid Flow, 8(1):3–15, 1987
This is used in many of Zlotnik's papers
This calculation expresses resistance in terms of mass flow equations"
function _calc_pipe_resistance_rho_phi_space(pipe::Dict{String,Any}, base_length)
    lambda      = pipe["friction_factor"]
    D           = pipe["diameter"]
    L           = pipe["length"]

    resistance = lambda * L * base_length / D;
    return resistance
end


"calculates the minimum flow on a pipe"
function _calc_pipe_flow_min(ref::Dict{Symbol,Any}, pipe)
    mf             = ref[:max_mass_flow]
    pd_min         = pipe["pd_min"]
    w              = pipe["resistance"]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a pipe"
function _calc_pipe_flow_max(ref::Dict{Symbol,Any}, pipe)
    mf             = ref[:max_mass_flow]
    pd_max         = pipe["pd_max"]
    w              = pipe["resistance"]
    pf_max         = pd_max < 0 ? -sqrt(w*abs(pd_max)) : sqrt(w*abs(pd_max))

    return min(mf, pf_max)
end


"A very simple model of computing resistance for resistors that is based on the Thorley model.
Eq (2.30) in Evaluating Gas Network Capacities"
function _calc_resistor_resistance(resistor::Dict{String,Any})
    lambda     = resistor["drag"]
    D          = resistor["diameter"]
    A          = (pi*D^2) / 4

    resistance = lambda / A / A / 2
    return resistance
end


"calculates the minimum flow on a resistor"
function _calc_resistor_flow_min(ref::Dict{Symbol,Any}, resistor)
    mf             = ref[:max_mass_flow]
    pd_min         = resistor["pd_min"]
    w              = resistor["resistance"]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a resistor"
function _calc_resistor_flow_max(ref::Dict{Symbol,Any}, resistor)
    mf             = ref[:max_mass_flow]
    pd_max         = resistor["pd_max"]
    w              = resistor["resistance"]
    pf_max         = pd_max < 0 ? -sqrt(w*abs(pd_max)) : sqrt(w*abs(pd_max))
    return min(mf, pf_max)
end


"calculates the minimum flow on a short pipe"
_calc_short_pipe_flow_min(ref::Dict{Symbol,Any}, short_pipe) = -ref[:max_mass_flow]


"calculates the maximum flow on a short pipe"
_calc_short_pipe_flow_max(ref::Dict{Symbol,Any}, short_pipe) = ref[:max_mass_flow]


"calculates the minimum flow on a valve"
_calc_valve_flow_min(ref::Dict{Symbol,Any}, valve) = -ref[:max_mass_flow]


"calculates the maximum flow on a valve"
_calc_valve_flow_max(ref::Dict{Symbol,Any}, valve) = ref[:max_mass_flow]


"calculates the minimum flow on a regulator"
_calc_regulator_flow_min(ref::Dict{Symbol,Any}, regulator) = -ref[:max_mass_flow]


"calculates the maximum flow on a regulator"
_calc_regulator_flow_max(ref::Dict{Symbol,Any}, resistor) = ref[:max_mass_flow]


"extracts the start value"
function comp_start_value(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)
end


"Helper function for determining if direction cuts can be applied"
function _apply_mass_flow_cuts(yp, branches)
    is_disjunction = true
    for k in branches
        is_disjunction &= isassigned(yp,k)
    end
    return is_disjunction
end


"calculates connections in parallel with one another and their orientation"
function _calc_parallel_connections(gm::AbstractGasModel, n::Int, connection::Dict{String,Any})
    i = min(connection["fr_junction"], connection["to_junction"])
    j = max(connection["fr_junction"], connection["to_junction"])

    parallel_pipes          = haskey(ref(gm,n,:parallel_pipes), (i,j)) ? ref(gm,n,:parallel_pipes, (i,j)) : []
    parallel_compressors    = haskey(ref(gm,n,:parallel_compressors), (i,j)) ? ref(gm,n,:parallel_compressors, (i,j)) : []
    parallel_short_pipes    = haskey(ref(gm,n,:parallel_short_pipes), (i,j)) ? ref(gm,n,:parallel_short_pipes, (i,j)) : []
    parallel_resistors      = haskey(ref(gm,n,:parallel_resistors), (i,j)) ? ref(gm,n,:parallel_resistors, (i,j)) : []
    parallel_valves         = haskey(ref(gm,n,:parallel_valves), (i,j)) ? ref(gm,n,:parallel_valves, (i,j)) : []
    parallel_regulators = haskey(ref(gm,n,:parallel_regulators), (i,j)) ? ref(gm,n,:parallel_regulators, (i,j)) : []

    num_connections = length(parallel_pipes) + length(parallel_compressors) + length(parallel_short_pipes) + length(parallel_resistors) +
                      length(parallel_valves) + length(parallel_regulators)

    pipes = ref(gm,n,:pipe)
    compressors = ref(gm,n,:compressor)
    resistors = ref(gm,n,:resistor)
    short_pipes = ref(gm,n,:short_pipe)
    valves = ref(gm,n,:valve)
    regulators = ref(gm,n,:regulator)

    aligned_pipes           = filter(i -> pipes[i]["fr_junction"] == connection["fr_junction"], parallel_pipes)
    opposite_pipes          = filter(i -> pipes[i]["fr_junction"] != connection["fr_junction"], parallel_pipes)
    aligned_compressors     = filter(i -> compressors[i]["fr_junction"] == connection["fr_junction"], parallel_compressors)
    opposite_compressors    = filter(i -> compressors[i]["fr_junction"] != connection["fr_junction"], parallel_compressors)
    aligned_resistors       = filter(i -> resistors[i]["fr_junction"] == connection["fr_junction"], parallel_resistors)
    opposite_resistors      = filter(i -> resistors[i]["fr_junction"] != connection["fr_junction"], parallel_resistors)
    aligned_short_pipes     = filter(i -> short_pipes[i]["fr_junction"] == connection["fr_junction"], parallel_short_pipes)
    opposite_short_pipes    = filter(i -> short_pipes[i]["fr_junction"] != connection["fr_junction"], parallel_short_pipes)
    aligned_valves          = filter(i -> valves[i]["fr_junction"] == connection["fr_junction"], parallel_valves)
    opposite_valves         = filter(i -> valves[i]["fr_junction"] != connection["fr_junction"], parallel_valves)
    aligned_regulators  = filter(i -> regulators[i]["fr_junction"] == connection["fr_junction"], parallel_regulators)
    opposite_regulators = filter(i -> regulators[i]["fr_junction"] != connection["fr_junction"], parallel_regulators)

    return num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators
end


"calculates connections in parallel with one another and their orientation"
function _calc_parallel_ne_connections(gm::AbstractGasModel, n::Int, connection::Dict{String,Any})
    i = min(connection["fr_junction"], connection["to_junction"])
    j = max(connection["fr_junction"], connection["to_junction"])

    parallel_pipes          = haskey(ref(gm,n,:parallel_pipes), (i,j)) ? ref(gm,n,:parallel_pipes, (i,j)) : []
    parallel_compressors    = haskey(ref(gm,n,:parallel_compressors), (i,j)) ? ref(gm,n,:parallel_compressors, (i,j)) : []
    parallel_short_pipes    = haskey(ref(gm,n,:parallel_short_pipes), (i,j)) ? ref(gm,n,:parallel_short_pipes, (i,j)) : []
    parallel_resistors      = haskey(ref(gm,n,:parallel_resistors), (i,j)) ? ref(gm,n,:parallel_resistors, (i,j)) : []
    parallel_valves         = haskey(ref(gm,n,:parallel_valves), (i,j)) ? ref(gm,n,:parallel_valves, (i,j)) : []
    parallel_regulators = haskey(ref(gm,n,:parallel_regulators), (i,j)) ? ref(gm,n,:parallel_regulators, (i,j)) : []
    parallel_ne_pipes       = haskey(ref(gm,n,:parallel_ne_pipes), (i,j)) ? ref(gm,n,:parallel_ne_pipes, (i,j)) : []
    parallel_ne_compressors = haskey(ref(gm,n,:parallel_ne_compressors), (i,j)) ? ref(gm,n,:parallel_ne_compressors, (i,j)) : []

    num_connections = length(parallel_pipes) + length(parallel_compressors) + length(parallel_short_pipes) + length(parallel_resistors) +
                      length(parallel_valves) + length(parallel_regulators) + length(parallel_ne_pipes) + length(parallel_ne_compressors)

    pipes = ref(gm,n,:pipe)
    compressors = ref(gm,n,:compressor)
    resistors = ref(gm,n,:resistor)
    short_pipes = ref(gm,n,:short_pipe)
    valves = ref(gm,n,:valve)
    regulators = ref(gm,n,:regulator)
    ne_pipes = ref(gm,n,:ne_pipe)
    ne_compressors = ref(gm,n,:ne_compressor)

    aligned_pipes           = filter(i -> pipes[i]["fr_junction"] == connection["fr_junction"], parallel_pipes)
    opposite_pipes          = filter(i -> pipes[i]["fr_junction"] != connection["fr_junction"], parallel_pipes)
    aligned_compressors     = filter(i -> compressors[i]["fr_junction"] == connection["fr_junction"], parallel_compressors)
    opposite_compressors    = filter(i -> compressors[i]["fr_junction"] != connection["fr_junction"], parallel_compressors)
    aligned_resistors       = filter(i -> resistors[i]["fr_junction"] == connection["fr_junction"], parallel_resistors)
    opposite_resistors      = filter(i -> resistors[i]["fr_junction"] != connection["fr_junction"], parallel_resistors)
    aligned_short_pipes     = filter(i -> short_pipes[i]["fr_junction"] == connection["fr_junction"], parallel_short_pipes)
    opposite_short_pipes    = filter(i -> short_pipes[i]["fr_junction"] != connection["fr_junction"], parallel_short_pipes)
    aligned_valves          = filter(i -> valves[i]["fr_junction"] == connection["fr_junction"], parallel_valves)
    opposite_valves         = filter(i -> valves[i]["fr_junction"] != connection["fr_junction"], parallel_valves)
    aligned_regulators  = filter(i -> regulators[i]["fr_junction"] == connection["fr_junction"], parallel_regulators)
    opposite_regulators = filter(i -> regulators[i]["fr_junction"] != connection["fr_junction"], parallel_regulators)
    aligned_ne_pipes        = filter(i -> ne_pipes[i]["fr_junction"] == connection["fr_junction"], parallel_ne_pipes)
    opposite_ne_pipes       = filter(i -> ne_pipes[i]["fr_junction"] != connection["fr_junction"], parallel_ne_pipes)
    aligned_ne_compressors  = filter(i -> ne_compressors[i]["fr_junction"] == connection["fr_junction"], parallel_ne_compressors)
    opposite_ne_compressors = filter(i -> ne_compressors[i]["fr_junction"] != connection["fr_junction"], parallel_ne_compressors)

    return num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators, aligned_ne_pipes, opposite_ne_pipes, aligned_ne_compressors, opposite_ne_compressors
end


"prints the text summary for a data file to IO"
function summary(io::IO, file::String; kwargs...)
    data = parse_file(file)
    summary(io, data; kwargs...)
    return data
end


const _gm_component_types_order = Dict(
    "junction" => 1.0, "pipe" => 2.0, "compressor" => 3.0, "receipt" => 4.0, "delivery" => 5.0, "transfer" => 6.0,
    "resistor" => 7.0, "short_pipe" => 8.0, "regulator" => 9.0, "valve" => 10.0, "storage" => 11.0
)


const _gm_component_parameter_order = Dict(
    "id" => 1.0, "junction_type" => 2.0,
    "p_min" => 3.0, "p_max" => 4.0, "p_nominal" => 5.0,

    "fr_junction" => 11.0, "to_junction" => 12.0,
    "length" => 13.0, "diameter" => 14.0, "friction_factor" => 15.0,
    "flow_min" => 16.0, "flow_max" => 17.0,
    "c_ratio_min" => 18.0, "c_ratio_max" => 19.0,
    "power_max" => 20.0,

    "junction_id" => 51.0,
    "injection_nominal" => 52.0, "injection_min" => 53.0, "injection_max" => 54.0,

    "withdrawal_nominal" => 72.0, "withdrawal_min" => 73.0, "withdrawal_max" => 74.0,

    "status" => 500.0,
)


"prints the text summary for a data dictionary to IO"
function summary(io::IO, data::Dict{String,Any}; kwargs...)
    InfrastructureModels.summary(io, data;
        component_types_order = _gm_component_types_order,
        component_parameter_order = _gm_component_parameter_order,
        kwargs...)
end


"""
computes the connected components of the network graph
returns a set of sets of juntion ids, each set is a connected component
"""
function calc_connected_components(data::Dict{String,<:Any}; edges=_gm_edge_types)
    if InfrastructureModels.ismultinetwork(data)
        Memento.error(_LOGGER, "calc_connected_components does not yet support multinetwork data")
    end

    active_junction = Dict(x for x in data["junction"] if x.second["status"] != 0)
    active_junction_ids = Set{Int64}([junction["junction_i"] for (i,junction) in active_junction])

    neighbors = Dict(i => [] for i in active_junction_ids)
    for edge_type in edges
        for edge in values(get(data, edge_type, Dict()))
            if get(edge, "status", 1) != 0 && edge["fr_junction"] in active_junction_ids && edge["to_junction"] in active_junction_ids
                push!(neighbors[edge["fr_junction"]], edge["to_junction"])
                push!(neighbors[edge["to_junction"]], edge["fr_junction"])
            end
        end
    end

    component_lookup = Dict(i => Set{Int64}([i]) for i in active_junction_ids)
    touched = Set{Int64}()

    for i in active_junction_ids
        if !(i in touched)
            _dfs(i, neighbors, component_lookup, touched)
        end
    end

    ccs = (Set(values(component_lookup)))

    return ccs
end


"perModels DFS on a graph"
function _dfs(i, neighbors, component_lookup, touched)
    push!(touched, i)
    for j in neighbors[i]
        if !(j in touched)
            new_comp = union(component_lookup[i], component_lookup[j])
            for k in new_comp
                component_lookup[k] = new_comp
            end
            _dfs(j, neighbors, component_lookup, touched)
        end
    end
end
