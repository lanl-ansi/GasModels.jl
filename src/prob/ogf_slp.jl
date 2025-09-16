"""A customized sequential linear programming (SLP) algorithm for solving the
optimal gas flow (OGF) problem.
"""

struct SlpOptimizer
    lp_optimizer # This should be either the OptimizerWithAttributes or the optimizer constructor
end

function _get_start_value(gm::GasModels.AbstractGasModel)
    return Dict(x => JuMP.start_value(x) for x in JuMP.all_variables(gm.model))
end

# TODO: At this high-level interface, how can I specify the initial guess?
# - My only option is to specify it as a function...
function run_ogf(
    file,
    model_type,
    optimizer::SlpOptimizer;
    # For now, this argument maps AbstractGasModel -> Dict{VariableRef,Float | Nothing}
    # I may reconsider this.
    _initial_guess::Function = _get_start_value,
    skip_correct = false,
    ext = Dict{Symbol,Any}(),
    setting = Dict{String,Any}(),
    jump_model = JuMP.Model(),
    kwargs...,
)
    data = GasModels.parse_file(file; skip_correct)
    gm = GasModels.instantiate_model(
        data,
        model_type,
        GasModels.build_ogf;
        ref_extensions = [],
        ext,
        setting,
        jump_model,
        kwargs...,
    )

    _t = time()
    x0 = _get_start_value(gm)
    _SLP.run_slp!(gm.model, x0)
    t_slp = time() - _t

    # TODO: Populate solution
    solution = Dict(
    )

    # I can't use JuMP.objective_bound because I will hit a NoOptimizer error
    sense_to_bound = Dict(
        JuMP.MIN_SENSE => -Inf,
        JuMP.MAX_SENSE => Inf,
        JuMP.FEASIBILITY_SENSE => NaN,
    )
    results = Dict(
        "solve_time" => t_slp,
        "optimizer" => "SLP",
        # TODO: I will need to set this manually...
        # For now, these will just be OptimizeNotCalled.
        "termination_status" => JuMP.termination_status(gm.model),
        "primal_status" => JuMP.primal_status(gm.model),
        "dual_status" => JuMP.dual_status(gm.model),
        # TODO! I can't use JuMP.objective_value because I will get NoOptimizer.
        "objective" => 0.0,
        "objective_lb" => sense_to_bound[JuMP.objective_sense(gm.model)],
        "solution" => solution,
    )
    if haskey(data, "objective_normalization")
        result["objective"] *= data["objective_normalization"]
    end
    return results
end

module _SLP

import GasModels
import JuMP

function run_slp!(model::JuMP.Model, x0::Dict)
    println("Hello from SLP")
    return
end

end
