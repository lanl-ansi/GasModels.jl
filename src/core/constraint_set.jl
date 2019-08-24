################################################################################################################
## This file contains definitions for utility functions which collect constraints into sets which are often    #
## used together to define one concept.  For example, constraints associated with the balance of flow at a     #
## junction. In some cases, the set of constraints may vary depending on the formulation.                      #
################################################################################################################

"Template: All constraints associated with flows at a junction"
constraint_set_junction_mass_flow(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow(gm, gm.cnw, i)

"Template: All constraints associated with flows at a junction with variable production and consumption "
constraint_set_junction_mass_flow_ls(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow_ls(gm, gm.cnw, i)

"Template: All constraints associated with flows at a junction with new pipe options"
constraint_set_junction_mass_flow_ne(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow_ne(gm, gm.cnw, i)

"Template: All constraints associated with flows at a junction with variable production and consumption "
constraint_set_junction_mass_flow_ne_ls(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow_ne_ls(gm, gm.cnw, i)

"Template: All constraints associated with flows at a junction with some directed edges"
constraint_set_junction_mass_flow_directed(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow_directed(gm, gm.cnw, i)

"Template: All constraints associated with flows through at a junction with variable production and consumption and some directed edges"
constraint_set_junction_mass_flow_ls_directed(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow_ls_directed(gm, gm.cnw, i)

"Template: All constraints associated with flows through at a junction with expansion options and some directed edges"
constraint_set_junction_mass_flow_ne_directed(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow_ne_directed(gm, gm.cnw, i)

"Template: All constraints associated with flows through at a junction with expansion options, some directed edges, and variable production and consumption"
constraint_set_junction_mass_flow_ne_ls_directed(gm::GenericGasModel, i::Int) = constraint_set_junction_mass_flow_ne_ls_directed(gm, gm.cnw, i)

"Template: All constraints associated with flows through a pipe"
constraint_set_pipe_flow(gm::GenericGasModel, k::Int) = constraint_set_pipe_flow(gm, gm.cnw, k)

"Template: All constraints associated with flows through a pipe that has flow in one direction"
constraint_set_pipe_flow_directed(gm::GenericGasModel, k::Int) = constraint_set_pipe_flow_directed(gm, gm.cnw, k)

"Template: All constraints associated with flows through a short pipe"
constraint_set_short_pipe_flow(gm::GenericGasModel, k::Int) = constraint_set_short_pipe_flow(gm, gm.cnw, k)

"Template: All constraints associated with flows through a short pipe that has flow in one direction"
constraint_set_short_pipe_flow_directed(gm::GenericGasModel, k::Int) = constraint_set_short_pipe_flow_directed(gm, gm.cnw, k)

"Template: All constraints associated with flows through a compressor"
constraint_set_compressor_flow(gm::GenericGasModel, k::Int) = constraint_set_compressor_flow(gm, gm.cnw, k)

"Template: All constraints associated with flows through a compressor that has flow in one direction"
constraint_set_compressor_flow_directed(gm::GenericGasModel, k::Int) = constraint_set_compressor_flow_directed(gm, gm.cnw, k)

"Template: All constraints associated with flows through a valve"
constraint_set_valve_flow(gm::GenericGasModel, k::Int) = constraint_set_valve_flow(gm, gm.cnw, k)

"Template: All constraints associated with flows through a valve that has flow in one direction"
constraint_set_valve_flow_directed(gm::GenericGasModel, k::Int) = constraint_set_valve_flow_directed(gm, gm.cnw, k)

"Template: All constraints associated with flows through a control valve"
constraint_set_control_valve_flow(gm::GenericGasModel, k::Int) = constraint_set_control_valve_flow(gm, gm.cnw, k)

"Template: All constraints associated with flows through a control valve that has flow in one direction"
constraint_set_control_valve_flow_directed(gm::GenericGasModel, k::Int) = constraint_set_control_valve_flow_directed(gm, gm.cnw, k)

"Template: All constraints associated with flows through an expansion pipe"
constraint_set_pipe_flow_ne(gm::GenericGasModel, k::Int) = constraint_set_pipe_flow_ne(gm, gm.cnw, k)

"Template: All constraints associated with flows through an expansion pipe which has flow in one direction"
constraint_set_pipe_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_set_pipe_flow_ne_directed(gm, gm.cnw, k)

"Template: All constraints associated with flows through an expansion compressor"
constraint_set_compressor_flow_ne(gm::GenericGasModel, k::Int) = constraint_set_compressor_flow_ne(gm, gm.cnw, k)

"Template: All constraints associated with flows through an expansion compressor which has flow in one direction"
constraint_set_compressor_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_set_compressor_flow_ne_directed(gm, gm.cnw, k)

"Constraint: Constraints for computing mass flows at a junction"
function constraint_set_junction_mass_flow(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance(gm, n, i)
end

"Constraint: Constraints for computing mass flows at a junction with load variables"
function constraint_set_junction_mass_flow_ls(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance_ls(gm, n, i)
end

"Constraint: Constraints for computing mass flows at junctions with expansion variables"
function constraint_set_junction_mass_flow_ne(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance_ne(gm, n, i)
end

"Constraint: Constraints for computing mass flows at junctions with expansion and load variables"
function constraint_set_junction_mass_flow_ne_ls(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
end

"Constraint: Constraints for computing mass flow balance at a junction when some edges are directed"
function constraint_set_junction_mass_flow_directed(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance(gm, n, i)
end

"Constraint: Constraints for computing mass flows at a junction when injections are variables and some edges are directed"
function constraint_set_junction_mass_flow_ls_directed(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance_ls(gm, n, i)
end

"Constraint: Constraints for computing mass flows at a junction when there are expansion edges and some edges are directed"
function constraint_set_junction_mass_flow_ne_directed(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance_ne(gm, n, i)
end

"Constraint: Constraints for computing mass flows at a junction when there are expansion edges, variable injections, and some edges are directed"
function constraint_set_junction_mass_flow_ne_ls_directed(gm::GenericGasModel, n::Int, i)
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
end

"Constraint: Constraints which define flow across a pipe"
function constraint_set_pipe_flow(gm::GenericGasModel, n::Int, i)
    constraint_pipe_mass_flow(gm, i)
    constraint_weymouth(gm, i)
end

"Constraint: Constraints which define the flow across a pipe when the pipe is directed"
function constraint_set_pipe_flow_directed(gm::GenericGasModel, n::Int, i)
    constraint_pressure_drop_directed(gm, i)
    constraint_pipe_flow_directed(gm, i)
    constraint_weymouth_directed(gm, i)
end

"Constraint: Constraints for modeling flow on a short pipe"
function constraint_set_short_pipe_flow(gm::GenericGasModel, n::Int, i)
    constraint_short_pipe_pressure_drop(gm, i)
end

"Constraint: Constraints for modeling flow on a short pipe with a known direction"
function constraint_set_short_pipe_flow_directed(gm::GenericGasModel, n::Int, i)
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_short_pipe_flow_directed(gm, i)
end

"Constraint: Constraints on flow through a compressor"
function constraint_set_compressor_flow(gm::GenericGasModel, n::Int, i)
    constraint_compressor_ratios(gm, i)
end

"Constraint: Constraints on flow through a compressor where the compressor has a known direction of flow"
function constraint_set_compressor_flow_directed(gm::GenericGasModel, n::Int, i)
    constraint_compressor_flow_directed(gm, i)
    constraint_compressor_ratios_directed(gm, i)
end

"Constraints: Valve flow"
function constraint_set_valve_flow(gm::GenericGasModel, n::Int, i)
    constraint_on_off_valve_flow(gm, i)
    constraint_valve_pressure_drop(gm, i)
end

"Constraint: constraints on a valve that has known flow direction"
function constraint_set_valve_flow_directed(gm::GenericGasModel, n::Int, i)
    constraint_valve_flow_directed(gm, i)
    constraint_valve_pressure_drop(gm, i)
end

"Constraints Constraints on flow through a control valve"
function constraint_set_control_valve_flow(gm::GenericGasModel, n::Int, i)
    constraint_on_off_control_valve_flow(gm, i)
    constraint_control_valve_pressure_drop(gm, i)
end

"Constraint: Constraints on flow through a control valve where the direction of flow is known"
function constraint_set_control_valve_flow_directed(gm::GenericGasModel, n::Int, i)
    constraint_control_valve_flow_directed(gm, i)
    constraint_control_valve_pressure_drop_directed(gm, i)
end

"Constraint: Constraints which define flow across a pipe"
function constraint_set_pipe_flow_ne(gm::GenericGasModel, n::Int, i)
    constraint_pipe_ne(gm, i)
    constraint_weymouth_ne(gm, i)
end

"Constraint: Constraints for an expansion pipe where the direction of flow is constrained"
function constraint_set_pipe_flow_ne_directed(gm::GenericGasModel, n::Int, i)
    constraint_pressure_drop_ne_directed(gm, i)
    constraint_pipe_flow_ne_directed(gm, i)
    constraint_pipe_ne(gm, i)
    constraint_weymouth_ne_directed(gm, i)
end

"Constraints through a new compressor that is undirected"
function constraint_set_compressor_flow_ne(gm::GenericGasModel, n::Int, i)
    constraint_compressor_ratios_ne(gm, i)
    constraint_compressor_ne(gm, i)
end

"Constraint: Constraints through a new compressor that has a known flow direction"
function constraint_set_compressor_flow_ne_directed(gm::GenericGasModel, n::Int, i)
    constraint_compressor_ne(gm, i)
    constraint_compressor_flow_ne_directed(gm, i)
    constraint_compressor_ratios_ne_directed(gm, i)
end
