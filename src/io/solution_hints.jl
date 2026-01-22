function add_solution_hints!(case::Dict, solution_file::String) 

    solution = JSON.parsefile(solution_file)
    sol_nw = solution["solution"]["nw"]

    # check if case has network data (static case won't have this, might need an extra function for that)
    if !haskey(case, "nw")
        @warn "Case does not contain network data (nw)"
        return case
    end

    for (nw_id, nw_sol) in sol_nw
        # check that this network exists in the case
        if !haskey(case["nw"], nw_id)
            @warn "Network $nw_id found in solution but not in case, skipping"
            continue
        end
        
        nw_case = case["nw"][nw_id]
        
        #add p_start
        if haskey(nw_sol, "junction") && haskey(nw_case, "junction")
            for (j_id, j_sol) in nw_sol["junction"]
                if haskey(nw_case["junction"], j_id)
                    if haskey(j_sol, "pressure")
                        nw_case["junction"][j_id]["p_start"] = j_sol["pressure"]
                    end
                end
            end
        end
        
        #add f_start
        if haskey(nw_sol, "pipe") && haskey(nw_case, "pipe")
            for (p_id, p_sol) in nw_sol["pipe"]
                if haskey(nw_case["pipe"], p_id)
                    if haskey(p_sol, "flow")
                        nw_case["pipe"][p_id]["f_start"] = p_sol["flow"]
                    end
                end
            end
        end
        
        #add f_start
        if haskey(nw_sol, "compressor") && haskey(nw_case, "compressor")
            for (c_id, c_sol) in nw_sol["compressor"]
                if haskey(nw_case["compressor"], c_id)
                    if haskey(c_sol, "flow")
                        nw_case["compressor"][c_id]["f_start"] = c_sol["flow"]
                    end
                end
            end
        end
    end

    return case
end