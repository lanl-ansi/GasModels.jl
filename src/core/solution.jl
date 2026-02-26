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

const LAST_SOL_ARG = Ref{Any}(nothing)

function sol_include_deactivated!(
    gm,
    result_or_solution;
    component_keys = nothing,
    copy_fields = nothing,
)
    @info "ENTER sol_include_deactivated!" gm_type = typeof(gm)

    component_keys === nothing && (component_keys = String[
        "junction","pipe","compressor","valve","regulator","resistor",
        "short_pipe","storage","receipt","delivery","transfer",
    ])
    copy_fields === nothing && (copy_fields = String["name", "status"])

    # detect shape and extract solution dict
    is_full_result = (result_or_solution isa AbstractDict) && haskey(result_or_solution, "solution")
    @info "shape detect" is_full_result = is_full_result

    solution = nothing
    if is_full_result
        solution = result_or_solution["solution"]
    elseif result_or_solution isa AbstractDict
        solution = result_or_solution
    else
        @info "unknown input shape - bailing" typeof_arg = typeof(result_or_solution)
        return result_or_solution
    end

    # record the exact object we were passed so you can inspect after solve
    LAST_SOL_ARG[] = solution

    # log object identity pointers 
    try
        sol_ptr = pointer_from_objref(solution)
        @info "solution pointer" ptr = sol_ptr
    catch e
        @info "pointer_from_objref failed" err = e
    end

    # file-shape handling like your add_solution_hints!
    sol_root = haskey(solution, "result") ? solution["result"] : solution
    @info "sol_root identity" sol_root_keys = collect(keys(sol_root))[1:min(10,end)]
    @info "is sol_root === solution?" equal_root_solution = (sol_root === solution)

    data = gm.data
    @info "gm.data keys count" n_data_keys = length(keys(data))

    # call helper on NW or single root
    if haskey(sol_root, "nw")
        @info "multinetwork path"
        haskey(data, "nw") || begin
            @info "gm.data has no 'nw' - nothing to do"
            return is_full_result ? result_or_solution : solution
        end
        for (nw_id, nw_sol_any) in sol_root["nw"]
            @info "processing network" nw_id = nw_id
            haskey(data["nw"], nw_id) || begin
                @info "no matching network in gm.data - skipping" nw_id = nw_id
                continue
            end
            nw_sol  = nw_sol_any::Dict{String,Any}
            nw_data = data["nw"][nw_id]::Dict{String,Any}
            _include_deactivated_into_solution_root!(nw_data, nw_sol; component_keys=component_keys, copy_fields=copy_fields)
        end
    else
        @info "single-network path; calling helper"
        _include_deactivated_into_solution_root!(data, sol_root; component_keys=component_keys, copy_fields=copy_fields)
    end

    # after helper finish, log where the junction ended up
    sol_has_top_junction = haskey(solution, "junction") && haskey(solution["junction"], "1")
    root_has_top_junction = haskey(sol_root, "junction") && haskey(sol_root["junction"], "1")
    @info "post-insert presence" sol_has_top_junction = sol_has_top_junction root_has_top_junction = root_has_top_junction sol_root_is_solution = (sol_root === solution)

    return is_full_result ? result_or_solution : solution
end


function _include_deactivated_into_solution_root!(
    data_root::Dict{String,Any},
    sol_root::Dict{String,Any};
    component_keys::Vector{String},
    copy_fields::Vector{String},
)
    # log pointer identity 
    try
        @info "_include_deactivated_into_solution_root! sol_root ptr" ptr = pointer_from_objref(sol_root)
    catch e
        @warn "pointer_from_objref failed on sol_root" err=e
    end
    @info "data_root keys count" n_data_keys = length(keys(data_root)) sol_root_keys_preview = collect(keys(sol_root))[1:min(8, end)]

    for comp_key in component_keys
        haskey(data_root, comp_key) || continue
        data_tbl_any = data_root[comp_key]
        data_tbl_any isa AbstractDict || continue
        data_tbl = data_tbl_any::Dict{String,Any}

        sol_tbl = get!(sol_root, comp_key) do
            Dict{String,Any}()
        end
        sol_tbl = sol_tbl::Dict{String,Any}

        # log pointer identity for the components
        try
            @info "component table ptr" comp_key = comp_key sol_tbl_ptr = pointer_from_objref(sol_tbl)
        catch e
            @warn "pointer_from_objref failed on sol_tbl" err=e
        end

        for (id, comp_any) in data_tbl
            comp_any isa AbstractDict || continue
            comp = comp_any::Dict{String,Any}

            s = get(comp, "status", 1)
            @info "checking component" comp_key = comp_key id = id status = s
            s == 0 || begin
                @info "skipping: not deactivated" id = id status = s
                continue
            end

            if haskey(sol_tbl, id)
                @info "skipping: already in solution table" id = id
                continue
            end

            new_entry = Dict{String,Any}()
            new_entry["status"] = 0

            for f in copy_fields
                f == "status" && continue
                if haskey(comp, f)
                    new_entry[f] = comp[f]
                else
                    @info "copy field missing in data component" field=f id=id
                end
            end

            # some kind of dumb pointer stuff to compare values
            exists_before = haskey(sol_tbl, id)
            try
                tbl_ptr_before = pointer_from_objref(sol_tbl)
            catch e
                tbl_ptr_before = nothing
            end
            @info "about to assign into sol_tbl" comp_key = comp_key id = id sol_tbl_ptr_before = tbl_ptr_before exists_before = exists_before new_entry_preview = new_entry

            # actual insertion 
            sol_tbl[id] = new_entry

            # re-check presence on sol_tbl and sol_root and log pointers again
            exists_after_tbl = haskey(sol_tbl, id)
            exists_after_root = haskey(sol_root, comp_key) && haskey(sol_root[comp_key], id)
            try
                tbl_ptr_after = pointer_from_objref(sol_tbl)
                root_ptr_after = pointer_from_objref(sol_root)
            catch e
                tbl_ptr_after = nothing
                root_ptr_after = nothing
            end
            @info "after assign" comp_key = comp_key id = id exists_after_tbl = exists_after_tbl exists_after_root = exists_after_root sol_tbl_ptr_after = tbl_ptr_after sol_root_ptr_after = root_ptr_after
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
