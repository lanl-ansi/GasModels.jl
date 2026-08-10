# Code to run inner approximation for a given fixed point
# Definitions for running an optimal gas flow (ia)

"entry point into running the ia problem"
function solve_ia(file, model_type, optimizer; kwargs...)

    return run_model(
        file,
        model_type,
        optimizer,
        build_ia;
        solution_processors = [
            # sol_psqr_to_p!,
            # sol_compressor_p_to_r!,
            # sol_regulator_p_to_r!,
        ],
        kwargs...,
    )
end


"Helper function to run a version of the ia problem which uses nominal values as bounds on gas consumption and production rather than
the physical engineering bounds on consumption and production. This allows the seperatation of engineering limits from a specific proposed
usage scenario"
function solve_ia_nominal(file, model_type, optimizer; kwargs...)
    return run_model(
        file,
        model_type,
        optimizer,
        build_ia;
        ref_extensions = [ref_nominal_flow_as_capacity!],
        solution_processors = [
            sol_psqr_to_p!,
            sol_compressor_p_to_r!,
            sol_regulator_p_to_r!,
        ],
        kwargs...,
    )
end


""
function solve_soc_ia(file, optimizer; kwargs...)
    return solve_ia(file, CRDWPGasModel, optimizer; kwargs...)
end


""
function solve_dwp_ia(file, optimizer; kwargs...)
    return solve_ia(file, DWPGasModel, optimizer; kwargs...)
end



function _prepare_ia_fixed_point!(gm::AbstractGasModel)
    raw = get(gm.ext, :fixed_point, nothing)
    isnothing(raw) && @_error("build_ia requires `ext = Dict(:fixed_point => previous_result)`")
    ia_ext = get!(gm.ext, :ia, Dict{Symbol,Any}())

    fp = parse_solution(raw, gm.data)  # handles result dict, solution dict, or JSON file
    _complete_ia_fixed_point!(fp)

    ia_ext[:fixed_point] = fp
    ia_ext[:reversal_allowed] = _ia_reversal_allowed(gm)
    return fp
end

function _ia_reversal_allowed(gm::AbstractGasModel)::Bool
    ia_ext = get(gm.ext, :ia, Dict{Symbol,Any}())
    value = get(ia_ext, :reversal_allowed, get(gm.ext, :reversal_allowed, false))
    value isa Bool || @_error("IA `reversal_allowed` must be true or false")
    return value
end

function _complete_ia_fixed_point!(fp::AbstractDict)
    if haskey(fp, "nw")
        for (_, nw_fp) in fp["nw"]
            _complete_ia_fixed_point_nw!(nw_fp)
        end
    else
        _complete_ia_fixed_point_nw!(fp)
    end
    return fp
end

function _complete_ia_fixed_point_nw!(fp::AbstractDict)
    for (_, junc) in get(fp, "junction", Dict())
        if !haskey(junc, "psqr") && haskey(junc, "p")
            junc["psqr"] = junc["p"]^2
        end
    end

    for (_, comp) in get(fp, "compressor", Dict())
        if !haskey(comp, "rsqr") && haskey(comp, "r")
            comp["rsqr"] = comp["r"]^2
        end
    end

    return fp
end

#Helper1 
function _ia_fixed_point(gm::AbstractGasModel, n::Int = nw_id_default)
    fp = gm.ext[:ia][:fixed_point]
    if haskey(fp, "nw")
        nws = fp["nw"]
        return get(nws, string(n), get(nws, n, nothing))
    end

    return fp
end
#Helper1 
function _ia_fp_value(gm::AbstractGasModel, n::Int, comp::Symbol, id, field::String)
    fp = _ia_fixed_point(gm, n)
    isnothing(fp) && @_error("fixed point missing network $(n)")

    comp_key = string(comp)
    haskey(fp, comp_key) || @_error("fixed point missing $(comp)")

    comp_dict = fp[comp_key]
    item = get(comp_dict, string(id), get(comp_dict, id, nothing))

    isnothing(item) && @_error("fixed point missing $(comp)[$(id)]")
    haskey(item, field) || @_error("fixed point missing $(comp)[$(id)][\"$(field)\"]")

    return item[field]
end

"construct the ia problem"
function build_ia(gm::AbstractGasModel)
    # bounded_compressors = Dict(
    #     x for x in ref(gm, :compressor) if
    #     _calc_is_compressor_energy_bounded(
    #         get_specific_heat_capacity_ratio(gm.data),
    #         get_gas_specific_gravity(gm.data),
    #         get_temperature(gm.data),
    #         x.second
    #     )
    # )
    _prepare_ia_fixed_point!(gm)

    variable_ia(gm)
    @info "Added variables"
    # objective_min_economic_costs(gm)

    for (i, junction) in ref(gm, :junction)
        constraint_ia_mass_flow_balance(gm, i)

    #     if (junction["junction_type"] == 1)
    #         constraint_ia_pressure(gm, i)
    #     end
    end

    for i in ids(gm, :pipe)
        # constraint_pipe_pressure(gm, i)
        # constraint_pipe_mass_flow(gm, i)
        constraint_ia_pipe_weymouth(gm, i)
    end

    # for i in ids(gm, :compressor)
    #     # constraint_compressor_ratios(gm, i)
    #     # constraint_compressor_mass_flow(gm, i)
    #     constraint_ia_compressor_ratio_value(gm, i)
    # end

    # for i in keys(bounded_compressors)
    #     constraint_compressor_energy(gm, i)
    # end


end
