function parse_solution(solution_file::String)::Dict
    @assert endswith(lowercase(solution_file), ".json") "Only JSON solution files are supported"
    sol = JSON.parsefile(solution_file)
    sol = haskey(sol, "solution") ? sol["solution"] : sol
    return haskey(sol, "result") ? sol["result"] : sol
end


function add_solution_hints!(case::Dict, solution_file::String)::Dict
    """add the results from a solution file as starting values. helps ensure solver consistency for testing"""
    sol_root = parse_solution(solution_file)

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


function build_solution_point(gm::_IM.AbstractInfrastructureModel, solution::Dict)::Dict{JuMP.VariableRef,Float64}
    point = Dict{JuMP.VariableRef,Float64}()
    objective_value = _solution_objective(solution)
    sol_root = haskey(solution, "solution") || haskey(solution, "result") ? _solution_root(solution) : solution
    nw_sol = gm.sol[:it][gm_it_sym][:nw]

    if haskey(sol_root, "nw")
        for (nw_id, nw_src) in sol_root["nw"]
            nw = parse(Int, nw_id)
            haskey(nw_sol, nw) || continue
            _build_solution_point!(point, nw_sol[nw], nw_src)
        end
    else
        _build_solution_point!(point, nw_sol[nw_id_default], sol_root)
    end

    _add_objective_aux_value!(point, gm.model, objective_value)
    return point
end


function JuMP.primal_feasibility_report(
    gm::_IM.AbstractInfrastructureModel,
    solution::Dict;
    atol::Float64 = 0.0,
    skip_missing::Bool = false,
)
    point = build_solution_point(gm, solution)
    return JuMP.primal_feasibility_report(gm.model, point; atol = atol, skip_missing = skip_missing)
end


function JuMP.primal_feasibility_report(
    gm::_IM.AbstractInfrastructureModel,
    solution_file::String;
    atol::Float64 = 0.0,
    skip_missing::Bool = false,
)
    @assert endswith(lowercase(solution_file), ".json") "Only JSON solution files are supported"
    return JuMP.primal_feasibility_report(gm, JSON.parsefile(solution_file); atol = atol, skip_missing = skip_missing)
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


function _solution_root(solution::Dict)::Dict
    sol = haskey(solution, "solution") ? solution["solution"] : solution
    return haskey(sol, "result") ? sol["result"] : sol
end


function _solution_objective(solution::Dict)
    if haskey(solution, "objective") && solution["objective"] isa Number
        return solution["objective"]
    elseif haskey(solution, "result") && solution["result"] isa Dict
        return _solution_objective(solution["result"])
    else
        return nothing
    end
end


function _build_solution_point!(point::Dict{JuMP.VariableRef,Float64}, template, value)
    if template isa JuMP.VariableRef && value isa Number
        point[template] = Float64(value)
    elseif template isa AbstractDict && value isa AbstractDict
        for (key, subval) in value
            template_key = _lookup_template_key(template, key)
            isnothing(template_key) && continue
            _build_solution_point!(point, template[template_key], subval)
        end
    elseif template isa AbstractArray && value isa AbstractArray
        for (template_item, value_item) in zip(template, value)
            _build_solution_point!(point, template_item, value_item)
        end
    end

    return point
end


function _lookup_template_key(template::AbstractDict, key)
    if haskey(template, key)
        return key
    elseif key isa AbstractString
        sym_key = Symbol(key)
        if haskey(template, sym_key)
            return sym_key
        end

        int_key = tryparse(Int, key)
        if !isnothing(int_key) && haskey(template, int_key)
            return int_key
        end
    end

    return nothing
end


function _add_objective_aux_value!(point::Dict{JuMP.VariableRef,Float64}, model::JuMP.Model, objective_value)
    objective_value isa Number || return point

    missing_vars = [v for v in JuMP.all_variables(model) if !haskey(point, v)]
    if length(missing_vars) == 1
        point[only(missing_vars)] = Float64(objective_value)
    end

    return point
end
