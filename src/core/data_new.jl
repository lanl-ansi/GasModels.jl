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
            data["base_time"] = get_base_length(data) / get_sound_speed(data)
            data["base_flow"] = get_base_pressure(data) / get_sound_speed(data)
        end  
    end 
end 

"adds additional non-dimensional constants to data dictionary"
function add_base_values!(data::Dict{String, Any})
    (get(data, "base_pressure", false) == false) && (data["base_pressure"] = calc_base_pressure(data))
    (get(data, "base_length", false) == false) && (data["base_length"] = 5000.0)
    data["base_time"] = get_base_length(data) / get_sound_speed(data)
    data["base_flow"] = get_base_pressure(data) / get_sound_speed(data)
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

        for (i, compressor) in get(data, "compressor", [])
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

        for (i, compressor) in get(data, "compressor", [])
            _apply_func!(compressor, "power_max", hp_to_watts)
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
    end 
    data["is_per_unit"] = 0
    data["is_si_units"] = 1 
    data["is_english_units"] = 0
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

        for (i, compressor) in get(data, "compressor", [])
            _apply_func!(compressor, "power_max", watts_to_hp)
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
    end 
    data["is_per_unit"] = 0
    data["is_si_units"] = 0 
    data["is_english_units"] = 1
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

        for (i, compressor) in get(data, "compressor", [])
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
    end 
    data["is_per_unit"] = 1
    data["is_si_units"] = 0 
    data["is_english_units"] = 0
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
                    Memento.error(_LOGGER, "both sides of $edge_type $(edge["index"]) connect to junction $(edge["junction_fr"])")
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