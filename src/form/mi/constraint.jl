########################################################################################################
## Versions of constraints used to compute flow balance
########################################################################################################

##############################################################################################################
# Constraints that don't need a template
#############################################################################################################

" Constraints which state a flow direction must be chosen "
constraint_flow_direction_choice(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice(gm, gm.cnw, i)

" Constraint that states a flow direction must be chosen for expansion connections "
constraint_flow_direction_choice_ne(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice_ne(gm, gm.cnw, i)

"Constraint for computing mass flow balance at node"
function constraint_junction_mass_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    junction = ref(gm,n,:junction,i)
    constraint_junction_mass_flow_balance(gm, n, i)

    consumer   = ref(gm,n,:consumer)
    producer   = ref(gm,n,:producer)
    consumers  = ref(gm,n,:junction_consumers,i)
    producers  = ref(gm,n,:junction_producers,i)

    fg         = length(producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in producers) : 0
    fl         = length(consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in consumers) : 0

    if fg > 0.0 && fl == 0.0
        constraint_source_flow(gm, n, i)
    end

    if fg == 0.0 && fl > 0.0
        constraint_sink_flow(gm, n, i)
    end

    if fg == 0.0 && fl == 0.0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)
    end
end

"Constraint for computing mass flow balance at a node when some edges are directed"
function constraint_junction_mass_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_junction_mass_flow_balance(gm, n, i)
    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end

"Constraint for computing mass flow balance at node when injections are variables"
function constraint_junction_mass_flow_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    junction = ref(gm,n,:junction,i)
    constraint_junction_mass_flow_balance_ls(gm, n, i)

    consumer   = ref(gm,n,:consumer)
    producer   = ref(gm,n,:producer)
    consumers  = ref(gm,n,:junction_consumers,i)
    producers  = ref(gm,n,:junction_producers,i)
    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg        = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl        = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0
    fgmax     = length(dispatch_producers) > 0 ? sum(calc_fgmax(gm.data, producer[j]) for j in dispatch_producers) : 0
    flmax     = length(dispatch_consumers) > 0 ? sum(calc_flmax(gm.data, consumer[j]) for j in dispatch_consumers) : 0
    fgmin     = length(dispatch_producers) > 0 ? sum(calc_fgmin(gm.data, producer[j]) for j in dispatch_producers) : 0
    flmin     = length(dispatch_consumers) > 0 ? sum(calc_flmin(gm.data, consumer[j]) for j in dispatch_consumers) : 0

    if max(fgmin,fg) > 0.0  && flmin == 0.0 && flmax == 0.0 && fl == 0.0 && fgmin >= 0.0
        constraint_source_flow(gm, n, i)
    end

    if fgmax == 0.0 && fgmin == 0.0 && fg== 0.0 && max(flmin,fl) > 0.0 && flmin >= 0.0
        constraint_sink_flow(gm, n, i)
    end

    if fgmax == 0 && fgmin == 0 && fg == 0 && flmax == 0 && flmin == 0 && fl == 0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)
    end
end

"Constraint for computing mass flow balance at node when injections are variables and some edges are directed"
function constraint_junction_mass_flow_ls_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_junction_mass_flow_balance_ls(gm, n, i)
    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end

"Constraint for computing mass flow balance at node when there are expansion edges"
function constraint_junction_mass_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    junction = ref(gm,n,:junction,i)
    constraint_junction_mass_flow_balance_ne(gm, n, i)

    consumer   = ref(gm,n,:consumer)
    producer   = ref(gm,n,:producer)
    consumers  = ref(gm,n,:junction_consumers,i)
    producers  = ref(gm,n,:junction_producers,i)

    fg     = length(producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in producers) : 0
    fl     = length(consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in consumers) : 0

    if fg > 0.0 && fl == 0.0
        constraint_source_flow_ne(gm, n, i)
    end
    if fg == 0.0 && fl > 0.0
        constraint_sink_flow_ne(gm, n, i)
    end
    if fg == 0.0 && fl == 0.0 && junction["degree_all"] == 2
        constraint_conserve_flow_ne(gm, n, i)
    end
end

"Constraint for computing mass flow balance at node when there are expansion edges and some edges are directed"
function constraint_junction_mass_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_junction_mass_flow_balance_ne(gm, n, i)
    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end

"Constraint for computing mass flow balance at node when there are expansion edges and variable injections"
function constraint_junction_mass_flow_ne_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    junction = ref(gm,n,:junction,i)
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)

    consumer   = ref(gm,n,:consumer)
    producer   = ref(gm,n,:producer)
    consumers  = ref(gm,n,:junction_consumers,i)
    producers  = ref(gm,n,:junction_producers,i)
    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg        = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl        = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0
    fgmax     = length(dispatch_producers) > 0 ? sum(calc_fgmax(gm.data, producer[j])  for  j in dispatch_producers) : 0
    flmax     = length(dispatch_consumers) > 0 ? sum(calc_flmax(gm.data, consumer[j])  for  j in dispatch_consumers) : 0
    fgmin     = length(dispatch_producers) > 0 ? sum(calc_fgmin(gm.data, producer[j])  for  j in dispatch_producers) : 0
    flmin     = length(dispatch_consumers) > 0 ? sum(calc_flmin(gm.data, consumer[j])  for  j in dispatch_consumers) : 0

    if max(fgmin,fg) > 0.0  && flmin == 0.0 && flmax == 0.0 && fl == 0.0 && fgmin >= 0.0
        constraint_source_flow_ne(gm, i)
    end
    if fgmax == 0.0 && fgmin == 0.0 && fg == 0.0 && max(flmin,fl) > 0.0 && flmin >= 0.0
        constraint_sink_flow_ne(gm, i)
    end
    if fgmax == 0 && fgmin == 0 && fg == 0 && flmax == 0 && flmin == 0 && fl == 0 && junction["degree_all"] == 2
        constraint_conserve_flow_ne(gm, i)
    end
end

"Constraint for computing mass flow balance at node when there are expansion edges, variable injections, and some edges are directed"
function constraint_junction_mass_flow_ne_ls_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end

#############################################################################################################
## Constraints for modeling flow across a pipe
############################################################################################################

"Constraints the define the pressure drop across a pipe"
function constraint_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow(gm, i)
    constraint_weymouth(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraints the define the pressure drop across a pipe when some pipe directions are known"
function constraint_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_pressure_drop_one_way(gm, i)
    constraint_pipe_flow_one_way(gm, i)
    constraint_weymouth_one_way(gm, i)
end

" constraints for modeling flow across an undirected pipe when there are new edges "
function constraint_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow(gm, i)
    constraint_weymouth(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

" constraints on pressure drop across an undirected pipe"
function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop1, k, @constraint(gm.model, (1-yp) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop2, k, @constraint(gm.model, pi - pj <= (1-yn)* pd_max))
end

" constraint on flow across an undirected pipe "
function constraint_on_off_pipe_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_pipe_flow1, k, @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f))
    add_constraint(gm, n, :on_off_pipe_flow2, k, @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(pd_max, abs(pd_min))))))
end

#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################

"Constraints for an expansion pipe with undirected flow"
function constraint_new_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_pressure_drop_ne(gm, i)
    constraint_on_off_pipe_flow_ne(gm, i)
    constraint_on_off_pipe_ne(gm, i)
    constraint_weymouth_ne(gm, i)

    constraint_flow_direction_choice_ne(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

"Constraints for an expansion pipe with undirected flow"
function constraint_new_pipe_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_pressure_drop_ne_one_way(gm, i)
    constraint_pipe_flow_ne_one_way(gm, i)
    constraint_on_off_pipe_ne(gm, i)
    constraint_weymouth_ne_one_way(gm, i)
end

" constraints on pressure drop across an undirected expansion pipe "
function constraint_on_off_pressure_drop_ne(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop_ne1, k, @constraint(gm.model, (1-yp) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop_ne2, k, @constraint(gm.model, pi - pj <= (1-yn)* pd_max))
end

" constraints on flow across an expansion undirected pipe "
function constraint_on_off_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)

    f  = var(gm,n,:f_ne,k)
    add_constraint(gm, n, :on_off_pipe_flow_ne1, k, @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(abs(pd_max), abs(pd_min)))) <= f))
    add_constraint(gm, n, :on_off_pipe_flow_ne2, k, @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(abs(pd_max), abs(pd_min))))))
end

###########################################################################################
### Short pipe constriants
###########################################################################################

" Constraints for modeling flow on an undirected short pipe"
function constraint_short_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_on_off_short_pipe_flow(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

" Constraints for modeling flow on a directed short pipe"
function constraint_short_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_short_pipe_flow_one_way(gm, i)
end

#" Constraints for modeling flow on an undirected short pipe for expansion planning models"
#function constraint_short_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
#    constraint_short_pipe_pressure_drop(gm, i)
#    constraint_on_off_short_pipe_flow(gm, i)

#    constraint_flow_direction_choice(gm, i)
#    constraint_parallel_flow_ne(gm, i)
#end

" constraints on flow across an undirected short pipe "
function constraint_on_off_short_pipe_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)

    f = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_short_pipe_flow1, k, @constraint(gm.model, -mf*(1-yp) <= f))
    add_constraint(gm, n, :on_off_short_pipe_flow2, k, @constraint(gm.model, f <= mf*(1-yn)))
end

" constraints on flow across an undirected short pipe "
function constraint_on_off_short_pipe_flow(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    pipe = ref(gm,n,:connection,k)

    i  = pipe["f_junction"]
    j  = pipe["t_junction"]
    mf = ref(gm,n,:max_mass_flow)

    constraint_on_off_short_pipe_flow(gm, n, k, i, j, mf)
end
constraint_on_off_short_pipe_flow(gm::GenericGasModel, k::Int) = constraint_on_off_short_pipe_flow(gm, gm.cnw, k)


######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

"Constraints on flow through a compressor where the compressor is undirected"
function constraint_compressor_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_flow(gm, i)
    constraint_on_off_compressor_ratios(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraints on flow through a compressor where the compressor is directed"
function constraint_compressor_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_compressor_flow_one_way(gm, i)
    constraint_compressor_ratios_one_way(gm, i)
end

"Constraints through a new compressor that is undirected"
function constraint_new_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_flow_ne(gm, i)
    constraint_on_off_compressor_ratios_ne(gm, i)
    constraint_on_off_compressor_ne(gm, i)

    constraint_flow_direction_choice_ne(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

"Constraints through a new compressor that is directed"
function constraint_new_compressor_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_ne(gm, i)
    constraint_compressor_flow_ne_one_way(gm, i)
    constraint_compressor_ratios_ne_one_way(gm, i)
end

#"Constraints through a compressor that is undirected in an expansion model"
#function constraint_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
#    constraint_on_off_compressor_flow(gm, i)
#    constraint_on_off_compressor_ratios(gm, i)

#    constraint_flow_direction_choice(gm, i)
#    constraint_parallel_flow_ne(gm, i)
#end

#"Constraints through a compressor that is directed in an expansion model"
#function constraint_compressor_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
#    constraint_compressor_flow_one_way(gm, i)
#    constraint_compressor_ratios_one_way(gm, i)
#end

" constraints on flow across an undirected compressor "
function constraint_on_off_compressor_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)

    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction1, k, @constraint(gm.model, -(1-yp)*mf <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction2, k, @constraint(gm.model, f <= (1-yn)*mf))
end



" enforces pressure changes bounds that obey compression ratios for an undirected compressor "
function constraint_on_off_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)

    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios3, k, @constraint(gm.model, pi - pj <= (1-yn)*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios4, k, @constraint(gm.model, pj - pi <= (1-yn)*(j_pmax^2)))

end

" constraints on flow across compressors "
function constraint_on_off_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)
    f  = var(gm,n,:f_ne,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne1, k, @constraint(gm.model, -(1-yp)*mf <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne2, k, @constraint(gm.model, f <= (1-yn)*mf))
end

" constraints on pressure drop across an undirected compressor "
function constraint_on_off_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, i_pmax) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)

    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)

    add_constraint(gm, n, :on_off_compressor_ratios_ne1, k, @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-yp-zc)*j_pmax^2))
    add_constraint(gm, n, :on_off_compressor_ratios_ne2, k, @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-yp-zc)*(min_ratio^2*i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios_ne3, k, @constraint(gm.model,  pi - (max_ratio^2*pj) <= (2-yn-zc)*i_pmax^2))
    add_constraint(gm, n, :on_off_compressor_ratios_ne4, k, @constraint(gm.model,  (min_ratio^2*pj) - pi <= (2-yn-zc)*(min_ratio^2*j_pmax^2)))

end

" constraints on a valve that is undirected"
function constraint_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_valve_flow(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

" constraints on a valve that is directed"
function constraint_valve_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_valve_flow_one_way(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)
end



" constraints on flow across undirected valves "
function constraint_on_off_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    constraint_on_off_valve_flow(gm, n, k, i, j, mf, yp, yn)
end

" constraints on flow across undirected valves "
function constraint_on_off_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf, yp, yn) where T <: AbstractMIForms
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n,:on_off_valve_flow_direction1, k, @constraint(gm.model, -mf*(1-yp) <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction2, k, @constraint(gm.model, f <= mf*(1-yn)))
    add_constraint(gm, n,:on_off_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end

#" constraints on flow across an undirected valve in an expansion planning model"
#function constraint_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
#    constraint_on_off_valve_flow(gm, i)
#    constraint_on_off_valve_pressure_drop(gm, i)

#    constraint_flow_direction_choice(gm, i)
#    constraint_parallel_flow_ne(gm, i)
#end

#" constraints on flow across a directed valve in an expansion planning model"
#function constraint_valve_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
#    constraint_on_off_valve_flow_one_way(gm, i)
#    constraint_on_off_valve_pressure_drop(gm, i)
#end

" constraints on flow an undirected control valve"
function constraint_control_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_control_valve_flow(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

" constraints on flow an directed control valve"
function constraint_control_valve_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_control_valve_flow_one_way(gm, i)
    constraint_control_valve_pressure_drop_one_way(gm, i)
end

######################################################
# Flow Constraints for control valves
#######################################################

" constraints on flow across control valves that are undirected "
function constraint_on_off_control_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)

    constraint_on_off_control_valve_flow(gm, n, k, i, j, mf, yp, yn)
end

" constraints on flow across control valves"
function constraint_on_off_control_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf, yp, yn) where T <: AbstractMIForms
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)

    add_constraint(gm, n, :on_off_control_valve_flow_direction1, k, @constraint(gm.model, -mf*(1-yp) <= f))
    add_constraint(gm, n, :on_off_control_valve_flow_direction2, k, @constraint(gm.model, f <= mf*(1-yn)))
    add_constraint(gm, n, :on_off_control_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f ))
    add_constraint(gm, n, :on_off_control_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end



" constraints on pressure drop across control valves that are undirected "
function constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)

    constraint_on_off_control_valve_pressure_drop(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, yp, yn)
end

" constraints on pressure drop across control valves"
function constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, yp, yn) where T <: AbstractMIForms
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v = var(gm,n,:v,k)

    add_constraint(gm, n, :on_off_control_valve_pressure_drop1, k, @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-yp-v)*j_pmax^2))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop2, k, @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-yp-v)*(i_pmax^2) ))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop3, k, @constraint(gm.model,  pj - pi <= (2-yn-v)*j_pmax^2))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop4, k, @constraint(gm.model,  pi - pj <= (2-yn-v)*(i_pmax^2)))
end

#"constraints on undirected control value flows for expansion planning"
#function constraint_control_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
#    constraint_on_off_control_valve_flow(gm, i)
#    constraint_on_off_control_valve_pressure_drop(gm, i)

#    constraint_flow_direction_choice(gm, i)
#    constraint_parallel_flow_ne(gm, i)
#end

#"constraints on directed control value flows for expansion planning"
#function constraint_control_valve_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
#    constraint_control_valve_flow_one_way(gm, i)
#    constraint_control_valve_pressure_drop_one_way(gm, i)
#end

######################################################################
# Constraints used for generating cuts on direction variables
#########################################################################

function constraint_flow_direction_choice(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    yp = var(gm,n,:yp,i)
    yn = var(gm,n,:yn,i)
    add_constraint(gm, n, :flow_direction_choice, i,  @constraint(gm.model, yp + yn == 1))
end

function constraint_flow_direction_choice_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,i)
    yn = var(gm,n,:yn_ne,i)
    add_constraint(gm, n, :flow_direction_choice_ne, i,  @constraint(gm.model, yp + yn == 1))
end

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    add_constraint(gm, n, :source_flow, i,  @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) >= 1))
end

" Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)

    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)
    add_constraint(gm, n, :source_flow_ne, i, @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) + sum(yp_ne[a] for a in f_branches_ne) + sum(yn_ne[a] for a in t_branches_ne) >= 1))
end

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    add_constraint(gm, n, :sink_flow, i, @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) >= 1))
end

" Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)
    add_constraint(gm, n, :sink_flow_ne, i, @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) + sum(yn_ne[a] for a in f_branches_ne) + sum(yp_ne[a] for a in t_branches_ne) >= 1))
end

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::GenericGasModel{T}, n::Int, i, yp_first, yn_first, yp_last, yn_last) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)

    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yn[i1]  == yp[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yp[i1]  == yn[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yn[i1] + yn[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yp[i1] + yp[i2] == 1))
            end
        end
    end

    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yn[i1] == yn[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yp[i1] == yp[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yn[i1] + yp[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yp[i1] + yn[i2] == 1))
            end
        end
    end

    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yp[i1]  == yp[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yn[i1]  == yn[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yp[i1] + yn[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yn[i1] + yp[i2] == 1))
            end
        end
    end

    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yp[i1] == yn[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yn[i1] == yp[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yp[i1] + yp[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yn[i1] + yn[i2] == 1))
            end
        end
    end
end

" This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow_ne(gm::GenericGasModel{T}, n::Int, idx, yp_first, yn_first, yp_last, yn_last) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)

    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yn1  == yp2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yp1  == yn2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yn1 + yn2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yp1 + yp2 == 1))
            end
        end
    end

    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yn1 == yn2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yp1 == yp2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yn1 + yp2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yp1 + yn2 == 1))

            end
        end
    end

    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yp1 == yp2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yn1 == yn2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yp1 + yn2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yn1 + yp2 == 1))

            end
        end
    end

    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yp1 == yn2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yn1 == yp2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yp1 + yp2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yn1 + yn2 == 1))
            end
        end
    end
end

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    add_constraint(gm, n, :parallel_flow, k, @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) == yp[k] * length(ref(gm,n,:parallel_connections,(i,j)))))
end

" ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)
    yp_i = haskey(ref(gm,n,:connection), k) ? yp[k] : yp_ne[k]

    add_constraint(gm, n, :parallel_flow_ne, k, @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) + sum(yp_ne[i] for i in f_connections_ne) + sum(yn_ne[i] for i in t_connections_ne) == yp_i * length(ref(gm,n,:all_parallel_connections,(i,j)))))
end
