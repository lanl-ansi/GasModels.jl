# tools for working with GasModels internal data format

"GasModels wrapper for the InfrastructureModels `apply!` function."
function apply_gm!(func!::Function, data::Dict{String, <:Any}; apply_to_subnetworks::Bool = true)
    _IM.apply!(func!, data, gm_it_name; apply_to_subnetworks = apply_to_subnetworks)
end


"GasModels wrapper for the InfrastructureModels `get_data` function."
function get_data_gm(func::Function, data::Dict{String, <:Any}; apply_to_subnetworks::Bool = true)
    return _IM.get_data(func, data, gm_it_name; apply_to_subnetworks = apply_to_subnetworks)
end


"Convenience function for retrieving the gas-only portion of network data."
function get_gm_data(data::Dict{String, <:Any})
    return _IM.ismultiinfrastructure(data) ? data["it"][gm_it_name] : data
end


"data getters"
@inline get_base_pressure(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_pressure"]), data; apply_to_subnetworks = false)
@inline get_base_density(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_density"]), data; apply_to_subnetworks = false)
@inline get_base_length(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_length"]), data; apply_to_subnetworks = false)
@inline get_base_flow(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_flow"]), data; apply_to_subnetworks = false)
@inline get_base_flux(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_flux"]), data; apply_to_subnetworks = false)
@inline get_base_time(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_time"]), data; apply_to_subnetworks = false)
@inline get_base_diameter(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_diameter"]), data; apply_to_subnetworks = false)
@inline get_base_volume(data::Dict{String, <:Any}) = get_data_gm((x -> return x["base_volume"]), data; apply_to_subnetworks = false)
@inline get_sound_speed(data::Dict{String, <:Any}) = get_data_gm((x -> return get(x, "sound_speed", 371.6643)), data; apply_to_subnetworks = false)
@inline get_specific_heat_capacity_ratio(data::Dict{String, <:Any}) = get_data_gm((x -> return get(x, "specific_heat_capacity_ratio", 0.6)), data; apply_to_subnetworks = false)
@inline get_gas_specific_gravity(data::Dict{String, <:Any}) = get_data_gm((x -> return get(x, "gas_specific_gravity", 0.6)), data; apply_to_subnetworks = false)
@inline get_gas_constant(data::Dict{String, <:Any}) = get_data_gm((x -> return get(x, "R", 8.314)), data; apply_to_subnetworks = false)
@inline get_temperature(data::Dict{String, <:Any}) = get_data_gm((x -> return get(x, "temperature", 288.7060)), data; apply_to_subnetworks = false)
@inline get_base_mass(data::Dict{String, <:Any}) = get_base_flow(data) * get_base_time(data)
@inline get_economic_weighting(data::Dict{String, <:Any}) = get_data_gm((x -> return get(x, "economic_weighting", 1.0)), data; apply_to_subnetworks = false)


"calculates base_pressure"
function calc_base_pressure(data::Dict{String,<:Any})
    p_squares = [junc["p_max"]^2 for junc in values(data["junction"])]

    if length(p_squares) > 0
        # Use the square root of the median max squared pressure.
        return sqrt(Statistics.median(p_squares))
    else
        return 1.379e6 # In Pascals, 200 PSI.
    end
end

"calculates the base_time"
function calc_base_time(data::Dict{String,<:Any})
    return get_base_length(data) / get_sound_speed(data)
end

"calculates the base_flow - this is actually wrong terminology (has to be base_flux - kg/m^2/s, flow is kg/s)"
function calc_base_flow(data::Dict{String,<:Any})
    return get_base_pressure(data) / get_sound_speed(data)
end

"calculates the base_flux"
function calc_base_flux(data::Dict{String,<:Any})
    return get_base_density(data) * get_sound_speed(data)
end

"calculates the base density"
function calc_base_density(data::Dict{String,<:Any})
    return get_base_pressure(data) / get_sound_speed(data)^2
end

"estimates standard density from existing data"
function _estimate_standard_density(data::Dict{String,<:Any})
    standard_pressure = 101325.0 # 1 atm in Pascals
    molecular_mass_of_air = 0.02896
    temperature = get_temperature(data)
    specific_gravity = get_gas_specific_gravity(data)
    gas_constant = get_gas_constant(data)

    return standard_pressure * specific_gravity *
        molecular_mass_of_air * inv(temperature * gas_constant)
end

"apply a function on a dict entry"
function _apply_func!(data::Dict{String,Any}, key::String, func)
    if haskey(data, key)
        data[key] = func(data[key])
    end
end


"if original data is in per-unit ensure it has base values"
function per_unit_data_field_check!(data::Dict{String, <:Any})
    apply_gm!(_per_unit_data_field_check!, data; apply_to_subnetworks = false)
end


"if original data is in per-unit ensure it has base values"
function _per_unit_data_field_check!(data::Dict{String,Any})
    if get(data, "is_per_unit", false) == true
        if get(data, "base_pressure", false) == false || get(data, "base_length", false) == false
            Memento.error(_LOGGER, "data in .m file is in per unit but no base_pressure (in Pa) and base_length (in m) values are provided")
        else
            if get(data, "base_density", false) == false
                data["base_density"] = calc_base_density(data)
            end

            data["base_diameter"] = 1.0
            data["base_time"] = calc_base_time(data)

            if get(data, "base_flow", false) == false
                data["base_flow"] = calc_base_flow(data)
            end

            if get(data, "base_flux", false) == false
                data["base_flux"] = calc_base_flux(data)
            end
        end
    end
end


"adds additional non-dimensional constants to data dictionary"
function add_base_values!(data::Dict{String, <:Any})
    apply_gm!(_add_base_values!, data; apply_to_subnetworks = false)
end


"adds additional non-dimensional constants to data dictionary"
function _add_base_values!(data::Dict{String,Any})
    if get(data, "base_pressure", false) == false
        data["base_pressure"] = calc_base_pressure(data)
    end

    if get(data, "base_density", false) == false
        data["base_density"] = calc_base_density(data)
    end

    if get(data, "base_length", false) == false
        data["base_length"] = 5000.0
    end

    data["base_diameter"] = 1.0
    data["base_time"] = calc_base_time(data)

    if get(data, "base_flow", false) == false
        data["base_flow"] = calc_base_flow(data)
    end

    if get(data, "base_flux", false) == false
        data["base_flux"] = calc_base_flux(data)
    end

    if get(data, "base_volume", false) == false
        data["base_volume"] = data["base_length"]
    end

    if get(data, "base_mass", false) == false
        data["base_mass"] = data["base_density"] * data["base_volume"]
    end
end


"make transient data to si units"
function make_si_units!(transient_data::Array{Dict{String, Any}, 1}, static_data::Dict{String,Any})
    gm_static_data = get_gm_data(static_data)

    if gm_static_data["units"] == "si"
        return
    end

    mmscfd_to_kgps = x -> x * get_mmscfd_to_kgps_conversion_factor(gm_static_data)
    inv_mmscfd_to_kgps = x -> x / get_mmscfd_to_kgps_conversion_factor(gm_static_data)

    pressure_params = [
        "p_min",
        "p_max",
        "p_nominal",
        "p",
        "inlet_p_min",
        "inlet_p_max",
        "outlet_p_min",
        "outlet_p_max",
        "design_inlet_pressure",
        "design_outlet_pressure",
        "pressure_nominal",
        "reservoir_p_max",
        "reservoir_pressure",
    ]

    flow_params = [
        "f",
        "fd",
        "ft",
        "fg",
        "flow_min",
        "flow_max",
        "withdrawal_min",
        "withdrawal_max",
        "withdrawal_nominal",
        "injection_min",
        "injection_max",
        "injection_nominal",
        "design_flow_rate",
        "flow_injection_rate_min",
        "flow_injection_rate_max",
        "flow_withdrawal_rate_min",
        "flow_withdrawal_rate_max",
        "well_flux_avg",
        "well_flux_neg",
        "bottom_hole_flow",
        "well_head_flow",
    ]

    inv_flow_params = ["bid_price", "offer_price"]

    for line in transient_data
        param = line["parameter"]

        if param in pressure_params
            line["value"] = psi_to_pascal(line["value"])
        end

        if param in flow_params
            line["value"] = mmscfd_to_kgps(line["value"])
        end

        if param in inv_flow_params
            line["value"] = inv_mmscfd_to_kgps(line["value"])
        end
    end
end

const _params_for_unit_conversions = Dict(
    "junction" => [
        "p_min",
        "p_max",
        "p_nominal",
        "p",
        "pressure",
        "density",
        "net_injection",
        "net_nodal_edge_out_flow",
    ],
    "original_junction" => ["p_min", "p_max", "p_nominal", "p"],
    "pipe" => [
        "length",
        "p_min",
        "p_max",
        "f",
        "flux",
        "flow",
        "flow_min",
        "flow_max",
        "flux_avg",
        "flux_neg",
        "flux_fr",
        "flux_to",
        "flow_avg",
        "flow_neg",
        "flow_fr",
        "flow_to",
    ],
    "original_pipe" => ["length", "p_min", "p_max", "f", "flow_min", "flow_max"],
    "ne_pipe" => ["length", "p_min", "p_max", "f", "flow_min", "flow_max"],
    "compressor" => [
        "length",
        "flow_min",
        "flow_max",
        "inlet_p_min",
        "inlet_p_max",
        "outlet_p_min",
        "outlet_p_max",
        "f",
        "power_max",
        "flow",
        "power",
        "power_var",
        "power_expr"
    ],
    "ne_compressor" => [
        "length",
        "flow_min",
        "flow_max",
        "inlet_p_min",
        "inlet_p_max",
        "outlet_p_min",
        "outlet_p_max",
        "f",
        "power_max",
    ],
    "transfer" => [
        "withdrawal_min",
        "withdrawal_max",
        "withdrawal_nominal",
        "ft",
        "bid_price",
        "offer_price",
        "injection",
        "withdrawal",
    ],
    "receipt" => [
        "injection_min",
        "injection_max",
        "injection_nominal",
        "fg",
        "offer_price",
        "injection",
    ],
    "delivery" => [
        "withdrawal_min",
        "withdrawal_max",
        "withdrawal_nominal",
        "fd",
        "bid_price",
        "withdrawal",
    ],
    "regulator" => [
        "flow_min",
        "flow_max",
        "design_flow_rate",
        "design_inlet_pressure",
        "design_outlet_pressure",
        "f",
    ],
    "storage" => [
        "well_depth",
        "reservoir_p_max",
        "flow_injection_rate_min",
        "flow_injection_rate_max",
        "flow_withdrawal_rate_min",
        "flow_withdrawal_rate_max",
        "base_gas_capacity",
        "total_field_capacity",
        "bottom_hole_flow",
        "well_head_flow",
        "well_flux_avg",
        "well_flux_neg",
        "well_flux_fr",
        "well_flux_to",
        "well_flow_avg",
        "well_flow_neg",
        "well_flow_fr",
        "well_flow_to",
        "reservoir_density",
        "reservoir_pressure",
        "well_density",
        "well_pressure",
        "withdrawal"
    ],
    "loss_resistor" => [
        "f",
        "p_loss",
        "flow_min",
        "flow_max"
    ],
    "resistor" => [
        "f",
        "flow_min",
        "flow_max"
    ],
    "valve" => [
        "flow_min",
        "flow_max"
    ],
)

function _rescale_functions(rescale_pressure::Function, rescale_density::Function, rescale_length::Function, rescale_diameter::Function, rescale_flow::Function, rescale_mass::Function, rescale_inv_flow::Function)::Dict{String,Function}
    Dict{String,Function}(
        "p_min" => rescale_pressure,
        "p_max" => rescale_pressure,
        "p_nominal" => rescale_pressure,
        "p" => rescale_pressure,
        "inlet_p_min" => rescale_pressure,
        "inlet_p_max" => rescale_pressure,
        "outlet_p_min" => rescale_pressure,
        "outlet_p_max" => rescale_pressure,
        "reservoir_pressure" => rescale_pressure,
        "well_pressure" => rescale_pressure,
        "pressure" => rescale_pressure,
        "p_loss" => rescale_pressure,
        "design_inlet_pressure" => rescale_pressure,
        "design_outlet_pressure" => rescale_pressure,
        "pressure_nominal" => rescale_pressure,
        "reservoir_p_max" => rescale_pressure,
        "density" => rescale_density,
        "reservoir_density" => rescale_density,
        "well_density" => rescale_density,
        "length" => rescale_length,
        "well_depth" => rescale_length,
        "diameter" => rescale_diameter,
        "well_diameter" => rescale_diameter,
        "f" => rescale_flow,
        "flow_min" => rescale_flow,
        "flow_max" => rescale_flow,
        "flow" => rescale_flow,
        "flux_avg" => rescale_flow,
        "flux_neg" => rescale_flow,
        "flux_fr" => rescale_flow,
        "flux_to" => rescale_flow,
        "flow_avg" => rescale_flow,
        "flow_neg" => rescale_flow,
        "flow_fr" => rescale_flow,
        "flow_to" => rescale_flow,
        "withdrawal" => rescale_flow,
        "injection" => rescale_flow,
        "power" => rescale_flow,
        "flux" => rescale_flow,
        "flow" => rescale_flow,
        "withdrawal_max" => rescale_flow,
        "withdrawal_min" => rescale_flow,
        "injection_min" => rescale_flow,
        "injection_max" => rescale_flow,
        "net_injection" => rescale_flow,
        "net_nodal_edge_out_flow" => rescale_flow,
        "withdrawal_nominal" => rescale_flow,
        "injection_nominal" => rescale_flow,
        "fd" => rescale_flow,
        "fg" => rescale_flow,
        "ft" => rescale_flow,
        "power_max" => rescale_flow,
        "power_var" => rescale_flow,
        "power_expr" => rescale_flow,
        "design_flow_rate" => rescale_flow,
        "flow_injection_rate_min" => rescale_flow,
        "flow_injection_rate_max" => rescale_flow,
        "flow_withdrawal_rate_min" => rescale_flow,
        "flow_withdrawal_rate_max" => rescale_flow,
        "base_gas_capacity" => rescale_mass,
        "total_field_capacity" => rescale_mass,
        "well_flux_avg" => rescale_flow,
        "well_flux_neg" => rescale_flow,
        "well_flux_fr" => rescale_flow,
        "well_flux_to" => rescale_flow,
        "well_flow_avg" => rescale_flow,
        "well_flow_neg" => rescale_flow,
        "well_flow_fr" => rescale_flow,
        "well_flow_to" => rescale_flow,
        "well_head_flow" => rescale_flow,
        "bottom_hole_flow" => rescale_flow,
        "bid_price" => rescale_inv_flow,
        "offer_price" => rescale_inv_flow,
    )
end


"Transforms data to si units"
function si_to_pu!(data::Dict{String,<:Any}; id = "0")
    rescale_flow = x -> x / get_base_flow(data)
    rescale_inv_flow = x -> x * get_base_flow(data)
    rescale_pressure = x -> x / get_base_pressure(data)
    rescale_density = x -> x / get_base_density(data)
    rescale_length = x -> x / get_base_length(data)
    rescale_time = x -> x / get_base_time(data)
    rescale_mass = x -> x / get_base_flow(data) / get_base_time(data)
    rescale_diameter = x -> x / get_base_diameter(data)
    functions = _rescale_functions(
        rescale_pressure,
        rescale_density,
        rescale_length,
        rescale_diameter,
        rescale_flow,
        rescale_mass,
        rescale_inv_flow,
    )

    gm_data = get_gm_data(data)
    gm_nw_data = (id == "0") ? gm_data : gm_data["nw"][id]
    _apply_func!(gm_nw_data, "time_point", rescale_time)

    for (component, parameters) in _params_for_unit_conversions
        for (i, comp) in get(gm_nw_data, component, [])
            if !haskey(comp, "is_per_unit") && !haskey(gm_data, "is_per_unit")
                Memento.error(_LOGGER, "the current units of the data/result dictionary unknown")
            end

            if !haskey(comp, "is_per_unit") && haskey(gm_data, "is_per_unit")
                comp["is_per_unit"] = gm_data["is_per_unit"]
                comp["is_si_units"] = 0
                comp["is_english_units"] = 0
            end

            if comp["is_si_units"] == true && comp["is_per_unit"] == false
                for param in parameters
                    _apply_func!(comp, param, functions[param])
                end

                comp["is_si_units"] = 0
                comp["is_english_units"] = 0
                comp["is_per_unit"] = 1
            end
        end
    end
end


function pu_to_si!(data::Dict{String,<:Any}; id = "0")
    rescale_flow = x -> x * get_base_flow(data)
    rescale_inv_flow = x -> x / get_base_flow(data)
    rescale_pressure = x -> x * get_base_pressure(data)
    rescale_density = x -> x * get_base_density(data)
    rescale_length = x -> x * get_base_length(data)
    rescale_time = x -> x * get_base_time(data)
    rescale_mass = x -> x * get_base_flow(data) * get_base_time(data)
    rescale_diameter = x -> x * get_base_diameter(data)
    functions = _rescale_functions(
        rescale_pressure,
        rescale_density,
        rescale_length,
        rescale_diameter,
        rescale_flow,
        rescale_mass,
        rescale_inv_flow,
    )

    gm_data = get_gm_data(data)
    gm_nw_data = (id == "0") ? gm_data : gm_data["nw"][id]
    _apply_func!(gm_nw_data, "time_point", rescale_time)

    for (component, parameters) in _params_for_unit_conversions
        for (i, comp) in get(gm_nw_data, component, [])
            if !haskey(comp, "is_per_unit") && !haskey(gm_data, "is_per_unit")
                Memento.error(_LOGGER, "the current units of the data/result dictionary unknown")
            end

            if !haskey(comp, "is_per_unit") && haskey(gm_data, "is_per_unit")
                @assert gm_data["is_per_unit"] == 1
                comp["is_per_unit"] = gm_data["is_per_unit"]
                comp["is_si_units"] = 0
                comp["is_english_units"] = 0
            end

            if comp["is_si_units"] == false && comp["is_per_unit"] == true
                for param in parameters
                    _apply_func!(comp, param, functions[param])
                    comp["is_si_units"] = 1
                    comp["is_english_units"] = 0
                    comp["is_per_unit"] = 0
                end
            end
        end
    end
end


function si_to_english!(data::Dict{String,<:Any}; id = "0")
    rescale_flow = x -> x * get_kgps_to_mmscfd_conversion_factor(data)
    rescale_inv_flow = x -> x / get_kgps_to_mmscfd_conversion_factor(data)
    rescale_mass = x -> x / get_mmscfd_to_kgps_conversion_factor(data) / 86400.0
    rescale_density = x -> x
    rescale_pressure = pascal_to_psi
    rescale_length = m_to_miles
    rescale_diameter = m_to_inches
    functions = _rescale_functions(
        rescale_pressure,
        rescale_density,
        rescale_length,
        rescale_diameter,
        rescale_flow,
        rescale_mass,
        rescale_inv_flow,
    )

    gm_data = get_gm_data(data)
    gm_nw_data = (id == "0") ? gm_data : gm_data["nw"][id]

    for (component, parameters) in _params_for_unit_conversions
        for (i, comp) in get(gm_nw_data, component, [])
            if !haskey(comp, "is_per_unit") && !haskey(gm_data, "is_per_unit")
                Memento.error(_LOGGER, "the current units of the data/result dictionary unknown")
            end

            if !haskey(comp, "is_per_unit") && haskey(gm_data, "is_per_unit")
                @assert gm_data["is_per_unit"] == 1
                comp["is_per_unit"] = gm_data["is_per_unit"]
                comp["is_si_units"] = 0
                comp["is_english_units"] = 0
            end

            if comp["is_english_units"] == false && comp["is_si_units"] == true
                for param in parameters
                    _apply_func!(comp, param, functions[param])
                    comp["is_si_units"] = 0
                    comp["is_english_units"] = 1
                    comp["is_per_unit"] = 0
                end
            end
        end
    end
end


function english_to_si!(data::Dict{String,<:Any}; id = "0")
    rescale_flow = x -> x * get_mmscfd_to_kgps_conversion_factor(data)
    rescale_inv_flow = x -> x / get_mmscfd_to_kgps_conversion_factor(data)
    rescale_mass = x -> x * get_mmscfd_to_kgps_conversion_factor(data) * 86400.0
    rescale_density = x -> x
    rescale_pressure = psi_to_pascal
    rescale_length = miles_to_m
    rescale_diameter = inches_to_m
    functions = _rescale_functions(
        rescale_pressure,
        rescale_density,
        rescale_length,
        rescale_diameter,
        rescale_flow,
        rescale_mass,
        rescale_inv_flow,
    )

    gm_data = get_gm_data(data)
    gm_nw_data = (id == "0") ? gm_data : gm_data["nw"][id]

    for (component, parameters) in _params_for_unit_conversions
        for (i, comp) in get(gm_nw_data, component, [])
            if !haskey(comp, "is_per_unit") && !haskey(gm_data, "is_per_unit")
                Memento.error(_LOGGER, "the current units of the data/result dictionary unknown")
            end

            if !haskey(comp, "is_per_unit") && haskey(gm_data, "is_per_unit")
                @assert gm_data["is_per_unit"] == 1
                comp["is_per_unit"] = gm_data["is_per_unit"]
                comp["is_si_units"] = 0
                comp["is_english_units"] = 0
            end

            if comp["is_english_units"] == true && comp["is_si_units"] == false
                for param in parameters
                    _apply_func!(comp, param, functions[param])
                    comp["is_si_units"] = 1
                    comp["is_english_units"] = 0
                    comp["is_per_unit"] = 0
                end
            end
        end
    end
end


"transforms data to si units"
function make_si_units!(data::Dict{String, <:Any})
    apply_gm!(_make_si_units!, data; apply_to_subnetworks = false)
end


"transforms data to si units"
function _make_si_units!(data::Dict{String,<:Any})
    if get(data, "is_si_units", false) == true
        return
    end

    if get(data, "is_per_unit", false) == true
        if _IM.ismultinetwork(data)
            for (i, _) in data["nw"]
                pu_to_si!(data, id = i)
            end
        else
            pu_to_si!(data)
        end

        if haskey(data, "time_step")
            rescale_time = x -> x * get_base_time(data)
            data["time_step"] = rescale_time(data["time_step"])
        end

        data["is_si_units"] = 1
        data["is_english_units"] = 0
        data["is_per_unit"] = 0
    end

    if get(data, "is_english_units", false) == true
        if _IM.ismultinetwork(data)
            for (i, _) in data["nw"]
                english_to_si!(data, id = i)
            end
        else
            english_to_si!(data)
        end

        data["is_si_units"] = 1
        data["is_english_units"] = 0
        data["is_per_unit"] = 0
    end
end


"Transforms network data into English units"
function make_english_units!(data::Dict{String, <:Any})
    apply_gm!(_make_english_units!, data; apply_to_subnetworks = false)
end

"Transforms network data into English units"
function _make_english_units!(data::Dict{String, <:Any})
    if get(data, "is_english_units", false) == true
        return
    end

    if get(data, "is_per_unit", false) == true
        make_si_units!(data)
    end

    if get(data, "is_si_units", false) == true
        if _IM.ismultinetwork(data)
            for (i, _) in data["nw"]
                si_to_english!(data, id = i)
            end
        else
            si_to_english!(data)
        end

        data["is_si_units"] = 0
        data["is_english_units"] = 1
        data["is_per_unit"] = 0
    end
end


"Transforms network data into per unit"
function make_per_unit!(data::Dict{String, <:Any})
    apply_gm!(_make_per_unit!, data; apply_to_subnetworks = false)
end


"Transforms network data into per unit"
function _make_per_unit!(data::Dict{String,<:Any})
    if get(data, "is_per_unit", false) == true
        return
    end

    if get(data, "is_english_units", false) == true
        make_si_units!(data)
    end

    if get(data, "is_si_units", false) == true
        if _IM.ismultinetwork(data)
            for (i, _) in data["nw"]
                si_to_pu!(data, id = i)
            end
        else
            si_to_pu!(data)
        end

        if haskey(data, "time_step")
            rescale_time = x -> x / get_base_time(data)
            data["time_step"] = rescale_time(data["time_step"])
        end

        data["is_si_units"] = 0
        data["is_english_units"] = 0
        data["is_per_unit"] = 1
    end
end


"checks for non-negativity of certain fields in the data"
function check_non_negativity(data::Dict{String, <:Any})
    apply_gm!(_check_non_negativity, data; apply_to_subnetworks = false)
end


"checks for non-negativity of certain fields in the data"
function _check_non_negativity(data::Dict{String, <:Any})
    for field in non_negative_metadata
        if get(data, field, 0.0) < 0.0
            Memento.error(_LOGGER, "Metadata $field is less than zero.")
        end
    end

    for field in keys(non_negative_data)
        for (i, table) in get(data, field, [])
            for column_name in get(non_negative_data, field, [])
                if get(table, column_name, 0.0) < 0.0
                    Memento.error(_LOGGER, "$field[$i][$column_name] is less than zero.")
                end
            end
        end
    end
end


"checks validity of global-level parameters"
function check_global_parameters(data::Dict{String, <:Any})
    apply_gm!(_check_global_parameters, data; apply_to_subnetworks = false)
end


"checks validity of global-level parameters"
function _check_global_parameters(data::Dict{String, <:Any})
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


"Correct mass flow bounds"
function correct_f_bounds!(data::Dict{String, <:Any})
    apply_gm!(_correct_f_bounds!, data; apply_to_subnetworks = false)
end

"Correct mass flow bounds"
function _correct_f_bounds!(data::Dict{String,Any})
    mf = _calc_max_mass_flow(
        data["receipt"],
        get(data, "storage", Dict()),
        get(data, "transfer", Dict()),
    )

    for (idx, pipe) in get(data, "pipe", Dict())
        pipe["flow_min"] = _calc_pipe_flow_min(
            -mf,
            pipe,
            data["junction"][string(pipe["fr_junction"])],
            data["junction"][string(pipe["to_junction"])],
            data["base_length"],
            data["base_pressure"],
            data["base_flow"],
            data["sound_speed"],
        )
        pipe["flow_max"] = _calc_pipe_flow_max(
            mf,
            pipe,
            data["junction"][string(pipe["fr_junction"])],
            data["junction"][string(pipe["to_junction"])],
            data["base_length"],
            data["base_pressure"],
            data["base_flow"],
            data["sound_speed"],
        )
    end

    for (idx, compressor) in get(data, "compressor", Dict())
        compressor["flow_min"] = _calc_compressor_flow_min(-mf, compressor)
        compressor["flow_max"] = _calc_compressor_flow_max(mf, compressor)
    end

    for (idx, pipe) in get(data, "short_pipe", Dict())
        pipe["flow_min"] = _calc_short_pipe_flow_min(-mf, pipe)
        pipe["flow_max"] = _calc_short_pipe_flow_max(mf, pipe)
    end

    if "standard_density" in keys(data)
        density = data["standard_density"]
    else
        density = _estimate_standard_density(data)
    end

    for (idx, resistor) in get(data, "resistor", Dict())
        resistor["flow_min"] = _calc_resistor_flow_min(
            -mf, resistor, data["junction"][string(resistor["fr_junction"])],
            data["junction"][string(resistor["to_junction"])],
            Float64(data["base_pressure"]), Float64(data["base_flow"]), density)

        resistor["flow_max"] = _calc_resistor_flow_max(
            mf, resistor, data["junction"][string(resistor["fr_junction"])],
            data["junction"][string(resistor["to_junction"])],
            Float64(data["base_pressure"]), Float64(data["base_flow"]), density)
    end

    for (idx, loss_resistor) in get(data, "loss_resistor", Dict())
        loss_resistor["flow_min"] = _calc_loss_resistor_flow_min(-mf, loss_resistor)
        loss_resistor["flow_max"] = _calc_loss_resistor_flow_max(mf, loss_resistor)
    end

    for (idx, valve) in get(data, "valve", Dict())
        valve["flow_min"] = _calc_valve_flow_min(-mf, valve)
        valve["flow_max"] = _calc_valve_flow_max(mf, valve)
    end

    for (idx, regulator) in get(data, "regulator", Dict())
        regulator["flow_min"] = _calc_regulator_flow_min(-mf, regulator)
        regulator["flow_max"] = _calc_regulator_flow_max(mf, regulator)
    end

    for (idx, pipe) in get(data, "ne_pipe", Dict())
        pipe["flow_min"] = _calc_ne_pipe_flow_min(
            -mf,
            pipe,
            data["junction"][string(pipe["fr_junction"])],
            data["junction"][string(pipe["to_junction"])],
            data["base_length"],
            data["base_pressure"],
            data["base_flow"],
            data["sound_speed"],
        )

        pipe["flow_max"] = _calc_ne_pipe_flow_max(
            mf,
            pipe,
            data["junction"][string(pipe["fr_junction"])],
            data["junction"][string(pipe["to_junction"])],
            data["base_length"],
            data["base_pressure"],
            data["base_flow"],
            data["sound_speed"],
        )
    end

    for (idx, compressor) in get(data, "ne_compressor", Dict())
        compressor["flow_min"] = _calc_ne_compressor_flow_min(-mf, compressor)
        compressor["flow_max"] = _calc_ne_compressor_flow_max(mf, compressor)
    end
end


"Correct minimum pressures"
function correct_p_mins!(data::Dict{String, <:Any})
    apply_gm!(_correct_p_mins!, data; apply_to_subnetworks = false)
end


"Correct minimum pressures"
function _correct_p_mins!(data::Dict{String,Any}; si_value = 1.37e6, english_value = 200.0)
    for (i, junction) in get(data, "junction", [])
        if junction["p_min"] < 0.0
            Memento.warn(_LOGGER, "junction $i's p_min changed to 1.37E6 Pa (200 PSI) from < 0")
            (data["is_si_units"] == 1) && (junction["p_min"] = si_value)
            (data["is_english_units"] == 1) && (junction["p_min"] = english_value)
        end
    end

    for (i, pipe) in get(data, "pipe", [])
        if pipe["p_min"] < 0.0
            Memento.warn(_LOGGER, "pipe $i's p_min changed to 1.37E6 Pa (200 PSI) from < 0")
            (data["is_si_units"] == 1) && (pipe["p_min"] = si_value)
            (data["is_english_units"] == 1) && (pipe["p_min"] = english_value)
        end
    end

    for (i, compressor) in get(data, "compressor", [])
        if compressor["inlet_p_min"] < 0
            Memento.warn(_LOGGER, "compressor $i's inlet_p_min changed to 1.37E6 Pa (200 PSI) from < 0")
            (data["is_si_units"] == 1) && (compressor["inlet_p_min"] = si_value)
            (data["is_english_units"] == 1) && (compressor["inlet_p_min"] = english_value)
        end

        if compressor["outlet_p_min"] < 0
            Memento.warn(_LOGGER, "compressor $i's outlet_p_min changed to 1.37E6 Pa (200 PSI) from < 0")
            (data["is_si_units"] == 1) && (compressor["outlet_p_min"] = si_value)
            (data["is_english_units"] == 1) && (compressor["outlet_p_min"] = english_value)
        end
    end
end


"add additional compressor fields - required for transient"
function add_compressor_fields!(data::Dict{String, <:Any})
    apply_gm!(_add_compressor_fields!, data; apply_to_subnetworks = false)
end


"add additional compressor fields - required for transient"
function _add_compressor_fields!(data::Dict{String,<:Any})
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
            compressor["length"] = 250.0 / base_length
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
                compressor["length"] = 250.0 / base_length
                compressor["friction_factor"] = 0.001
            end
        end
    end
end


const _gm_component_types = [
    "pipe",
    "compressor",
    "valve",
    "regulator",
    "short_pipe",
    "resistor",
    "loss_resistor",
    "ne_pipe",
    "ne_compressor",
    "junction",
    "delivery",
    "receipt",
]

const _gm_junction_keys = ["fr_junction", "to_junction", "junction", "junction_id"]

const _gm_edge_types = [
    "pipe",
    "compressor",
    "valve",
    "regulator",
    "short_pipe",
    "resistor",
    "loss_resistor",
    "ne_pipe",
    "ne_compressor",
]


"checks that all junctions are unique and other components link to valid junctions"
function check_connectivity(data::Dict{String, <:Any})
    apply_gm!(_check_connectivity, data; apply_to_subnetworks = true)
end


"checks that all buses are unique and other components link to valid buses"
function _check_connectivity(data::Dict{String,<:Any})
    junc_ids = Set(junc["id"] for (i, junc) in data["junction"])
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
function check_status(data::Dict{String, <:Any})
    apply_gm!(_check_status, data; apply_to_subnetworks = false)
end


"checks that active components are not connected to inactive buses, otherwise prints warnings"
function _check_status(data::Dict{String,<:Any})
    if _IM.ismultinetwork(data)
        Memento.error(_LOGGER, "check_status does not yet support multinetwork data")
    end

    active_junction_ids = Set(
        junction["id"]
        for (i, junction) in data["junction"] if get(junction, "status", 1) != 0
    )

    for comp_type in _gm_component_types
        for (i, comp) in get(data, comp_type, Dict())
            for junc_key in _gm_junction_keys
                if haskey(comp, junc_key)
                    if get(comp, "status", 1) != 0 &&
                       !(comp[junc_key] in active_junction_ids)
                        Memento.warn(_LOGGER, "active $comp_type $i is connected to inactive junction $(comp[junc_key])")
                    end
                end
            end
        end
    end
end


"checks that all edges connect two distinct junctions"
function check_edge_loops(data::Dict{String, <:Any})
    apply_gm!(_check_edge_loops, data; apply_to_subnetworks = false)
end


"checks that all edges connect two distinct junctions"
function _check_edge_loops(data::Dict{String,<:Any})
    if _IM.ismultinetwork(data)
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


"checks that all edges connect two distinct junctions"
function propagate_topology_status!(data::Dict{String, <:Any})
    apply_gm!(_propagate_topology_status!, data; apply_to_subnetworks = true)
end


"helper function to propagate disabled status of junctions to connected components"
function _propagate_topology_status!(data::Dict{String,<:Any})
    disabled_junctions = Set([junc["index"] for junc in values(data["junction"]) if junc["status"] == 0])

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
function _calc_max_mass_flow(receipts::Dict, storages::Dict, transfers::Dict)
    max_flow = 0

    for (idx, receipt) in receipts
        if receipt["injection_max"] > 0
            max_flow = max_flow + receipt["injection_max"]
        end
    end

    for (idx, storage) in storages
        if storage["flow_injection_rate_max"] > 0
            max_flow = max_flow + storage["flow_injection_rate_max"]
        end
    end

    for (idx, transfer) in transfers
        if transfer["withdrawal_min"] < 0
            max_flow = max_flow - transfer["withdrawal_min"]
        end
    end

    return max_flow
end


"Calculate the bounds on minimum and maximum pressure difference across a resistor."
function _calc_resistor_pd_bounds(resistor::Dict{String,Any}, i::Dict{String,Any}, j::Dict{String,Any})
    pd_min = i["p_min"] - j["p_max"]
    pd_max = i["p_max"] - j["p_min"]

    is_bidirectional = get(resistor, "is_bidirectional", 1)
    flow_direction = get(resistor, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        pd_min = max(0.0, pd_min)
    elseif flow_direction == -1
        pd_max = min(0.0, pd_max)
    end

    return pd_min, pd_max
end


"Calculate the bounds on minimum and maximum pressure difference squared for a pipe"
function _calc_pipe_pd_bounds_sqr(pipe::Dict{String,Any}, i::Dict{String,Any}, j::Dict{String,Any})
    pd_max = i["p_max"]^2 - j["p_min"]^2
    pd_min = i["p_min"]^2 - j["p_max"]^2

    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        pd_min = max(0, pd_min)
    end

    if flow_direction == -1
        pd_max = min(0, pd_max)
    end

    return pd_min, pd_max
end


"Calculate the bounds on minimum and maximum pressure difference squared for a ne pipe, which is different dependeing on whether or not the pipe is present"
function _calc_ne_pipe_pd_bounds_sqr(pipe::Dict{String,Any}, i::Dict{String,Any}, j::Dict{String,Any})
    pd_max_on = pd_max_off = i["p_max"]^2 - j["p_min"]^2
    pd_min_on = pd_min_off = i["p_min"]^2 - j["p_max"]^2

    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        pd_min_on = max(0, pd_min_on)
    end

    if flow_direction == -1
        pd_max_on = min(0, pd_max_on)
    end

    return pd_min_on, pd_max_on, pd_min_off, pd_max_off
end


"Calculates pipeline resistance from this paper Thorley and CH Tiley. Unsteady and transient flow of compressible
fluids in pipelines–a review of theoretical and some experimental studies.
International Journal of Heat and Fluid Flow, 8(1):3–15, 1987
This is used in many of Zlotnik's papers
This calculation expresses resistance in terms of mass flow equations"
function _calc_pipe_resistance(pipe::Dict{String,Any}, base_length, base_pressure, base_flow, sound_speed)
    lambda = pipe["friction_factor"]
    D = pipe["diameter"]
    L = pipe["length"] * base_length

    a_sqr = sound_speed^2
    A = pi * D^2 / 4.0 # cross sectional area
    resistance = ((D * A^2) / (lambda * L * a_sqr)) * (base_pressure^2 / base_flow^2) # second half is the non-dimensionalization
    return resistance
end


"Calculates pipeline resistance from this paper Thorley and CH Tiley.
Unsteady and transient flow of compressible
fluids in pipelines–a review of theoretical and some experimental studies.
International Journal of Heat and Fluid Flow, 8(1):3–15, 1987
This is used in many of Zlotnik's papers
This calculation expresses resistance in terms of mass flow equations"
function _calc_pipe_resistance_rho_phi_space(pipe::Dict{String,Any}, base_length)
    lambda = pipe["friction_factor"]
    D = pipe["diameter"]
    L = pipe["length"]

    resistance = lambda * L * base_length / D
    return resistance
end


"calculates the minimum flow on a pipe"
function _calc_pipe_flow_min(mf::Float64, pipe::Dict, i::Dict, j::Dict, base_length::Number, base_pressure::Number, base_flow::Number, sound_speed::Number)
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)
    flow_min         = get(pipe, "flow_min", mf)
    pd_min, pd_max   = _calc_pipe_pd_bounds_sqr(pipe, i, j)
    w                = _calc_pipe_resistance(pipe, base_length, base_pressure, base_flow, sound_speed)
    pf_min           = pd_min < 0 ? -sqrt(w * abs(pd_min)) : sqrt(w * abs(pd_min))

    if is_bidirectional == 0 || flow_direction == 1
        return max(mf, pf_min, flow_min, 0)
    else
        return max(mf, pf_min, flow_min)
    end
end


"calculates the maximum flow on a pipe"
function _calc_pipe_flow_max(mf::Float64, pipe::Dict, i::Dict, j::Dict, base_length::Number, base_pressure::Number, base_flow::Number, sound_speed::Number)
    flow_direction = get(pipe, "flow_direction", 0)
    flow_max = get(pipe, "flow_max", mf)
    pd_min, pd_max = _calc_pipe_pd_bounds_sqr(pipe, i, j)
    w = _calc_pipe_resistance(pipe, base_length, base_pressure, base_flow, sound_speed)
    pf_max = pd_max < 0 ? -sqrt(w * abs(pd_max)) : sqrt(w * abs(pd_max))

    if flow_direction == -1
        return min(mf, pf_max, flow_max, 0)
    else
        return min(mf, pf_max, flow_max)
    end
end


"calculates the minimum flow on a resistor"
function _calc_resistor_flow_min(mf::Float64, resistor::Dict, i::Dict, j::Dict, base_pressure::Float64, base_flow::Float64, density::Float64)
    is_bidirectional = get(resistor, "is_bidirectional", 1)
    flow_direction   = get(resistor, "flow_direction", 0)
    flow_min         = get(resistor, "flow_min", mf)
    pd_min, pd_max   = _calc_resistor_pd_bounds(resistor, i, j)
    w                = _calc_resistor_resistance(resistor, base_pressure, base_flow, density)
    pf_min           = pd_min < 0.0 ? -sqrt(inv(w) * abs(pd_min)) : sqrt(inv(w) * abs(pd_min))

    if is_bidirectional == 0 || flow_direction == 1
        return max(mf, pf_min, flow_min, 0.0)
    else
        return max(mf, pf_min, flow_min)
    end
end


"calculates the maximum flow on a resistor"
function _calc_resistor_flow_max(mf::Float64, resistor::Dict, i::Dict, j::Dict, base_pressure::Float64, base_flow::Float64, density::Float64)
    flow_direction = get(resistor, "flow_direction", 0)
    flow_max       = get(resistor, "flow_max", mf)
    pd_min, pd_max = _calc_resistor_pd_bounds(resistor, i, j)
    w              = _calc_resistor_resistance(resistor, base_pressure, base_flow, density)
    pf_max         = pd_max < 0.0 ? -sqrt(inv(w) * abs(pd_max)) : sqrt(inv(w) * abs(pd_max))

    if flow_direction == -1
        return min(mf, pf_max, flow_max, 0.0)
    else
        return min(mf, pf_max, flow_max)
    end
end


"calculates the minimum flow on a ne pipe"
function _calc_ne_pipe_flow_min(mf::Float64, pipe::Dict, i::Dict, j::Dict, base_length::Number, base_pressure::Number, base_flow::Number, sound_speed::Number)
    flow_min = get(pipe, "flow_min", mf)
    pd_min_on, pd_max_on, pd_min_off, pd_max_off = _calc_ne_pipe_pd_bounds_sqr(pipe, i, j)
    pd_min = pd_min_on
    w = _calc_pipe_resistance(pipe, base_length, base_pressure, base_flow, sound_speed)
    pf_min = pd_min < 0 ? -sqrt(w * abs(pd_min)) : sqrt(w * abs(pd_min))
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        return min(0.0, max(mf, pf_min, flow_min, 0.0))
    else
        return min(0.0, max(mf, pf_min, flow_min))
    end
end


"calculates the maximum flow on a pipe"
function _calc_ne_pipe_flow_max(mf::Float64, pipe::Dict, i::Dict, j::Dict, base_length::Number, base_pressure::Number, base_flow::Number, sound_speed::Number)
    flow_max = min(mf, get(pipe, "flow_max", mf))
    pd_min_on, pd_max_on, pd_min_off, pd_max_off = _calc_ne_pipe_pd_bounds_sqr(pipe, i, j)
    pd_max = pd_max_on
    w = _calc_pipe_resistance(pipe, base_length, base_pressure, base_flow, sound_speed)
    pf_max = pd_max < 0 ? -sqrt(w * abs(pd_max)) : sqrt(w * abs(pd_max))
    flow_direction = get(pipe, "flow_direction", 0)

    if flow_direction == -1
        return max(0,min(mf, pf_max, flow_max, 0))
    else
        return max(0,min(mf, pf_max, flow_max))
    end
end

"calculates the minimum flow on a compressor"
function _calc_compressor_flow_min(mf::Float64, compressor::Dict)
    flow_min = get(compressor, "flow_min", mf)
    directionality = get(compressor, "directionality", 0)
    flow_direction = get(compressor, "flow_direction", 0)

    if directionality == 1 || flow_direction == 1
        return max(mf, flow_min, 0)
    else
        return max(mf, flow_min)
    end
end


"calculates the maximum flow on a pipe"
function _calc_compressor_flow_max(mf::Float64, compressor::Dict)
    flow_max = get(compressor, "flow_max", mf)
    flow_direction = get(compressor, "flow_direction", 0)

    if flow_direction == -1
        return min(mf, flow_max, 0)
    else
        return min(mf, flow_max)
    end
end

"calculates the minimum flow on a compressor"
function _calc_ne_compressor_flow_min(mf::Float64, compressor::Dict)
    flow_min = get(compressor, "flow_min", mf)
    directionality = get(compressor, "directionality", 0)
    flow_direction = get(compressor, "flow_direction", 0)

    if directionality == 1 || flow_direction == 1
        return min(0.0, max(mf, flow_min, 0.0))
    else
        return min(0.0, max(mf, flow_min))
    end
end


"calculates the maximum flow on a pipe"
function _calc_ne_compressor_flow_max(mf::Float64, compressor::Dict)
    flow_max = get(compressor, "flow_max", mf)
    flow_direction = get(compressor, "flow_direction", 0)

    if flow_direction == -1
        return max(0.0, min(mf, flow_max, 0.0))
    else
        return max(0.0, min(mf, flow_max))
    end
end


"calculates resistor resistances as per Equation (2.30) in Evaluating Gas Network Capacities"
function _calc_resistor_resistance(resistor::Dict{String,Any}, base_pressure::Float64, base_flow::Float64, density::Float64)
    resistance = 8.0 * resistor["drag"] * inv(pi^2 * resistor["diameter"]^4) * inv(density)
    return resistance * base_flow^2 * inv(base_pressure) # Nondimensionalization.
end


"calculates the minimum flow on a loss resistor"
function _calc_loss_resistor_flow_min(mf::Float64, loss_resistor::Dict{String,Any})
    is_bidirectional = get(loss_resistor, "is_bidirectional", 1)
    flow_direction = get(loss_resistor, "flow_direction", 0)
    flow_min = get(loss_resistor, "flow_min", mf)

    if is_bidirectional == 0 || flow_direction == 1
        return max(mf, flow_min, 0.0)
    else
        return max(mf, flow_min)
    end
end


"calculates the maximum flow on a loss resistor"
function _calc_loss_resistor_flow_max(mf::Float64, loss_resistor::Dict{String,Any})
    flow_direction = get(loss_resistor, "flow_direction", 0)
    flow_max = get(loss_resistor, "flow_max", mf)

    if flow_direction == -1
        return min(mf, flow_max, 0.0)
    else
        return min(mf, flow_max)
    end
end


"calculates the minimum flow on a short pipe"
function _calc_short_pipe_flow_min(mf::Float64, short_pipe::Dict)
    flow_min = get(short_pipe, "flow_min", mf)
    is_bidirectional = get(short_pipe, "is_bidirectional", 1)
    flow_direction = get(short_pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        return max(0.0, flow_min, mf)
    end

    return max(flow_min, mf)
end


"calculates the maximum flow on a short pipe"
function _calc_short_pipe_flow_max(mf::Float64, short_pipe::Dict)
    flow_max = get(short_pipe, "flow_max", mf)
    flow_direction = get(short_pipe, "flow_direction", 0)

    if flow_direction == -1
        return min(0.0, flow_max, mf)
    end

    return min(flow_max, mf)
end


"calculates the minimum flow on a valve"
function _calc_valve_flow_min(mf::Float64, valve::Dict)
    flow_min = get(valve, "flow_min", mf)
    is_bidirectional = get(valve, "is_bidirectional", 1)
    flow_direction = get(valve, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        return min(0.0, max(0.0, flow_min, mf))
    end

    return min(0.0, max(flow_min, mf))
end


"calculates the maximum flow on a valve"
function _calc_valve_flow_max(mf::Float64, valve::Dict)
    flow_max = get(valve, "flow_max", mf)
    flow_direction = get(valve, "flow_direction", 0)

    if flow_direction == -1
        return max(0,min(0, flow_max, mf))
    end

    return max(0,min(flow_max, mf))
end


"calculates the minimum flow on a regulator"
function _calc_regulator_flow_min(mf::Float64, regulator::Dict)
    flow_min = get(regulator, "flow_min", mf)
    is_bidirectional = get(regulator, "is_bidirectional", 1)
    flow_direction = get(regulator, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        return min(0,max(0, flow_min, mf))
    end

    return min(0,max(flow_min, mf))
end


"calculates the maximum flow on a regulator"
function _calc_regulator_flow_max(mf::Float64, regulator::Dict)
    flow_max = get(regulator, "flow_max", mf)
    flow_direction = get(regulator, "flow_direction", 0)

    if flow_direction == -1
        return max(0,min(0, flow_max, mf))
    end
    return max(0,min(flow_max, mf))
end


"extracts the start value"
function comp_start_value(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)
end


"Helper function for determining if direction cuts can be applied"
function _apply_mass_flow_cuts(yp, branches)
    is_disjunction = true

    for k in branches
        is_disjunction &= haskey(yp, k)
    end

    return is_disjunction
end


"calculates connections in parallel with one another and their orientation"
function _calc_parallel_connections(gm::AbstractGasModel, n::Int, connection::Dict{String,Any})
    i = min(connection["fr_junction"], connection["to_junction"])
    j = max(connection["fr_junction"], connection["to_junction"])

    parallel_pipes = haskey(ref(gm, n, :parallel_pipes), (i, j)) ? ref(gm, n, :parallel_pipes, (i, j)) : []
    parallel_compressors = haskey(ref(gm, n, :parallel_compressors), (i, j)) ? ref(gm, n, :parallel_compressors, (i, j)) : []
    parallel_short_pipes = haskey(ref(gm, n, :parallel_short_pipes), (i, j)) ? ref(gm, n, :parallel_short_pipes, (i, j)) : []
    parallel_resistors = haskey(ref(gm, n, :parallel_resistors), (i, j)) ? ref(gm, n, :parallel_resistors, (i, j)) : []
    parallel_loss_resistors = haskey(ref(gm, n, :parallel_loss_resistors), (i, j)) ? ref(gm, n, :parallel_loss_resistors, (i, j)) : []
    parallel_valves = haskey(ref(gm, n, :parallel_valves), (i, j)) ? ref(gm, n, :parallel_valves, (i, j)) : []
    parallel_regulators = haskey(ref(gm, n, :parallel_regulators), (i, j)) ? ref(gm, n, :parallel_regulators, (i, j)) : []

    num_connections = length(parallel_pipes) +
        length(parallel_compressors) +
        length(parallel_short_pipes) +
        length(parallel_resistors) +
        length(parallel_loss_resistors) +
        length(parallel_valves) +
        length(parallel_regulators)

    pipes = ref(gm, n, :pipe)
    compressors = ref(gm, n, :compressor)
    resistors = ref(gm, n, :resistor)
    loss_resistors = ref(gm, n, :loss_resistor)
    short_pipes = ref(gm, n, :short_pipe)
    valves = ref(gm, n, :valve)
    regulators = ref(gm, n, :regulator)

    aligned_pipes = filter(i -> pipes[i]["fr_junction"] == connection["fr_junction"], parallel_pipes)
    opposite_pipes = filter(i -> pipes[i]["fr_junction"] != connection["fr_junction"], parallel_pipes)
    aligned_compressors = filter(i -> compressors[i]["fr_junction"] == connection["fr_junction"], parallel_compressors)
    opposite_compressors = filter(i -> compressors[i]["fr_junction"] != connection["fr_junction"], parallel_compressors)
    aligned_resistors = filter(i -> resistors[i]["fr_junction"] == connection["fr_junction"], parallel_resistors)
    opposite_resistors = filter(i -> resistors[i]["fr_junction"] != connection["fr_junction"], parallel_resistors)
    aligned_loss_resistors = filter(i -> loss_resistors[i]["fr_junction"] == connection["fr_junction"], parallel_loss_resistors)
    opposite_loss_resistors = filter(i -> loss_resistors[i]["fr_junction"] != connection["fr_junction"], parallel_loss_resistors)
    aligned_short_pipes = filter(i -> short_pipes[i]["fr_junction"] == connection["fr_junction"], parallel_short_pipes)
    opposite_short_pipes = filter(i -> short_pipes[i]["fr_junction"] != connection["fr_junction"], parallel_short_pipes)
    aligned_valves = filter(i -> valves[i]["fr_junction"] == connection["fr_junction"], parallel_valves)
    opposite_valves = filter(i -> valves[i]["fr_junction"] != connection["fr_junction"], parallel_valves)
    aligned_regulators = filter(i -> regulators[i]["fr_junction"] == connection["fr_junction"], parallel_regulators)
    opposite_regulators = filter(i -> regulators[i]["fr_junction"] != connection["fr_junction"], parallel_regulators)

    return num_connections,
    aligned_pipes,
    opposite_pipes,
    aligned_compressors,
    opposite_compressors,
    aligned_resistors,
    opposite_resistors,
    aligned_loss_resistors,
    opposite_loss_resistors,
    aligned_short_pipes,
    opposite_short_pipes,
    aligned_valves,
    opposite_valves,
    aligned_regulators,
    opposite_regulators
end


"calculates connections in parallel with one another and their orientation"
function _calc_parallel_ne_connections(gm::AbstractGasModel, n::Int, connection::Dict{String,Any})
    i = min(connection["fr_junction"], connection["to_junction"])
    j = max(connection["fr_junction"], connection["to_junction"])

    parallel_pipes = haskey(ref(gm, n, :parallel_pipes), (i, j)) ? ref(gm, n, :parallel_pipes, (i, j)) : []
    parallel_compressors = haskey(ref(gm, n, :parallel_compressors), (i, j)) ? ref(gm, n, :parallel_compressors, (i, j)) : []
    parallel_short_pipes = haskey(ref(gm, n, :parallel_short_pipes), (i, j)) ? ref(gm, n, :parallel_short_pipes, (i, j)) : []
    parallel_resistors = haskey(ref(gm, n, :parallel_resistors), (i, j)) ? ref(gm, n, :parallel_resistors, (i, j)) : []
    parallel_loss_resistors = haskey(ref(gm, n, :parallel_loss_resistors), (i, j)) ? ref(gm, n, :parallel_loss_resistors, (i, j)) : []
    parallel_valves = haskey(ref(gm, n, :parallel_valves), (i, j)) ? ref(gm, n, :parallel_valves, (i, j)) : []
    parallel_regulators = haskey(ref(gm, n, :parallel_regulators), (i, j)) ? ref(gm, n, :parallel_regulators, (i, j)) : []
    parallel_ne_pipes = haskey(ref(gm, n, :parallel_ne_pipes), (i, j)) ? ref(gm, n, :parallel_ne_pipes, (i, j)) : []
    parallel_ne_compressors = haskey(ref(gm, n, :parallel_ne_compressors), (i, j)) ? ref(gm, n, :parallel_ne_compressors, (i, j)) : []

    num_connections = length(parallel_pipes) +
        length(parallel_compressors) +
        length(parallel_short_pipes) +
        length(parallel_resistors) +
        length(parallel_loss_resistors) +
        length(parallel_valves) +
        length(parallel_regulators) +
        length(parallel_ne_pipes) +
        length(parallel_ne_compressors)

    pipes = ref(gm, n, :pipe)
    compressors = ref(gm, n, :compressor)
    resistors = ref(gm, n, :resistor)
    loss_resistors = ref(gm, n, :loss_resistor)
    short_pipes = ref(gm, n, :short_pipe)
    valves = ref(gm, n, :valve)
    regulators = ref(gm, n, :regulator)
    ne_pipes = ref(gm, n, :ne_pipe)
    ne_compressors = ref(gm, n, :ne_compressor)

    aligned_pipes = filter(i -> pipes[i]["fr_junction"] == connection["fr_junction"], parallel_pipes)
    opposite_pipes = filter(i -> pipes[i]["fr_junction"] != connection["fr_junction"], parallel_pipes)
    aligned_compressors = filter(i -> compressors[i]["fr_junction"] == connection["fr_junction"], parallel_compressors)
    opposite_compressors = filter(i -> compressors[i]["fr_junction"] != connection["fr_junction"], parallel_compressors)
    aligned_resistors = filter(i -> resistors[i]["fr_junction"] == connection["fr_junction"], parallel_resistors)
    opposite_resistors = filter(i -> resistors[i]["fr_junction"] != connection["fr_junction"], parallel_resistors)
    aligned_loss_resistors = filter(i -> loss_resistors[i]["fr_junction"] == connection["fr_junction"], parallel_loss_resistors)
    opposite_loss_resistors = filter(i -> loss_resistors[i]["fr_junction"] != connection["fr_junction"], parallel_loss_resistors)
    aligned_short_pipes = filter(i -> short_pipes[i]["fr_junction"] == connection["fr_junction"], parallel_short_pipes)
    opposite_short_pipes = filter(i -> short_pipes[i]["fr_junction"] != connection["fr_junction"], parallel_short_pipes)
    aligned_valves = filter(i -> valves[i]["fr_junction"] == connection["fr_junction"], parallel_valves)
    opposite_valves = filter(i -> valves[i]["fr_junction"] != connection["fr_junction"], parallel_valves)
    aligned_regulators = filter(i -> regulators[i]["fr_junction"] == connection["fr_junction"], parallel_regulators)
    opposite_regulators = filter(i -> regulators[i]["fr_junction"] != connection["fr_junction"], parallel_regulators)
    aligned_ne_pipes = filter(i -> ne_pipes[i]["fr_junction"] == connection["fr_junction"], parallel_ne_pipes)
    opposite_ne_pipes = filter(i -> ne_pipes[i]["fr_junction"] != connection["fr_junction"], parallel_ne_pipes)
    aligned_ne_compressors = filter(i -> ne_compressors[i]["fr_junction"] == connection["fr_junction"], parallel_ne_compressors)
    opposite_ne_compressors = filter(i -> ne_compressors[i]["fr_junction"] != connection["fr_junction"], parallel_ne_compressors)

    return num_connections,
    aligned_pipes,
    opposite_pipes,
    aligned_compressors,
    opposite_compressors,
    aligned_resistors,
    opposite_resistors,
    aligned_loss_resistors,
    opposite_loss_resistors,
    aligned_short_pipes,
    opposite_short_pipes,
    aligned_valves,
    opposite_valves,
    aligned_regulators,
    opposite_regulators,
    aligned_ne_pipes,
    opposite_ne_pipes,
    aligned_ne_compressors,
    opposite_ne_compressors
end


"prints the text summary for a data file to IO"
function summary(io::IO, file::String; kwargs...)
    data = parse_file(file)
    summary(io, data; kwargs...)
    return data
end


const _gm_component_types_order = Dict(
    "junction" => 1.0,
    "pipe" => 2.0,
    "compressor" => 3.0,
    "receipt" => 4.0,
    "delivery" => 5.0,
    "transfer" => 6.0,
    "resistor" => 7.0,
    "short_pipe" => 8.0,
    "regulator" => 9.0,
    "valve" => 10.0,
    "storage" => 11.0,
    "loss_resistor" => 12.0,
)


const _gm_component_parameter_order = Dict(
    "id" => 1.0,
    "junction_type" => 2.0,
    "p_min" => 3.0,
    "p_max" => 4.0,
    "p_nominal" => 5.0,
    "p_loss" => 6.0,
    "fr_junction" => 11.0,
    "to_junction" => 12.0,
    "length" => 13.0,
    "diameter" => 14.0,
    "friction_factor" => 15.0,
    "flow_min" => 16.0,
    "flow_max" => 17.0,
    "c_ratio_min" => 18.0,
    "c_ratio_max" => 19.0,
    "power_max" => 20.0,
    "junction_id" => 51.0,
    "injection_nominal" => 52.0,
    "injection_min" => 53.0,
    "injection_max" => 54.0,
    "withdrawal_nominal" => 72.0,
    "withdrawal_min" => 73.0,
    "withdrawal_max" => 74.0,
    "status" => 500.0,
)


"prints the text summary for a data dictionary to IO"
function summary(io::IO, data::Dict{String,Any}; kwargs...)
    _IM.summary(
        io,
        data;
        component_types_order = _gm_component_types_order,
        component_parameter_order = _gm_component_parameter_order,
        kwargs...,
    )
end


"""
computes the connected components of the network graph
returns a set of sets of juntion ids, each set is a connected component
"""
function calc_connected_components(data::Dict{String,<:Any}; edges = _gm_edge_types)
    gm_data = get_gm_data(data)

    if _IM.ismultinetwork(gm_data)
        Memento.error(_LOGGER, "calc_connected_components does not yet support multinetwork data")
    end

    active_junction = Dict(x for x in gm_data["junction"] if x.second["status"] != 0)
    active_junction_ids = Set{Int64}([junction["id"] for (i, junction) in active_junction])

    neighbors = Dict(i => [] for i in active_junction_ids)
    for edge_type in edges
        for edge in values(get(gm_data, edge_type, Dict()))
            if get(edge, "status", 1) != 0 &&
                edge["fr_junction"] in active_junction_ids &&
                edge["to_junction"] in active_junction_ids
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

"Calculate the work of a compressor"
function _calc_compressor_work(gamma, G, T, compressor::Dict)
    magic_num = 286.76
    return ((magic_num / G) * T * (gamma / (gamma - 1)))
end

"Calculate the m value of a compressor when the ratios are expressed in terms of its square"
function _calc_compressor_m_sqr(gamma, compressor::Dict)
    return ((gamma - 1) / gamma) / 2
end

"Determine if a compressor is energy bounded"
function _calc_is_compressor_energy_bounded(gamma, G, T, compressor::Dict)
    power_max = compressor["power_max"]
    max_ratio = compressor["c_ratio_max"]
    f_max = max(abs(compressor["flow_max"]), abs(compressor["flow_min"]))

    work = _calc_compressor_work(gamma, G, T, compressor)
    m = _calc_compressor_m_sqr(gamma, compressor)

    return f_max * (max_ratio^2^m - 1) > power_max / work
end
