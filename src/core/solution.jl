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

const IS_DISPATCHABLE_ZERO_DEFAULTS = Dict(
    :receipt => Dict("fg" => "injection_nominal"),
    :delivery => Dict("fd" => "withdrawal_nominal"),
    :transfer => Dict("ft" => "withdrawal_nominal"),
)

function sol_is_dispatchable_zero_components!(gm::AbstractGasModel, solution::Dict)
    println("[dispatchable-zero] entered processor")

    if haskey(solution["it"][gm_it_name], "nw")
        nws_sol = solution["it"][gm_it_name]["nw"]
        println("[dispatchable-zero] solution is multinetwork with networks: ", collect(keys(nws_sol)))
    else
        nws_sol = Dict("0" => solution["it"][gm_it_name])
        println("[dispatchable-zero] solution is single network")
    end

    nws_data =
        if get(gm.data, "multinetwork", false)
            println("[dispatchable-zero] gm.data is multinetwork with networks: ", collect(keys(gm.data["nw"])))
            gm.data["nw"]
        else
            println("[dispatchable-zero] gm.data is single network")
            Dict("0" => gm.data)
        end

    for (n_str, nw_sol) in nws_sol
        n = parse(Int, n_str)
        nw_data = nws_data[n_str]

        println("[dispatchable-zero] processing network ", n_str)
        println("[dispatchable-zero] nw_sol component keys: ", collect(keys(nw_sol)))
        println("[dispatchable-zero] nw_data component keys: ", collect(keys(nw_data)))

        for (comp_name, defaults) in IS_DISPATCHABLE_ZERO_DEFAULTS
            println("[dispatchable-zero] checking component type: ", comp_name)
            _backfill_is_dispatchable_zero_components!(
                gm,
                n,
                nw_data,
                nw_sol,
                comp_name,
                defaults,
            )
        end
    end

    println("[dispatchable-zero] finished processor")
end

function _is_dispatchable_zero_missing_ids(
    gm::AbstractGasModel,
    n::Int,
    nw_data::Dict,
    nw_sol::Dict,
    comp_name::Symbol,
)
    comp_key = string(comp_name)

    if !haskey(nw_data, comp_key)
        return Int[]
    end

    data_comps = nw_data[comp_key]
    sol_comps = get(nw_sol, comp_key, Dict{String,Any}())

    out = Int[]

    for (k, data_comp) in data_comps
        i = parse(Int, k)

        if get(data_comp, "is_dispatchable", 1) == 0 &&
           !haskey(sol_comps, k)
            push!(out, i)
        end
    end

    return out
end
function _backfill_is_dispatchable_zero_components!(
    gm::AbstractGasModel,
    n::Int,
    nw_data::Dict,
    nw_sol::Dict,
    comp_name::Symbol,
    defaults::Dict{String,String},
)
    ids0 = _is_dispatchable_zero_missing_ids(gm, n, nw_data, nw_sol, comp_name)

    if isempty(ids0)
        println("[dispatchable-zero] no components to backfill for ", comp_name, " on network ", n)
        return
    end

    comp_key = string(comp_name)
    data_comps = nw_data[comp_key]
    sol_comps = get!(nw_sol, comp_key, Dict{String,Any}())

    for i in ids0
        k = string(i)
        dat = data_comps[k]
        sol = get!(sol_comps, k, Dict{String,Any}())

        println("[dispatchable-zero] backfilling ", comp_key, " ", k)
        println("[dispatchable-zero]   data keys: ", collect(keys(dat)))
        println("[dispatchable-zero]   defaults: ", defaults)

        sol["is_dispatchable"] = 0

        if haskey(dat, "status")
            sol["status"] = dat["status"]
            println("[dispatchable-zero]   set status=", dat["status"])
        end

        for (sol_var, data_field) in defaults
            if haskey(dat, data_field)
                sol[sol_var] = dat[data_field]
                println(
                    "[dispatchable-zero]   set ",
                    sol_var,
                    " = ",
                    dat[data_field],
                    " from ",
                    data_field,
                )
            else
                println(
                    "[dispatchable-zero]   MISSING required data field ",
                    data_field,
                    " for ",
                    comp_key,
                    " ",
                    k,
                )
            end
        end

        println("[dispatchable-zero]   final sol entry: ", sol)
    end
end