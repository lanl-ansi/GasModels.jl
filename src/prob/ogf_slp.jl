"""A customized sequential linear programming (SLP) algorithm for solving the
optimal gas flow (OGF) problem.
"""

module _SLP

using Printf
import GasModels
import JuMP
import MathOptInterface as MOI
import SparseArrays

mutable struct Timer
    construct_lp::Float64
    construct_nlp::Float64
    optimize_lp::Float64
    evaluate_nlp::Float64
    Timer() = new(0.0, 0.0, 0.0, 0.0)
end

function Base.show(io::IO, timer::Timer)
    println(io, "==========================")
    println(io, "SLP Timing Information (s)")
    println(io, "--------------------------")
    println(io, "  Construct NLP: $(@sprintf("%6.2f", timer.construct_nlp))")
    println(io, "   Evaluate NLP: $(@sprintf("%6.2f", timer.evaluate_nlp))")
    println(io, "  Construct  LP: $(@sprintf("%6.2f", timer.construct_lp))")
    println(io, "   Optimize  LP: $(@sprintf("%6.2f", timer.optimize_lp))")
    println(io, "==========================")
end

struct Optimizer
    lp_optimizer # This should be either the OptimizerWithAttributes or the optimizer constructor
    max_iter::Int
    tol::Float64
    init_trust_region::Float64
    function Optimizer(
        # Can't provide a default because no solvers are dependencies of GasModels
        lp_optimizer;
        max_iter = 100,
        tol = 1e-6,
        init_trust_region = 10.0,
    )
        return new(lp_optimizer, max_iter, tol, init_trust_region)
    end
end

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

function merit_function(nlp::NLP, x)
    # Let's use a merit function that is the objective value plus constraint violation
    convals = eval_constraints(nlp, x)
    eq_values = convals[nlp.eq_indices]
    eq_rhs = nlp.constraint_ubs[nlp.eq_indices]
    ineq_values = convals[nlp.ineq_indices]
    ineq_lbs = nlp.constraint_lbs[nlp.ineq_indices]
    ineq_ubs = nlp.constraint_ubs[nlp.ineq_indices]
    eq_violations = abs.(eq_values .- eq_rhs)
    ineq_violations = max.(ineq_values .- ineq_ubs, ineq_lbs .- ineq_values, 0.0)
    return (
        nlp.lagrangian_objective_factor * eval_objective(nlp, x)
        + sum(eq_violations)
        + sum(ineq_violations)
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
    slp::Optimizer,
    model::JuMP.Model,
    x0::Dict;
    λ0::Union{Nothing,Dict} = nothing,
    timer::Timer = Timer(),
)
    _t = time()
    nlp = NLP(model)
    timer.construct_nlp += time() - _t
    # Note that obj_sense is different than the nlp's lagrangian_objective_factor.
    obj_sense = JuMP.objective_sense(model)
    nvar = length(nlp.variables)
    ncon = length(nlp.constraints)

    # Initialize state we will update during the algorithm
    x = map(v -> x0[v], nlp.variables)
    λ = (λ0 !== nothing ? map(c -> λ0[c], nlp.constraints) : zeros(ncon))
    iter_count = 0

    # Trust region parameters
    nominal_trust_region_radius = slp.init_trust_region
    trust_region_radius = nominal_trust_region_radius
    max_trust_region_radius = 5 * nominal_trust_region_radius
    min_trust_region_radius = 1e-3
    expand_factor = 1.25
    shrink_factor = 0.5
    # We expand or shrink the TRR depending on the ratio between actual
    # and predicted improvement in a merit function.
    expansion_threshold = 1.0
    reduction_threshold = 1.3

    # Initialize these to dummy values so we can access them outside the loop later
    obj_val = 0.0
    termination_status = nothing
    primal_status = nothing
    dual_status = nothing
    dx = fill(NaN, nvar)
    lp_status = "N/A"
    for i in 1:slp.max_iter
        infeas = eval_infeasibilities(nlp, x, λ)
        obj_val = eval_objective(nlp, x)
        if (iter_count % 10) == 0
            println("iter    objective   inf_pr    inf_du   inf_comp   ||d||    TR_radius  LP_status")
        end
        @assert all(infeas.primal .>= 0.0)
        @assert all(infeas.dual .>= 0.0)
        @assert all(infeas.complementarity .>= 0.0)
        log_items = [
            @sprintf("%4d", iter_count),
            @sprintf("%13.3e", obj_val),
            @sprintf("%10.2e", maximum(infeas.primal)),
            @sprintf("%10.2e", maximum(infeas.dual)),
            @sprintf("%10.2e", maximum(infeas.complementarity)),
            # TODO: I would like to make this the dx _computed_ at this step,
            # not the previous dx...
            @sprintf("%10.2e", maximum(abs.(dx))),
            @sprintf("%11.2e", trust_region_radius),
            @sprintf("%11s", lp_status),
        ]
        log_line = join(log_items)
        println(log_line)
        # TODO: I want the convergence check to happen at the end of the loop
        # so I actually check the last iteration.
        # I should refactor this into a "do-while"-like loop.
        if is_converged(infeas, slp.tol)
            termination_status = JuMP.LOCALLY_SOLVED
            primal_status = JuMP.FEASIBLE_POINT
            dual_status = JuMP.FEASIBLE_POINT
            break
        elseif i == slp.max_iter
            termination_status = JuMP.ITERATION_LIMIT
            primal_status = (all(infeas.primal .<= slp.tol) ? JuMP.FEASIBLE_POINT : JuMP.INFEASIBLE_POINT)
            dual_status = (all(infeas.dual .<= slp.tol) ? JuMP.FEASIBLE_POINT : JuMP.INFEASIBLE_POINT)
            break
        end
        _t = time()
        obj_val = eval_objective(nlp, x)
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
        timer.evaluate_nlp += time() - _t

        # TODO: Reuse a single model for performance
        _t = time()
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
        JuMP.@constraint(lp_model,
            trust_region,
            - trust_region_radius .<= lp_var .- x .<= trust_region_radius
        )
        timer.construct_lp += time() - _t
        _t = time()
        JuMP.optimize!(lp_model)
        timer.optimize_lp += time() - _t

        # Update trust region size
        if JuMP.is_solved_and_feasible(lp_model)
            xnew = JuMP.value.(lp_var)
            dx .= xnew .- x
            lp_status = "feasible"
            ratio = (
                (merit_function(nlp, xnew) - merit_function(nlp, x))
                / (
                    # Linear approximation to the merit function
                    # Since the LP is feasible, the constraint violations are zero.
                    # The approximation is then:
                    # ∇f(x^0)^T (x - x^0)
                    nlp.lagrangian_objective_factor * sum(obj_grad .* (xnew .- x))
                )
            )
            # Luke also tests some quantity called the "boundary ratio"
            if ratio < expansion_threshold
                trust_region_radius = min(trust_region_radius * expand_factor, max_trust_region_radius)
            elseif ratio > reduction_threshold
                trust_region_radius = max(trust_region_radius * shrink_factor, min_trust_region_radius)
            end
        else
            dx .= 0.0
            lp_status = "infeasible"
            # Increase trust region size
            # I'm copying this iteration-dependent update from Luke's code.
            if i < 10
                trust_region_radius += 0.5 * nominal_trust_region_radius
            else
                trust_region_radius += 0.1 * nominal_trust_region_radius
            end
        end
        # TODO: Detect the case where expanding the trust region doesn't
        # fix infeasibility. Here we have basically two options:
        # 1. Converge at a locally infeasible point
        # 2. Feasibility restoration

        # We update primal-dual variables to hold most recent LP solution
        # *after* updating the trust region radius, which uses the previous
        # points.
        if JuMP.is_solved_and_feasible(lp_model)
            x .= JuMP.value.(lp_var)
            λ[nlp.eq_indices] .= JuMP.dual.(lp_equality)
            λ[nlp.ineq_indices] .= JuMP.dual.(lp_inequality)
        end

        iter_count = i
    end
    # TODO: Run a Newton solve to clean up primal tolerance
    return (;
        termination_status,
        primal_status,
        dual_status,
        objective_value = obj_val,
        primal_solution = Dict(zip(nlp.variables, x)),
        dual_solution = Dict(zip(nlp.constraints, λ)),
        timer,
    )
end

end

function _get_start_value(gm::GasModels.AbstractGasModel)::Tuple{Dict{JuMP.VariableRef,Float64},Any}
    return _get_start_value(gm.model)
end

function _get_start_value(model::JuMP.Model)::Tuple{Dict{JuMP.VariableRef,Float64},Any}
    x0 = Dict{JuMP.VariableRef,Float64}()
    for x in JuMP.all_variables(model)
        if JuMP.has_start_value(x)
            x0[x] = JuMP.start_value(x)
        elseif JuMP.has_lower_bound(x) && JuMP.has_upper_bound(x)
            x0[x] = 0.5 * (JuMP.lower_bound(x) + JuMP.upper_bound(x))
        else
            x0[x] = 0.0
        end
    end
    return x0, nothing
end

# TODO: Move this import
import HiGHS

function _solve_penalized_relaxation(
    gm::GasModels.AbstractGasModel;
    tol = 1e-6,
    max_iter = 100,
    init_trust_region = 10.0,
)::Tuple{Dict{JuMP.VariableRef,Float64},Any}
    model, refmap = JuMP.copy_model(gm.model)
    # TODO: More systematic handling of options
    slpopt = _SLP.Optimizer(HiGHS.Optimizer; tol, max_iter, init_trust_region)
    original_variables = JuMP.all_variables(model)
    JuMP.@objective(model, Min, 0.0)
    JuMP.relax_with_penalty!(model)
    x0, _ = _get_start_value(model)
    result = _SLP.run_slp(slpopt, model, x0)
    #@assert result.termination_status == JuMP.LOCALLY_SOLVED
    #@assert result.primal_status == JuMP.FEASIBLE_POINT
    #@assert result.dual_status == JuMP.FEASIBLE_POINT
    ncon = length(JuMP.all_constraints(model; include_variable_in_set_constraints = false))
    #@assert result.objective_value <= 1e-6 * ncon
    primal_values = map(x -> result.primal_solution[x], original_variables)
    original_vars = JuMP.all_variables(gm.model)
    result = merge((; model, refmap), result)
    return Dict(zip(original_vars, primal_values)), result
end

function solve_ogf(
    file::String,
    model_type::Type,
    optimizer::_SLP.Optimizer;
    _initial_guess::Function = _get_start_value, # AbstractGasModel -> Dict{VariableRef,Float64}
    kwargs...,
)
    data = GasModels.parse_file(file; skip_correct = false)
    return solve_ogf(data, model_type, optimizer; _initial_guess, kwargs...)
end

function solve_ogf(
    data::Dict,
    model_type::Type,
    optimizer::_SLP.Optimizer;
    # TODO: Allow keywords for this function
    _initial_guess::Function = _get_start_value, # AbstractGasModel -> Dict{VariableRef,Float64}
    kwargs...,
)
    gm = GasModels.instantiate_model(
        data,
        model_type,
        GasModels.build_ogf;
        kwargs...,
    )

    _t = time()
    x0, _ = _initial_guess(gm)
    slp_results = _SLP.run_slp(optimizer, gm.model, x0)
    t_slp = time() - _t

    unchanged_keys = [
        "base_density",
        "is_per_unit",
        "multinetwork",
        "base_volume",
        "base_mass",
        "base_flow",
        "base_time",
        "base_pressure",
    ]
    solution = Dict{String,Any}(k => copy(data[k]) for k in unchanged_keys)
    solution["multiinfrastructure"] = false

    ref = gm.ref[:it][:gm][:nw][0]
    var_lookup = gm.var[:it][:gm][:nw][0]
    con_lookup = gm.con[:it][:gm][:nw][0]
    _primal(sym::Symbol, idx::Int) = slp_results.primal_solution[var_lookup[sym][idx]]
    _dual(sym::Symbol, idx::Int) = slp_results.dual_solution[con_lookup[sym][idx]]
    _primal(name::String, idx::Int) = slp_results.primal_solution[JuMP.variable_by_name(gm.model, "$(name)[$idx]")]
    # TODO: Include duals if they are requested. Does this API exist?
    solution["compressor"] = Dict(
        "$i" => Dict(
            "f" => _primal(:f_compressor, i),
            "rsqr" => _primal(:rsqr, i),
            # TODO: What is r? just √rsqr?
            # For solutions from Ipopt, it is not exactly this...
            "r" => sqrt(_primal(:rsqr, i)),
        )
        for i in keys(ref[:compressor])
    )
    solution["receipt"] = Dict(
        "$i" => Dict("fg" => _primal(:fg, i))
        for (i, r) in ref[:receipt] if Bool(r["is_dispatchable"])
    )
    solution["delivery"] = Dict(
        "$i" => Dict("fl" => _primal(:fl, i))
        for (i, d) in ref[:delivery] if Bool(d["is_dispatchable"])
    )
    solution["junction"] = Dict(
        "$i" => Dict("p" => sqrt(_primal(:psqr, i)), "psqr" => _primal(:psqr, i))
        for i in keys(ref[:junction])
    )
    solution["pipe"] = Dict(
        "$i" => Dict("f" => _primal(:f_pipe, i)) for i in keys(ref[:pipe])
    )
    # TODO: Short pipe? Regulator? Resistor? Valve?

    # I can't use JuMP.objective_bound because I will hit a NoOptimizer error
    sense_to_bound = Dict(
        JuMP.MIN_SENSE => -Inf,
        JuMP.MAX_SENSE => Inf,
        JuMP.FEASIBILITY_SENSE => NaN,
    )
    results = Dict(
        "solve_time" => t_slp,
        "optimizer" => "SLP",
        "termination_status" => slp_results.termination_status,
        "primal_status" => slp_results.primal_status,
        "dual_status" => slp_results.dual_status,
        "objective" => slp_results.objective_value,
        "objective_lb" => sense_to_bound[JuMP.objective_sense(gm.model)],
        "solution" => solution,
    )
    if haskey(data, "objective_normalization")
        results["objective"] *= data["objective_normalization"]
    end
    return results
end
