# Define LP implementations of Gas Models

######################################################################################################
## Constraints
######################################################################################################

"Constraint: Weymouth equation--not applicable for LP models"
function constraint_pipe_weymouth(gm::AbstractLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in nlp.jl
end


"Constraint: Weymouth equation--not applicable for LP models"
function constraint_resistor_weymouth(gm::AbstractLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    #TODO Linear convex hull of the weymouth equations in nlp.jl
end


"Constraint: Compressor ratio constraints on pressure differentials--not applicable for LP models"
function constraint_compressor_ratios(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
    #TODO Linear convex hull of compressor ratio equations in nlp.jl
end


"constraints on pressure drop across control valves--not applicable for LP models"
function constraint_on_off_regulator_pressure(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, f_min, i_pmin, i_pmax, j_pmin, j_pmax)
        #TODO Linear convex hull of equations in nlp.jl
end


"Constraint: Weymouth equation--not applicable for MIP models--not applicable for LP models"
function constraint_pipe_weymouth_ne(gm::AbstractLPModel,  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
        #TODO Linear convex hull equations in nlp.jl
end


"Constraint: compressor ratios on a new compressor--not applicable for MIP models-not applicable for LP models"
function constraint_compressor_ratios_ne(gm::AbstractLPModel, n::Int, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
    #TODO Linear convex hull equations in nlp.jl
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractLPModel, n::Int, k, i, j)
    #TODO Linear convex hull equations in nlp.jl
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value_ne(gm::AbstractLPModel, n::Int, k, i, j)
    #TODO Linear convex hull equations in nlp.jl
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractLPModel, n::Int, k, power_max, m, work)
    #TODO Linear convex hull equations in nlp.jl
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy_ne(gm::AbstractLPModel, n::Int, k, power_max, m, work)
    #TODO Linear convex hull equations in nlp.jl
end
