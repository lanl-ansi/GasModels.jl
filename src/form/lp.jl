# Define MIP implementations of Gas Models

#################################################################################################
### Variables
#################################################################################################

"continous relaxation of variables associated with operating valves"
function variable_valve_on_off_operation(gm::AbstractLPModel, nw::Int=gm.cnw; report::Bool=true)
    v_valve = gm.var[:nw][nw][:v_valve] = JuMP.@variable(gm.model,
        [l in keys(gm.ref[:nw][nw][:valve])],
        upper_bound=1.0,
        lower_bound=0.0,
        base_name="$(nw)_v_valve",
        start=comp_start_value(gm.ref[:nw][nw][:valve], l, "v_start", 1.0)
    )

    report && _IM.sol_component_value(gm, nw, :valve, :v, ids(gm, nw, :valve), v_valve)
end

"continous relaxation of variables associated with operating regulators"
function variable_on_off_operation(gm::AbstractLPModel, nw::Int=gm.cnw; report::Bool=true)
    v_regulator = gm.var[:nw][nw][:v_regulator] = JuMP.@variable(gm.model,
        [l in keys(gm.ref[:nw][nw][:regulator])],
        upper_bound=1.0,
        lower_bound=0.0,
        base_name="$(nw)_v_regulator",
        start=comp_start_value(gm.ref[:nw][nw][:regulator], l, "v_start", 1.0)
    )

    report && _IM.sol_component_value(gm, nw, :regulator, :v, ids(gm, nw, :regulator), v_regulator)
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


"Constraint: Constraint on pressure drop across a short pipe--not applicable for LP models"
function constraint_short_pipe_pressure(gm::AbstractLPModel, n::Int, k, i, j)
end


"Constraint: Compressor ratio constraints on pressure differentials--not applicable for LP models"
function constraint_compressor_ratios(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
end


"Constraint: Constraints on pressure drop across valves where the valve can open or close--not applicable for LP models"
function constraint_on_off_valve_pressure(gm::AbstractLPModel, n::Int, k, i, j, i_pmax, j_pmax)
end


"constraints on pressure drop across control valves that are undirected--not applicable for LP models"
function constraint_on_off_regulator_pressure(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, f_min, i_pmin, i_pmax, j_pmin, j_pmax)
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
function constraint_pipe_pressure_ne(gm::AbstractLPModel, n::Int, k, i, j, pd_min, pd_max, pd_min_M, pd_max_M)
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractLPModel, n::Int, k, i, j)
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractLPModel, n::Int, k, power_max, work)
end
