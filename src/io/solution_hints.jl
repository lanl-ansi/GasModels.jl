
function add_solution_hints!(case::Dict, solution_file::String)
    if case["multinetwork"] #compatible with mnw data that doesn't have original_pipe, original_junction, etc
        try
            _add_solution_hints_mnw!(case, solution_file)
        catch e
            if isa(e, KeyError)
                @warn "add_solution_hints! is only compatible with multinetwork data from the parse_multinetwork function, not parse_files"
                @warn "Returning the original case with no modifications"
                @warn "problem key: $(e.key)"
            end
        end
        return case
    else
        return _add_solution_hints_static!(case, solution_file) #static data doesn't have "nw"
    end
end

function _add_solution_hints_static!(case::Dict, solution_file::String)
    solution = JSON.parsefile(solution_file)
    sol = solution["solution"]
    
    #add p_start
    #overusing haskey in case some files are missing components
    #not a real issue for junction/pipe but could be important if this gets extended to other comp types
    if haskey(sol, "junction") && haskey(case, "junction")
        for (j_id, j_sol) in sol["junction"]
            if haskey(case["junction"], j_id)
                if haskey(j_sol, "p")
                    case["junction"][j_id]["p_start"] = j_sol["p"]
                end
            end
        end
    else
        @warn "case is missing junction information: skipping..."
    end
    
    #add f_start for pipes
    if haskey(sol, "pipe") && haskey(case, "pipe")
        for (p_id, p_sol) in sol["pipe"]
            if haskey(case["pipe"], p_id)
                if haskey(p_sol, "f")
                    case["pipe"][p_id]["f_start"] = p_sol["f"]
                end
            end
        end
    else
        @warn "case is missing pipe information: skipping..."
    end
    
    #add f_start for compressors
    if haskey(sol, "pipe") && haskey(case, "pipe")
        for (c_id, c_sol) in sol["compressor"]
            if haskey(case["compressor"], c_id)
                if haskey(c_sol, "f")
                    case["compressor"][c_id]["f_start"] = c_sol["f"]
                end
            end
        end
    else
        @warn "case is missing compressor information: skipping..."
    end
    
    return case
end

function _add_solution_hints_mnw!(case::Dict, solution_file::String) 
    #throws KeyError if working on data from parse_files
    #this is likely to happen, so this function is very defensive

    solution = JSON.parsefile(solution_file)
    sol_nw = solution["solution"]["nw"] #try catch key error handles this

    for (nw_id, nw_sol) in sol_nw
        # check that this network exists in the case
        if !haskey(case["nw"], nw_id)
            @warn "Network $nw_id found in solution but not in case, skipping"
            continue
        end
        
        nw_case = case["nw"][nw_id]

        if haskey(nw_sol, "original_junction")
            throw(KeyError("key 'original_junction' detected"))
        end

        #add p_start
        if haskey(nw_sol, "junction") && haskey(nw_case, "junction")
            for (j_id, j_sol) in nw_sol["junction"]
                if haskey(nw_case["junction"], j_id)
                    if haskey(j_sol, "pressure")
                        nw_case["junction"][j_id]["p_start"] = j_sol["pressure"]
                    end
                end
            end
        else
            @warn "case is missing junction information: skipping..."
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
        else
            @warn "case is missing pipe information: skipping..."
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
        else
            @warn "case is missing compressor information: skipping..."
        end
    end

    return case
end