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
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

    add_constraint(gm, n, :weymouth1, k, @NLconstraint(gm.model, w*(pi - pj) == f * abs(f)))
end

"Weymouth equation with one way direction"
function constraint_weymouth_one_way(gm::GenericGasModel{T}, n::Int, k, i, j, w, yp, yn) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

    add_constraint(gm, n, :weymouth1, k, @NLconstraint(gm.model, w*(pi - pj) >= (yp-yn) * f^2))
    add_constraint(gm, n, :weymouth2, k, @NLconstraint(gm.model, w*(pi - pj) <= (yp-yn) * f^2))
end

#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################

"Weymouth equation for directed expansion pipes"
function constraint_weymouth_ne_one_way(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, yp, yn) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

    if yp == 1
        add_constraint(gm, n, :weymouth_ne1, k, @NLconstraint(gm.model, w*(pi - pj) >= f^2 - zp*mf^2))
        add_constraint(gm, n, :weymouth_ne2, k, @NLconstraint(gm.model, w*(pi - pj) <= f^2 + zp*mf^2))
    else
        add_constraint(gm, n, :weymouth_ne3, k, @NLconstraint(gm.model, w*(pj - pi) >= f^2 - zp*mf^2))
        add_constraint(gm, n, :weymouth_ne4, k, @NLconstraint(gm.model, w*(pj - pi) <= f^2 + zp*mf^2))
    end
end

" Weymouth equation for an undirected expansion pipe "
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

    add_constraint(gm, n, :weymouth_ne1, k, @NLconstraint(gm.model, w*(pi - pj) >= f * abs(f) - (1-zp)*mf^2))
    add_constraint(gm, n, :weymouth_ne2, k, @NLconstraint(gm.model, w*(pi - pj) <= f * abs(f) + (1-zp)*mf^2))
end

######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

" enforces pressure changes bounds that obey compression ratios for an undirected compressor. "
function constraint_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f = var(gm,n,:yn,f)

    #TODO this constraint is only valid if min_ratio = 1
    add_constraint(gm, n, :compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= 0))
    add_constraint(gm, n, :compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= 0))
    add_constraint(gm, n, :compressor_ratios3, k, @constraint(gm.model, f * (1-pj/pi) <= 0))
end

" constraints on pressure drop across a compressor "
function constraint_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)

    #TODO this constraint is only valid if min_ratio = 1
    add_constraint(gm, n, :compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-zc)*j_pmax^2))
    add_constraint(gm, n, :compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-zc)*(min_ratio*i_pmax^2)))
    add_constraint(gm, n, :compressor_ratios3, k, @constraint(gm.model, f * (1-pj/pi) <= (1-zc) * mf * (1-j_pmax^2/i_pmin^2)))
end

##########################################################################################################
# Constraints on control valves
##########################################################################################################

" constraints on pressure drop across control valves that are undirected "
function constraint_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v = var(gm,n,:v,k)

    #TODO this constraint is only valid if max_ratio = 1
    add_constraint(gm, n, :control_valve_pressure_drop1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
    add_constraint(gm, n, :control_valve_pressure_drop2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
    add_constraint(gm, n, :control_valve_pressure_drop3, k, @constraint(gm.model, f * (1-pj/pi) >= (1-zc) * mf * (1-j_pmax^2/i_pmin^2)))
end
