function add_solution_hints!(case::Dict, solution_file::String)::Dict
    sol = JSON.parsefile(solution_file)["solution"]
    sol_root = haskey(sol, "result") ? sol["result"] : sol #handle the case of "solution = solve_ogf" vs "result = solve_ogf"

    if haskey(sol_root, "nw")
        for (nw_id, nw_sol) in sol_root["nw"]
            haskey(case, "nw") && haskey(case["nw"], nw_id) || continue
            _apply_hints!(nw_sol, case["nw"][nw_id])
        end
    else
        _apply_hints!(sol_root, case)
    end

    return case
end

function _apply_hints!(src::Dict, dst::Dict)
    for (comp, comp_sol) in src     # junction, pipe, etc
        haskey(dst, comp) || continue
        comp_sol isa AbstractDict || continue   # skip objective

        for (id, id_sol) in comp_sol      # junction 1, junction 2, etc
            haskey(dst[comp], id) || continue
            id_sol isa AbstractDict || continue # skip scalars

            for (var, value) in id_sol 
                value isa Number || continue   #only use numbers for start guesses
                dst_key = string(var, "_start")
                dst[comp][id][dst_key] = value
            end
        end
    end
end