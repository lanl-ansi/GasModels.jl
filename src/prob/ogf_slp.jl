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

using Printf
import GasModels
import JuMP
import MathOptInterface as MOI
import SparseArrays

struct NLP
    variables::Vector{JuMP.VariableRef}
    constraints::Vector{<:JuMP.ConstraintRef}
    constraint_ubs::Vector{Float64}
    constraint_lbs::Vector{Float64}
    eq_indices::Vector{Int}
    ineq_indices::Vector{Int}
    lagrangian_objective_factor::Int
    evaluator::MOI.AbstractNLPEvaluator
    function NLP(model::JuMP.Model)
        nlp = MOI.Nonlinear.Model()
        variables = JuMP.all_variables(model)
        constraints = JuMP.all_constraints(model; include_variable_in_set_constraints = true)
        ncon = length(constraints)
        constraint_ubs = fill(Inf, ncon)
        constraint_lbs = fill(-Inf, ncon)
        eq_indices = Int[]
        ineq_indices = Int[]
        for (i, cref) in enumerate(constraints)
            # What to do about vector functions?
            @assert cref.shape == JuMP.ScalarShape()
            con = JuMP.constraint_object(cref)
            MOI.Nonlinear.add_constraint(nlp, con.func, con.set)
            if con.set isa MOI.EqualTo
                push!(eq_indices, i)
                constraint_ubs[i] = con.set.value
                constraint_lbs[i] = con.set.value
            elseif con.set isa MOI.LessThan
                push!(ineq_indices, i)
                constraint_ubs[i] = con.set.upper
            elseif con.set isa MOI.GreaterThan
                push!(ineq_indices, i)
                constraint_lbs[i] = con.set.lower
            elseif con.set isa MOI.Interval
                push!(ineq_indices, i)
                constraint_lbs[i] = con.set.lower
                constraint_ubs[i] = con.set.upper
            else
                error("Unsupported constraint set $(con.set)")
            end
        end
        MOI.Nonlinear.set_objective(nlp, JuMP.objective_function(model))
        # The purpose of the objective factor is to make sure that the objective-gradient
        # term in the gradient of the Lagrangian is a direction of improvement.
        # Note that we solve *minimization and maximization* problems, and this factor
        # is only for the purpose of computing the Lagrangian.
        lagrangian_objective_factor = JuMP.objective_sense(model) == JuMP.MIN_SENSE ? -1 : 1
        evaluator = MOI.Nonlinear.Evaluator(nlp, MOI.Nonlinear.SparseReverseMode(), JuMP.index.(variables))
        MOI.initialize(evaluator, [:Grad, :Jac, :Hess])
        return new(
            variables,
            constraints,
            constraint_ubs,
            constraint_lbs,
            eq_indices,
            ineq_indices,
            lagrangian_objective_factor,
            evaluator,
        )
   end
end

function eval_objective(nlp, x)
    return MOI.eval_objective(nlp.evaluator, x)
end

function eval_objective_gradient(nlp, x)
    grad = zeros(length(nlp.variables))
    MOI.eval_objective_gradient(nlp.evaluator, grad, x)
    return grad
end

function eval_constraints(nlp, x)
    g = zeros(length(nlp.constraints))
    MOI.eval_constraint(nlp.evaluator, g, x)
    return g
end

function eval_constraint_jacobian(nlp, x)
    structure = MOI.jacobian_structure(nlp.evaluator)
    values = zeros(length(structure))
    MOI.eval_constraint_jacobian(nlp.evaluator, values, x)
    rows = first.(structure)
    cols = last.(structure)
    jac = SparseArrays.sparse(rows, cols, values)
    return jac
end

function eval_lagrangian_gradient(nlp, x, λ)
    grad_obj = eval_objective_gradient(nlp, x)
    jac = eval_constraint_jacobian(nlp, x)
    grad_lagrangian = grad_obj * nlp.lagrangian_objective_factor + jac' * λ
    #grad_lagrangian = (
    #    grad_obj * nlp.obj_factor # objective factor makes this a direction of improvement
    #    + jac.eq' * λ.eq # Sign is arbitrary for an EQ constraint
    #    + jac.lt' * λ.lt # Dual is negative for a LT constraint. Interior direction.
    #    + jac.gt' * λ.gt # Dual is positive for a GT constraint. Interior direction.
    #    + jac.interval' * λ.interval # Sign of dual depends on which side is active
    #)
    return grad_lagrangian
end

function eval_infeasibilities(nlp::NLP, x, λ)
    grad_lagrangian = eval_lagrangian_gradient(nlp, x, λ)
    convals = eval_constraints(nlp, x)
    eq_values = convals[nlp.eq_indices]
    eq_rhs = nlp.constraint_ubs[nlp.eq_indices]
    ineq_values = convals[nlp.ineq_indices]
    ineq_lbs = nlp.constraint_lbs[nlp.ineq_indices]
    ineq_ubs = nlp.constraint_ubs[nlp.ineq_indices]
    λ_ineq = λ[nlp.ineq_indices]

    eq_violations = abs.(eq_values .- eq_rhs)
    ineq_violations = max.(ineq_values .- ineq_ubs, ineq_lbs .- ineq_values, 0.0)

    # This is a "disaggregated" approach to handling slacks that can be inf.
    #leq_indices = (ineq_lbs .== -Inf .&& ineq_ubs .!= Inf)
    #geq_indices = (ineq_ubs .== Inf .&& ineq_lbs .!= -Inf)
    #interval_indices = (ineq_lbs .!= -Inf .&& ineq_ubs .!= Inf)
    ## Unclear where these multiplier signs should be enforced...
    #@assert all(λ_ineq[leq_indices] .<= 0.0)
    #@assert all(λ_ineq[geq_indices] .>= 0.0)
    #complementarity = zeros(length(nlp.ineq_indices))
    #complementarity[geq_indices] += abs.((ineq_values[geq_indices] .- ineq_lbs[geq_indices]) .* λ_ineq[geq_indices]) # max.(λ_ineq[geq_indices], 0.0)
    #complementarity[leq_indices] += abs.((ineq_ubs[leq_indices] .- ineq_values[leq_indices]) .* λ_ineq[leq_indices]) # max.(-λ_ineq[leq_indices], 0.0)
    #complementarity[interval_indices] += abs.(
    #    (ineq_values[interval_indices] .- ineq_lbs[interval_indices]) .* max.(λ_ineq[interval_indices], 0.0)
    #    .+ (ineq_ubs[interval_indices] .- ineq_values[interval_indices]) .* max.(-λ_ineq[interval_indices], 0.0)
    #)

    # - This can be negative if a constraint is violated, so we take the absolute value.
    # - At most one of these terms can be nonzero. λ≥0 for a lower bound
    # - If the bound is inf, we penalize the corresponding signed magnitude of λ.
    #   λ should not have, e.g., a positive magnitude if the lower bound is -Inf.
    complementarity = abs.(
        ifelse.(ineq_lbs .== -Inf, 1.0, ineq_values .- ineq_lbs) .* max.(λ_ineq, 0.0)
        .+ ifelse.(ineq_ubs .== Inf, 1.0, ineq_ubs .- ineq_values) .* max.(-λ_ineq, 0.0)
    )

    return (;
        primal = vcat(eq_violations, ineq_violations),
        dual = abs.(grad_lagrangian),
        complementarity,
    )
end

function is_converged(infeas::NamedTuple, tol)
    # TODO: Allow different tolerances for each category?
    # Is there any reason to break up the primal infeasibilities by constraint type?
    return (
        all(infeas.primal .<= tol)
        && all(infeas.dual .<= tol)
        && all(infeas.complementarity .<= tol)
    )
end

function run_slp(
    slp::GasModels.SlpOptimizer,
    model::JuMP.Model,
    x0::Dict;
    λ0::Union{Nothing,Dict} = nothing,
)
    nlp = NLP(model)
    # Note that obj_sense is different than the nlp's lagrangian_objective_factor.
    obj_sense = JuMP.objective_sense(model)
    nvar = length(nlp.variables)
    ncon = length(nlp.constraints)
    x = map(v -> x0[v], nlp.variables)
    λ = something(map(c -> λ0[c], nlp.constraints), zeros(ncon))
    iter_count = 0
    for i in 1:slp.max_iter
        infeas = eval_infeasibilities(nlp, x, λ)
        obj_val = eval_objective(nlp, x)
        if (iter_count % 10) == 0
            println("iter    objective   inf_pr    inf_du   inf_comp")
        end
        @assert all(infeas.primal .>= 0.0)
        @assert all(infeas.dual .>= 0.0)
        @assert all(infeas.complementarity .>= 0.0)
        log_line = (
            @sprintf("%4d", iter_count)
            * @sprintf("%13.3e", obj_val)
            * @sprintf("%10.2e", maximum(infeas.primal))
            * @sprintf("%10.2e", maximum(infeas.dual))
            * @sprintf("%10.2e", maximum(infeas.complementarity))
        )
        println(log_line)
        # TODO: I want the convergence check to happen at the end of the loop
        # so I actually check the last iteration.
        # I should refactor this into a "do-while"-like loop.
        if is_converged(infeas, slp.tol)
            break
        end
        # 1. Obtain a linearization of all constraints at x
        # 2. Construct a LP using the linearized constraints
        # 3. Solve this LP with the specified solver
        # 4. Extract a candidate point from the solution
        # 5. Apply a trust region correction to the candidate point
        # 6. Check convergence with new point
        obj_grad = eval_objective_gradient(nlp, x)
        convals = eval_constraints(nlp, x)
        eq_values = convals[nlp.eq_indices]
        eq_rhs = nlp.constraint_ubs[nlp.eq_indices]
        ineq_values = convals[nlp.ineq_indices]
        ineq_lbs = nlp.constraint_lbs[nlp.ineq_indices]
        ineq_ubs = nlp.constraint_ubs[nlp.ineq_indices]
        jac = eval_constraint_jacobian(nlp, x)
        eq_jac = jac[nlp.eq_indices, :]
        ineq_jac = jac[nlp.ineq_indices, :]

        lp_model = JuMP.Model(slp.lp_optimizer)
        JuMP.set_silent(lp_model)
        # TODO: Handle bounds separately from inequalities
        JuMP.@variable(lp_model, lp_var[i in 1:nvar], start = x[i])
        # It doesn't matter for the solve, but if we want this objective to match
        # the original model's objective at the solution, we need to offset by
        # the objective value at x.
        JuMP.@objective(lp_model, obj_sense, sum(obj_grad .* lp_var))
        JuMP.@constraint(lp_model,
            lp_equality,
            eq_values .+ eq_jac * (lp_var .- x) .== eq_rhs
        )
        JuMP.@constraint(lp_model,
            lp_inequality,
            ineq_lbs .<= ineq_values .+ ineq_jac * (lp_var .- x) .<= ineq_ubs
        )
        JuMP.optimize!(lp_model)
        #@assert JuMP.is_solved_and_feasible(lp_model)

        trial_x = JuMP.value.(lp_var)
        trial_λ = zeros(ncon)
        trial_λ[nlp.eq_indices] .= JuMP.dual.(lp_equality)
        trial_λ[nlp.ineq_indices] .= JuMP.dual.(lp_inequality)

        # TODO: Trust region correction
        x .= trial_x
        λ .= trial_λ
        iter_count = i
    end
    # TODO: Run a Newton solve to clean up primal tolerance
    return
end

end
