function _IM.solution_preprocessor(gm::AbstractGasModel, solution::Dict)
    solution["it"][gm_it_name]["is_per_unit"] = get_data_gm((x -> return x["is_per_unit"]), gm.data; apply_to_subnetworks = false)
    solution["it"][gm_it_name]["multinetwork"] = ismultinetwork(gm)
    solution["it"][gm_it_name]["base_pressure"] = gm.ref[:it][gm_it_sym][:base_pressure]
    solution["it"][gm_it_name]["base_flow"] = gm.ref[:it][gm_it_sym][:base_flow]
    solution["it"][gm_it_name]["base_time"] = gm.ref[:it][gm_it_sym][:base_time]
    solution["it"][gm_it_name]["base_length"] = gm.ref[:it][gm_it_sym][:base_length]
    solution["it"][gm_it_name]["base_density"] = gm.ref[:it][gm_it_sym][:base_density]
    solution["it"][gm_it_name]["base_volume"] = gm.ref[:it][gm_it_sym][:base_volume]
    solution["it"][gm_it_name]["base_mass"] = gm.ref[:it][gm_it_sym][:base_mass]
end

function sol_include_deactivated!(gm, result; component_keys=nothing, copy_fields=nothing)
    """
    Post-solve solution processor: re-inserts deactivated components (status==0) from gm.data
    into the returned result["solution"] dict so they appear in outputs even if filtered out
    of ref and not modeled.

    Works for both:
    - transient/multinetwork: result["solution"]["nw"][nw_id][comp][id]
    - static:               result["solution"][comp][id]
    """
    sol = get(result, "solution", nothing)
    sol === nothing && return result

    if component_keys === nothing
        component_keys = String[
            "junction",
            "pipe",
            "compressor",
            "valve",
            "regulator",
            "resistor",
            "short_pipe",
            "storage",
            "receipt",
            "delivery",
            "transfer",
        ]
    end

    #fields to copy into the solution entry
    if copy_fields === nothing
        copy_fields = String["name", "status"]
    end

    data = gm.data

    if haskey(sol, "nw")
        # multinetwork
        haskey(data, "nw") || return result

        for (nw_id, nw_sol_any) in sol["nw"]
            haskey(data["nw"], nw_id) || continue
            nw_sol  = nw_sol_any::Dict{String,Any}
            nw_data = data["nw"][nw_id]::Dict{String,Any}
            _include_deactivated_into_solution_root!(nw_data, nw_sol; component_keys, copy_fields)
        end
    else
        # static
        _include_deactivated_into_solution_root!(data, sol; component_keys, copy_fields)
    end

    return result
end


function _include_deactivated_into_solution_root!(
    data_root::Dict{String,Any},
    sol_root::Dict{String,Any};
    component_keys::Vector{String},
    copy_fields::Vector{String},
)
    for comp_key in component_keys
        haskey(data_root, comp_key) || continue
        data_tbl_any = data_root[comp_key]
        data_tbl_any isa AbstractDict || continue
        data_tbl = data_tbl_any::Dict{String,Any}

        sol_tbl = get!(sol_root, comp_key) do
            Dict{String,Any}()
        end
        sol_tbl = sol_tbl::Dict{String,Any}

        for (id, comp_any) in data_tbl
            comp_any isa AbstractDict || continue
            comp = comp_any::Dict{String,Any}

            get(comp, "status", 1) == 0 || continue
            haskey(sol_tbl, id) && continue

            new_entry = Dict{String,Any}()
            new_entry["status"] = 0

            for f in copy_fields
                f == "status" && continue
                haskey(comp, f) || continue
                new_entry[f] = comp[f]
            end

            sol_tbl[id] = new_entry
        end
    end

    return sol_root
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
