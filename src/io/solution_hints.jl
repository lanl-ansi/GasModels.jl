function parse_solution(solution_file::String; data::Union{AbstractDict{String,<:Any},String}=nothing)::Dict
    @assert endswith(lowercase(solution_file), ".json") "Only JSON solution files are supported"
    return parse_solution(JSON.parsefile(solution_file); data=data)
end


function parse_solution(result::AbstractDict; data::Union{AbstractDict{String,<:Any},String}=nothing)::Dict
    @assert data !== nothing "parse_solution requires a data dictionary or filename to normalize base values"

    result = deepcopy(result)
    solution = normalize_solution_base_values!(result, data)

    make_per_unit!(solution)
    if haskey(result, "objective") && !haskey(solution, "objective")
        solution["objective"] = result["objective"]
    end
    return solution
end


function _is_solution_root(solution::AbstractDict)::Bool
    return haskey(solution, "nw") ||
        any(haskey(solution, component) for component in keys(_params_for_unit_conversions))
end


function normalize_solution_base_values!(result::AbstractDict, data::Union{AbstractDict{String,<:Any},String})::Dict
    if isa(data, String)
        data = GasModels.parse_file(data)
    end

    sol = _solution_root(result)
    @assert _is_solution_root(sol) "Unsupported solution dictionary."

    if get(sol, "si_units", false) == false
        make_si_units!(sol)
    end
    @assert get(sol, "si_units", false) == true "Solution data could not be normalized to SI units."
    @assert get(sol, "per_unit", false) == false "Solution data could not be normalized to SI units."

    data = get_gm_data(data)
    _replace_base_values!(sol, data)

    return sol
end


function _replace_base_values!(solution::AbstractDict, data::AbstractDict)
    for key in collect(keys(solution))
        startswith(key, "base_") && delete!(solution, key)
    end

    for key in keys(data)
        startswith(key, "base_") && (solution[key] = data[key])
    end

    return solution
end


function add_solution_hints!(case::AbstractDict, solution_file::String)::Dict
    """add the results from a solution file as starting values. helps ensure solver consistency for testing"""
    sol_root = parse_solution(solution_file; data=case)

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


function build_solution_point(gm::_IM.AbstractInfrastructureModel, solution::AbstractDict)::Dict{JuMP.VariableRef,Float64}
    point = Dict{JuMP.VariableRef,Float64}()
    objective_value = _solution_objective(solution)
    sol_root = _solution_root(solution)
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


function primal_feasibility_report(
    gm::_IM.AbstractInfrastructureModel,
    solution::AbstractDict;
    atol::Float64 = 0.0,
    skip_missing::Bool = false,
)
    point = build_solution_point(gm, parse_solution(solution; data=gm.data))
    return JuMP.primal_feasibility_report(gm.model, point; atol = atol, skip_missing = skip_missing)
end


function primal_feasibility_report(
    gm::_IM.AbstractInfrastructureModel,
    solution_file::String;
    atol::Float64 = 0.0,
    skip_missing::Bool = false,
)
    point = build_solution_point(gm, parse_solution(solution_file; data=gm.data))
    return JuMP.primal_feasibility_report(gm.model, point; atol = atol, skip_missing = skip_missing)
end

function _apply_hints!(src::AbstractDict, dst::AbstractDict)
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


function _solution_root(solution::AbstractDict)::AbstractDict
    if haskey(solution, "solution")
        solution["solution"] isa AbstractDict || error("Unsupported solution format: `solution` must map to a dictionary")
        return solution["solution"]
    end

    return solution
end


function _solution_objective(solution::AbstractDict)
    if haskey(solution, "objective") && solution["objective"] isa Number
        return solution["objective"]
    else
        return nothing
    end
end


function _build_solution_point!(point::AbstractDict{JuMP.VariableRef,Float64}, template, value)
    if template isa JuMP.VariableRef && value isa Number
        point[template] = Float64(value)
    elseif template isa AbstractDict && value isa AbstractDict
        for (key, subval) in value
            template_key = _lookup_template_key(template, key)
            isnothing(template_key) && continue
            _build_solution_point!(point, template[template_key], subval)
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


function _add_objective_aux_value!(point::AbstractDict{JuMP.VariableRef,Float64}, model::JuMP.Model, objective_value)
    objective_value isa Number || return point

    objective_var = JuMP.objective_function(model)
    if objective_var isa JuMP.VariableRef && !haskey(point, objective_var)
        point[objective_var] = Float64(objective_value)
    end

    return point
end
