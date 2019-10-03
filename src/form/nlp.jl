# This file contains implementations of functions for the nlp formulation

export
    NLPGasModel, StandardNLPForm

""
abstract type AbstractNLPForm <: AbstractGasFormulation end

""
abstract type StandardNLPForm <: AbstractNLPForm end

const NLPGasModel = GenericGasModel{StandardNLPForm} # the standard NLP model

"default NLP constructor"
NLPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardNLPForm)

#############################################################################################################
## Constraints for modeling flow across a pipe
############################################################################################################

"Weymouth equation with absolute value "
function constraint_pipe_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_pipe,k)
    add_constraint(gm, n, :weymouth1, k, @NLconstraint(gm.model, (pi - pj) <= (f * abs(f))/w))
    add_constraint(gm, n, :weymouth2, k, @NLconstraint(gm.model, (pi - pj) >= (f * abs(f))/w))
end

"Weymouth equation with absolute value "
function constraint_resistor_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_resistor,k)
    add_constraint(gm, n, :weymouth1, k, @NLconstraint(gm.model, (pi - pj) <= (f * abs(f))/w))
    add_constraint(gm, n, :weymouth2, k, @NLconstraint(gm.model, (pi - pj) >= (f * abs(f))/w))
end

"Weymouth equation with one way direction"
function constraint_pipe_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, f_min, f_max, directed) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_pipe,k)

    if directed == 1
        add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, w*(pi - pj) >= f^2))
        add_constraint(gm, n, :weymouth_ne2, k, @constraint(gm.model, w*(pi - pj) <= f^2))
    else
        add_constraint(gm, n, :weymouth_ne3, k, @constraint(gm.model, w*(pj - pi) >= f^2))
        add_constraint(gm, n, :weymouth_ne4, k, @constraint(gm.model, w*(pj - pi) <= f^2))
    end
end

"Weymouth equation with one way direction"
function constraint_resistor_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, f_min, f_max, directed) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_resistor,k)

    if directed == 1
        add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, w*(pi - pj) >= f^2))
        add_constraint(gm, n, :weymouth_ne2, k, @constraint(gm.model, w*(pi - pj) <= f^2))
    else
        add_constraint(gm, n, :weymouth_ne3, k, @constraint(gm.model, w*(pj - pi) >= f^2))
        add_constraint(gm, n, :weymouth_ne4, k, @constraint(gm.model, w*(pj - pi) <= f^2))
    end
end

#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################

"Weymouth equation for directed expansion pipes"
function constraint_pipe_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, pd_min, pd_max, f_min, f_max, direction) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne_pipe,k)

    # The big M needs to be the min and max pressure difference in either direction multiplied by w (referenced by i to j or j to i)
    if direction == 1
        add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, w*(pi - pj) >= f^2 + (1-zp) * w * pd_min))
        add_constraint(gm, n, :weymouth_ne2, k, @constraint(gm.model, w*(pi - pj) <= f^2 + (1-zp) * w * pd_max))
    else
        add_constraint(gm, n, :weymouth_ne3, k, @constraint(gm.model, w*(pj - pi) >= f^2 - (1-zp) * w * pd_max))
        add_constraint(gm, n, :weymouth_ne4, k, @constraint(gm.model, w*(pj - pi) <= f^2 - (1-zp) * w * pd_min))
    end
end

" Weymouth equation for an undirected expansion pipe "
function constraint_pipe_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne_pipe,k)

    add_constraint(gm, n, :weymouth_ne1, k, @NLconstraint(gm.model, w*(pi - pj) >= f * abs(f) + (1-zp) * w * pd_min))
    add_constraint(gm, n, :weymouth_ne2, k, @NLconstraint(gm.model, w*(pi - pj) <= f * abs(f) + (1-zp) * w * pd_max))
end

######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

" enforces pressure changes bounds that obey compression ratios for an undirected compressor. "
function constraint_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_compressor,k)

    #TODO this constraint is only valid if min_ratio = 1
    add_constraint(gm, n, :compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= 0))
    add_constraint(gm, n, :compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= 0))
    add_constraint(gm, n, :compressor_ratios3, k, @constraint(gm.model, f*(pi - pj) <= 0))
end

" constraints on pressure drop across a compressor "
function constraint_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)
    f  = var(gm,n,:f_ne_compressor,k)

    M = abs(max(i_pmax,j_pmax)) - abs(min(i_pmin, j_pmin))
    #TODO this constraint is only valid if min_ratio = 1
    add_constraint(gm, n, :compressor_ratios_ne1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-zc)*j_pmax^2))
    add_constraint(gm, n, :compressor_ratios_ne2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-zc)*(min_ratio*i_pmax^2)))
    add_constraint(gm, n, :compressor_ratios_ne3, k, @constraint(gm.model, f * (pi - pj) <= (1-zc) * f_max * M))
end

##########################################################################################################
# Constraints on control valves
##########################################################################################################

" constraints on pressure drop across control valves that are undirected "
function constraint_on_off_control_valve_pressure(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v  = var(gm,n,:v_control_valve,k)
    f  = var(gm,n,:f_control_valve,k)

    M = abs(max(i_pmax,j_pmax)) - abs(min(i_pmin, j_pmin))
    #TODO this constraint is only valid if max_ratio = 1
    add_constraint(gm, n, :control_valve_pressure_drop1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
    add_constraint(gm, n, :control_valve_pressure_drop2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
    add_constraint(gm, n, :control_valve_pressure_drop3, k, @constraint(gm.model, f * (pi - pj) >= 0))
end

"Constraint: constrains the ratio to be p_i * ratio = p_j"
function constraint_compressor_ratio_value(gm::GenericGasModel{T}, n::Int, k, i, j) where T <: AbstractNLPForm
    pi    = var(gm,n,:p,i)
    pj    = var(gm,n,:p,j)
    r = var(gm,n,:r,k)
    add_constraint(gm, n, :compressor_ratio_value1, k, @constraint(gm.model, r * pi <= pj))
    add_constraint(gm, n, :compressor_ratio_value2, k, @constraint(gm.model, r * pi >= pj))
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::GenericGasModel{T}, n::Int, k, power_max) where T <: AbstractNLPForm
end
