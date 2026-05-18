function _IM.solution_preprocessor(gm::AbstractGasModel, solution::Dict)
    solution["it"][gm_it_name]["per_unit"] = get_data_gm((x -> return x["per_unit"]), gm.data; apply_to_subnetworks = false)
    solution["it"][gm_it_name]["multinetwork"] = ismultinetwork(gm)
    solution["it"][gm_it_name]["base_pressure"] = gm.ref[:it][gm_it_sym][:base_pressure]
    solution["it"][gm_it_name]["base_flow"] = gm.ref[:it][gm_it_sym][:base_flow]
    solution["it"][gm_it_name]["base_time"] = gm.ref[:it][gm_it_sym][:base_time]
    solution["it"][gm_it_name]["base_length"] = gm.ref[:it][gm_it_sym][:base_length]
    solution["it"][gm_it_name]["base_density"] = gm.ref[:it][gm_it_sym][:base_density]
    solution["it"][gm_it_name]["base_volume"] = gm.ref[:it][gm_it_sym][:base_volume]
    solution["it"][gm_it_name]["base_mass"] = gm.ref[:it][gm_it_sym][:base_mass]
end


"GasModels wrapper for the InfrastructureModels `sol_component_value` function."
function sol_component_value(aim::AbstractGasModel, n::Int, comp_name::Symbol, field_name::Symbol, comp_ids, variables)
    return _IM.sol_component_value(aim, gm_it_sym, n, comp_name, field_name, comp_ids, variables)
end

function get_potential(gm::AbstractGasModel, x)
    b1, b2 = gm.data["non_ideal_coeffs"]
    return b1 * x^2/2.0 + b2 * x^3/3.0 
end 

function find_ub(gm::AbstractGasModel, val::Float64, ub::Float64)::Float64
    @assert ub > 0
    while get_potential(gm, ub) < val
        ub = 1.5 * ub
    end 
    return ub
end 

function find_lb(gm::AbstractGasModel,val::Float64, lb::Float64)::Float64
    @assert lb < 0
    while get_potential(gm, lb) > val
        lb = 1.5 * lb
    end 
    return lb
end 

function bisect(gm::AbstractGasModel, lb::Float64, ub::Float64, val::Float64)::Float64  
    @assert ub > lb
    mb = 1.0
    while (ub - lb) > 1e-7
        mb = (ub + lb) / 2.0
        if get_potential(gm, mb) > val
            ub = mb
        else
            lb = mb 
        end
    end
    return mb
end

invert_positive_potential(gm::AbstractGasModel, val) = bisect(gm, 0.0, find_ub(gm, val, 1.0), val)
invert_negative_potential(gm::AbstractGasModel, val) = bisect(gm, find_lb(gm, val, -1.0), 0.0, val)
invert_potential(gm::AbstractGasModel, val) = (val >= 0) ? invert_positive_potential(gm, val) : invert_negative_potential(gm, val)

function sol_pressure!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "junction")
            for (i, junction) in nw_data["junction"]
                if haskey(junction, "potential")
                    junction["pressure"] = invert_potential(gm, junction["potential"])
                end
            end
        end
    end
end 

function sol_compressor_ratio!(gm, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    for (n, nw_data) in nws_data
        for (i, compressor) in get(nw_data, "compressor", [])
            fr_junction = ref(gm, parse(Int64, n), :compressor, parse(Int64, i))["fr_junction"]
            to_junction = ref(gm, parse(Int64, n), :compressor, parse(Int64, i))["to_junction"]
            type = get(ref(gm, parse(Int64, n), :compressor, parse(Int64, i)), "directionality", 0)
            ratio = nw_data["junction"][string(to_junction)]["pressure"] /
                nw_data["junction"][string(fr_junction)]["pressure"]
            if type == 0 
                compressor["c_ratio"] = (ratio < 1) ? 1/ratio : ratio
            else 
                compressor["c_ratio"] = ratio 
            end 
        end
    end
end 

function sol_compressor_power!(gm, solution::Dict)

    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    gamma = get_specific_heat_capacity_ratio(gm.data)
    T = get_temperature(gm.data)
    G = get_gas_specific_gravity(gm.data)
    mul_constant = gamma / (gamma - 1) * 286.0 / G * T
    exponent = (gamma - 1) / gamma
    for (n, nw_data) in nws_data
        for (i, compressor) in get(nw_data, "compressor", [])
            flow = compressor["flow"]
            fr_junction = ref(gm, parse(Int64, n), :compressor, parse(Int64, i))["fr_junction"]
            to_junction = ref(gm, parse(Int64, n), :compressor, parse(Int64, i))["to_junction"]
            type = get(ref(gm, parse(Int64, n), :compressor, parse(Int64, i)), "directionality", 0)
            tmp_ratio = nw_data["junction"][string(to_junction)]["potential"] /
                nw_data["junction"][string(fr_junction)]["potential"]
            if type == 0 
                ratio = (tmp_ratio < 1) ? 1/tmp_ratio : tmp_ratio
            else 
                ratio = tmp_ratio
            end 
            power_consumed = mul_constant * round(exponent * 0.5; digits=3) * abs(flow) * (ratio - 1)
            compressor["power"] = power_consumed
        end
    end
end 


function sol_psqr_to_p!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "junction")
            for (i, junction) in nw_data["junction"]
                if haskey(junction, "psqr")
                    junction["p"] = sqrt(max(0.0, junction["psqr"]))
                end
            end
        end
    end
end


function sol_rsqr_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "compressor")
            for (i, compressor) in nw_data["compressor"]
                if haskey(compressor, "rsqr")
                    compressor["r"] = sqrt(max(0.0, compressor["rsqr"]))
                end
            end
        end
    end
end


function sol_compressor_p_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "compressor")
            for (k, compressor) in nw_data["compressor"]
                i = ref(gm, :compressor, parse(Int, k); nw = parse(Int, n))["fr_junction"]
                j = ref(gm, :compressor, parse(Int, k); nw = parse(Int, n))["to_junction"]
                f = compressor["f"]
                pi = max(0.0, nw_data["junction"][string(i)]["psqr"])
                pj = max(0.0, nw_data["junction"][string(j)]["psqr"])

                compressor["r"] = (f >= 0) ? sqrt(pj) / sqrt(pi) : sqrt(pi) / sqrt(pj)
            end
        end
    end
end


function sol_ne_compressor_p_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "ne_compressor")
            for (k, compressor) in nw_data["ne_compressor"]
                i = ref(gm, :ne_compressor, parse(Int, k); nw = parse(Int, n))["fr_junction"]
                j = ref(gm, :ne_compressor, parse(Int, k); nw = parse(Int, n))["to_junction"]
                f = compressor["f"]
                pi = max(0.0, nw_data["junction"][string(i)]["psqr"])
                pj = max(0.0, nw_data["junction"][string(j)]["psqr"])

                compressor["r"] = (f >= 0) ? sqrt(pj) / sqrt(pi) : sqrt(pi) / sqrt(pj)
            end
        end
    end
end

function sol_regulator_p_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_data = solution["it"][gm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][gm_it_name])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "regulator")
            for (k, regulator) in nw_data["regulator"]
                i = ref(gm, :regulator, parse(Int, k); nw = parse(Int, n))["fr_junction"]
                j = ref(gm, :regulator, parse(Int, k); nw = parse(Int, n))["to_junction"]
                f = regulator["f"]
                pi = max(0.0, nw_data["junction"][string(i)]["psqr"])
                pj = max(0.0, nw_data["junction"][string(j)]["psqr"])

                regulator["r"] = (f >= 0) ? sqrt(pj) / sqrt(pi) : sqrt(pi) / sqrt(pj)
            end
        end
    end
end
