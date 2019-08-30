##########################################################################################################
# The purpose of this file is to define commonly used and created constraints used in gas flow models
##########################################################################################################

" Utility function for adding constraints to a gm.model "
function add_constraint(gm::GenericGasModel, n::Int, key, k, constraint)
    if !haskey(gm.con[:nw][n], key)
        gm.con[:nw][n][key] = Dict{Any,ConstraintRef}()
    end
    gm.con[:nw][n][key][k] = constraint
end

#################################################################################################
# Constraints associated with junctions
#################################################################################################

" Constraint: standard mass flow balance equation where demand and production are constants "
function constraint_junction_mass_flow_balance(gm::GenericGasModel, n::Int, i, f_branches, t_branches, fg, fl)
    f = var(gm,n,:f)
    add_constraint(gm, n, :junction_mass_flow_balance, i, @constraint(gm.model, fg - fl == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches)))
end

" Constraint: standard flow balance equation where demand and production are constants and there are expansion connections"
function constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fg, fl)
    f    = var(gm,n,:f)
    f_ne = var(gm,n,:f_ne)
    add_constraint(gm, n, :junction_mass_flow_balance_ne, i, @constraint(gm.model, fg - fl == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne)))
end

" Constraint: standard flow balance equation where demand and production are variables "
function constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, n::Int, i, f_branches, t_branches, fl_constant, fg_constant, consumers, producers)
    f  = var(gm,n,:f)
    fg = var(gm,n,:fg)
    fl = var(gm,n,:fl)
    add_constraint(gm, n, :junction_mass_flow_balance_ls, i, @constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches)))
end

" Constraint: standard flow balance equation where demand and production are variables and there are expansion connections"
function constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fl_constant, fg_constant, consumers, producers)
    f    = var(gm,n,:f)
    f_ne = var(gm,n,:f_ne)
    fg   = var(gm,n,:fg)
    fl   = var(gm,n,:fl)
    add_constraint(gm, n, :junction_mass_flow_balance_ne_ls, i, @constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne)))
end

#################################################################################################
# Constraints associated with short pipes
#################################################################################################

" Constraint: Constraint on pressure drop across a short pipe "
function constraint_short_pipe_pressure_drop(gm::GenericGasModel, n::Int, k, i, j)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :short_pipe_pressure_drop, k, @constraint(gm.model,  pi == pj))
end

" Constraint: Constraints on flow across a short pipe where direction of flow is constrained"
function constraint_short_pipe_flow_directed(gm::GenericGasModel, n::Int, k, i, j, direction)
    f = var(gm,n,:f,k)
    if direction == 1
        add_constraint(gm, n, :short_pipe_flow, k, @constraint(gm.model, f >= 0))
    else
        add_constraint(gm, n, :short_pipe_flow, k, @constraint(gm.model, 0 <= f))
    end
end

#################################################################################################
# Constraints associated with vakves
#################################################################################################

" Constraint: Constraints on pressure drop across valves where the valve can open or close"
function constraint_valve_pressure_drop(gm::GenericGasModel, n::Int, k, i, j, i_pmax, j_pmax)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v  = var(gm,n,:v,k)
    add_constraint(gm, n, :valve_pressure_drop1, k, @constraint(gm.model,  pj - ((1-v)*j_pmax^2) <= pi))
    add_constraint(gm, n, :valve_pressure_drop2, k, @constraint(gm.model,  pi <= pj + ((1-v)*i_pmax^2)))
end

" constraints on flow across undirected valves "
function constraint_on_off_valve_flow(gm::GenericGasModel, n::Int, k, i, j, mf)
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n,:on_off_valve_flow1, k, @constraint(gm.model, -mf*v <= f))
    add_constraint(gm, n,:on_off_valve_flow2, k, @constraint(gm.model, f <= mf*v))
end

" Constraint: constraints on flow across valves when the direction of flow is constrained. "
function constraint_valve_flow_directed(gm::GenericGasModel, n::Int, k, i, j, mf, direction)
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)

    if direction == 1
        add_constraint(gm, n,:valve_flow_direction1, k, @constraint(gm.model, 0 <= f))
        add_constraint(gm, n,:valve_flow_direction2, k, @constraint(gm.model, f <= mf*v))
    else
        add_constraint(gm, n,:valve_flow_direction1, k, @constraint(gm.model, f <= 0))
        add_constraint(gm, n,:valve_flow_direction2, k, @constraint(gm.model, -mf*v <= f))
    end
end

#################################################################################################
# Constraints associated with pipes
#################################################################################################

" Constraint: on/off constraints on flow across pipes for expansion pipes "
function constraint_pipe_ne(gm::GenericGasModel, n::Int, k, w, mf, pd_min, pd_max)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)
    add_constraint(gm, n, :pipe_ne1, k, @constraint(gm.model, f <= zp*min(mf, sqrt(w*max(abs(pd_max), abs(pd_min))))))
    add_constraint(gm, n, :pipe_ne2, k, @constraint(gm.model, f >= -zp*min(mf, sqrt(w*max(abs(pd_max), abs(pd_min))))))
end

" Constraint: constraints on pressure drop across where direction is constrained"
function constraint_pressure_drop_directed(gm::GenericGasModel, n::Int, k, i, j, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    if direction == 1
        add_constraint(gm, n, :pressure_drop_directed, k, @constraint(gm.model, pi - pj >= 0))
    else
        add_constraint(gm, n, :pressure_drop_directed, k, @constraint(gm.model, pi - pj <= 0))
    end
end

" Constraint: Constraint on mass flow across the pipe"
function constraint_pipe_mass_flow(gm::GenericGasModel, n::Int, k, i, j, mf, pd_min, pd_max, w)
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :pipe_flow1, k, @constraint(gm.model, -min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f))
    add_constraint(gm, n, :pipe_flow2, k, @constraint(gm.model, f <= min(mf, sqrt(w*max(pd_max, abs(pd_min))))))
end

" Constraint: constraint on flow across the pipe where direction is constrained"
function constraint_pipe_flow_directed(gm::GenericGasModel, n::Int, k, i, j, direction)
    f  = var(gm,n,:f,k)
    if direction == 1
        add_constraint(gm, n, :pipe_flow, k, @constraint(gm.model, f >= 0))
    else
        add_constraint(gm, n, :pipe_flow, k, @constraint(gm.model, f <= 0))
    end
end

" Constraint: Pressure drop across an expansion pipe when direction is constrained"
function constraint_pressure_drop_ne_directed(gm::GenericGasModel, n::Int, k, i, j, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    if direction == 1
        add_constraint(gm, n, :pressure_drop_ne, k, @constraint(gm.model, pi - pj >= 0))
    else
        add_constraint(gm, n, :pressure_drop_ne, k, @constraint(gm.model, pi - pj <= 0))
    end
end

" Constraint: Flow across an expansion pipe when direction is constrained "
function constraint_pipe_flow_ne_directed(gm::GenericGasModel, n::Int, k, i, j, direction)
    f  = var(gm,n,:f_ne,k)
    if direction == 1
        add_constraint(gm, n, :pipe_flow, k, @constraint(gm.model, f >= 0))
    else
        add_constraint(gm, n, :pipe_flow, k, @constraint(gm.model, f <= 0))
    end
end

#################################################################################################
# Constraints associated with compressors
#################################################################################################

" Constraint: on/off constraints on flow across compressors for expansion variables "
function constraint_compressor_ne(gm::GenericGasModel,  n::Int, k, mf)
    zc = var(gm,n,:zc,k)
    f  =  var(gm,n,:f_ne,k)
    add_constraint(gm, n, :compressor_flow_ne1, k, @constraint(gm.model, -mf*zc <= f))
    add_constraint(gm, n, :compressor_flow_ne2, k, @constraint(gm.model, f <= mf*zc))
end

" Constraint: flow across a compressor when flow is restricted to one direction"
function constraint_compressor_flow_directed(gm::GenericGasModel, n::Int, k, i, j, direction)
    f  = var(gm,n,:f,k)
    if direction == 1
        add_constraint(gm, n, :compressor_flow, k, @constraint(gm.model, f >= 0))
    else
        add_constraint(gm, n, :compressor_flow, k, @constraint(gm.model, f <= 0))
    end
end

" Constraint: Compressor ratio when the flow direction is constrained "
function constraint_compressor_ratios_directed(gm::GenericGasModel, n::Int, k, i, j, min_ratio, max_ratio, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)

    if direction == 1
        add_constraint(gm, n, :compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= 0))
        add_constraint(gm, n, :compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= 0))
    else
        add_constraint(gm, n, :compressor_ratios1, k, @constraint(gm.model, pj == pi))
    end
end

" Constraint: flow across expansion compressors when the direction is constrained "
function constraint_compressor_flow_ne_directed(gm::GenericGasModel, n::Int, k, i, j, mf, direction)
    f  = var(gm,n,:f_ne,k)

    if direction == 1
        add_constraint(gm, n, :compressor_flow_direction_ne, k, @constraint(gm.model, f >= 0))
    else
        add_constraint(gm, n, :compressor_flow_direction_ne, k, @constraint(gm.model, 0 <= f))
    end
end

" Constraint: Pressure drop across an expansion compressor when direction is constrained"
function constraint_compressor_ratios_ne_directed(gm::GenericGasModel, n::Int, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)

    if direction == 1
        add_constraint(gm, n, :compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-zc)*j_pmax^2))
        add_constraint(gm, n, :compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-zc)*(min_ratio*i_pmax^2)))
    else
        add_constraint(gm, n, :compressor_ratios1, k, @constraint(gm.model, f * (1-pj/pi) <= (1-zc) * mf * (1-j_pmax^2/i_pmin^2)))
    end
end

#################################################################################################
# Constraints associated with control valves
#################################################################################################

" constraints on flow across control valves that are undirected "
function constraint_on_off_control_valve_flow(gm::GenericGasModel, n::Int, k, i, j, mf)
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n,:on_off_valve_flow1, k, @constraint(gm.model, -mf*v <= f))
    add_constraint(gm, n,:on_off_valve_flow2, k, @constraint(gm.model, f <= mf*v))
end

" Constraint: Flow across control valves when direction is constrained "
function constraint_control_valve_flow_directed(gm::GenericGasModel, n::Int, k, i, j, mf, direction)
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)

    if direction == 1
        add_constraint(gm, n,:control_valve_flow_direction1, k, @constraint(gm.model, 0 <= f))
        add_constraint(gm, n,:control_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
    else
        add_constraint(gm, n,:control_valve_flow_direction2, k, @constraint(gm.model, f <= 0))
        add_constraint(gm, n,:control_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f))
    end
end

" Constraint: Pressure drop across a control valves when directions is constrained "
function constraint_control_valve_pressure_drop_directed(gm::GenericGasModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, direction)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v  = var(gm,n,:v,k)

    if direction == 1
        add_constraint(gm, n, :control_valve_pressure_drop1, k, @constraint(gm.model, pj - max_ratio^2*pi <= 0))
        add_constraint(gm, n, :control_valve_pressure_drop1, k, @constraint(gm.model, min_ratio^2*pi - pj <= 0))
    else
        add_constraint(gm, n, :control_valve_pressure_drop1, k, @constraint(gm.model,  pj - ((1-v)*j_pmax^2) <= pi))
        add_constraint(gm, n, :control_valve_pressure_drop2, k, @constraint(gm.model,  pi <= pj + ((1-v)*i_pmax^2)))
    end
end

#################################################################################################
# Misc Constraints
#################################################################################################

" Constraint: This function ensures at most one pipe in parallel is selected "
function constraint_exclusive_new_pipes(gm::GenericGasModel,  n::Int, i, j, parallel)
    zp = var(gm,n,:zp)
    add_constraint(gm, n, :exclusive_new_pipes, (i,j), @constraint(gm.model, sum(zp[i] for i in parallel) <= 1))
end
