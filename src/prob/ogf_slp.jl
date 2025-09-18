"""A customized sequential linear programming (SLP) algorithm for solving the
optimal gas flow (OGF) problem.
"""

struct SlpOptimizer
    lp_optimizer # This should be either the OptimizerWithAttributes or the optimizer constructor
    max_iter
    tol
    function SlpOptimizer(
        # Can't provide a default because no solvers are dependencies of GasModels
        lp_optimizer;
        max_iter = 100,
        tol = 1e-6,
    )
        return new(lp_optimizer, max_iter, tol)
    end
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
    _SLP.run_slp(optimizer, gm.model, x0)
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

struct NLP
    function NLP(model::JuMP.Model)
        return new()
    end
end

function eval_grad_lagrangian(nlp, x, λ)
    grad_obj = eval_grad_obj(nlp, x)
    jac = eval_jacobian(nlp, x)
    grad_lagrangian = (
        grad_obj * nlp.obj_factor # objective factor makes this a direction of improvement
        + jac.eq' * λ.eq # Sign is arbitrary for an EQ constraint
        + jac.lt' * λ.lt # Dual is negative for a LT constraint. Interior direction.
        + jac.gt' * λ.gt # Dual is positive for a GT constraint. Interior direction.
        + jac.interval' * λ.interval # Sign of dual depends on which side is active
    )
    return grad_lagrangian
end

# TODO: Specify tolerance
function evaluate_infeasibilities(nlp::NLP, x, λ)
    grad_lagrangian = eval_grad_lagrangian(nlp, x, λ)
    eq_con_values = eval_eq_cons(nlp, x)
    lt_con_values = eval_lt_cons(nlp, x)
    gt_con_values = eval_gt_cons(nlp, x)
    interval_con_values = eval_interval_cons(nlp, x)

    # Evaluating violations and complementarities probably gets slightly
    # simpler if constraints all have a consistent data structure.

    # TODO: get RHSs somehow
    eq_con_violations = abs.(eq_con_values .- eq_rhs)
    lt_con_violations = max.(lt_con_values .- lt_rhs, 0.0)
    gt_con_violations = max.(gt_rhs .- gt_con_values, 0.0)
    interval_con_violations = max.(interval_lb .- interval_values, interval_values .- interval_ub, 0.0)

    # All of these complementarities can be negative (if a constraint is violated, for
    # example), so we take the absolute value
    # LT: Dual is negative, so this product is positive when feasible
    lt_complementarity = abs.((lt_rhs .- lt_con_values) .* (-λ.lt))
    # GT: Dual is positive
    gt_complementarity = abs.((gt_con_values .- gt_rhs) .* λ.gt)
    interval_complementarity = abs.(
        # At most one of these terms can be nonzero
        (interval_values .- interval_lb) .* max.(λ.interval, 0)
        .+ (interval_ub .- interval_values) .* max(-λ.interval, 0)
    )

    return (;
        primal = vcat(eq_con_violations, lt_con_violations, gt_con_violations, interval_con_violations),
        dual = grad_lagrangian,
        complementarity = vcat(lt_complementarity, gt_complementarity, interval_complementarity),
    )
end

function check_if_converged(infeas::NamedTuple, tol)
    # TODO: Allow different tolerances for each category?
    # Is there any reason to break up the primal infeasibilities by constraint type?
    return (
        all(infeas.primal .<= tol)
        && all(infeas.dual .<= tol)
        && all(infeas.complementarity .<= tol)
    )
end

function run_slp(slp::GasModels.SlpOptimizer, model::JuMP.Model, x0::Dict)
    println("Hello from SLP")
    obj_sense = JuMP.objective_sense(model)
    variables = JuMP.all_variables(model)
    # TODO: Split constraints into equality, GT, etc.
    constraints = JuMP.all_constraints(model; include_variable_in_set_constraints = true)
    nvar = length(variables)
    ncon = length(constraints)
    x = map(v -> something(x0[v], 0.0), variables)
    λ = zeros(ncon)
    nlp = NLP(model)
    infeas = evaluate_infeasibilities(nlp, x, λ)
    for i in 1:slp.max_iter
        if check_if_converged(infeas, slp.tol)
            break
        end
        # 1. Obtain a linearization of all constraints at x
        # 2. Construct a LP using the linearized constraints
        # 3. Solve this LP with the specified solver
        # 4. Extract a candidate point from the solution
        # 5. Apply a trust region correction to the candidate point
        # 6. Check convergence with new point
        lp_model = JuMP.Model(slp.lp_optimizer)
        JuMP.@variable(lp_model, lp_var[1:nvar])
        JuMP.@objective(lp_model, obj_sense, sum(obj_grad .* lp_var))
        # If all my constraints are L <= g(x) <= U, then this is easy to implement.
        # At some point, I will probably want to implement bounds separately.
        JuMP.@constraint(lp_model, lp_equality[1:n_eq], eq_jac * lp_var == eq_rhs)
        JuMP.@constraint(lp_model, lp_lt[1:n_lt], lt_jac * lp_var <= lt_rhs)
        JuMP.@constraint(lp_model, lp_gt[1:n_gt], gt_jac * lp_var >= gt_rhs)
        JuMP.@constraint(lp_model, lp_interval[1:n_interval], interval_lb <= interval_jac * lp_var <= interval_ub)
        JuMP.optimize!(lp_model)
        @assert JuMP.is_solved_and_feasible(lp_model)

        trial_x = JuMP.value.(lp_var)
        trial_λ_eq = JuMP.dual.(lp_equality)
        trial_λ_lt = JuMP.dual.(lp_lt)
        trial_λ_gt = JuMP.dual.(lp_gt)
        trial_λ_interval = JuMP.dual.(lp_interval)

        # TODO: Trust region correction
    end
    # TODO: Run a Newton solve to clean up primal tolerance
    return
end

end
