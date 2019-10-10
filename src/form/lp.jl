# Define MIP implementations of Gas Models

#################################################################################################
### Variables
#################################################################################################

"continous relaxation of variables associated with operating valves"
function variable_valve_operation(gm::AbstractLPModel, n::Int=gm.cnw)
    gm.var[:nw][n][:v_valve] = JuMP.@variable(gm.model, [l in keys(gm.ref[:nw][n][:valve])],  upper_bound=1.0, lower_bound=0.0, base_name="$(n)_v_valve", start=comp_start_value(gm.ref[:nw][n][:valve], l, "v_start", 1.0))
    gm.var[:nw][n][:v_control_valve] = JuMP.@variable(gm.model, [l in keys(gm.ref[:nw][n][:control_valve])],  upper_bound=1.0, lower_bound=0.0, base_name="$(n)_v_control_valve", start=comp_start_value(gm.ref[:nw][n][:control_valve], l, "v_start", 1.0))
end


######################################################################################################
## Constraints
######################################################################################################

"Constraint: Weymouth equation--not applicable for LP models"
function constraint_pipe_weymouth(gm::AbstractLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO we could think about putting a polyhendra around the weymouth
end


"Constraint: Weymouth equation--not applicable for LP models"
function constraint_resistor_weymouth(gm::AbstractLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO we could think about putting a polyhendra around the weymouth
end


"Constraint: Weymouth equation with one way direction--not applicable for LP models"
function constraint_pipe_weymouth_directed(gm::AbstractLPModel, n::Int, k, i, j, w, f_min, f_max, direction)
    #TODO we could think about putting a polyhendra around the weymouth
end


"Constraint: Weymouth equation with one way direction--not applicable for LP models"
function constraint_resistor_weymouth_directed(gm::AbstractLPModel, n::Int, k, i, j, w, f_min, f_max, direction)
    #TODO we could think about putting a polyhendra around the weymouth
end


"Constraint: constraints on pressure drop across where direction is constrained"
function constraint_pipe_pressure_directed(gm::AbstractLPModel, n::Int, k, i, j, pd_min, pd_max)
end


"Constraint: constraints on pressure drop across where direction is constrained"
function constraint_resistor_pressure_directed(gm::AbstractLPModel, n::Int, k, i, j, pd_min, pd_max)
end


"Constraint: Constraint on pressure drop across a short pipe--not applicable for LP models"
function constraint_short_pipe_pressure(gm::AbstractLPModel, n::Int, k, i, j)
end


"Constraint: Compressor ratio constraints on pressure differentials--not applicable for LP models"
function constraint_compressor_ratios(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax)
end


"Constraint: Compressor ratio when the flow direction is constrained--not applicable for LP models"
function constraint_compressor_ratios_directed(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, direction)
end


"Constraint: Constraints on pressure drop across valves where the valve can open or close--not applicable for LP models"
function constraint_on_off_valve_pressure(gm::AbstractLPModel, n::Int, k, i, j, i_pmax, j_pmax)
end


"constraints on pressure drop across control valves that are undirected--not applicable for LP models"
function constraint_on_off_control_valve_pressure(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax)
end


"Constraint: Pressure drop across a control valves when directions is constrained--not applicable for LP models"
function constraint_on_off_control_valve_pressure_directed(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, yp, yn)
end


"Constraint: Weymouth equation--not applicable for MIP models--not applicable for LP models"
function constraint_pipe_weymouth_ne(gm::AbstractLPModel,  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
end


"Constraint: Pressure drop across an expansion pipe when direction is constrained--not applicable for LP models"
function constraint_pipe_pressure_drop_ne_directed(gm::AbstractLPModel, n::Int, k, i, j, yp, yn)
end


"Constraint: Pressure drop across an expansion pipe when direction is constrained--not applicable for LP models"
function constraint_resistor_pressure_drop_ne_directed(gm::AbstractLPModel, n::Int, k, i, j, yp, yn)
end


"Constraint: Weymouth equation--not applicable for MIP models--not applicable for LP models"
function constraint_pipe_weymouth_ne_directed(gm::AbstractLPModel,  n::Int, k, i, j, w, pd_min, pd_max, f_min, f_max, direction)
end


"Constraint: compressor ratios on a new compressor--not applicable for MIP models-not applicable for LP models"
function constraint_compressor_ratios_ne(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax)
end


"Constraint: Pressure drop across an expansion compressor when direction is constrained-not applicable for LP models"
function constraint_compressor_ratios_ne_directed(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, direction)
end


"Constraint: Constraints which define pressure drop across a pipe"
function constraint_pipe_pressure(gm::AbstractLPModel, n::Int, k, i, j, pd_min, pd_max)
end


"Constraint: Constraints which define pressure drop across a resistor"
function constraint_resistor_pressure(gm::AbstractLPModel, n::Int, k, i, j, pd_min, pd_max)
end


"Constraint: constraints on pressure drop across an expansion pipe"
function constraint_pipe_pressure_ne(gm::AbstractLPModel, n::Int, k, i, j, pd_min, pd_max)
end


"Constraint: constrains the ratio to be p_i * ratio = p_j"
function constraint_compressor_ratio_value(gm::AbstractLPModel, n::Int, k, i, j)
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractLPModel, n::Int, k, power_max, work)
end
