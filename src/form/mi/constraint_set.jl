################################################################################################################
## This file contains definitions for utility functions which collect constraints into sets which are often    #
## used together to define one concept.  For example, constraints associated with the balance of flow at a     #
## junction. In some cases, the set of constraints may vary depending on the formulation.                      #
################################################################################################################

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
