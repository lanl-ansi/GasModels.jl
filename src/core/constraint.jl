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

# Constraints that don't need a template

" Constraint that states a flow direction must be chosen "
constraint_flow_direction_choice(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice(gm, gm.cnw, i)

" Constraint that states a flow direction must be chosen for new edges "
constraint_flow_direction_choice_ne(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice_ne(gm, gm.cnw, i)

" All constraints associated with flows through at a junction"
constraint_junction_mass_flow(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow(gm, gm.cnw, i)

" All constraints associated with flows through at a junction with load shedding"
constraint_junction_mass_flow_ls(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_ls(gm, gm.cnw, i)

" All constraints associated with flows through at a junction with new pipe options"
constraint_junction_mass_flow_ne(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_ne(gm, gm.cnw, i)

" All constraints associated with flows through at a junction with new pipe options"
constraint_junction_mass_flow_ne_ls(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_ne_ls(gm, gm.cnw, i)

" All constraints associated with flows through at a junction with some directed edges"
constraint_junction_mass_flow_directed(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_directed(gm, gm.cnw, i)

" All constraints associated with flows through at a junction with load shedding with some directed edges"
constraint_junction_mass_flow_ls_directed(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_ls_directed(gm, gm.cnw, i)

" All constraints associated with flows through at a junction with new pipe options with some directed edges"
constraint_junction_mass_flow_ne_directed(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_ne_directed(gm, gm.cnw, i)

" All constraints associated with flows through at a junction with new pipe options with some directed edges"
constraint_junction_mass_flow_ne_ls_directed(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_ne_ls_directed(gm, gm.cnw, i)

" All constraints associated with flows through a pipe"
constraint_pipe_flow(gm::GenericGasModel, k::Int) = constraint_pipe_flow(gm, gm.cnw, k)

" All constraints associated with flows through a pipe that is directed"
constraint_pipe_flow_directed(gm::GenericGasModel, k::Int) = constraint_pipe_flow_directed(gm, gm.cnw, k)

" All constraints associated with flows through a short pipe"
constraint_short_pipe_flow(gm::GenericGasModel, k::Int) = constraint_short_pipe_flow(gm, gm.cnw, k)

" All constraints associated with flows through a compressor"
constraint_compressor_flow(gm::GenericGasModel, k::Int) = constraint_compressor_flow(gm, gm.cnw, k)

" All constraints associated with flows through a directed compressor"
constraint_compressor_flow_directed(gm::GenericGasModel, k::Int) = constraint_compressor_flow_directed(gm, gm.cnw, k)

" All constraints associated with flows through a valve that is undirected"
constraint_valve_flow(gm::GenericGasModel, k::Int) = constraint_valve_flow(gm, gm.cnw, k)

" All constraints associated with flows through a valve that is directed"
constraint_valve_flow_directed(gm::GenericGasModel, k::Int) = constraint_valve_flow_directed(gm, gm.cnw, k)

" All constraints associated with flows through a control valve"
constraint_control_valve_flow(gm::GenericGasModel, k::Int) = constraint_control_valve_flow(gm, gm.cnw, k)

" All constraints associated with flows through a control valve"
constraint_control_valve_flow_directed(gm::GenericGasModel, k::Int) = constraint_control_valve_flow_directed(gm, gm.cnw, k)

" All constraints associated with flows through a pipe"
constraint_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_pipe_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a short pipe"
constraint_short_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_short_pipe_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a short pipe for expansion planning models"
constraint_short_pipe_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_short_pipe_flow_ne_directed(gm, gm.cnw, k)

" All constraints associated with flows through a compressor"
constraint_compressor_flow_ne(gm::GenericGasModel, k::Int) = constraint_compressor_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a compressor"
constraint_compressor_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_compressor_flow_ne_directed(gm, gm.cnw, k)

" All constraints associated with flows through an undirected valve"
constraint_valve_flow_ne(gm::GenericGasModel, k::Int) = constraint_valve_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a directed valve"
constraint_valve_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_valve_flow_ne_directed(gm, gm.cnw, k)

" All constraints associated with flows through a control valve"
constraint_control_valve_flow_ne(gm::GenericGasModel, k::Int) = constraint_control_valve_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a control valve that is directed"
constraint_control_valve_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_control_valve_flow_ne_directed(gm, gm.cnw, k)

" All constraints associated with flows through an undirected expansion pipe"
constraint_new_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_new_pipe_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a directed expansion pipe"
constraint_new_pipe_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_new_pipe_flow_ne_directed(gm, gm.cnw, k)

" All constraints associated with flows through an expansion compressor"
constraint_new_compressor_flow_ne(gm::GenericGasModel, k::Int) = constraint_new_compressor_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through an expansion compressor"
constraint_new_compressor_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_new_compressor_flow_ne_directed(gm, gm.cnw, k)

# Constraints with templates

" standard mass flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance(gm::GenericGasModel, n::Int, i, f_branches, t_branches, fg, fl)
    p = gm.var[:nw][n][:p]
    f = gm.var[:nw][n][:f]
    add_constraint(gm, n, :junction_mass_flow_balance, i, @constraint(gm.model, fg - fl == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches)))
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fg, fl)
    p = gm.var[:nw][n][:p]
    f = gm.var[:nw][n][:f]
    f_ne = gm.var[:nw][n][:f_ne]
    add_constraint(gm, n, :junction_mass_flow_balance_ne, i, @constraint(gm.model, fg - fl == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne)))
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, n::Int, i, f_branches, t_branches, fl_constant, fg_constant, consumers, producers)
    p = gm.var[:nw][n][:p]
    f = gm.var[:nw][n][:f]
    fg = gm.var[:nw][n][:fg]
    fl = gm.var[:nw][n][:fl]

    add_constraint(gm, n, :junction_mass_flow_balance_ls, i, @constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches)))
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fl_constant, fg_constant, consumers, producers)
    p = gm.var[:nw][n][:p]
    f = gm.var[:nw][n][:f]
    f_ne = gm.var[:nw][n][:f_ne]
    fg = gm.var[:nw][n][:fg]
    fl = gm.var[:nw][n][:fl]

    add_constraint(gm, n, :junction_mass_flow_balance_ne_ls, i, @constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne)))
end

" constraints on pressure drop across pipes "
function constraint_short_pipe_pressure_drop(gm::GenericGasModel, n::Int, k, i, j)
    pi = gm.var[:nw][n][:p][i]
    pj = gm.var[:nw][n][:p][j]
    add_constraint(gm, n, :short_pipe_pressure_drop, k, @constraint(gm.model,  pi == pj))
end

" constraints on pressure drop across valves "
function constraint_on_off_valve_pressure_drop(gm::GenericGasModel, n::Int, k, i, j, i_pmax, j_pmax)
    pi = gm.var[:nw][n][:p][i]
    pj = gm.var[:nw][n][:p][j]
    v = gm.var[:nw][n][:v][k]

    add_constraint(gm, n, :on_off_valve_pressure_drop1, k, @constraint(gm.model,  pj - ((1-v)*j_pmax^2) <= pi))
    add_constraint(gm, n, :on_off_valve_pressure_drop2, k, @constraint(gm.model,  pi <= pj + ((1-v)*i_pmax^2)))
end

" on/off constraints on flow across pipes for expansion variables "
function constraint_on_off_pipe_ne(gm::GenericGasModel, n::Int, k, w, mf, pd_min, pd_max)
    zp = gm.var[:nw][n][:zp][k]
    f  = gm.var[:nw][n][:f_ne][k]

    add_constraint(gm, n, :on_off_pipe_flow_ne1, k, @constraint(gm.model, f <= zp*min(mf, sqrt(w*max(pd_max, abs(pd_min))))))
    add_constraint(gm, n, :on_off_pipe_flow_ne2, k,  @constraint(gm.model, f >= -zp*min(mf, sqrt(w*max(pd_max, abs(pd_min))))))
end

" on/off constraints on flow across compressors for expansion variables "
function constraint_on_off_compressor_ne(gm::GenericGasModel,  n::Int, k, mf)
    zc = gm.var[:nw][n][:zc][k]
    f =  gm.var[:nw][n][:f_ne][k]
    add_constraint(gm, n, :on_off_compressor_flow_ne1, k, @constraint(gm.model, -mf*zc <= f))
    add_constraint(gm, n, :on_off_compressor_flow_ne2, k, @constraint(gm.model, f <= mf*zc))
end

" This function ensures at most one pipe in parallel is selected "
function constraint_exclusive_new_pipes(gm::GenericGasModel,  n::Int, i, j, parallel)
    zp = gm.var[:nw][n][:zp]
    add_constraint(gm, n, :exclusive_new_pipes, (i,j), @constraint(gm.model, sum(zp[i] for i in parallel) <= 1))
end

"compressor rations have on off for direction and expansion"
function constraint_new_compressor_ratios_ne(gm::GenericGasModel,  n::Int, k, i, j, min_ratio, max_ratio, p_mini, p_maxi, p_minj, p_maxj)
    pi = gm.var[:nw][n][:p][i]
    pj = gm.var[:nw][n][:p][j]
    yp = gm.var[:nw][n][:yp][k]
    yn = gm.var[:nw][n][:yn][k]
    zc = gm.var[:nw][n][:zc][k]

    add_constraint(gm, n, :new_compressor_ratios_ne1, c_idx, @constraint(gm.model, pj - (max_ratio^2*pi) <= (2-yp-zc)*p_maxj^2))
    add_constraint(gm, n, :new_compressor_ratios_ne2, c_idx, @constraint(gm.model, (min_ratio^2*pi) - pj <= (2-yp-zc)*(min_ratio^2*p_maxi^2 - p_minj^2)))
    add_constraint(gm, n, :new_compressor_ratios_ne3, c_idx, @constraint(gm.model, pi - (max_ratio^2*pj) <= (2-yn-zc)*p_maxi^2))
    add_constraint(gm, n, :new_compressor_ratios_ne4, c_idx, @constraint(gm.model, (min_ratio^2*pj) - pi <= (2-yn-zc)*(min_ratio^2*p_maxj^2 - p_mini^2)))
end
