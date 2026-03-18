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