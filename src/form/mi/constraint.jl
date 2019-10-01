########################################################################################################
## Versions of constraints used to compute flow balance
########################################################################################################

##############################################################################################################
# Constraints for modeling junction_nondispatchable_consumers
#############################################################################################################

" Constraint: standard mass flow balance equation where demand and production are constants "
function constraint_mass_flow_balance(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, fg, fl) where T <: AbstractMIForms
    f_pipe          = var(gm,n,:f_pipe)
    f_compressor    = var(gm,n,:f_compressor)
    f_resistor      = var(gm,n,:f_resistor)
    f_short_pipe    = var(gm,n,:f_short_pipe)
    f_valve         = var(gm,n,:f_valve)
    f_control_valve = var(gm,n,:f_control_valve)
    y               = var(gm,n,:y)

    add_constraint(gm, n, :junction_mass_flow_balance, i, @constraint(gm.model, fg - fl == sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                                           sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) +
                                                                                           sum(f_resistor[a] for a in f_resistors) - sum(f_resistor[a] for a in t_resistors) +
                                                                                           sum(f_short_pipe[a] for a in f_short_pipes) - sum(f_short_pipe[a] for a in t_short_pipes) +
                                                                                           sum(f_valve[a] for a in f_valves) - sum(f_valve[a] for a in t_valves) +
                                                                                           sum(f_control_valve[a] for a in f_control_valves) - sum(f_control_valve[a] for a in t_control_valves)
                                                                     ))

    is_disjunction = apply_mass_flow_cuts(y, f_pipes) && apply_mass_flow_cuts(y, t_pipes) &&
                     apply_mass_flow_cuts(y, f_compressors) && apply_mass_flow_cuts(y, t_compressors) &&
                     apply_mass_flow_cuts(y, f_resistors) && apply_mass_flow_cuts(y, t_resistors) &&
                     apply_mass_flow_cuts(y, f_short_pipes) && apply_mass_flow_cuts(y, t_short_pipes) &&
                     apply_mass_flow_cuts(y, f_valves) && apply_mass_flow_cuts(y, t_valves) &&
                     apply_mass_flow_cuts(y, f_control_valves) && apply_mass_flow_cuts(y, t_control_valves)

    if fg > 0.0 && fl == 0.0 && is_disjunction
        constraint_source_flow(gm, n, i)
    end

    if fg == 0.0 && fl > 0.0 && is_disjunction
        constraint_sink_flow(gm, n, i)
    end

    if fg == 0.0 && fl == 0.0 && ref(gm,n,:degree)[i] == 2 && is_disjunction
        constraint_conserve_flow(gm, n, i)
    end
end

"Helper function for determining if direction cuts can be applied"
function apply_mass_flow_cuts(yp, branches)
    is_disjunction = true
    for k in branches
        is_disjunction &= isassigned(yp,k)
    end
    return is_disjunction
end

" Constraint: standard flow balance equation where demand and production are constants and there are expansion connections"
function constraint_mass_flow_balance_ne(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors, fg, fl) where T <: AbstractMIForms
    f_pipe           = var(gm,n,:f_pipe)
    f_compressor     = var(gm,n,:f_compressor)
    f_resistor       = var(gm,n,:f_resistor)
    f_short_pipe     = var(gm,n,:f_short_pipe)
    f_valve          = var(gm,n,:f_valve)
    f_control_valve  = var(gm,n,:f_control_valve)
    f_ne_pipe        = var(gm,n,:f_ne_pipe)
    f_ne_compressor  = var(gm,n,:f_ne_compressor)
    y                = var(gm,n,:y)
    y_ne             = var(gm,n,:y_ne)

    add_constraint(gm, n, :junction_mass_flow_balance_ne, i, @constraint(gm.model, fg - fl ==
                                                                                              sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                                              sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) +
                                                                                              sum(f_resistor[a] for a in f_resistors) - sum(f_resistor[a] for a in t_resistors) +
                                                                                              sum(f_short_pipe[a] for a in f_short_pipes) - sum(f_short_pipe[a] for a in t_short_pipes) +
                                                                                              sum(f_valve[a] for a in f_valves) - sum(f_valve[a] for a in t_valves) +
                                                                                              sum(f_control_valve[a] for a in f_control_valves) - sum(f_control_valve[a] for a in t_control_valves) +
                                                                                              sum(f_ne_pipe[a] for a in f_ne_pipes) - sum(f_ne_pipe[a] for a in t_ne_pipes) +
                                                                                              sum(f_ne_compressor[a] for a in f_ne_compressors) - sum(f_ne_compressor[a] for a in t_ne_compressors)
                                                                        ))

    is_disjunction = apply_mass_flow_cuts(y, f_pipes) &&
                     apply_mass_flow_cuts(y, t_pipes) &&
                     apply_mass_flow_cuts(y, f_compressors) &&
                     apply_mass_flow_cuts(y, t_compressors) &&
                     apply_mass_flow_cuts(y, f_resistors) &&
                     apply_mass_flow_cuts(y, t_resistors) &&
                     apply_mass_flow_cuts(y, f_short_pipes) &&
                     apply_mass_flow_cuts(y, t_short_pipes) &&
                     apply_mass_flow_cuts(y, f_valves) &&
                     apply_mass_flow_cuts(y, t_valves) &&
                     apply_mass_flow_cuts(y, f_control_valves) &&
                     apply_mass_flow_cuts(y, t_control_valves) &&
                     apply_mass_flow_cuts(y_ne, f_ne_pipes) &&
                     apply_mass_flow_cuts(y_ne, t_ne_pipes) &&
                     apply_mass_flow_cuts(y_ne, f_ne_compressors) &&
                     apply_mass_flow_cuts(y_ne, t_ne_compressors)


    if fg > 0.0 && fl == 0.0 && is_disjunction
        constraint_source_flow_ne(gm, n, i)
    end

    if fg == 0.0 && fl > 0.0 && is_disjunction
        constraint_sink_flow_ne(gm, n, i)
    end

    if fg == 0.0 && fl == 0.0 && ref(gm,n,:degree_ne)[i] == 2 && is_disjunction
        constraint_conserve_flow_ne(gm, n, i)
    end
end

" Constraint: standard flow balance equation where demand and production are variables "
function constraint_mass_flow_balance_ls(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, fl_constant, fg_constant, consumers, producers, flmin, flmax, fgmin, fgmax) where T <: AbstractMIForms
    f_pipe           = var(gm,n,:f_pipe)
    f_compressor     = var(gm,n,:f_compressor)
    f_resistor       = var(gm,n,:f_resistor)
    f_short_pipe     = var(gm,n,:f_short_pipe)
    f_valve          = var(gm,n,:f_valve)
    f_control_valve  = var(gm,n,:f_control_valve)
    fg               = var(gm,n,:fg)
    fl               = var(gm,n,:fl)
    y                = var(gm,n,:y)

    add_constraint(gm, n, :junction_mass_flow_balance_ls, i, @constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) ==
                                                                               sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                               sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) +
                                                                               sum(f_resistor[a] for a in f_resistors) - sum(f_resistor[a] for a in t_resistors) +
                                                                               sum(f_short_pipe[a] for a in f_short_pipes) - sum(f_short_pipe[a] for a in t_short_pipes) +
                                                                               sum(f_valve[a] for a in f_valves) - sum(f_valve[a] for a in t_valves) +
                                                                               sum(f_control_valve[a] for a in f_control_valves) - sum(f_control_valve[a] for a in t_control_valves)
                                                                        ))

    is_disjunction = apply_mass_flow_cuts(y, f_pipes) &&
                     apply_mass_flow_cuts(y, t_pipes) &&
                     apply_mass_flow_cuts(y, f_compressors) &&
                     apply_mass_flow_cuts(y, t_compressors) &&
                     apply_mass_flow_cuts(y, f_resistors) &&
                     apply_mass_flow_cuts(y, t_resistors) &&
                     apply_mass_flow_cuts(y, f_short_pipes) &&
                     apply_mass_flow_cuts(y, t_short_pipes) &&
                     apply_mass_flow_cuts(y, f_valves) &&
                     apply_mass_flow_cuts(y, t_valves) &&
                     apply_mass_flow_cuts(y, f_control_valves) &&
                     apply_mass_flow_cuts(y, t_control_valves)

    if max(fgmin,fg_constant) > 0.0  && flmin == 0.0 && flmax == 0.0 && fl_constant == 0.0 && fgmin >= 0.0 && is_disjunction
        constraint_source_flow(gm, n, i)
    end

    if fgmax == 0.0 && fgmin == 0.0 && fg_constant == 0.0 && max(flmin,fl_constant) > 0.0 && flmin >= 0.0 && is_disjunction
        constraint_sink_flow(gm, n, i)
    end

    if fgmax == 0 && fgmin == 0 && fg_constant == 0 && flmax == 0 && flmin == 0 && fl_constant == 0 && ref(gm,n,:degree)[i] == 2 && is_disjunction
        constraint_conserve_flow(gm, n, i)
    end
end

" Constraint: standard flow balance equation where demand and production are variables and there are expansion connections"
function constraint_mass_flow_balance_ne_ls(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors, fl_constant, fg_constant, consumers, producers, flmin, flmax, fgmin, fgmax) where T <: AbstractMIForms
    f_pipe           = var(gm,n,:f_pipe)
    f_compressor     = var(gm,n,:f_compressor)
    f_resistor       = var(gm,n,:f_resistor)
    f_short_pipe     = var(gm,n,:f_short_pipe)
    f_valve          = var(gm,n,:f_valve)
    f_control_valve  = var(gm,n,:f_control_valve)
    f_ne_pipe        = var(gm,n,:f_ne_pipe)
    f_ne_compressor  = var(gm,n,:f_ne_compressor)
    fg               = var(gm,n,:fg)
    fl               = var(gm,n,:fl)
    y                = var(gm,n,:y)
    y_ne             = var(gm,n,:y_ne)

    add_constraint(gm, n, :junction_mass_flow_balance_ne_ls, i, @constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) ==
                                                                                      sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                                      sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) +
                                                                                      sum(f_resistor[a] for a in f_resistors) - sum(f_resistor[a] for a in t_resistors) +
                                                                                      sum(f_short_pipe[a] for a in f_short_pipes) - sum(f_short_pipe[a] for a in t_short_pipes) +
                                                                                      sum(f_valve[a] for a in f_valves) - sum(f_valve[a] for a in t_valves) +
                                                                                      sum(f_control_valve[a] for a in f_control_valves) - sum(f_control_valve[a] for a in t_control_valves) +
                                                                                      sum(f_ne_pipe[a] for a in f_ne_pipes) - sum(f_ne_pipe[a] for a in t_ne_pipes) +
                                                                                      sum(f_ne_compressor[a] for a in f_ne_compressors) - sum(f_ne_compressor[a] for a in t_ne_compressors)
                                                                            ))

    is_disjunction = apply_mass_flow_cuts(y, f_pipes) &&
                     apply_mass_flow_cuts(y, t_pipes) &&
                     apply_mass_flow_cuts(y, f_compressors) &&
                     apply_mass_flow_cuts(y, t_compressors) &&
                     apply_mass_flow_cuts(y, f_resistors) &&
                     apply_mass_flow_cuts(y, t_resistors) &&
                     apply_mass_flow_cuts(y, f_short_pipes) &&
                     apply_mass_flow_cuts(y, t_short_pipes) &&
                     apply_mass_flow_cuts(y, f_valves) &&
                     apply_mass_flow_cuts(y, t_valves) &&
                     apply_mass_flow_cuts(y, f_control_valves) &&
                     apply_mass_flow_cuts(y, t_control_valves) &&
                     apply_mass_flow_cuts(y_ne, f_ne_pipes) &&
                     apply_mass_flow_cuts(y_ne, t_ne_pipes) &&
                     apply_mass_flow_cuts(y_ne, f_ne_compressors) &&
                     apply_mass_flow_cuts(y_ne, t_ne_compressors)

    if max(fgmin,fg_constant) > 0.0  && flmin == 0.0 && flmax == 0.0 && fl_constant == 0.0 && fgmin >= 0.0 && is_disjunction
        constraint_source_flow_ne(gm, i)
    end

    if fgmax == 0.0 && fgmin == 0.0 && fg_constant == 0.0 && max(flmin,fl_constant) > 0.0 && flmin >= 0.0 && is_disjunction
        constraint_sink_flow_ne(gm, i)
    end

    if fgmax == 0 && fgmin == 0 && fg_constant == 0 && flmax == 0 && flmin == 0 && fl_constant == 0 && ref(gm,n,:degree_ne)[i] == 2 && is_disjunction
        constraint_conserve_flow_ne(gm, i)
    end

end

#############################################################################################################
## Constraints for modeling flow across a pipe
############################################################################################################

"Constraint: Constraints which define pressure drop across a pipe when there are on/off direction variables"
function constraint_pipe_pressure(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIForms
    y = var(gm,n,:y,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop1, k, @constraint(gm.model, (1-y) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop2, k, @constraint(gm.model, pi - pj <= y * pd_max))
end

"Constraint: Constraint on flow across a pipe when there are on/off direction variables "
function constraint_pipe_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y,k)
    f = var(gm,n,:f_pipe,k)
    add_constraint(gm, n, :on_off_pipe_flow1, k, @constraint(gm.model, (1-y) * f_min <= f))
    add_constraint(gm, n, :on_off_pipe_flow2, k, @constraint(gm.model, f <= y * f_max))

    constraint_parallel_flow(gm, k)
end

#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################

"Constraint: constraints on pressure drop across an expansion pipe with on/off direction variables"
function constraint_pipe_pressure_ne(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIForms
    y = var(gm,n,:y_ne,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop_ne1, k, @constraint(gm.model, (1-y) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop_ne2, k, @constraint(gm.model, pi - pj <= y * pd_max))
end

"Constraint: constraints on flow across an expansion pipe with on/off direction variables "
function constraint_pipe_mass_flow_ne(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_ne,k)
    f  = var(gm,n,:f_ne_pipe,k)
    add_constraint(gm, n, :on_off_pipe_flow_ne1, k, @constraint(gm.model, (1-y)*f_min <= f))
    add_constraint(gm, n, :on_off_pipe_flow_ne2, k, @constraint(gm.model, f <= y*f_max))

    constraint_parallel_flow_ne(gm, k)
end

###########################################################################################
### Short pipe constriants
###########################################################################################

"Constraint: Constraints on flow across a short pipe with on/off direction variables"
function constraint_short_pipe_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y,k)
    f = var(gm,n,:f_short_pipe,k)
    add_constraint(gm, n, :on_off_short_pipe_flow1, k, @constraint(gm.model, f_min*(1-y) <= f))
    add_constraint(gm, n, :on_off_short_pipe_flow2, k, @constraint(gm.model, f <= f_max*y))

    constraint_parallel_flow(gm, k)
end

######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

"Constraint: constraints on flow across a compressor with on/off direction variables "
function constraint_compressor_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y,k)
    f = var(gm,n,:f_compressor,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction1, k, @constraint(gm.model, (1-y)*f_min <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction2, k, @constraint(gm.model, f <= y*f_max))

    constraint_parallel_flow(gm, k)
end

"Constraint: enforces pressure changes bounds that obey compression ratios for a compressor with on/off direction variables"
function constraint_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractMIForms
    y = var(gm,n,:y,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-y)*(j_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-y)*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios3, k, @constraint(gm.model, pi - pj <= y*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios4, k, @constraint(gm.model, pj - pi <= y*(j_pmax^2)))
end

"Constraint: constraints on flow across compressors with on/off direction variables"
function constraint_compressor_mass_flow_ne(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_ne,k)
    f  = var(gm,n,:f_ne_compressor,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne1, k, @constraint(gm.model, (1-y)*f_min <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne2, k, @constraint(gm.model, f <= y*f_max))

    constraint_parallel_flow_ne(gm, k)
end

"Constraint: constraints on pressure drop across expansion compressors with on/off decision variables "
function constraint_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax) where T <: AbstractMIForms
    y = var(gm,n,:y_ne,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)

    # TODO these are modeled as bi directinal.  Need to be one direction
    add_constraint(gm, n, :on_off_compressor_ratios_ne1, k, @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-y-zc)*j_pmax^2))
    add_constraint(gm, n, :on_off_compressor_ratios_ne2, k, @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-y-zc)*(min_ratio^2*i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios_ne3, k, @constraint(gm.model,  pi - (max_ratio^2*pj) <= (1+y-zc)*i_pmax^2))
    add_constraint(gm, n, :on_off_compressor_ratios_ne4, k, @constraint(gm.model,  (min_ratio^2*pj) - pi <= (1+y-zc)*(min_ratio^2*j_pmax^2)))

end

"Constraint: Constraints on flow across valves with on/off direction variables "
function constraint_on_off_valve_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y,k)
    f = var(gm,n,:f_valve,k)
    v = var(gm,n,:v_valve,k)
    add_constraint(gm, n,:on_off_valve_flow_direction1, k, @constraint(gm.model, f_min*(1-y) <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction2, k, @constraint(gm.model, f <= f_max*y))
    add_constraint(gm, n,:on_off_valve_flow_direction3, k, @constraint(gm.model, f_min*v <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction4, k, @constraint(gm.model, f <= f_max*v))

    constraint_parallel_flow(gm, k)
end

#######################################################
# Flow Constraints for control valves
#######################################################

"Constraint: Constraints on flow across control valves with on/off direction variables "
function constraint_on_off_control_valve_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y,k)
    f = var(gm,n,:f_control_valve,k)
    v = var(gm,n,:v_control_valve,k)
    add_constraint(gm, n, :on_off_control_valve_flow_direction1, k, @constraint(gm.model, f_min*(1-y) <= f))
    add_constraint(gm, n, :on_off_control_valve_flow_direction2, k, @constraint(gm.model, f <= f_max*y))
    add_constraint(gm, n, :on_off_control_valve_flow_direction3, k, @constraint(gm.model, f_min*v <= f ))
    add_constraint(gm, n, :on_off_control_valve_flow_direction4, k, @constraint(gm.model, f <= f_max*v))

    constraint_parallel_flow(gm, k)
end

"Constraint: Constraints on pressure drop across control valves that have on/off direction variables "
function constraint_on_off_control_valve_pressure(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax) where T <: AbstractMIForms
    y  = var(gm,n,:y,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v  = var(gm,n,:v_control_valve,k)
    add_constraint(gm, n, :on_off_control_valve_pressure_drop1, k, @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-y-v)*j_pmax^2))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop2, k, @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-y-v)*i_pmax^2))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop3, k, @constraint(gm.model,  pj - pi <= (1 + y - v)*j_pmax^2))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop4, k, @constraint(gm.model,  pi - pj <= (1 + y - v)*i_pmax^2))
end

######################################################################
# Constraints used for generating cuts on direction variables
#########################################################################

"Constraint: Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIForms
    y = var(gm,n,:y)
    add_constraint(gm, n, :source_flow, i,  @constraint(gm.model, sum(y[a] for a in f_branches) + sum( (1-y[a]) for a in t_branches) >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIForms
    y    = var(gm,n,:y)
    y_ne = var(gm,n,:y_ne)
    add_constraint(gm, n, :source_flow_ne, i, @constraint(gm.model, sum(y[a] for a in f_branches) + sum( (1-y[a]) for a in t_branches) + sum(y_ne[a] for a in f_branches_ne) + sum( (1-y_ne[a]) for a in t_branches_ne) >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIForms
    y = var(gm,n,:y)
    add_constraint(gm, n, :sink_flow, i, @constraint(gm.model, sum( (1-y[a]) for a in f_branches) + sum(y[a] for a in t_branches) >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIForms
    y   = var(gm,n,:y)
    y_ne = var(gm,n,:y_ne)
    add_constraint(gm, n, :sink_flow_ne, i, @constraint(gm.model, sum( (1-y[a]) for a in f_branches) + sum(y[a] for a in t_branches) + sum( (1-y_ne[a]) for a in f_branches_ne) + sum(y_ne[a] for a in t_branches_ne) >= 1))
end

"Constraint: This constraint is intended to ensure that flow is one direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::GenericGasModel{T}, n::Int, idx, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves) where T <: AbstractMIForms
    y = var(gm,n,:y)

    y_fr = []
    y_to  = []

    for i in f_pipes push!(y_fr, y[i]) end
    for i in f_compressors push!(y_fr, y[i]) end
    for i in f_short_pipes push!(y_fr, y[i]) end
    for i in f_resistors push!(y_fr, y[i]) end
    for i in f_valves push!(y_fr, y[i]) end
    for i in f_control_valves push!(y_fr, y[i]) end

    for i in t_pipes push!(y_to, y[i]) end
    for i in t_compressors push!(y_to, y[i]) end
    for i in t_short_pipes push!(y_to, y[i]) end
    for i in t_resistors push!(y_to, y[i]) end
    for i in t_valves push!(y_to, y[i]) end
    for i in t_control_valves push!(y_to, y[i]) end

    for i = 1:length(y_fr)
        for j = i+1:length(y_fr)
            add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y_fr[i] + y_fr[j] == 1))
        end
    end

    for i = 1:length(y_to)
        for j = i+1:length(y_to)
            add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y_to[i] + y_to[j] == 1))
        end
    end

    for i = 1:length(y_fr)
        for j = 1:length(y_to)
            add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y_fr[i] == y_to[i]))
        end
    end



#    if length(yn_first) > 0 && length(yp_last) > 0
#        for i1 in yn_first
#            for i2 in yp_last
#                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, (1-y[i1])  == y[i2]))
#            end
#        end
#    end

#    if length(yn_first) > 0 && length(yn_last) > 0
#        for i1 in yn_first
#            for i2 in yn_last
#                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, (1-y[i1]) == (1-y[i2])))
#            end
#        end
#    end

#    if length(yp_first) > 0 && length(yp_last) > 0
#        for i1 in yp_first
#            for i2 in yp_last
#                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, y[i1]  == y[i2]))
#            end
#        end
#    end

#    if length(yp_first) > 0 && length(yn_last) > 0
#        for i1 in yp_first
#            for i2 in yn_last
#                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, y[i1] == (1-y[i2])))
#            end
#        end
#    end
end

"Constraint: This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption for a node with expansion edges"
function constraint_conserve_flow_ne(gm::GenericGasModel{T}, n::Int, idx, yp_first, yn_first, yp_last, yn_last) where T <: AbstractMIForms
#function constraint_conserve_flow_ne(gm::GenericGasModel{T}, n::Int, idx, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors) where T <: AbstractMIForms

    y = var(gm,n,:y)
    y_ne = var(gm,n,:y_ne)

#    y_fr = []
#    y_to  = []

#    for i in f_pipes push!(y_fr, y[i]) end
#    for i in f_compressors push!(y_fr, y[i]) end
#    for i in f_short_pipes push!(y_fr, y[i]) end
#    for i in f_resistors push!(y_fr, y[i]) end
#    for i in f_valves push!(y_fr, y[i]) end
#    for i in f_control_valves push!(y_fr, y[i]) end
#    for i in f_ne_pipes push!(y_fr, y_ne[i]) end
#    for i in f_ne_compressors push!(y_fr, y_ne[i]) end

#    for i in t_pipes push!(y_to, y[i]) end
#    for i in t_compressors push!(y_to, y[i]) end
#    for i in t_short_pipes push!(y_to, y[i]) end
#    for i in t_resistors push!(y_to, y[i]) end
#    for i in t_valves push!(y_to, y[i]) end
#    for i in t_control_valves push!(y_to, y[i]) end
#    for i in t_ne_pipes push!(y_to, y_ne[i]) end
#    for i in t_ne_compressors push!(y_to, y_ne[i]) end

#    for i = 1:length(y_fr)
#        for j = i+1:length(y_fr)
#            add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y_fr[i] + y_fr[j] == 1))
#        end
#    end

#    for i = 1:length(y_to)
#        for j = i+1:length(y_to)
#            add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y_to[i] + y_to[j] == 1))
#        end
#    end

#    for i = 1:length(y_fr)
#        for j = 1:length(y_to)
#            add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y_fr[i] == y_to[i]))
#        end
#    end






    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                y1 = haskey(ref(gm,n,:connection),i1) ? y[i1] : y_ne[i1]
                y2 = haskey(ref(gm,n,:connection),i2) ? y[i2] : y_ne[i2]
                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, (1-y1)  == y2))
            end
        end
    end

    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                y1 = haskey(ref(gm,n,:connection),i1) ? y[i1] : y_ne[i1]
                y2 = haskey(ref(gm,n,:connection),i2) ? y[i2] : y_ne[i2]
                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, (1-y1) == (1-y2)))
            end
        end
    end

    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                y1 = haskey(ref(gm,n,:connection),i1) ? y[i1] : y_ne[i1]
                y2 = haskey(ref(gm,n,:connection),i2) ? y[i2] : y_ne[i2]
                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, y1 == y2))
            end
        end
    end

    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                y1 = haskey(ref(gm,n,:connection),i1) ? y[i1] : y_ne[i1]
                y2 = haskey(ref(gm,n,:connection),i2) ? y[i2] : y_ne[i2]
                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, y1 == (1-y2)))
            end
        end
    end
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections) where T <: AbstractMIForms
    y = var(gm,n,:y)
    add_constraint(gm, n, :parallel_flow1, k, @constraint(gm.model, sum(y[i] for i in f_connections) + sum( (1-y[i]) for i in t_connections) == y[k] * length(ref(gm,n,:parallel_connections,(i,j)))))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne) where T <: AbstractMIForms
    y = var(gm,n,:y)
    y_ne = var(gm,n,:y_ne)
    y_k = haskey(ref(gm,n,:connection), k) ? y[k] : y_ne[k]

    add_constraint(gm, n, :parallel_flow_ne1, k, @constraint(gm.model, sum(y[i] for i in f_connections) + sum( (1-y[i]) for i in t_connections) + sum(y_ne[i] for i in f_connections_ne) + sum( (1-y_ne[i]) for i in t_connections_ne) == y_k * length(ref(gm,n,:parallel_ne_connections,(i,j)))))
end
