################################################################################################################
## This file contains definitions for utility functions which collect constraints into sets which are often    #
## used together to define one concept.  For example, constraints associated with the balance of flow at a     #
## junction. In some cases, the set of constraints may vary depending on the formulation.                      #
################################################################################################################

"Constraint: Constraint for computing mass flow balance at node"
function constraint_set_junction_mass_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
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

#    if fg == 0.0 && fl == 0.0 && junction["degree"] == 2
    if fg == 0.0 && fl == 0.0 && ref(gm,n,:degree)[i] == 2
        constraint_conserve_flow(gm, n, i)
    end
end

"Constraint: Constraints for computing mass flow balance at node when injections are variables"
function constraint_set_junction_mass_flow_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
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

#    if fgmax == 0 && fgmin == 0 && fg == 0 && flmax == 0 && flmin == 0 && fl == 0 && junction["degree"] == 2
    if fgmax == 0 && fgmin == 0 && fg == 0 && flmax == 0 && flmin == 0 && fl == 0 && ref(gm,n,:degree)[i] == 2
        constraint_conserve_flow(gm, n, i)
    end
end

"Constraint: Constraint for computing mass flow balance at node when there are expansion edges"
function constraint_set_junction_mass_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
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

#    if fg == 0.0 && fl == 0.0 && junction["degree_all"] == 2
    if fg == 0.0 && fl == 0.0 && ref(gm,n,:degree_ne)[i] == 2
        constraint_conserve_flow_ne(gm, n, i)
    end
end

"Constraint: Constraints for computing mass flow balance at node when there are expansion edges and variable injections"
function constraint_set_junction_mass_flow_ne_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
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
#    if fgmax == 0 && fgmin == 0 && fg == 0 && flmax == 0 && flmin == 0 && fl == 0 && junction["degree_all"] == 2
    if fgmax == 0 && fgmin == 0 && fg == 0 && flmax == 0 && flmin == 0 && fl == 0 && ref(gm,n,:degree_ne)[i] == 2
        constraint_conserve_flow_ne(gm, i)
    end
end

"Constraint: Constraints which define the pressure drop across a pipe when there are on/off direction variables"
function constraint_set_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_mass_flow(gm, i)
    constraint_weymouth(gm, i)
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraint: Constraints for modeling flow on a short pipe with on/off direction variables"
function constraint_set_short_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_on_off_short_pipe_flow(gm, i)
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraint: Constraints on flow through a compressor where the compressor has on/off direction variables"
function constraint_set_compressor_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_flow(gm, i)
    constraint_on_off_compressor_ratios(gm, i)
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraint: Constraints on a valve that have on/off direction variables"
function constraint_set_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_valve_flow(gm, i)
    constraint_valve_pressure_drop(gm, i)
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraint: Constraints on flow on control valves with on/off direction variables"
function constraint_set_control_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_control_valve_flow(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraint: All Constraints for an expansion pipe when there are on/off direction variables"
function constraint_set_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_pressure_drop_ne(gm, i)
    constraint_on_off_pipe_flow_ne(gm, i)
    constraint_pipe_ne(gm, i)
    constraint_weymouth_ne(gm, i)
    constraint_flow_direction_choice_ne(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

"Constraint: Constraints through a new compressor that has on/off direction variables"
function constraint_set_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_flow_ne(gm, i)
    constraint_on_off_compressor_ratios_ne(gm, i)
    constraint_compressor_ne(gm, i)
    constraint_flow_direction_choice_ne(gm, i)
    constraint_parallel_flow_ne(gm, i)
end
