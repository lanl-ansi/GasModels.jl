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

const LAST_SOL_ARG = Ref{Any}(nothing)

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

function sol_status_zero_components!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"][gm_it_name], "nw")
        nws_sol = solution["it"][gm_it_name]["nw"]
    else
        nws_sol = Dict("0" => solution["it"][gm_it_name])
    end

    nws_data =
        if get(gm.data, "multinetwork", false)
            gm.data["nw"]
        else
            Dict("0" => gm.data)
        end

    for (n_str, nw_sol) in nws_sol
        n = parse(Int, n_str)
        nw_data = nws_data[n_str]

        _backfill_status_zero_junctions!(gm, n, nw_data, nw_sol)
        _backfill_status_zero_pipes!(gm, n, nw_data, nw_sol)
        _backfill_status_zero_compressors!(gm, n, nw_data, nw_sol)
        _backfill_status_zero_transfers!(gm, n, nw_data, nw_sol)
        _backfill_status_zero_receipts!(gm, n, nw_data, nw_sol)
        _backfill_status_zero_deliveries!(gm, n, nw_data, nw_sol)
    end
end

function _status_zero_missing_ids(
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

    ref_ids = Set(ids(gm, n, comp_name))
    out = Int[]

    for (k, data_comp) in data_comps
        i = parse(Int, k)

        if get(data_comp, "status", 1) == 0 &&
           !(i in ref_ids) &&
           !haskey(sol_comps, k)
            push!(out, i)
        end
    end

    return out
end

function _backfill_status_zero_junctions!(gm, n, nw_data, nw_sol)
    ids0 = _status_zero_missing_ids(gm, n, nw_data, nw_sol, :junction)
    isempty(ids0) && return

    data_comps = nw_data["junction"]
    sol_comps = get!(nw_sol, "junction", Dict{String,Any}())

    for i in ids0
        k = string(i)
        dat = data_comps[k]
        sol = get!(sol_comps, k, Dict{String,Any}())

        sol["status"] = 0

        if haskey(dat, "psqr")
            sol["psqr"] = dat["psqr"]
        end
        if haskey(dat, "p")
            sol["p"] = dat["p"]
        elseif haskey(sol, "psqr")
            sol["p"] = sqrt(max(0.0, sol["psqr"]))
        end
    end
end


function _backfill_status_zero_pipes!(gm, n, nw_data, nw_sol)
    ids0 = _status_zero_missing_ids(gm, n, nw_data, nw_sol, :pipe)
    isempty(ids0) && return

    sol_comps = get!(nw_sol, "pipe", Dict{String,Any}())
    for i in ids0
        sol = get!(sol_comps, string(i), Dict{String,Any}())
        sol["status"] = 0
        sol["f"] = 0.0
    end
end


function _backfill_status_zero_compressors!(gm, n, nw_data, nw_sol)
    ids0 = _status_zero_missing_ids(gm, n, nw_data, nw_sol, :compressor)
    isempty(ids0) && return

    sol_comps = get!(nw_sol, "compressor", Dict{String,Any}())
    for i in ids0
        sol = get!(sol_comps, string(i), Dict{String,Any}())
        sol["status"] = 0
        sol["f"] = 0.0
        sol["r"] = 1.0
        sol["rsqr"] = 1.0
    end
end


function _backfill_status_zero_transfers!(gm, n, nw_data, nw_sol)
    ids0 = _status_zero_missing_ids(gm, n, nw_data, nw_sol, :transfer)
    isempty(ids0) && return

    sol_comps = get!(nw_sol, "transfer", Dict{String,Any}())
    for i in ids0
        sol = get!(sol_comps, string(i), Dict{String,Any}())
        sol["status"] = 0
        sol["ft"] = 0.0
    end
end


function _backfill_status_zero_receipts!(gm, n, nw_data, nw_sol)
    ids0 = _status_zero_missing_ids(gm, n, nw_data, nw_sol, :receipt)
    isempty(ids0) && return

    sol_comps = get!(nw_sol, "receipt", Dict{String,Any}())
    for i in ids0
        sol = get!(sol_comps, string(i), Dict{String,Any}())
        sol["status"] = 0
        sol["fg"] = 0.0
    end
end


function _backfill_status_zero_deliveries!(gm, n, nw_data, nw_sol)
    ids0 = _status_zero_missing_ids(gm, n, nw_data, nw_sol, :delivery)
    isempty(ids0) && return

    sol_comps = get!(nw_sol, "delivery", Dict{String,Any}())
    for i in ids0
        sol = get!(sol_comps, string(i), Dict{String,Any}())
        sol["status"] = 0
        sol["fd"] = 0.0
    end
end