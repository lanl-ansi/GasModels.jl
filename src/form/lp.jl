# Define MIP implementations of Gas Models

export
    LPGasModel, StandardLPForm

""
abstract type AbstractLPForm <: AbstractGasFormulation end

""
abstract type StandardLPForm <: AbstractLPForm end

const LPGasModel = GenericGasModel{StandardLPForm} # the standard LP model

"default LP constructor"
LPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardLPForm)

#################################################################################################
### Variables
#################################################################################################

" continous relaxation of variables associated with operating valves "
function variable_valve_operation(gm::GenericGasModel{T}, n::Int=gm.cnw) where T <: AbstractLPForm
    gm.var[:nw][n][:v] = @variable(gm.model, [l in [collect(keys(gm.ref[:nw][n][:valve])); collect(keys(gm.ref[:nw][n][:control_valve]))]],  upper_bound=1.0, lower_bound=0.0, base_name="$(n)_v", start = getstart(gm.ref[:nw][n][:connection], l, "v_start", 1.0))
end

######################################################################################################
## Constraints
######################################################################################################

"Constraint: Weymouth equation--not applicable for LP models"
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max) where T <: AbstractLPForm
    #TODO we could think about putting a polyhendra around the weymouth
end

"Constraint: Weymouth equation with one way direction--not applicable for LP models"
function constraint_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, yp, yn) where T <: AbstractLPForm
    #TODO we could think about putting a polyhendra around the weymouth
end

" Constraint: constraints on pressure drop across where direction is constrained"
function constraint_pressure_drop_directed(gm::GenericGasModel{T}, n::Int, k, i, j, yp, yn) where T <: AbstractLPForm
end

" Constraint: Constraint on pressure drop across a short pipe--not applicable for LP models"
function constraint_short_pipe_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j) where T <: AbstractLPForm
end

"Constraint: Compressor ratio constraints on pressure differentials--not applicable for LP models"
function constraint_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio) where T <: AbstractLPForm
end

" Constraint: Compressor ratio when the flow direction is constrained--not applicable for LP models"
function constraint_compressor_ratios_directed(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, yp, yn) where T <: AbstractLPForm
end

" Constraint: Constraints on pressure drop across valves where the valve can open or close--not applicable for LP models"
function constraint_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, i_pmax, j_pmax) where T <: AbstractLPForm
end

" constraints on pressure drop across control valves that are undirected--not applicable for LP models"
function constraint_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractLPForm
end

" Constraint: Pressure drop across a control valves when directions is constrained--not applicable for LP models"
function constraint_control_valve_pressure_drop_directed(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, yp, yn) where T <: AbstractLPForm
end

"Constraint: Weymouth equation--not applicable for MIP models--not applicable for LP models"
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max) where T <: AbstractLPForm
end

" Constraint: Pressure drop across an expansion pipe when direction is constrained--not applicable for LP models"
function constraint_pressure_drop_ne_directed(gm::GenericGasModel{T}, n::Int, k, i, j, yp, yn) where T <: AbstractLPForm
end

"Constraint: Weymouth equation--not applicable for MIP models--not applicable for LP models"
function constraint_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, yp, yn) where T <: AbstractLPForm
end

"Constraint: compressor ratios on a new compressor--not applicable for MIP models-not applicable for LP models"
function constraint_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax) where T <: AbstractLPForm
end

" Constraint: Pressure drop across an expansion compressor when direction is constrained-not applicable for LP models"
function constraint_compressor_ratios_ne_directed(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, yp, yn) where T <: AbstractLPForm
end
