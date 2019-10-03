########################################################################################################
## Versions of constraints used to compute flow balance
########################################################################################################

##############################################################################################################
# Constraints for modeling junction_nondispatchable_consumers
#############################################################################################################

"Helper function for determining if direction cuts can be applied"
function apply_mass_flow_cuts(yp, branches)
    is_disjunction = true
    for k in branches
        is_disjunction &= isassigned(yp,k)
    end
    return is_disjunction
end

" Constraint: standard flow balance equation where demand and production are variables "
function constraint_mass_flow_balance(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, fl_constant, fg_constant, consumers, producers, flmin, flmax, fgmin, fgmax) where T <: AbstractMIForms
    f_pipe           = var(gm,n,:f_pipe)
    f_compressor     = var(gm,n,:f_compressor)
    f_resistor       = var(gm,n,:f_resistor)
    f_short_pipe     = var(gm,n,:f_short_pipe)
    f_valve          = var(gm,n,:f_valve)
    f_control_valve  = var(gm,n,:f_control_valve)
    fg               = var(gm,n,:fg)
    fl               = var(gm,n,:fl)
    y_pipe           = var(gm,n,:y_pipe)
    y_compressor     = var(gm,n,:y_compressor)
    y_resistor       = var(gm,n,:y_resistor)
    y_short_pipe     = var(gm,n,:y_short_pipe)
    y_valve          = var(gm,n,:y_valve)
    y_control_valve  = var(gm,n,:y_control_valve)

    add_constraint(gm, n, :junction_mass_flow_balance, i, @constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in producers) - sum(fl[a] for a in consumers) ==
                                                                               sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                               sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) +
                                                                               sum(f_resistor[a] for a in f_resistors) - sum(f_resistor[a] for a in t_resistors) +
                                                                               sum(f_short_pipe[a] for a in f_short_pipes) - sum(f_short_pipe[a] for a in t_short_pipes) +
                                                                               sum(f_valve[a] for a in f_valves) - sum(f_valve[a] for a in t_valves) +
                                                                               sum(f_control_valve[a] for a in f_control_valves) - sum(f_control_valve[a] for a in t_control_valves)
                                                                        ))

    is_disjunction = apply_mass_flow_cuts(y_pipe, f_pipes) &&
                     apply_mass_flow_cuts(y_pipe, t_pipes) &&
                     apply_mass_flow_cuts(y_compressor, f_compressors) &&
                     apply_mass_flow_cuts(y_compressor, t_compressors) &&
                     apply_mass_flow_cuts(y_resistor, f_resistors) &&
                     apply_mass_flow_cuts(y_resistor, t_resistors) &&
                     apply_mass_flow_cuts(y_short_pipe, f_short_pipes) &&
                     apply_mass_flow_cuts(y_short_pipe, t_short_pipes) &&
                     apply_mass_flow_cuts(y_valve, f_valves) &&
                     apply_mass_flow_cuts(y_valve, t_valves) &&
                     apply_mass_flow_cuts(y_control_valve, f_control_valves) &&
                     apply_mass_flow_cuts(y_control_valve, t_control_valves)

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
function constraint_mass_flow_balance_ne(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors, fl_constant, fg_constant, consumers, producers, flmin, flmax, fgmin, fgmax) where T <: AbstractMIForms
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
    y_pipe           = var(gm,n,:y_pipe)
    y_compressor     = var(gm,n,:y_compressor)
    y_resistor       = var(gm,n,:y_resistor)
    y_short_pipe     = var(gm,n,:y_short_pipe)
    y_valve          = var(gm,n,:y_valve)
    y_control_valve  = var(gm,n,:y_control_valve)
    y_ne_pipe        = var(gm,n,:y_ne_pipe)
    y_ne_compressor  = var(gm,n,:y_ne_compressor)

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

    is_disjunction = apply_mass_flow_cuts(y_pipe, f_pipes) &&
                     apply_mass_flow_cuts(y_pipe, t_pipes) &&
                     apply_mass_flow_cuts(y_compressor, f_compressors) &&
                     apply_mass_flow_cuts(y_compressor, t_compressors) &&
                     apply_mass_flow_cuts(y_resistor, f_resistors) &&
                     apply_mass_flow_cuts(y_resistor, t_resistors) &&
                     apply_mass_flow_cuts(y_short_pipe, f_short_pipes) &&
                     apply_mass_flow_cuts(y_short_pipe, t_short_pipes) &&
                     apply_mass_flow_cuts(y_valve, f_valves) &&
                     apply_mass_flow_cuts(y_valve, t_valves) &&
                     apply_mass_flow_cuts(y_control_valve, f_control_valves) &&
                     apply_mass_flow_cuts(y_control_valve, t_control_valves) &&
                     apply_mass_flow_cuts(y_ne_pipe, f_ne_pipes) &&
                     apply_mass_flow_cuts(y_ne_pipe, t_ne_pipes) &&
                     apply_mass_flow_cuts(y_ne_compressor, f_ne_compressors) &&
                     apply_mass_flow_cuts(y_ne_compressor, t_ne_compressors)

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
    y = var(gm,n,:y_pipe,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop1, k, @constraint(gm.model, (1-y) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop2, k, @constraint(gm.model, pi - pj <= y * pd_max))
end

"Constraint: Constraint on flow across a pipe when there are on/off direction variables "
function constraint_pipe_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_pipe,k)
    f = var(gm,n,:f_pipe,k)
    add_constraint(gm, n, :on_off_pipe_flow1, k, @constraint(gm.model, (1-y) * f_min <= f))
    add_constraint(gm, n, :on_off_pipe_flow2, k, @constraint(gm.model, f <= y * f_max))

    constraint_pipe_parallel_flow(gm,k)
end

#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################

"Constraint: constraints on pressure drop across an expansion pipe with on/off direction variables"
function constraint_pipe_pressure_ne(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIForms
    y = var(gm,n,:y_ne_pipe,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop_ne1, k, @constraint(gm.model, (1-y) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop_ne2, k, @constraint(gm.model, pi - pj <= y * pd_max))
end

"Constraint: constraints on flow across an expansion pipe with on/off direction variables "
function constraint_pipe_mass_flow_ne(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_ne_pipe,k)
    f  = var(gm,n,:f_ne_pipe,k)
    add_constraint(gm, n, :on_off_pipe_flow_ne1, k, @constraint(gm.model, (1-y)*f_min <= f))
    add_constraint(gm, n, :on_off_pipe_flow_ne2, k, @constraint(gm.model, f <= y*f_max))

    constraint_ne_pipe_parallel_flow(gm,k)
end

###########################################################################################
### Short pipe constriants
###########################################################################################

"Constraint: Constraints on flow across a short pipe with on/off direction variables"
function constraint_short_pipe_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_short_pipe,k)
    f = var(gm,n,:f_short_pipe,k)
    add_constraint(gm, n, :on_off_short_pipe_flow1, k, @constraint(gm.model, f_min*(1-y) <= f))
    add_constraint(gm, n, :on_off_short_pipe_flow2, k, @constraint(gm.model, f <= f_max*y))

    constraint_short_pipe_parallel_flow(gm,k)
end

######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

"Constraint: constraints on flow across a compressor with on/off direction variables "
function constraint_compressor_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_compressor,k)
    f = var(gm,n,:f_compressor,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction1, k, @constraint(gm.model, (1-y)*f_min <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction2, k, @constraint(gm.model, f <= y*f_max))

#    constraint_parallel_flow(gm, k)
    constraint_compressor_parallel_flow(gm,k)
end

"Constraint: enforces pressure changes bounds that obey compression ratios for a compressor with on/off direction variables"
function constraint_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractMIForms
    y  = var(gm,n,:y_compressor,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-y)*(j_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-y)*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios3, k, @constraint(gm.model, pi - pj <= y*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios4, k, @constraint(gm.model, pj - pi <= y*(j_pmax^2)))
end

"Constraint: constraints on flow across compressors with on/off direction variables"
function constraint_compressor_mass_flow_ne(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_ne_compressor,k)
    f  = var(gm,n,:f_ne_compressor,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne1, k, @constraint(gm.model, (1-y)*f_min <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne2, k, @constraint(gm.model, f <= y*f_max))
    constraint_ne_compressor_parallel_flow(gm,k)
end

"Constraint: constraints on pressure drop across expansion compressors with on/off decision variables "
function constraint_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax) where T <: AbstractMIForms
    y = var(gm,n,:y_ne_compressor,k)
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
    y = var(gm,n,:y_valve,k)
    f = var(gm,n,:f_valve,k)
    v = var(gm,n,:v_valve,k)
    add_constraint(gm, n,:on_off_valve_flow_direction1, k, @constraint(gm.model, f_min*(1-y) <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction2, k, @constraint(gm.model, f <= f_max*y))
    add_constraint(gm, n,:on_off_valve_flow_direction3, k, @constraint(gm.model, f_min*v <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction4, k, @constraint(gm.model, f <= f_max*v))

    constraint_valve_parallel_flow(gm,k)
end

#######################################################
# Flow Constraints for control valves
#######################################################

"Constraint: Constraints on flow across control valves with on/off direction variables "
function constraint_on_off_control_valve_mass_flow(gm::GenericGasModel{T}, n::Int, k, f_min, f_max) where T <: AbstractMIForms
    y = var(gm,n,:y_control_valve,k)
    f = var(gm,n,:f_control_valve,k)
    v = var(gm,n,:v_control_valve,k)
    add_constraint(gm, n, :on_off_control_valve_flow_direction1, k, @constraint(gm.model, f_min*(1-y) <= f))
    add_constraint(gm, n, :on_off_control_valve_flow_direction2, k, @constraint(gm.model, f <= f_max*y))
    add_constraint(gm, n, :on_off_control_valve_flow_direction3, k, @constraint(gm.model, f_min*v <= f ))
    add_constraint(gm, n, :on_off_control_valve_flow_direction4, k, @constraint(gm.model, f <= f_max*v))

    constraint_control_valve_parallel_flow(gm,k)
#    constraint_parallel_flow(gm, k)
end

"Constraint: Constraints on pressure drop across control valves that have on/off direction variables "
function constraint_on_off_control_valve_pressure(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax) where T <: AbstractMIForms
    y  = var(gm,n,:y_control_valve,k)
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
function constraint_source_flow(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)

    add_constraint(gm, n, :source_flow, i,  @constraint(gm.model, sum(y_pipe[a] for a in f_pipes) + sum((1-y_pipe[a]) for a in t_pipes) +
                                                                  sum(y_compressor[a] for a in f_compressors) + sum((1-y_compressor[a]) for a in t_compressors) +
                                                                  sum(y_resistor[a] for a in f_resistors) + sum((1-y_resistor[a]) for a in t_resistors) +
                                                                  sum(y_short_pipe[a] for a in f_short_pipes) + sum((1-y_short_pipe[a]) for a in t_short_pipes) +
                                                                  sum(y_valve[a] for a in f_valves) + sum((1-y_valve[a]) for a in t_valves) +
                                                                  sum(y_control_panel[a] for a in f_control_valves) + sum((1-y_control_valve[a]) for a in t_control_valves)
                                                                  >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors) where T <: AbstractMIForms
    y_pipe               = var(gm,n,:y_pipe)
    y_compressor         = var(gm,n,:y_compressor)
    y_resistor           = var(gm,n,:y_resistor)
    y_short_pipe         = var(gm,n,:y_short_pipe)
    y_valve              = var(gm,n,:y_valve)
    y_control_valve      = var(gm,n,:y_control_valve)

    y_ne_pipe       = var(gm,n,:y_ne_pipe)
    y_ne_compressor = var(gm,n,:y_ne_compressor)
    add_constraint(gm, n, :source_flow_ne, i, @constraint(gm.model, sum(y_pipe[a] for a in f_pipes) + sum((1-y_pipe[a]) for a in t_pipes) +
                                                                    sum(y_compressor[a] for a in f_compressors) + sum((1-y_compressor[a]) for a in t_compressors) +
                                                                    sum(y_resistor[a] for a in f_resistors) + sum((1-y_resistor[a]) for a in t_resistors) +
                                                                    sum(y_short_pipe[a] for a in f_short_pipes) + sum((1-y_short_pipe[a]) for a in t_short_pipes) +
                                                                    sum(y_valve[a] for a in f_valves) + sum((1-y_valve[a]) for a in t_valves) +
                                                                    sum(y_control_valve[a] for a in f_control_valves) + sum((1-y_control_valve[a]) for a in t_control_valves) +
                                                                    sum(y_ne_pipe[a] for a in f_ne_pipes) + sum( (1-y_ne_pipe[a]) for a in t_ne_pipes) +
                                                                    sum(y_ne_compressor[a] for a in f_ne_compressors) + sum( (1-y_ne_compressor[a]) for a in t_ne_compressors)
                                                                     >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)

    add_constraint(gm, n, :sink_flow, i, @constraint(gm.model, sum((1-y_pipe[a]) for a in f_pipes) + sum(y_pipe[a] for a in t_pipes) +
                                                               sum((1-y_compressor[a]) for a in f_compressors) + sum(y_compressor[a] for a in t_compressors) +
                                                               sum((1-y_resistor[a]) for a in f_resistors) + sum(y_resistor[a] for a in t_resistors) +
                                                               sum((1-y_short_pipe[a]) for a in f_short_pipes) + sum(y_short_pipe[a] for a in t_short_pipes) +
                                                               sum((1-y_valve[a]) for a in f_valves) + sum(y_valve[a] for a in t_valves) +
                                                               sum((1-y_control_valve[a]) for a in f_control_valves) + sum(y_control_valve[a] for a in t_control_valves)
                                                               >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)
    y_ne_pipe       = var(gm,n,:y_ne_pipe)
    y_ne_compressor = var(gm,n,:y_ne_compressor)

    add_constraint(gm, n, :sink_flow_ne, i, @constraint(gm.model, sum((1-y_pipe[a]) for a in f_pipes) + sum(y_pipe[a] for a in t_pipes) +
                                                                  sum((1-y_compressor[a]) for a in f_compressors) + sum(y_compressor[a] for a in t_compressors) +
                                                                  sum((1-y_resistor[a]) for a in f_resistors) + sum(y_resistor[a] for a in t_resistors) +
                                                                  sum((1-y_short_pipe[a]) for a in f_short_pipes) + sum(y_short_pipe[a] for a in t_short_pipes) +
                                                                  sum((1-y_valve[a]) for a in f_valves) + sum(y_valve[a] for a in t_valves) +
                                                                  sum((1-y_control_valve[a]) for a in f_control_valves) + sum(y_control_valve[a] for a in t_control_valves) +
                                                                  sum((1-y_ne_pipe[a]) for a in f_ne_pipes) + sum(y_ne_pipe[a] for a in t_ne_pipes) +
                                                                  sum((1-y_ne_compressor[a]) for a in f_ne_compressors) + sum(y_ne_compressor[a] for a in t_ne_compressors)
                                                                  >= 1))
end

"Constraint: This constraint is intended to ensure that flow is one direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::GenericGasModel{T}, n::Int, idx, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)

    y_fr = Dict()
    y_to  = Dict()

    for (i,key) in f_pipes y_fr[y_pipe[i]] = key  end
    for (i,key) in f_compressors y_fr[y_compressor[i]] = key  end
    for (i,key) in f_resistors y_fr[y_resistor[i]] = key  end
    for (i,key) in f_short_pipes y_fr[y_short_pipe[i]] = key  end
    for (i,key) in f_valves y_fr[y_valve[i]] = key  end
    for (i,key) in f_control_valves y_fr[y_control_valve[i]] = key  end

    for (i,key) in t_pipes y_to[y_pipe[i]] = key  end
    for (i,key) in t_compressors y_to[y_compressor[i]] = key  end
    for (i,key) in t_resistors y_to[y_resistor[i]] = key  end
    for (i,key) in t_short_pipes y_to[y_short_pipe[i]] = key  end
    for (i,key) in t_valves y_to[y_valve[i]] = key  end
    for (i,key) in t_control_valves y_to[y_control_valve[i]] = key  end

    for (y1, t1) in y_fr
        for (y2, t2) in y_fr
            if t1 != t2
                add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y1 + y2 == 1))
            end
        end
    end

    for (y1, t1) in y_to
        for (y2, t2) in y_to
            if t1 != t2
                add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y1 + y2 == 1))
            end
        end
    end

    for (y1, t1) in y_fr
        for (y2, t2) in y_to
            if t1 != t2
                add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y1 == y2))
            end
        end
    end
end

"Constraint: This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption for a node with expansion edges"
function constraint_conserve_flow_ne(gm::GenericGasModel{T}, n::Int, idx, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)
    y_ne_pipe       = var(gm,n,:y_ne_pipe)
    y_ne_compressor = var(gm,n,:y_ne_compressor)

    y_fr = Dict()
    y_to  = Dict()

    for (i,key) in f_pipes y_fr[y_pipe[i]] = key  end
    for (i,key) in f_compressors y_fr[y_compressor[i]] = key  end
    for (i,key) in f_resistors y_fr[y_resistor[i]] = key  end
    for (i,key) in f_short_pipes y_fr[y_short_pipe[i]] = key  end
    for (i,key) in f_valves y_fr[y_valve[i]] = key  end
    for (i,key) in f_control_valves y_fr[y_control_valve[i]] = key  end
    for (i,key) in f_ne_pipes y_fr[y_ne_pipe[i]] = key  end
    for (i,key) in f_ne_compressors y_fr[y_ne_compressor[i]] = key  end

    for (i,key) in t_pipes y_to[y_pipe[i]] = key  end
    for (i,key) in t_compressors y_to[y_compressor[i]] = key  end
    for (i,key) in t_resistors y_to[y_resistor[i]] = key  end
    for (i,key) in t_short_pipes y_to[y_short_pipe[i]] = key  end
    for (i,key) in t_valves y_to[y_valve[i]] = key  end
    for (i,key) in t_control_valves y_to[y_control_valve[i]] = key  end
    for (i,key) in t_ne_pipes y_to[y_ne_pipe[i]] = key  end
    for (i,key) in t_ne_compressors y_to[y_ne_compressor[i]] = key  end

    for (y1, t1) in y_fr
        for (y2, t2) in y_fr
            if t1 != t2
                add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y1 + y2 == 1))
            end
        end
    end

    for (y1, t1) in y_to
        for (y2, t2) in y_to
            if t1 != t2
                add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y1 + y2 == 1))
            end
        end
    end

    for (y1, t1) in y_fr
        for (y2, t2) in y_to
            if t1 != t2
                add_constraint(gm, n, :conserve_flow, idx, @constraint(gm.model, y1 == y2))
            end
        end
    end
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_ne_pipe_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves, aligned_ne_pipes, opposite_ne_pipes, aligned_ne_compressors, opposite_ne_compressors) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)
    y_ne_pipe       = var(gm,n,:y_ne_pipe)
    y_ne_compressor = var(gm,n,:y_ne_compressor)
    y_k             = y_ne_pipe[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistor[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves) +
                                                                      sum(y_ne_pipe[i] for i in aligned_ne_pipes) + sum((1-y_ne_pipe[i]) for i in opposite_ne_pipes) +
                                                                      sum(y_ne_compressor[i] for i in aligned_ne_compressors) + sum((1-y_ne_compressor[i]) for i in opposite_ne_compressors)
                                                                      == y_k * num_connections))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_ne_compressor_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves, aligned_ne_pipes, opposite_ne_pipes, aligned_ne_compressors, opposite_ne_compressors) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)
    y_ne_pipe       = var(gm,n,:y_ne_pipe)
    y_ne_compressor = var(gm,n,:y_ne_comprsesor)
    y_k             = y_ne_compressor[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistor[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves) +
                                                                      sum(y_ne_pipe[i] for i in aligned_ne_pipes) + sum((1-y_ne_pipe[i]) for i in opposite_ne_pipes) +
                                                                      sum(y_ne_compressor[i] for i in aligned_ne_compressors) + sum((1-y_ne_compressor[i]) for i in opposite_ne_compressors)
                                                                      == y_k * num_connections))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_pipe_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves) where T <: AbstractMIForms
    y_pipe           = var(gm,n,:y_pipe)
    y_compressor     = var(gm,n,:y_compressor)
    y_short_pipe     = var(gm,n,:y_short_pipe)
    y_resistor       = var(gm,n,:y_resistor)
    y_valve          = var(gm,n,:y_valve)
    y_control_valve  = var(gm,n,:y_control_valve)

    y_k  = y_pipe[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistor[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves)
                                                                      == y_k * num_connections))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_compressor_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves) where T <: AbstractMIForms
    y_pipe          = var(gm,n,:y_pipe)
    y_compressor    = var(gm,n,:y_compressor)
    y_resistor      = var(gm,n,:y_resistor)
    y_short_pipe    = var(gm,n,:y_short_pipe)
    y_valve         = var(gm,n,:y_valve)
    y_control_valve = var(gm,n,:y_control_valve)
    y_k             = y_compressor[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistor[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves)
                                                                      == y_k * num_connections))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_resistor_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves) where T <: AbstractMIForms
    y_pipe             = var(gm,n,:y_pipe)
    y_compressor       = var(gm,n,:y_compressor)
    y_resistor         = var(gm,n,:y_resistor)
    y_short_pipe       = var(gm,n,:y_short_pipe)
    y_valve            = var(gm,n,:y_valve)
    y_control_valve    = var(gm,n,:y_control_valve)
    y_k                = y_resistor[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistor[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves)
                                                                      == y_k * num_connections))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_short_pipe_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves) where T <: AbstractMIForms
    y_pipe             = var(gm,n,:y_pipe)
    y_compressor       = var(gm,n,:y_compressor)
    y_short_pipe       = var(gm,n,:y_short_pipe)
    y_resistor         = var(gm,n,:y_resistor)
    y_valve            = var(gm,n,:y_valve)
    y_control_valve    = var(gm,n,:y_control_valve)
    y_k                = y_short_pipe[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistor[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves)
                                                                      == y_k * num_connections))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_valve_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves) where T <: AbstractMIForms
    y_pipe           = var(gm,n,:y_pipe)
    y_compressor     = var(gm,n,:y_compressor)
    y_resistor       = var(gm,n,:y_resistor)
    y_short_pipe     = var(gm,n,:y_short_pipe)
    y_valve          = var(gm,n,:y_valve)
    y_control_valve  = var(gm,n,:y_control_valve)
    y_k              = y_valve[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistor[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves)
                                                                      == y_k * num_connections))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_control_valve_parallel_flow(gm::GenericGasModel{T}, n::Int, k, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                 aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                 aligned_control_valves, opposite_control_valves) where T <: AbstractMIForms
    y_pipe           = var(gm,n,:y_pipe)
    y_compressor     = var(gm,n,:y_compressor)
    y_resistor       = var(gm,n,:y_resistor)
    y_short_pipe     = var(gm,n,:y_short_pipe)
    y_valve          = var(gm,n,:y_valve)
    y_control_valve  = var(gm,n,:y_control_valve)
    y_k              = y_control_valve[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(y_pipe[i] for i in aligned_pipes) + sum((1-y_pipe[i]) for i in opposite_pipes) +
                                                                      sum(y_compressor[i] for i in aligned_compressors) + sum((1-y_compressor[i]) for i in opposite_compressors) +
                                                                      sum(y_resistor[i] for i in aligned_resistors) + sum((1-y_resistance[i]) for i in opposite_resistors) +
                                                                      sum(y_short_pipe[i] for i in aligned_short_pipes) + sum((1-y_short_pipe[i]) for i in opposite_short_pipes) +
                                                                      sum(y_valve[i] for i in aligned_valves) + sum((1-y_valve[i]) for i in opposite_valves) +
                                                                      sum(y_control_valve[i] for i in aligned_control_valves) + sum((1-y_control_valve[i]) for i in opposite_control_valves)
                                                                      == y_k * num_connections))
end
