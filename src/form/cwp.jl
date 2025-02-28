
"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractCWPModel, nw::Int = nw_id_default; bounded::Bool = true, report::Bool = true)
    variable_mass_flow(gm, nw; bounded = bounded, report = report)
    variable_pipe_mass_flow_slack(gm, nw; bounded, report)
end


"""
    variable_pipe_mass_flow(gm::CWPGasModel, data, cdata)

Overrides the default pipe flow variable creation to define complementarity-based
flow variables f⁺[p] and f⁻[p], along with a net flow variable f[p] = f⁺[p] - f⁻[p].
"""
function variable_pipe_mass_flow_slack(gm::AbstractCWPModel, nw::Int=nw_id_default; bounded::Bool=true, report::Bool=true)
    # 1) Define f⁺ variables (nonnegative)
    f_plus_pipe = var(gm, nw)[:f_plus_pipe] = JuMP.@variable(
        gm.model,
        [i in ids(gm, nw, :pipe)],
        lower_bound = 0,
        base_name = "$(nw)_f_plus",
        start = comp_start_value(ref(gm, nw, :pipe), i, "f_plus_start", 0)
    )

    # 2) Define f⁻ variables (nonnegative)
    f_minus_pipe = var(gm, nw)[:f_minus_pipe] = JuMP.@variable(
        gm.model,
        [i in ids(gm, nw, :pipe)],
        lower_bound = 0,
        base_name = "$(nw)_f_minus",
        start = comp_start_value(ref(gm, nw, :pipe), i, "f_minus_start", 0)
    )

    # 2) Optionally set bounds from pipe data
    if bounded
        for (i, pipe_dict) in ref(gm, nw, :pipe)
            # handle flow_min
            if haskey(pipe_dict, "flow_min")
                flow_min = pipe_dict["flow_min"]
                if flow_min > 0
                    # pipe demands a strictly positive lower bound on "forward" flow
                    JuMP.set_lower_bound(f_plus_pipe[i], flow_min)
                elseif flow_min <= 0
                    # pipe demands a strictly negative flow_min => set a bound on "reverse" flow
                    JuMP.set_upper_bound(f_minus_pipe[i], -flow_min)
                end
            end

            # handle flow_max
            if haskey(pipe_dict, "flow_max")
                flow_max = pipe_dict["flow_max"]
                if flow_max < 0
                    # maximum is negative => limit the reverse flow variable
                    JuMP.set_lower_bound(f_minus_pipe[i], -flow_max)
                elseif flow_max >= 0
                    # standard positive flow bound
                    JuMP.set_upper_bound(f_plus_pipe[i], flow_max)
                end
            end
        end
    end

    # 4) Optionally register these variables for solution reporting
    if report
        sol_component_value(gm, nw, :pipe, :f_plus_pipe, ids(gm, nw, :pipe), f_plus_pipe)
        sol_component_value(gm, nw, :pipe, :f_minus_pipe, ids(gm, nw, :pipe), f_minus_pipe)
    end
end   

"Weymouth equation with absolute value"
function constraint_pipe_weymouth(gm::AbstractCWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    # Retrieve squared pressures at the 'from' and 'to' nodes
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    
    # Retrieve f for this pipe
    f_plus  = var(gm, n, :f_plus_pipe, k)
    f_minus = var(gm, n, :f_minus_pipe, k)
    f       = var(gm, n, :f_pipe, k)
    
    if w == 0.0
        # Degenerate case
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, pi - pj == 0.0))
    else
        _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, pi - pj == (f_plus^2 - f_minus^2) / w))    
    end

    # Complementarity (no simultaneous forward and reverse flow):
     _add_constraint!(gm, n, :complementarity_weymouth, k, JuMP.@constraint(gm.model, f_plus * f_minus == 0))

    #Relate the net flow variable f to f_plus and f_minus:
    _add_constraint!(gm, n, :weymouth_flow_relation, k, JuMP.@constraint(gm.model, f == f_plus - f_minus))
end
    
    