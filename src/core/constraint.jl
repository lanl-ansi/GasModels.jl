##########################################################################################################
# The purpose of this file is to define commonly used and created constraints used in gas flow models
##########################################################################################################

"Utility function for adding constraints to a gm.model"
function _add_constraint!(gm::AbstractGasModel, n::Int, key, k, constraint)
    if !haskey(gm.con[:nw][n], key)
        gm.con[:nw][n][key] = Dict{Any,JuMP.ConstraintRef}()
    end
    gm.con[:nw][n][key][k] = constraint
end

#################################################################################################
# Constraints associated with resistors
#################################################################################################

"Constraint: Constraints which define pressure drop across a resistor"
function constraint_resistor_pressure(gm::AbstractGasModel, n::Int, k, i, j, pd_min, pd_max)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    _add_constraint!(gm, n, :pressure_drop1, k, JuMP.@constraint(gm.model, pd_min <= pi - pj))
    _add_constraint!(gm, n, :pressure_drop2, k, JuMP.@constraint(gm.model, pi - pj <= pd_max))
end


"Constraint: constraints on pressure drop across where direction is constrained"
function constraint_resistor_pressure_directed(gm::AbstractGasModel, n::Int, k, i, j, pd_min, pd_max)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    _add_constraint!(gm, n, :pressure_drop1, k, JuMP.@constraint(gm.model, pi - pj <= pd_max))
    _add_constraint!(gm, n, :pressure_drop2, k, JuMP.@constraint(gm.model, pd_min <= pi - pj))
end


"Constraint: Constraint on mass flow across the resistor"
function constraint_resistor_mass_flow(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_resistor,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: constraint on flow across the resistor where direction is constrained"
function constraint_resistor_mass_flow_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_resistor,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


#################################################################################################
# Constraints associated with junctions
#################################################################################################

" Constraint: standard flow balance equation where demand and production are variables "
function constraint_pressure(gm::AbstractGasModel, n::Int, i, p_nom)
    p  = var(gm,n,:p,i)
    JuMP.set_lower_bound(p, p_nom)
    JuMP.set_upper_bound(p, p_nom)
end


"Constraint: standard flow balance equation where demand and production are variables"
function constraint_mass_flow_balance(gm::AbstractGasModel, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, fl_constant, fg_constant, consumers, producers, flmin, flmax, fgmin, fgmax)
    f_pipe          = var(gm,n,:f_pipe)
    f_compressor    = var(gm,n,:f_compressor)
    f_resistor      = var(gm,n,:f_resistor)
    f_short_pipe    = var(gm,n,:f_short_pipe)
    f_valve         = var(gm,n,:f_valve)
    f_control_valve = var(gm,n,:f_control_valve)
    fg              = var(gm,n,:fg)
    fl              = var(gm,n,:fl)
    _add_constraint!(gm, n, :junction_mass_flow_balance, i, JuMP.@constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) ==
                                                                            sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                            sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) +
                                                                            sum(f_resistor[a] for a in f_resistors) - sum(f_resistor[a] for a in t_resistors) +
                                                                            sum(f_short_pipe[a] for a in f_short_pipes) - sum(f_short_pipe[a] for a in t_short_pipes) +
                                                                            sum(f_valve[a] for a in f_valves) - sum(f_valve[a] for a in t_valves) +
                                                                            sum(f_control_valve[a] for a in f_control_valves) - sum(f_control_valve[a] for a in t_control_valves)
                                                                        ))
end


"Constraint: standard flow balance equation where demand and production are variables and there are expansion connections"
function constraint_mass_flow_balance_ne(gm::AbstractGasModel, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors, fl_constant, fg_constant, consumers, producers, flmin, flmax, fgmin, fgmax)
    f_pipe          = var(gm,n,:f_pipe)
    f_compressor    = var(gm,n,:f_compressor)
    f_resistor      = var(gm,n,:f_resistor)
    f_short_pipe    = var(gm,n,:f_short_pipe)
    f_valve         = var(gm,n,:f_valve)
    f_control_valve = var(gm,n,:f_control_valve)
    f_ne_pipe       = var(gm,n,:f_ne_pipe)
    f_ne_compressor = var(gm,n,:f_ne_compressor)
    fg              = var(gm,n,:fg)
    fl              = var(gm,n,:fl)
    _add_constraint!(gm, n, :junction_mass_flow_balance_ne_ls, i, JuMP.@constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) ==
                                                                                      sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                                      sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) +
                                                                                      sum(f_resistor[a] for a in f_resistors) - sum(f_resistor[a] for a in t_resistors) +
                                                                                      sum(f_short_pipe[a] for a in f_short_pipes) - sum(f_short_pipe[a] for a in t_short_pipes) +
                                                                                      sum(f_valve[a] for a in f_valves) - sum(f_valve[a] for a in t_valves) +
                                                                                      sum(f_control_valve[a] for a in f_control_valves) - sum(f_control_valve[a] for a in t_control_valves) +
                                                                                      sum(f_ne_pipe[a] for a in f_ne_pipes) - sum(f_ne_pipe[a] for a in t_ne_pipes) +
                                                                                      sum(f_ne_compressor[a] for a in f_ne_compressors) - sum(f_ne_compressor[a] for a in t_ne_compressors)
                                                                            ))
end


#################################################################################################
# Constraints associated with short pipes
#################################################################################################

"Constraint: Constraint on pressure drop across a short pipe"
function constraint_short_pipe_pressure(gm::AbstractGasModel, n::Int, k, i, j)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    _add_constraint!(gm, n, :short_pipe_pressure_drop, k, JuMP.@constraint(gm.model,  pi == pj))
end


"Constraint: Constraints on flow across a short pipe with on/off direction variables"
function constraint_short_pipe_mass_flow(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_short_pipe,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: Constraints on flow across a short pipe where direction of flow is constrained"
function constraint_short_pipe_mass_flow_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_short_pipe,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


#################################################################################################
# Constraints associated with vakves
#################################################################################################

"Constraint: Constraints on pressure drop across valves where the valve can open or close"
function constraint_on_off_valve_pressure(gm::AbstractGasModel, n::Int, k, i, j, i_pmax, j_pmax)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v  = var(gm,n,:v_valve,k)
    _add_constraint!(gm, n, :valve_pressure_drop1, k, JuMP.@constraint(gm.model,  pj - ((1-v)*j_pmax^2) <= pi))
    _add_constraint!(gm, n, :valve_pressure_drop2, k, JuMP.@constraint(gm.model,  pi <= pj + ((1-v)*i_pmax^2)))
end


"constraints on flow across undirected valves"
function constraint_on_off_valve_mass_flow(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f = var(gm,n,:f_valve,k)
    v = var(gm,n,:v_valve,k)
    _add_constraint!(gm, n,:on_off_valve_flow1, k, JuMP.@constraint(gm.model, f_min*v <= f))
    _add_constraint!(gm, n,:on_off_valve_flow2, k, JuMP.@constraint(gm.model, f <= f_max*v))
end


"Constraint: constraints on flow across valves when the direction of flow is constrained."
function constraint_on_off_valve_mass_flow_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f = var(gm,n,:f_valve,k)
    v = var(gm,n,:v_valve,k)
    _add_constraint!(gm, n,:valve_flow_direction1, k, JuMP.@constraint(gm.model, f_min*v <= f))
    _add_constraint!(gm, n,:valve_flow_direction2, k, JuMP.@constraint(gm.model, f <= f_max*v))
end


#################################################################################################
# Constraints associated with pipes
#################################################################################################

"Constraint: on/off constraints on flow across pipes for expansion pipes"
function constraint_pipe_ne(gm::AbstractGasModel, n::Int, k, w, f_min, f_max)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne_pipe,k)
    _add_constraint!(gm, n, :pipe_ne1, k, JuMP.@constraint(gm.model, f <= zp*f_max))
    _add_constraint!(gm, n, :pipe_ne2, k, JuMP.@constraint(gm.model, f >= zp*f_min))
end


"Constraint: Constraints which define pressure drop across a pipe"
function constraint_pipe_pressure(gm::AbstractGasModel, n::Int, k, i, j, pd_min, pd_max)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    _add_constraint!(gm, n, :pressure_drop1, k, JuMP.@constraint(gm.model, pd_min <= pi - pj))
    _add_constraint!(gm, n, :pressure_drop2, k, JuMP.@constraint(gm.model, pi - pj <= pd_max))
end


"Constraint: constraints on pressure drop across where direction is constrained"
function constraint_pipe_pressure_directed(gm::AbstractGasModel, n::Int, k, i, j, pd_min, pd_max)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    _add_constraint!(gm, n, :pressure_drop1, k, JuMP.@constraint(gm.model, pi - pj <= pd_max))
    _add_constraint!(gm, n, :pressure_drop2, k, JuMP.@constraint(gm.model, pd_min <= pi - pj))
end


"Constraint: constraints on pressure drop across an expansion pipe"
function constraint_pipe_pressure_ne(gm::AbstractGasModel, n::Int, k, i, j, pd_min, pd_max)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    _add_constraint!(gm, n, :on_off_pressure_drop_ne1, k, JuMP.@constraint(gm.model, pd_min  <= pi - pj))
    _add_constraint!(gm, n, :on_off_pressure_drop_ne2, k, JuMP.@constraint(gm.model, pi - pj <= pd_max))
end


"Constraint: Constraint on mass flow across the pipe"
function constraint_pipe_mass_flow(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_pipe,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: constraints on flow across an expansion pipe"
function constraint_pipe_mass_flow_ne(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_ne_pipe,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: constraint on flow across the pipe where direction is constrained"
function constraint_pipe_mass_flow_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_pipe,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: Pressure drop across an expansion pipe when direction is constrained"
function constraint_pipe_pressure_ne_directed(gm::AbstractGasModel, n::Int, k, i, j, pd_min, pd_max, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    z  = var(gm,n,:zp,k)

    if direction == 1
        _add_constraint!(gm, n, :pressure_drop_ne, k, JuMP.@constraint(gm.model, pi - pj >= (1-z)*pd_max))
    else
        _add_constraint!(gm, n, :pressure_drop_ne, k, JuMP.@constraint(gm.model, pi - pj <= (1-z)*pd_min))
    end
end


"Constraint: Flow across an expansion pipe when direction is constrained"
function constraint_pipe_mass_flow_ne_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_ne_pipe,k)
    _add_constraint!(gm, n, :pipe_flow, k, JuMP.@constraint(gm.model, f >= f_min))
    _add_constraint!(gm, n, :pipe_flow, k, JuMP.@constraint(gm.model, f <= f_max))
end

#################################################################################################
# Constraints associated with compressors
#################################################################################################

"Constraint: on/off constraints on flow across compressors for expansion variables"
function constraint_compressor_ne(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    zc = var(gm,n,:zc,k)
    f  =  var(gm,n,:f_ne_compressor,k)
    _add_constraint!(gm, n, :compressor_flow_ne1, k, JuMP.@constraint(gm.model, f_min*zc <= f))
    _add_constraint!(gm, n, :compressor_flow_ne2, k, JuMP.@constraint(gm.model, f <= f_max*zc))
end


"Constraint: constraints on flow across a compressor with on/off direction variables"
function constraint_compressor_mass_flow(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_compressor,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: constraints on flow across compressors with on/off direction variables"
function constraint_compressor_mass_flow_ne(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_ne_compressor,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: flow across a compressor when flow is restricted to one direction"
function constraint_compressor_mass_flow_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_compressor,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: Compressor ratio when the flow direction is constrained"
function constraint_compressor_ratios_directed(gm::AbstractGasModel, n::Int, k, i, j, min_ratio, max_ratio, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)

    if direction == 1
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= 0))
        _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= 0))
    else
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pj == pi))
    end
end


"Constraint: flow across expansion compressors when the direction is constrained"
function constraint_compressor_mass_flow_ne_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f  = var(gm,n,:f_ne_compressor,k)
    lb = JuMP.has_lower_bound(f) ? max(JuMP.lower_bound(f), f_min) : f_min
    ub = JuMP.has_upper_bound(f) ? min(JuMP.upper_bound(f), f_max) : f_max
    JuMP.set_lower_bound(f, lb)
    JuMP.set_upper_bound(f, ub)
end


"Constraint: Pressure drop across an expansion compressor when direction is constrained"
function constraint_compressor_ratios_ne_directed(gm::AbstractGasModel, n::Int, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)

    if direction == 1
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-zc)*j_pmax^2))
        _add_constraint!(gm, n, :compressor_ratios2, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-zc)*(min_ratio*i_pmax^2)))
    else
        _add_constraint!(gm, n, :compressor_ratios1, k, JuMP.@constraint(gm.model, f * (1-pj/pi) <= (1-zc) * mf * (1-j_pmax^2/i_pmin^2)))
    end
end


#################################################################################################
# Constraints associated with control valves
#################################################################################################

"constraints on flow across control valves that are undirected"
function constraint_on_off_control_valve_mass_flow(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f = var(gm,n,:f_control_valve,k)
    v = var(gm,n,:v_control_valve,k)
    _add_constraint!(gm, n,:on_off_valve_flow1, k, JuMP.@constraint(gm.model, f_min*v <= f))
    _add_constraint!(gm, n,:on_off_valve_flow2, k, JuMP.@constraint(gm.model, f <= f_max*v))
end


"Constraint: Flow across control valves when direction is constrained"
function constraint_on_off_control_valve_mass_flow_directed(gm::AbstractGasModel, n::Int, k, f_min, f_max)
    f = var(gm,n,:f_control_valve,k)
    v = var(gm,n,:v_control_valve,k)

    _add_constraint!(gm, n,:control_valve_flow_direction4, k, JuMP.@constraint(gm.model, f <= f_max*v))
    _add_constraint!(gm, n,:control_valve_flow_direction3, k, JuMP.@constraint(gm.model, f_min*v <= f))
end


"Constraint: Pressure drop across a control valves when directions is constrained"
function constraint_on_off_control_valve_pressure_directed(gm::AbstractGasModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v  = var(gm,n,:v_control_valve,k)

    if direction == 1
        _add_constraint!(gm, n, :control_valve_pressure_drop1, k, JuMP.@constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
        _add_constraint!(gm, n, :control_valve_pressure_drop1, k, JuMP.@constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
    else
        _add_constraint!(gm, n, :control_valve_pressure_drop1, k, JuMP.@constraint(gm.model,  pj - pi <= (1-v)*j_pmax^2))
        _add_constraint!(gm, n, :control_valve_pressure_drop2, k, JuMP.@constraint(gm.model,  pi - pj <= (1-v)*i_pmax^2))
    end
end


#################################################################################################
# Misc Constraints
#################################################################################################

"Constraint: This function ensures at most one pipe in parallel is selected"
function constraint_exclusive_new_pipes(gm::AbstractGasModel,  n::Int, i, j, parallel)
    zp = var(gm,n,:zp)
    _add_constraint!(gm, n, :exclusive_new_pipes, (i,j), JuMP.@constraint(gm.model, sum(zp[i] for i in parallel) <= 1))
end
