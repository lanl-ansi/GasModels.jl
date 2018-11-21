######################################:ne_connection####################################################################
# The purpose of this file is to define commonly used and created constraints used in gas flow models
##########################################################################################################

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

" All constraints associated with flows through a pipe"
constraint_pipe_flow(gm::GenericGasModel, k::Int) = constraint_pipe_flow(gm, gm.cnw, k)

" All constraints associated with flows through a short pipe"
constraint_short_pipe_flow(gm::GenericGasModel, k::Int) = constraint_short_pipe_flow(gm, gm.cnw, k)

" All constraints associated with flows through a compressor"
constraint_compressor_flow(gm::GenericGasModel, k::Int) = constraint_compressor_flow(gm, gm.cnw, k)

" All constraints associated with flows through a valve"
constraint_valve_flow(gm::GenericGasModel, k::Int) = constraint_valve_flow(gm, gm.cnw, k)

" All constraints associated with flows through a control valve"
constraint_control_valve_flow(gm::GenericGasModel, k::Int) = constraint_control_valve_flow(gm, gm.cnw, k)

" All constraints associated with flows through a pipe"
constraint_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_pipe_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a short pipe"
constraint_short_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_short_pipe_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a compressor"
constraint_compressor_flow_ne(gm::GenericGasModel, k::Int) = constraint_compressor_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a valve"
constraint_valve_flow_ne(gm::GenericGasModel, k::Int) = constraint_valve_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a control valve"
constraint_control_valve_flow_ne(gm::GenericGasModel, k::Int) = constraint_control_valve_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a valve"
constraint_new_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_new_pipe_flow_ne(gm, gm.cnw, k)

" All constraints associated with flows through a control valve"
constraint_new_compressor_flow_ne(gm::GenericGasModel, k::Int) = constraint_new_compressor_flow_ne(gm, gm.cnw, k)

# Constraints with templates

" constraints on pressure drop across control valves "
function constraint_on_off_compressor_ratios_ne(gm::GenericGasModel, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, i_pmax)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp_ne][k] 
    yn = gm.var[:nw][n][:yn_ne][k]     
    zc = gm.var[:nw][n][:zc][k] 
            
    if !haskey(gm.con[:nw][n], :on_off_compressor_ratios_ne1)
        gm.con[:nw][n][:on_off_compressor_ratios_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:on_off_compressor_ratios_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_ratios_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_ratios_ne1][k] = @constraint(gm.model,  pj - (max_ratio*pi) <= (2-yp-zc)*j_pmax^2)              
    gm.con[:nw][n][:on_off_compressor_ratios_ne2][k] = @constraint(gm.model,  (min_ratio*pi) - pj <= (2-yp-zc)*(min_ratio*i_pmax^2) )
    gm.con[:nw][n][:on_off_compressor_ratios_ne3][k] = @constraint(gm.model,  pi - (max_ratio*pj) <= (2-yn-zc)*i_pmax^2)              
    gm.con[:nw][n][:on_off_compressor_ratios_ne4][k] = @constraint(gm.model,  (min_ratio*pj) - pi <= (2-yn-zc)*(min_ratio*j_pmax^2))                             
end

" standard mass flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance(gm::GenericGasModel, n::Int, i, f_branches, t_branches, fgfirm, flfirm)
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f] 

    if !haskey(gm.con[:nw][n], :junction_mass_flow_balance)
        gm.con[:nw][n][:junction_mass_flow_balance] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_mass_flow_balance][i] = @constraint(gm.model, fgfirm - flfirm == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) )              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fgfirm, flfirm)
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f] 
    f_ne = gm.var[:nw][n][:f_ne] 
                  
    if !haskey(gm.con[:nw][n], :junction_mass_flow_balance_ne)
        gm.con[:nw][n][:junction_mass_flow_balance_ne] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_mass_flow_balance_ne][i] = @constraint(gm.model, fgfirm - flfirm == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne) )              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, n::Int, i, f_branches, t_branches, fl_firm, fg_firm, consumers, producers)
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f]
    fg = gm.var[:nw][n][:fg]   
    fl = gm.var[:nw][n][:fl]   

    if !haskey(gm.con[:nw][n], :junction_mass_flow_balance_ls)
        gm.con[:nw][n][:junction_mass_flow_balance_ls] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_mass_flow_balance_ls][i] = @constraint(gm.model, fg_firm - fl_firm + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) )              
end

" standard flow balance equation where demand and production is fixed "
function constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fl_firm, fg_firm, consumers, producers)  
    p = gm.var[:nw][n][:p] 
    f = gm.var[:nw][n][:f] 
    f_ne = gm.var[:nw][n][:f_ne]
    fg = gm.var[:nw][n][:fg]   
    fl = gm.var[:nw][n][:fl]   
    
    if !haskey(gm.con[:nw][n], :junction_mass_flow_balance_ne_ls)
        gm.con[:nw][n][:junction_mass_flow_balance_ne_ls] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:junction_mass_flow_balance_ne_ls][i] = @constraint(gm.model, fg_firm - fl_firm + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) == sum(f[a] for a in f_branches) - sum(f[a] for a in t_branches) + sum(f_ne[a] for a in f_branches_ne) - sum(f_ne[a] for a in t_branches_ne) )              
end

" constraints on pressure drop across pipes "
function constraint_short_pipe_pressure_drop(gm::GenericGasModel, n::Int, k, i, j)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 

    if !haskey(gm.con[:nw][n], :short_pipe_pressure_drop)
        gm.con[:nw][n][:short_pipe_pressure_drop] = Dict{Int,ConstraintRef}()
    end    
    gm.con[:nw][n][:short_pipe_pressure_drop][k] = @constraint(gm.model,  pi == pj)              
end

" constraints on pressure drop across valves "
function constraint_on_off_valve_pressure_drop(gm::GenericGasModel, n::Int, k, i, j, i_pmax, j_pmax)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 

    v = gm.var[:nw][n][:v][k] 

    if !haskey(gm.con[:nw][n], :on_off_valve_pressure_drop1)
        gm.con[:nw][n][:on_off_valve_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_valve_pressure_drop2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_valve_pressure_drop1][k] = @constraint(gm.model,  pj - ((1-v)*j_pmax^2) <= pi)              
    gm.con[:nw][n][:on_off_valve_pressure_drop2][k] = @constraint(gm.model,  pi <= pj + ((1-v)*i_pmax^2))              
end

" on/off constraints on flow across pipes for expansion variables "
function constraint_on_off_pipe_flow_ne(gm::GenericGasModel, n::Int, k, w, mf, pd_min, pd_max)
    zp = gm.var[:nw][n][:zp][k] 
    f  = gm.var[:nw][n][:f_ne][k] 
          
    if !haskey(gm.con[:nw][n], :on_off_pipe_flow_ne1)
        gm.con[:nw][n][:on_off_pipe_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pipe_flow_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_pipe_flow_ne1][k] = @constraint(gm.model, f <= zp*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))              
    gm.con[:nw][n][:on_off_pipe_flow_ne2][k] = @constraint(gm.model, f >= -zp*min(mf, sqrt(w*max(pd_max, abs(pd_min)))))              
end

" on/off constraints on flow across compressors for expansion variables "
function constraint_on_off_compressor_flow_ne(gm::GenericGasModel,  n::Int, k, mf)
    zc = gm.var[:nw][n][:zc][k] 
    f =  gm.var[:nw][n][:f_ne][k] 
    
    if !haskey(gm.con[:nw][n], :on_off_compressor_flow_ne1)
        gm.con[:nw][n][:on_off_compressor_flow_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_compressor_flow_ne2] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:on_off_compressor_flow_ne1][k] = @constraint(gm.model, -mf*zc <= f)              
    gm.con[:nw][n][:on_off_compressor_flow_ne2][k] = @constraint(gm.model, f <= mf*zc)              
end

" This function ensures at most one pipe in parallel is selected "
function constraint_exclusive_new_pipes(gm::GenericGasModel,  n::Int, i, j, parallel)  
    zp = gm.var[:nw][n][:zp]             
    if !haskey(gm.con[:nw][n], :exclusive_new_pipes)
        gm.con[:nw][n][:exclusive_new_pipes] = Dict{Any,ConstraintRef}()
    end    
    gm.con[:nw][n][:exclusive_new_pipes][(i,j)] = @constraint(gm.model, sum(zp[i] for i in parallel) <= 1)              
end

"compressor rations have on off for direction and expansion"
function constraint_new_compressor_ratios_ne(gm::GenericGasModel,  n::Int, k, i, j, min_ratio, max_ratio, p_mini, p_maxi, p_minj, p_maxj)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    zc = gm.var[:nw][n][:zc][k] 
            
    if !haskey(gm.con[:nw][n], :new_compressor_ratios_ne1)
        gm.con[:nw][n][:new_compressor_ratios_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:new_compressor_ratios_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:new_compressor_ratios_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:new_compressor_ratios_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:new_compressor_ratios_ne1][c_idx] = @constraint(gm.model, pj - (max_ratio^2*pi) <= (2-yp-zc)*p_maxj^2)              
    gm.con[:nw][n][:new_compressor_ratios_ne2][c_idx] = @constraint(gm.model, (min_ratio^2*pi) - pj <= (2-yp-zc)*(min_ratio^2*p_maxi^2 - p_minj^2))
    gm.con[:nw][n][:new_compressor_ratios_ne3][c_idx] = @constraint(gm.model, pi - (max_ratio^2*pj) <= (2-yn-zc)*p_maxi^2)              
    gm.con[:nw][n][:new_compressor_ratios_ne4][c_idx] = @constraint(gm.model, (min_ratio^2*pj) - pi <= (2-yn-zc)*(min_ratio^2*p_maxj^2 - p_mini^2))                               
end