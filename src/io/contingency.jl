abstract type Contingency end

Base.@kwdef struct FailedComponentContingency <: Contingency
    asset_type::String
    asset_id::String
end

Base.@kwdef struct PowerOutageContingency <: Contingency
    asset_type::String
    asset_id::String
    available_power_fraction::Float64
    
    function PowerOutageContingency(asset_type, asset_id, available_power_fraction)
        if !(0.0 <= available_power_fraction <= 1.0)
            throw(ArgumentError("available_power_fraction must be between 0.0 and 1.0"))
        end
        if asset_type != "compressor"
            @warn "PowerOutageContingency currently only supports 'compressor' asset type"
        end
        new(asset_type, asset_id, available_power_fraction)
    end
end

const _COMPASS_DIRECTIONS = ("north", "south", "east", "west")

# asset types that have fr_junction/to_junction and flow_min/flow_max bounds
const _DIRECTIONAL_FLOW_ASSET_TYPES =
    ("pipe", "compressor", "short_pipe", "resistor", "loss_resistor", "valve", "regulator")

"""
    DirectionalFlowLimitContingency(; asset_type, asset_id, direction, max_mass_flow)

Limits the mass flow through an edge component when the flow travels in a
compass `direction` (`"north"`, `"south"`, `"east"`, or `"west"`).
`max_mass_flow` is in kg/s, regardless of the case's unit system.

The compass direction is mapped onto the edge's `fr_junction` → `to_junction`
orientation using the junctions' `lat`/`lon` coordinates. Both junctions must
have finite coordinates. Otherwise, or if the edge runs exactly perpendicular to
`direction`, the contingency is not applied. To limit both directions, use two
contingencies (e.g. one `"north"` and one `"south"`).

The contingency only tightens existing bounds. It is respected by every
steady-state formulation, but not by the transient formulations, which do not
read `flow_min`/`flow_max`. For limits specified in Dth/d, see
`dth_per_day_to_kgps`.
"""
Base.@kwdef struct DirectionalFlowLimitContingency <: Contingency
    asset_type::String
    asset_id::String
    direction::String
    max_mass_flow::Float64

    function DirectionalFlowLimitContingency(asset_type, asset_id, direction, max_mass_flow)
        dir = lowercase(direction)
        if !(dir in _COMPASS_DIRECTIONS)
            throw(ArgumentError("direction must be one of $(_COMPASS_DIRECTIONS), got '$direction'"))
        end
        if !(max_mass_flow >= 0.0)
            throw(ArgumentError("max_mass_flow must be nonnegative, got $max_mass_flow"))
        end
        if !(asset_type in _DIRECTIONAL_FLOW_ASSET_TYPES)
            throw(ArgumentError("asset_type must be one of $(_DIRECTIONAL_FLOW_ASSET_TYPES), got '$asset_type'"))
        end
        new(asset_type, asset_id, dir, max_mass_flow)
    end
end

"""
    dth_per_day_to_kgps(dth_per_day, data; heating_value = 1037.0)

Converts an energy flow rate in dekatherms per day (Dth/d, as used in pipeline
capacity postings) to a mass flow rate in kg/s, for use with
`DirectionalFlowLimitContingency`.

Assumptions:
- `heating_value` is the gas's higher heating value in Btu per standard cubic
  foot. The default of 1037 Btu/scf is the approximate U.S. average for pipeline
  natural gas (EIA). Actual values vary by pipeline and over time, so pass the
  value the operator publishes if you have it.
- 1 Dth = 10^6 Btu. So, Dth/d ÷ (Btu/scf) = MMSCFD.
- MMSCFD is converted to kg/s with `get_mmscfd_to_kgps_conversion_factor`,
  which uses standard pressure of 1 atm, the network's `temperature`, and the
  `gas_specific_gravity` from `data`. U.S. pipelines often define standard
  conditions as 14.73 psia and 60 °F, which differs from this by about 0.2%.
"""
function dth_per_day_to_kgps(dth_per_day::Real, data::Dict{String,<:Any}; heating_value::Real = 1037.0)
    heating_value > 0 || throw(ArgumentError("heating_value must be positive, got $heating_value"))
    mmscfd = dth_per_day / heating_value
    return mmscfd * get_mmscfd_to_kgps_conversion_factor(data)
end

#struct that takes a vector of individual contingencies
Base.@kwdef struct ContingencyScenario
    name::String
    description::String = ""
    contingencies::Vector{<:Contingency}
end

struct ContingencyResult
    contingency::Contingency
    success::Bool
    message::String
end

#helper functions
function all_applied(results::Vector{ContingencyResult})
    """check to see if all contingencies were applied successfully"""
    return all(r.success for r in results)
end

function summarize_results(results::Vector{ContingencyResult})
    """summary string of results"""
    n_success = count(r.success for r in results)
    n_total = length(results)
    return "Applied $n_success/$n_total contingencies successfully"
end

#main function
function apply_contingency!(
    case::AbstractDict{String, <:Any},
    scenario::ContingencyScenario
)::Vector{ContingencyResult}
    results = ContingencyResult[]
    
    for cont in scenario.contingencies
        success = _apply_contingency!(case, cont)
        msg = success ? "Applied successfully" : "Failed to apply"
        push!(results, ContingencyResult(cont, success, msg))
    end
    
    return results
end

function _apply_contingency!(
    case::AbstractDict{String, <:Any},
    contingency::FailedComponentContingency
)::Bool
    if !haskey(case, contingency.asset_type)
        #some models don't have all asset types
        @warn "Asset type '$(contingency.asset_type)' not found in model data."
        return false
    end

    asset_group = case[contingency.asset_type]
    
    if !haskey(asset_group, contingency.asset_id)
        @warn "Asset ID '$(contingency.asset_id)' not found in '$(contingency.asset_type)'."
        return false
    end

    asset = asset_group[contingency.asset_id]
    
    orig_status = asset["status"]
    if orig_status != 0
        asset["status"] = 0
        return true
    end
    
    return false
end

function _apply_contingency!(
    case::AbstractDict{String, <:Any},
    contingency::PowerOutageContingency
)::Bool
    #scales compressor ratio based on available power
    if contingency.asset_type != "compressor"
        @warn "PowerOutageContingency only applies to compressors"
        return false
    end
    
    if !haskey(case, contingency.asset_type)
        @warn "Asset type '$(contingency.asset_type)' not found in model data."
        return false
    end

    asset_group = case[contingency.asset_type]
    
    if !haskey(asset_group, contingency.asset_id)
        @warn "Asset ID '$(contingency.asset_id)' not found in '$(contingency.asset_type)'."
        return false
    end

    asset = asset_group[contingency.asset_id]
    
    #new_max = min + (max - min) * available_fraction
    orig_min = get(asset, "c_ratio_min", 1.0)
    orig_max = asset["c_ratio_max"]
    
    new_max = orig_min + (orig_max - orig_min) * contingency.available_power_fraction
    
    if new_max != orig_max
        asset["c_ratio_max"] = new_max
        asset["c_ratio_min"] = orig_min
        return true
    end
    
    return false
end


"returns the (lat, lon) of a junction, or `nothing` if either is missing or non-finite"
function _junction_coordinates(junction::AbstractDict)
    lat, lon = get(junction, "lat", nothing), get(junction, "lon", nothing)
    if lat isa Real && lon isa Real && isfinite(lat) && isfinite(lon)
        return (Float64(lat), Float64(lon))
    end
    return nothing
end


"""
returns the (north, east) components of the unit vector along the initial
great-circle bearing from `fr` to `to`, each given as (lat, lon) in degrees
"""
function _bearing_components(fr::Tuple{Float64,Float64}, to::Tuple{Float64,Float64})
    φ1, φ2 = deg2rad(fr[1]), deg2rad(to[1])
    Δλ = deg2rad(to[2] - fr[2])
    east = sin(Δλ) * cos(φ2)
    north = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
    norm = hypot(north, east)
    return norm == 0.0 ? (0.0, 0.0) : (north / norm, east / norm)
end


"converts a mass flow in kg/s into the flow units the case data is currently in"
function _kgps_to_case_flow_units(case::AbstractDict{String,<:Any}, kgps::Float64)
    if get(case, "per_unit", false) == true
        return kgps / get_base_flow(case)
    elseif get(case, "english_units", false) == true
        return kgps * get_kgps_to_mmscfd_conversion_factor(case)
    end
    return kgps
end


function _apply_contingency!(
    case::AbstractDict{String, <:Any},
    contingency::DirectionalFlowLimitContingency
)::Bool
    asset_label = "$(contingency.asset_type) $(contingency.asset_id)"

    if !haskey(case, contingency.asset_type)
        @_warn "Asset type '$(contingency.asset_type)' not found in model data."
        return false
    end

    asset_group = case[contingency.asset_type]

    if !haskey(asset_group, contingency.asset_id)
        @_warn "Asset ID '$(contingency.asset_id)' not found in '$(contingency.asset_type)'."
        return false
    end

    asset = asset_group[contingency.asset_id]

    if !haskey(asset, "flow_min") || !haskey(asset, "flow_max")
        @_warn "$asset_label has no flow bounds; parse the case with parse_file before applying."
        return false
    end

    fr = _junction_coordinates(case["junction"][string(asset["fr_junction"])])
    to = _junction_coordinates(case["junction"][string(asset["to_junction"])])
    if fr === nothing || to === nothing
        @_warn "DirectionalFlowLimitContingency requires lat/lon on both junctions of $asset_label."
        return false
    end

    north, east = _bearing_components(fr, to)
    component = Dict("north" => north, "south" => -north, "east" => east, "west" => -east)[contingency.direction]

    # forward flow (fr -> to) travels in the requested direction if component > 0,
    # reverse flow does if component < 0; perpendicular edges are ambiguous
    if abs(component) < 1e-9
        @_warn "$asset_label runs perpendicular to '$(contingency.direction)' (or its junctions coincide); cannot map direction."
        return false
    end

    cap = _kgps_to_case_flow_units(case, contingency.max_mass_flow)

    if component > 0
        new_min, new_max = asset["flow_min"], min(asset["flow_max"], cap)
    else
        new_min, new_max = max(asset["flow_min"], -cap), asset["flow_max"]
    end

    if new_min > new_max
        @_warn "Limiting $asset_label $(contingency.direction)bound to $(contingency.max_mass_flow) kg/s conflicts with its existing flow bounds."
        return false
    end

    asset["flow_min"], asset["flow_max"] = new_min, new_max
    return true
end




# #example use
# scenario = ContingencyScenario(
#     name = "Winter Storm",
#     description = "Two pipes frozen, one compressor at reduced power",
#     contingencies = [
#             FailedComponentContingency(asset_type="pipe", asset_id="1"),
#             FailedComponentContingency(asset_type="pipe", asset_id="2"),
#             PowerOutageContingency(asset_type="compressor", asset_id="2", available_power_fraction=0.3),
#     ]
# )

# storm_case = apply_contingency!(case, scenario)